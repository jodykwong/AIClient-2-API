# Token 自动刷新 - 快速开始

这是一个5分钟快速上手指南，帮助你快速启用 Token 自动刷新功能。

## 前置条件

✅ Node.js 已安装
✅ Git 已安装
✅ 项目已克隆到本地
✅ 已运行 `npm install`

## 步骤 1: 运行测试验证

```bash
# 运行集成测试，确保所有功能正常
./scripts/test-token-refresh.sh
```

**期望输出**: `ALL TESTS PASSED! ✓`

## 步骤 2: 启动服务

```bash
# 启动 AIClient-2-API 服务
npm start
```

服务将在 http://localhost:3000 启动

## 步骤 3: 配置 OAuth Provider

1. 访问 http://localhost:3000
2. 登录管理后台（如果配置了密码）
3. 进入"提供商池管理"或"配置管理"
4. 添加你的 OAuth 凭据（Kiro, Gemini, 等）

## 步骤 4: 验证自动刷新功能

### 自动化已内置，无需额外配置！

系统会自动：
- ✅ 检测 Token 过期（每次 API 调用时）
- ✅ 估算 refreshToken 过期时间（默认90天）
- ✅ 在 Token 即将过期时（7天前）发送通知
- ✅ 在 UI 显示弹窗提示重新授权
- ✅ 自动过滤已过期的 Provider

### 测试流程

**方式 1: 等待自然过期**
- 等待 Token 即将过期（7天内）
- UI 会自动弹窗提示

**方式 2: 模拟过期（开发测试）**
```javascript
// 在浏览器控制台手动触发
const testEvent = {
  providerType: 'claude-kiro-oauth',
  uuid: 'test-node',
  status: {
    isNear: true,
    daysRemaining: 3,
    hasFailed: false,
    reason: 'RefreshToken will expire in 3 days'
  },
  timestamp: new Date().toISOString()
};

// 触发事件（需要 eventSource 已连接）
const event = new MessageEvent('token_expiry', {
  data: JSON.stringify(testEvent)
});
window.eventSource.dispatchEvent(event);
```

## 步骤 5: 设置 Git 同步（可选）

如果需要跨多节点同步 Token：

```bash
# 运行交互式设置向导
./scripts/setup-sync.sh
```

按提示操作：
1. 初始化 Git 仓库（如果尚未初始化）
2. 配置 Git 用户信息
3. 添加远程仓库地址
4. 选择自动化方式（Cron 或 Systemd）

### 手动配置 Cron（可选）

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每15分钟同步一次）
*/15 * * * * cd /home/sunrise/AIClient-2-API && ./scripts/sync-tokens.sh sync >> logs/cron-sync.log 2>&1
```

## 功能验证清单

### ✅ 基础功能
- [ ] 服务成功启动
- [ ] UI 界面可访问
- [ ] OAuth Provider 配置成功
- [ ] API 调用正常工作

### ✅ Token 刷新功能
- [ ] 访问 `/api/providers-needing-reauth` 返回正常
- [ ] SSE 连接成功（浏览器控制台检查 `window.eventSource`）
- [ ] Token 过期时显示弹窗
- [ ] 重新授权按钮可点击
- [ ] OAuth 流程正常工作

### ✅ Git 同步功能（如果启用）
- [ ] `./scripts/sync-tokens.sh help` 正常工作
- [ ] Git 仓库已配置
- [ ] 手动同步成功: `./scripts/sync-tokens.sh sync`
- [ ] Cron 任务已添加（如果选择）

## 监控和日志

### 查看服务日志
```bash
# 实时查看服务日志
npm start  # 在前台运行查看实时日志

# 或使用 pm2
pm2 logs
```

### 查看 Token 同步日志
```bash
tail -f logs/token-sync.log
```

### 查看 SSE 事件
打开浏览器开发者工具 → Network → EventStream → 查看实时事件

## 常见问题

### Q1: Token 过期了但没收到通知？

**检查:**
```bash
# 1. 检查 SSE 连接
# 浏览器控制台输入:
window.eventSource.readyState  // 应该返回 1

# 2. 检查服务日志
tail -f logs/*.log | grep "token_expiry"

# 3. 重启服务
npm restart
```

### Q2: Git 同步失败？

**检查:**
```bash
# 1. 测试 Git 连接
git fetch origin

# 2. 查看同步日志
tail -n 50 logs/token-sync.log

# 3. 手动测试
./scripts/sync-tokens.sh sync
```

### Q3: 重新授权后仍显示过期？

**解决:**
```bash
# 手动清除过期标记
curl -X POST http://localhost:3000/api/provider-reauth-complete \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"providerType":"claude-kiro-oauth","uuid":"your-uuid"}'
```

## 配置文件位置

```
AIClient-2-API/
├── configs/
│   ├── kiro/              # Kiro OAuth tokens
│   ├── gemini/            # Gemini OAuth tokens
│   ├── config.json        # 主配置文件
│   └── provider_pools.json # Provider 池配置
├── logs/
│   ├── token-sync.log     # Git 同步日志
│   └── cron-sync.log      # Cron 执行日志
└── scripts/
    ├── sync-tokens.sh     # 同步脚本
    └── test-token-refresh.sh  # 测试脚本
```

## 高级配置

### 自定义 Token 生命周期

编辑 `configs/config.json`:

```json
{
  "KIRO_REFRESH_TOKEN_LIFETIME_DAYS": 90,
  "KIRO_REFRESH_TOKEN_NEAR_EXPIRY_DAYS": 7
}
```

### 自定义 Git 同步路径

创建 `scripts/token-sync.env`:

```bash
TOKEN_SYNC_PATHS="configs/kiro configs/gemini configs/qwen"
TOKEN_SYNC_BRANCH=tokens
TOKEN_SYNC_REMOTE=origin
```

使用配置:
```bash
source scripts/token-sync.env
./scripts/sync-tokens.sh sync
```

## 下一步

1. **生产部署**: 参考 `TOKEN_REFRESH_FLOW.md` 了解完整架构
2. **安全加固**: 配置 HTTPS, 启用防火墙, 使用私有 Git 仓库
3. **监控告警**: 设置日志监控和 Token 过期告警
4. **备份策略**: 定期备份配置文件和 Token 文件

## 获取帮助

- 📖 完整文档: `TOKEN_REFRESH_FLOW.md`
- 🔧 Git 同步文档: `scripts/README.md`
- 🧪 运行测试: `./scripts/test-token-refresh.sh`
- 📝 查看日志: `tail -f logs/*.log`

---

**快速开始完成！** 🎉

你的 Token 自动刷新系统现已启用。系统会自动检测过期并通知你，你只需在收到通知时点击"重新授权"即可。
