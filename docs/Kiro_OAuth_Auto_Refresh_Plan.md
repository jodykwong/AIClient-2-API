# Kiro OAuth Token 自动化刷新方案

## 问题根因
- Kiro OAuth的**refreshToken**有效期约7-14天
- 过期后AIClient-2-API的token刷新返回400错误
- 当前代码只处理accessToken刷新，没有处理refreshToken过期的情况

## 解决策略：多层防护

```
用户层（低频手动）──┐
                   ↓
自动刷新层（高频自动）──┐
                      ↓
账号池轮转层（故障转移）──┐
                        ↓
跨平台同步层（可选）
```

---

## Phase 1: 基础设施改进 [P0]

### 1.1 修改 `src/claude/claude-kiro.js`

**位置**: 第479-525行 (initializeAuth刷新逻辑)

**改动**:
```javascript
// 在catch块中（第522-525行）添加400错误检测
} catch (error) {
    console.error('[Kiro Auth] Token refresh failed:', error.message);

    // 新增：检测refreshToken过期（400错误）
    if (error.response && error.response.status === 400) {
        console.error('[Kiro Auth] RefreshToken expired, needs re-authorization');
        // 触发重授权事件
        this.emit('refreshTokenExpired', {
            uuid: this.uuid,
            error: error.message
        });
    }
    throw new Error(`Token refresh failed: ${error.message}`);
}
```

**新增方法**:
```javascript
// 估算refreshToken过期时间（基于最后成功刷新时间+14天）
getRefreshTokenExpiresAt() {
    if (this.lastRefreshSuccess) {
        return new Date(this.lastRefreshSuccess.getTime() + 14 * 24 * 60 * 60 * 1000);
    }
    return null;
}

isRefreshTokenNearExpiry(warningDays = 3) {
    const expiresAt = this.getRefreshTokenExpiresAt();
    if (!expiresAt) return false;
    const warningTime = new Date(Date.now() + warningDays * 24 * 60 * 60 * 1000);
    return expiresAt <= warningTime;
}
```

### 1.2 修改 `src/adapter.js`

**位置**: 第290-296行 (KiroApiServiceAdapter.refreshToken)

**改动**:
```javascript
async refreshToken() {
    try {
        if (this.kiroApiService.isExpiryDateNear() === true) {
            console.log(`[Kiro] Expiry date is near, refreshing token...`);
            await this.kiroApiService.initializeAuth(true);
            // 新增：记录最后成功刷新时间
            this.kiroApiService.lastRefreshSuccess = new Date();
        }
        return Promise.resolve();
    } catch (error) {
        // 新增：捕获refreshToken过期错误
        if (error.message.includes('400') || error.message.includes('Token refresh failed')) {
            console.error('[Adapter] RefreshToken expired, broadcasting reauth event');
            // 通过EventEmitter或全局事件广播
            globalEventEmitter.emit('provider_needs_reauth', {
                provider: 'claude-kiro-oauth',
                uuid: this.kiroApiService.uuid,
                reason: 'refreshToken_expired'
            });
        }
        throw error;
    }
}
```

---

## Phase 2: 多账号轮转 [P1]

### 2.1 修改 `src/provider-pool-manager.js`

**在selectProvider方法中新增过滤**:
```javascript
// 排除refreshToken已过期的账号
const validProviders = providers.filter(p => {
    if (!p.config.isHealthy || p.config.isDisabled) return false;

    // 检查refreshToken是否过期
    if (p.config.refreshTokenExpiredAt) {
        if (new Date(p.config.refreshTokenExpiredAt) < new Date()) {
            this.markProviderUnhealthy(providerType, p.config, 'refreshToken expired');
            return false;
        }
    }
    return true;
});
```

