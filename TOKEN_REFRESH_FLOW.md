# Token 自动化刷新流程 - 完整文档

## 概述

本文档描述了 AIClient-2-API 的 Token 自动化刷新和同步系统。该系统实现了从 Token 过期检测到自动同步的完整流程。

## 系统架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         Token 生命周期管理                        │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  Phase 1: Token 过期检测                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  1.1 claude-kiro.js                                             │
│      • 400 错误检测 (refreshToken 失败)                          │
│      • refreshToken 过期时间估算 (默认90天)                      │
│      • isRefreshTokenNearExpiry() 方法                          │
│                                                                  │
│  1.2 adapter.js                                                 │
│      • EventEmitter 事件广播                                     │
│      • _handleTokenError() 错误处理                             │
│      • onRefreshTokenExpiry() 事件订阅                          │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  Phase 2: Provider 池管理                                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  provider-pool-manager.js                                        │
│      • needsReauth 标记过期账号                                  │
│      • 自动过滤 needsReauth=true 的 provider                     │
│      • markProviderNeedsReauth() 标记需要重授权                  │
│      • getProvidersNeedingReauth() 获取过期列表                  │
│      • _subscribeToAdapterEvents() 订阅 Token 事件               │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  Phase 3: UI 交互                                                │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  3.1 ui-manager.js (后端)                                        │
│      • GET  /api/providers-needing-reauth                       │
│      • POST /api/provider-reauth-complete                       │
│      • SSE 事件广播 (token_expiry, reauth_complete)             │
│                                                                  │
│  3.2 index.html (前端)                                           │
│      • Token 过期弹窗                                            │
│      • SSE 实时监听                                              │
│      • 重新授权按钮和 OAuth 流程                                  │
│      • 自动刷新和状态更新                                         │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│  Phase 4: Git 同步                                               │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  scripts/sync-tokens.sh                                          │
│      • pull: 从 Git 拉取最新 Token                               │
│      • push: 提交并推送本地 Token                                │
│      • sync: 完整双向同步                                        │
│      • Cron/Systemd 自动化支持                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 完整流程演示

### 场景 1: RefreshToken 自动过期检测

```
1. 系统启动时加载 Token 配置
   └─> claude-kiro.js 初始化
       └─> refreshTokenExpiresAt = now + 90天
       └─> 保存到 token 文件

2. 定期检查（每次 accessToken 刷新时）
   └─> isRefreshTokenNearExpiry() 检查
       └─> 如果 < 7 天: 发送事件
       └─> 如果已失败: 发送事件

3. 事件流
   └─> adapter.js 接收事件
       └─> _emitRefreshTokenExpiry()
           └─> provider-pool-manager.js 接收
               └─> markProviderNeedsReauth()
               └─> broadcastEvent('token_expiry')
                   └─> UI 前端接收 SSE 事件
                       └─> 弹出重授权提示
```

### 场景 2: 400 错误触发

```
1. API 调用返回 400 错误
   └─> claude-kiro.js callApi()
       └─> 检测到 400 错误
           └─> refreshTokenFailedAt = now
           └─> 抛出 "RefreshToken expired or invalid"

2. Adapter 捕获错误
   └─> adapter.js _handleTokenError()
       └─> 检测到 "RefreshToken expired"
           └─> _emitRefreshTokenExpiry()

3. 后续流程同上
```

### 场景 3: 用户重新授权

```
1. 用户在 UI 点击"重新授权"
   └─> handleReauth()
       └─> POST /api/oauth-link
           └─> 获取授权链接
           └─> 打开 OAuth 窗口

2. 用户完成 OAuth 授权
   └─> 新 Token 保存到 configs/kiro/xxx.json
       └─> 窗口关闭

3. 前端检测窗口关闭
   └─> POST /api/provider-reauth-complete
       └─> clearProviderReauthFlag()
       └─> broadcastEvent('reauth_complete')
           └─> 前端移除通知
           └─> Toast 提示成功

4. Cron 自动同步（可选）
   └─> sync-tokens.sh push
       └─> git add configs/kiro/
       └─> git commit -m "chore: update tokens"
       └─> git push origin main
```

### 场景 4: 多节点同步

```
节点 A (主节点):
1. 用户重新授权
   └─> 新 Token 保存
   └─> Cron: sync-tokens.sh push
       └─> 推送到 Git

节点 B, C, D (其他节点):
1. Cron: sync-tokens.sh pull (每 5 分钟)
   └─> git pull origin main
   └─> 获取最新 Token
   └─> 自动更新本地文件
   └─> Provider 恢复可用
```

