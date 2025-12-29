# 添加新 Claude OAuth 账户 SOP

Standard Operating Procedure for Adding New Claude OAuth Accounts to AIClient-2-API

---

## 📋 前置条件

- ✅ 有效的 Claude Pro 账户（或 Claude API 账户）
- ✅ 已安装 Kiro CLI (`~/.local/share/kiro-cli/`)
- ✅ AIClient-2-API 已启动
- ✅ 访问管理后台: http://localhost:3000

---

## 🎯 目标

添加第 3、4、5... 个 Claude OAuth 账户，扩展账户池以支持更多并发请求和故障转移。

---

## 📊 当前状态

```
credentials/
├── account-01.json      ✅ 已配置
├── account-02.json      ✅ 已配置
└── account-03.json      ⏳ 要添加
```

---

## 🚀 完整 SOP

### 步骤 1: 获取新的 Claude OAuth 凭证

#### 方式 A: 使用不同的 Claude Pro 账户（推荐）

```bash
# 1. 在新的浏览器或隐私模式中打开
# https://claude.ai

# 2. 使用不同的 email 登录
# 例如: jody@example.com

# 3. 完成登录和 Claude Pro 订阅验证

# 4. 打开 Kiro CLI 授权页面
open "http://localhost:3000/api/oauth/authorize?provider=claude-kiro-oauth"

# 5. 在新账户中完成 OAuth 授权流程
```

#### 方式 B: 使用同一账户的不同应用授权

```bash
# 某些情况下，你可以在同一 Claude 账户中授权多个应用实例
# 这在需要增加并发限制时有用

open "http://localhost:3000/api/oauth/authorize?provider=claude-kiro-oauth"
# 再次完成授权（系统会创建新的 clientId）
```

---

### 步骤 2: 获取 OAuth 回调信息

#### 自动方式（推荐）

授权完成后，系统会自动：

1. 生成新的 `account-03.json` 文件
2. 将其保存到 `credentials/account-03.json`
3. 在管理后台显示成功消息

**检查是否成功：**

```bash
# 1. 查看新文件是否创建
ls -la credentials/account-03.json

# 2. 验证文件内容
jq . credentials/account-03.json

# 应该包含:
# - accessToken
# - refreshToken
# - clientId
# - clientSecret
# - expiresAt
```

#### 手动方式（如果自动失败）

如果自动创建失败，手动创建文件：

```bash
# 1. 从授权响应中获取信息
# OAuth 响应通常包含:
# {
#   "accessToken": "...",
#   "refreshToken": "...",
#   "clientId": "...",
#   "clientSecret": "...",
#   "expiresAt": "2025-12-29T...",
#   "region": "us-east-1"
# }

# 2. 创建新账户文件
cat > credentials/account-03.json << 'EOF'
{
  "accessToken": "your-access-token-here",
  "refreshToken": "your-refresh-token-here",
  "clientId": "your-client-id-here",
  "clientSecret": "your-client-secret-here",
  "expiresAt": "2025-12-29T14:44:00.113Z",
  "region": "us-east-1",
  "authMethod": "device"
}
EOF

# 3. 验证 JSON 格式
jq . credentials/account-03.json
```

---

### 步骤 3: 验证新账户

在 Linux 服务器上执行：

```bash
# 1. 查看新账户列表
ls -la credentials/account-*.json

# 应该显示:
# account-01.json
# account-02.json
# account-03.json

# 2. 检查服务日志
tail -f logs/*.log | grep "account-03"

# 3. 访问管理后台查看账户池
# http://localhost:3000
# 导航到 "Provider Pool" 或 "Providers" 页面
# 应该看到 account-01, account-02, account-03 都列出来
```

---

### 步骤 4: 更新配置（可选）

如果需要自定义账户配置，编辑 `configs/provider_pools.json`：

```bash
nano configs/provider_pools.json
```

**添加新账户配置：**

```json
{
  "claude-kiro-oauth": {
    "accounts": [
      {
        "uuid": "account-01",
        "enabled": true,
        "priority": 1,
        "credentialsPath": "credentials/account-01.json"
      },
      {
        "uuid": "account-02",
        "enabled": true,
        "priority": 2,
        "credentialsPath": "credentials/account-02.json"
      },
      {
        "uuid": "account-03",
        "enabled": true,
        "priority": 3,
        "credentialsPath": "credentials/account-03.json"
      }
    ],
    "rotationPolicy": "lru",
    "maxConcurrent": 3
  }
}
```