**新增方法**:
```javascript
// 获取所有需要重授权的账号
getProvidersNeedingReauth(providerType) {
    const providers = this.providerStatus[providerType] || [];
    return providers.filter(p =>
        !p.config.isHealthy &&
        p.config.lastErrorMessage?.includes('refreshToken')
    );
}

// 标记账号需要重授权
markProviderNeedsReauth(providerType, uuid, reason) {
    const provider = this.findProvider(providerType, uuid);
    if (provider) {
        provider.config.needsReauth = true;
        provider.config.reauthReason = reason;
        this.saveProviderPoolsToFile();
    }
}
```

---

## Phase 3: Web UI 集成 [P2]

### 3.1 修改 `src/ui-manager.js`

**新增API端点**:
```javascript
// GET /api/tokens/status - 获取所有账号的token状态
app.get('/api/tokens/status', (req, res) => {
    const status = providerPoolManager.getProviderStatus('claude-kiro-oauth');
    res.json(status.map(p => ({
        uuid: p.config.uuid,
        name: p.config.name,
        isHealthy: p.config.isHealthy,
        needsReauth: p.config.needsReauth,
        lastRefreshSuccess: p.config.lastRefreshSuccess,
        refreshTokenExpiresAt: p.config.refreshTokenExpiredAt
    })));
});

// POST /api/tokens/reauth/:uuid - 触发重授权
app.post('/api/tokens/reauth/:uuid', async (req, res) => {
    const { uuid } = req.params;
    // 触发Device Code Flow
    const result = await handleKiroBuilderIDDeviceCode({}, { targetUuid: uuid });
    res.json(result);
});
```

**SSE事件广播**:
```javascript
// 监听全局事件，广播到前端
globalEventEmitter.on('provider_needs_reauth', (data) => {
    broadcastEvent('reauth_required', data);
});

globalEventEmitter.on('oauth_success', (data) => {
    broadcastEvent('oauth_success', data);
});
```

### 3.2 修改 `static/index.html`

**新增授权弹窗组件**: 在适当位置添加模态框，显示设备码和授权链接

---

## Phase 4: 跨平台同步 [P3, 可选]

### 4.1 Git同步方案

**创建 `scripts/sync-tokens.sh`**:
```bash
#!/bin/bash
# 自动同步token到Git仓库
cd /home/sunrise/AIClient-2-API
git add configs/kiro/*.json provider_pools.json
git commit -m "Auto-sync tokens $(date +%Y-%m-%d-%H%M)"
git push origin main
```

**MacBook拉取**: 配置launchd每小时执行`git pull`

---

## 配置建议

### configs/config.json 新增
```json
{
    "REFRESH_TOKEN_WARNING_DAYS": 3,
    "REFRESH_TOKEN_VALIDITY_DAYS": 14,
    "AUTO_REAUTH_ENABLED": true
}
```

### 账号池建议
- **推荐5个账号**: 每2周只需更新1个账号
- **高可用10个账号**: 每月更新1次

---

## 关键文件清单

| 文件 | 改动 | 优先级 |
|------|------|--------|
| `src/claude/claude-kiro.js` | 400错误检测、refreshToken过期估算 | P0 |
| `src/adapter.js` | 失败处理、事件广播 | P0 |
| `src/provider-pool-manager.js` | 过期账号过滤、重授权标记 | P1 |
| `src/ui-manager.js` | 新增API端点、SSE事件 | P2 |
| `static/index.html` | 授权弹窗组件 | P2 |
| `scripts/sync-tokens.sh` | Git同步脚本（新增） | P3 |

---

## 实施顺序

1. **Phase 1** (1-2天): 基础设施 - 检测400错误，触发事件
2. **Phase 2** (1天): 多账号轮转 - 自动切换健康账号
3. **Phase 3** (2天): Web UI - 显示状态，引导授权
4. **Phase 4** (可选): 跨平台同步

---

## 预期效果

| 指标 | 当前 | 改进后 |
|------|------|--------|
| 手动维护频率 | 每周1次 | 每月1次(5账号) |
| 服务中断时间 | 数小时（发现问题后） | 几乎为0（自动切换） |
| 跨设备支持 | 无 | Git同步支持 |
| 用户感知 | 报错后才知道 | Web UI主动提醒 |