## API 端点

### 获取需要重新授权的 Providers

```bash
GET /api/providers-needing-reauth

Response:
{
  "success": true,
  "providers": [
    {
      "providerType": "claude-kiro-oauth",
      "uuid": "kiro-node-1",
      "refreshTokenStatus": {
        "isNear": true,
        "daysRemaining": 3,
        "hasFailed": false,
        "reason": "RefreshToken will expire in 3 days"
      },
      "lastReauthRequestTime": "2025-12-29T10:00:00.000Z"
    }
  ],
  "count": 1,
  "timestamp": "2025-12-29T10:30:00.000Z"
}
```

### 标记重新授权完成

```bash
POST /api/provider-reauth-complete
Content-Type: application/json

{
  "providerType": "claude-kiro-oauth",
  "uuid": "kiro-node-1"
}

Response:
{
  "success": true,
  "message": "重新授权标记已清除",
  "providerType": "claude-kiro-oauth",
  "uuid": "kiro-node-1"
}
```

## SSE 事件

### token_expiry 事件

当 refreshToken 即将过期或失败时触发。

```javascript
// 事件数据
{
  "providerType": "claude-kiro-oauth",
  "uuid": "kiro-node-1",
  "status": {
    "isNear": true,
    "daysRemaining": 3,
    "hasFailed": false,
    "reason": "RefreshToken will expire in 3 days"
  },
  "timestamp": "2025-12-29T10:00:00.000Z",
  "message": "Provider kiro-node-1 (claude-kiro-oauth) needs re-authorization"
}
```

### reauth_complete 事件

当重新授权完成时触发。

```javascript
// 事件数据
{
  "providerType": "claude-kiro-oauth",
  "uuid": "kiro-node-1",
  "timestamp": "2025-12-29T10:30:00.000Z"
}
```

## 配置选项

### claude-kiro.js 配置

```javascript
{
  // RefreshToken 生命周期（天），默认 90 天
  "KIRO_REFRESH_TOKEN_LIFETIME_DAYS": 90,

  // RefreshToken 过期预警阈值（天），默认 7 天
  "KIRO_REFRESH_TOKEN_NEAR_EXPIRY_DAYS": 7
}
```

### Git 同步配置

```bash
# 环境变量配置
export TOKEN_SYNC_REPO="/path/to/AIClient-2-API"
export TOKEN_SYNC_BRANCH="main"
export TOKEN_SYNC_REMOTE="origin"
export TOKEN_SYNC_PATHS="configs/kiro configs/gemini configs/qwen configs/antigravity"
export TOKEN_SYNC_LOG="logs/token-sync.log"
```

## 自动化设置

### Cron 方式

```bash
# 编辑 crontab
crontab -e

# 每 15 分钟完整同步
*/15 * * * * cd /path/to/AIClient-2-API && ./scripts/sync-tokens.sh sync >> logs/cron-sync.log 2>&1

# 或者分开配置
# 每 5 分钟拉取
*/5 * * * * cd /path/to/AIClient-2-API && ./scripts/sync-tokens.sh pull >> logs/cron-sync.log 2>&1

# 每 10 分钟推送
*/10 * * * * cd /path/to/AIClient-2-API && ./scripts/sync-tokens.sh push >> logs/cron-sync.log 2>&1
```

### Systemd 方式

```bash
# 安装服务
sudo cp scripts/systemd/token-sync.service /etc/systemd/system/
sudo cp scripts/systemd/token-sync.timer /etc/systemd/system/

# 启用并启动
sudo systemctl daemon-reload
sudo systemctl enable token-sync.timer
sudo systemctl start token-sync.timer

# 查看状态
sudo systemctl status token-sync.timer
sudo journalctl -u token-sync.service -f
```

## 数据结构

### Provider 配置 (provider_pools.json)

```json
{
  "claude-kiro-oauth": [
    {
      "uuid": "kiro-node-1",
      "KIRO_OAUTH_CREDS_FILE_PATH": "configs/kiro/node-1/credentials.json",
      "isHealthy": true,
      "isDisabled": false,
      "needsReauth": false,
      "refreshTokenStatus": null,
      "lastReauthRequestTime": null,
      "usageCount": 42,
      "errorCount": 0,
      "lastUsed": "2025-12-29T10:00:00.000Z",
      "lastHealthCheckTime": "2025-12-29T09:00:00.000Z"
    }
  ]
}
```

### Token 文件结构

