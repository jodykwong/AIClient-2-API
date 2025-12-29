# Kiro API 池精简部署指南

> **工具**: AIClient-2-API  
> **GitHub**: https://github.com/justlovemaki/AIClient-2-API  
> **功能**: Kiro 逆向 + 多账号池 + Web UI + 双协议（Anthropic/OpenAI）

---

## 一、获取 Token（每账号 3 分钟）

```bash
# 1. 下载 Kiro IDE: https://kiro.dev/downloads
# 2. 用 Google 账号登录
# 3. 登录成功后复制 Token：

# Mac/Linux
cp ~/.aws/sso/cache/kiro-auth-token.json ~/account-01.json

# Windows
copy %USERPROFILE%\.aws\sso\cache\kiro-auth-token.json account-01.json

# 4. 退出登录，换下一个账号，重复以上步骤
```

---

## 二、部署服务

### 方式 A：Docker 部署（推荐）

```bash
# 创建目录
mkdir -p ~/kiro-api && cd ~/kiro-api
mkdir configs credentials

# 复制 Token 文件
cp ~/account-*.json ./credentials/

# 创建账号池配置
cat > configs/provider_pools.json << 'EOF'
{
  "claude-kiro-oauth": {
    "providers": [
      {
        "name": "account-01",
        "enabled": true,
        "priority": 1,
        "config": {
          "KIRO_OAUTH_CREDS_FILE": "/app/credentials/account-01.json"
        }
      },
      {
        "name": "account-02",
        "enabled": true,
        "priority": 2,
        "config": {
          "KIRO_OAUTH_CREDS_FILE": "/app/credentials/account-02.json"
        }
      },
      {
        "name": "account-03",
        "enabled": true,
        "priority": 3,
        "config": {
          "KIRO_OAUTH_CREDS_FILE": "/app/credentials/account-03.json"
        }
      }
    ]
  }
}
EOF

# 启动服务
docker run -d \
  --name kiro-api \
  -p 3000:3000 \
  -v $(pwd)/configs:/app/configs \
  -v $(pwd)/credentials:/app/credentials \
  -e MODEL_PROVIDER=claude-kiro-oauth \
  -e REQUIRED_API_KEY=your-api-key \
  -e CRON_REFRESH_TOKEN=true \
  --restart unless-stopped \
  justlikemaki/aiclient-2-api:latest

# 查看日志
docker logs -f kiro-api
```

### 方式 B：源码部署

```bash
git clone https://github.com/justlovemaki/AIClient-2-API.git
cd AIClient-2-API
npm install

# 复制 Token 到 credentials 目录
mkdir credentials
cp ~/account-*.json ./credentials/

# 创建配置（同上 provider_pools.json）

# 启动
npm start
```

---

## 三、验证服务

```bash
# 健康检查
curl http://localhost:3000/health

# 测试 API（Anthropic 协议）
curl http://localhost:3000/v1/messages \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{"model":"claude-sonnet-4-5","max_tokens":100,"messages":[{"role":"user","content":"你好"}]}'

# Web UI 管理
# 浏览器打开: http://localhost:3000
```

---

## 四、接入使用

### Claude Code
```bash
export ANTHROPIC_BASE_URL="http://localhost:3000"
export ANTHROPIC_API_KEY="your-api-key"
claude
```

### Python SDK
```python
from anthropic import Anthropic

client = Anthropic(
    base_url="http://localhost:3000",
    api_key="your-api-key"
)
msg = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=[{"role": "user", "content": "你好"}]
)
print(msg.content[0].text)
```

### OpenAI 协议（兼容）
```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:3000/v1",
    api_key="your-api-key"
)
response = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=[{"role": "user", "content": "你好"}]
)
print(response.choices[0].message.content)
```

---

## 五、日常维护

| 任务 | 命令 |
|------|------|
| 查看状态 | `docker ps` |
| 查看日志 | `docker logs -f kiro-api` |
| 重启服务 | `docker restart kiro-api` |
| 添加账号 | Web UI → Provider Pools → Add |
| Token 过期 | 重新登录 Kiro → 替换 credentials 文件 → 重启 |

---

## 六、核心能力一览

| 能力 | 状态 |
|------|------|
| 多账号自动轮询 | ✅ 内置 |
| 故障自动转移 | ✅ 内置 |
| Token 自动刷新（accessToken） | ✅ 内置 |
| Web UI 管理 | ✅ 内置 |
| 健康检查 | ✅ 内置 |
| Anthropic 协议 | ✅ 支持 |
| OpenAI 协议 | ✅ 支持 |
| refreshToken 过期处理 | ⚠️ 需手动重登 Kiro（约 7-14 天一次）|

---

## 快速参考

```
GitHub:     https://github.com/justlovemaki/AIClient-2-API
Docker:     justlikemaki/aiclient-2-api:latest
API 地址:   http://localhost:3000
Web UI:     http://localhost:3000
协议:       Anthropic + OpenAI 双协议

环境变量:
  MODEL_PROVIDER=claude-kiro-oauth
  REQUIRED_API_KEY=你的密码
  CRON_REFRESH_TOKEN=true
```