---

### 步骤 5: 验证 Token 有效性

```bash
# 1. 测试 API 调用
curl -X POST http://localhost:3000/v1/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-token" \
  -d '{
    "model": "claude-sonnet-4-5",
    "max_tokens": 100,
    "messages": [{"role": "user", "content": "Hello"}]
  }'

# 2. 查看使用情况
curl http://localhost:3000/api/providers-needing-reauth | jq .

# 3. 检查 Token 状态
curl http://localhost:3000/api/status | jq .
```

---

### 步骤 6: 配置 Token 自动刷新

新账户会自动加入 Token 刷新系统：

```bash
# 1. 查看 Token 过期时间
jq .expiresAt credentials/account-03.json

# 2. 系统会在过期前 7 天自动发起重新授权
# 你会在 UI 中看到通知

# 3. 手动更新 Token（如需要）
# 访问: http://localhost:3000/api/oauth/authorize?provider=claude-kiro-oauth
# 或使用 kiro-cli:
kiro --update-token account-03
```

---

### 步骤 7: Git 同步（多节点）

如果有多个节点，同步新账户配置：

```bash
# 1. 在主节点上提交新账户文件
cd /path/to/AIClient-2-API

git add credentials/account-03.json
git commit -m "feat: add new Claude OAuth account (account-03)"

# 2. 推送到 Git 仓库
git push origin main

# 3. 在其他节点上拉取
cd /path/to/other-node
git pull origin main

# 4. 验证文件已同步
ls -la credentials/account-03.json
```

或使用自动同步脚本：

```bash
# 使用 sync-tokens.sh 脚本
./scripts/sync-tokens.sh sync

# 或手动配置 cron
*/15 * * * * cd /path/to/AIClient-2-API && ./scripts/sync-tokens.sh sync
```

---

## ✅ 验证清单

在添加新账户后，检查以下项目：

### 文件检查
- [ ] `credentials/account-03.json` 存在
- [ ] 文件包含有效的 `accessToken` 和 `refreshToken`
- [ ] 文件权限正确: `chmod 600 credentials/account-03.json`
- [ ] JSON 格式有效: `jq . credentials/account-03.json`

### 功能检查
- [ ] 管理后台显示新账户
- [ ] 新账户在 LRU 轮询列表中
- [ ] API 调用能使用新账户
- [ ] Token 刷新系统监控新账户
- [ ] 日志中看到新账户的活动

### 日志检查
```bash
# 查看新账户的初始化日志
grep "account-03" logs/*.log

# 查看 Token 刷新日志
grep "token_expiry" logs/*.log

# 查看 API 调用日志
grep "account-03" logs/*.log | tail -20
```

### Git 同步检查
- [ ] 新账户文件已 commit
- [ ] 文件已 push 到远程
- [ ] 其他节点能成功 pull

---

## 🔐 安全建议

### 文件权限
```bash
# 确保凭证文件只有用户可读
chmod 600 credentials/account-03.json

# 验证权限
ls -la credentials/account-03.json
# 应显示: -rw------- (600)
```

### Git 安全
```bash
# 确保 credentials 目录被 .gitignore 保护
grep "credentials/" .gitignore

# 验证凭证文件未被提交
git status | grep account-03

# 如果已误提交，从历史删除
git filter-branch --force --index-filter \
  'git rm --cached --force credentials/account-03.json' \
  --prune-empty --tag-name-filter cat -- --all
```

### 访问控制
```bash
# 限制谁可以访问 OAuth 授权端点
# 在 ui-manager.js 中配置身份验证

# 验证授权页面需要认证
curl -i http://localhost:3000/api/oauth/authorize
# 应返回 401 Unauthorized 或需要密码验证
```

---

## 🐛 故障排除

### 问题 1: OAuth 授权失败

**错误信息:**
```
Failed to exchange authorization code for tokens
```

**解决方案:**
```bash
# 1. 检查网络连接
ping api.anthropic.com

# 2. 查看服务日志
tail -f logs/*.log | grep -i "oauth\|error"

# 3. 检查 Kiro CLI 配置
kiro --config

# 4. 尝试重新授权
open "http://localhost:3000/api/oauth/authorize?provider=claude-kiro-oauth"
```

### 问题 2: Token 立即过期

**症状:**
```
Token expired after minutes
```