```json
{
  "accessToken": "ey...",
  "refreshToken": "ey...",
  "expiresAt": "2025-12-29T11:00:00.000Z",
  "refreshTokenExpiresAt": "2026-03-29T10:00:00.000Z",
  "profileArn": "arn:aws:iam::...",
  "region": "us-east-1",
  "clientId": "...",
  "clientSecret": "..."
}
```

## 监控和日志

### 查看同步日志

```bash
# 实时查看
tail -f logs/token-sync.log

# 查看最近的同步
tail -n 100 logs/token-sync.log | grep "Token Sync Script"

# 查看错误
grep "ERROR" logs/token-sync.log
```

### 查看 Git 历史

```bash
# 查看 Token 同步历史
git log --oneline --graph -- configs/kiro/ configs/gemini/

# 查看具体变更
git show <commit-hash>

# 查看文件变更统计
git log --stat -- configs/
```

### 检查 Provider 状态

```bash
# 通过 API 检查
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/providers-needing-reauth | jq

# 检查配置文件
cat configs/provider_pools.json | jq '.["claude-kiro-oauth"][] | select(.needsReauth == true)'
```

## 故障排除

### 问题 1: Token 过期但未收到通知

**检查步骤:**

1. 验证 SSE 连接
```javascript
// 浏览器控制台
console.log(window.eventSource.readyState); // 应该是 1 (OPEN)
```

2. 检查 provider-pool-manager 事件订阅
```bash
grep "_subscribeToAdapterEvents" logs/*.log
```

3. 手动触发检查
```bash
# 重启服务强制重新检查
npm restart
```

### 问题 2: Git 同步失败

**检查步骤:**

1. 测试 Git 连接
```bash
git fetch origin
ssh -T git@github.com  # 如果使用 SSH
```

2. 查看同步日志
```bash
tail -n 50 logs/token-sync.log
```

3. 手动同步测试
```bash
./scripts/sync-tokens.sh sync
```

### 问题 3: 重新授权后仍显示过期

**解决方案:**

1. 确认 Token 文件已更新
```bash
cat configs/kiro/xxx/credentials.json | jq '.refreshTokenExpiresAt'
```

2. 手动清除标记
```bash
curl -X POST http://localhost:3000/api/provider-reauth-complete \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"providerType":"claude-kiro-oauth","uuid":"kiro-node-1"}'
```

3. 重启服务
```bash
npm restart
```

## 安全建议

### 1. Git 仓库安全

- ✅ 使用私有仓库（GitHub Private, GitLab Private, 自建 Git 服务器）
- ✅ 启用双因素认证 (2FA)
- ✅ 使用 SSH 密钥而非密码
- ✅ 限制仓库访问权限
- ⚠️ 考虑使用 git-crypt 或 git-secret 加密 Token 文件

### 2. Token 文件保护

- ✅ 文件权限设为 600 (只有所有者可读写)
- ✅ 定期轮换 Token
- ✅ 不要在公共网络传输明文 Token
- ✅ 定期审计 Token 使用情况

### 3. 日志安全

- ✅ 确保日志不包含完整 Token
- ✅ 定期清理旧日志
- ✅ 限制日志文件访问权限
- ✅ 不要将日志提交到 Git

## 性能优化

### 减少 Git 操作频率

```bash
# 降低同步频率
# 从每 5 分钟改为每 15 分钟
*/15 * * * * ...
```

### 使用浅克隆

```bash
# 首次克隆时使用浅克隆
git clone --depth 1 <repo-url>
```

### 只同步必要的路径

```bash
# 只同步 Kiro 和 Gemini
TOKEN_SYNC_PATHS="configs/kiro configs/gemini" ./scripts/sync-tokens.sh sync
```

## 测试清单

- [x] Phase 1.1: Token 过期检测和估算
- [x] Phase 1.2: 事件广播系统
- [x] Phase 2: Provider 池过滤和标记
- [x] Phase 3.1: API 端点
- [x] Phase 3.2: 前端 UI 组件
- [x] Phase 4: Git 同步脚本
- [x] 集成测试: 所有测试通过

## 下一步

1. **启动服务**: `npm start`
2. **访问 UI**: http://localhost:3000
3. **配置 Provider**: 添加 OAuth 凭据
4. **测试流程**: 等待 Token 过期或手动触发
5. **设置同步**: `./scripts/setup-sync.sh`

## 支持

- 查看日志: `tail -f logs/*.log`
- 运行测试: `./scripts/test-token-refresh.sh`
- 查看文档: `scripts/README.md`

---

**文档版本**: 1.0
**最后更新**: 2025-12-29
**作者**: AIClient-2-API Team