**原因:** 可能是客户端时间与服务器时间不同步

**解决方案:**
```bash
# 1. 同步系统时间
sudo ntpdate -s time.nist.gov

# 2. 检查 expiresAt 字段
jq .expiresAt credentials/account-03.json

# 3. 手动更新 expiresAt（如果需要）
jq '.expiresAt = "2025-12-29T14:44:00.113Z"' credentials/account-03.json > temp.json
mv temp.json credentials/account-03.json
```

### 问题 3: 新账户不出现在轮询池中

**检查步骤:**
```bash
# 1. 验证文件存在
ls -la credentials/account-03.json

# 2. 检查文件格式
jq . credentials/account-03.json

# 3. 查看服务日志
tail -50 logs/*.log | grep -i "account-03\|provider"

# 4. 重启服务
npm restart

# 5. 再次检查
curl http://localhost:3000/api/status | jq .
```

### 问题 4: Git 同步失败

**检查步骤:**
```bash
# 1. 检查 Git 状态
git status

# 2. 查看远程配置
git remote -v

# 3. 手动推送
git push origin main

# 4. 其他节点手动拉取
git pull origin main

# 5. 查看同步日志
tail -f logs/token-sync.log
```

---

## 📈 扩展账户数量

根据需要，重复上述步骤添加更多账户：

```bash
# 添加 account-04
open "http://localhost:3000/api/oauth/authorize?provider=claude-kiro-oauth"

# 添加 account-05
open "http://localhost:3000/api/oauth/authorize?provider=claude-kiro-oauth"

# ... 继续
```

**建议账户数量：**
- 低并发 (< 10 req/min): 2-3 个账户
- 中并发 (10-50 req/min): 3-5 个账户
- 高并发 (> 50 req/min): 5-10 个账户

---

## 📊 监控新账户

### 实时监控
```bash
# 1. 查看账户池状态
watch -n 5 'curl -s http://localhost:3000/api/status | jq .providers'

# 2. 监控日志
tail -f logs/*.log | grep -E "account-03|rotation|oauth"

# 3. 检查 Token 有效期
watch -n 60 'jq .expiresAt credentials/account-*.json'
```

### 定期检查
```bash
# 每周检查一次 Token 状态
# 添加到 crontab:
0 9 * * 1 curl http://localhost:3000/api/providers-needing-reauth | mail -s "Weekly account status" admin@example.com
```

---

## 🎯 最佳实践

1. **定期备份凭证**
   ```bash
   tar -czf credentials.backup.$(date +%Y%m%d).tar.gz credentials/
   ```

2. **监控 Token 过期**
   ```bash
   # 设置提醒，在过期前重新授权
   jq '.expiresAt' credentials/account-03.json
   ```

3. **负载均衡**
   ```bash
   # 使用 LRU 轮询确保均匀分配
   # 检查配置: configs/provider_pools.json
   ```

4. **故障转移测试**
   ```bash
   # 定期禁用一个账户测试转移
   curl -X POST http://localhost:3000/api/provider-disable \
     -H "Content-Type: application/json" \
     -d '{"uuid":"account-03"}'
   ```

5. **版本控制**
   ```bash
   # 追踪账户变更
   git log --oneline -- credentials/
   ```

---

## 📞 常见问题

**Q: 可以添加多少个账户？**
A: 理论上无限制，但建议不超过 10 个（避免过度使用）。

**Q: Token 多久会过期？**
A: 通常 90 天，系统会在过期前 7 天提醒。

**Q: 账户可以共享吗？**
A: 不建议。每个账户应该对应独立的 Claude Pro 订阅。

**Q: 如何删除一个账户？**
A: `rm credentials/account-03.json && git commit`

**Q: 新账户添加后需要重启服务吗？**
A: 不需要，系统会自动检测新文件。

---

## ✅ 完成确认

添加新账户后，填写以下清单：

```
[ ] 账户文件已创建: credentials/account-03.json
[ ] OAuth 授权已完成
[ ] Token 有效期已确认
[ ] 管理后台已显示新账户
[ ] API 调用能成功使用新账户
[ ] 日志中看到新账户的活动
[ ] Git 变更已提交
[ ] 其他节点已同步
[ ] 文件权限正确 (600)
[ ] Token 刷新系统已监控
```

---

**现在你可以开始添加新账户了！** 🚀

有问题可以查看 `logs/*.log` 获取详细信息。
