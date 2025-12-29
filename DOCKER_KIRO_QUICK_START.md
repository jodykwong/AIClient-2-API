# AIClient-2-API Kiro 多账号池 Docker 快速部署

基于官方 `Kiro_API_Pool_Quick_SOP.md` 的 Docker Compose 部署版本，支持多 Kiro 账号自动轮询。

## 📋 前置要求

1. **Docker** >= 20.10
2. **Docker Compose** >= 2.0
3. **Kiro IDE** - 用于获取 Token
4. **Google 账号** - 用于登录 Kiro

## 🚀 快速部署（5 分钟）

### 第一步：获取 Kiro Token

```bash
# 1. 下载 Kiro IDE: https://kiro.dev/downloads
# 2. 用 Google 账号登录
# 3. 登录成功后复制 Token（每个账号需要重复此步骤）

# Mac/Linux
cp ~/.aws/sso/cache/kiro-auth-token.json ~/account-01.json
# 退出登录，用另一个账号登录
cp ~/.aws/sso/cache/kiro-auth-token.json ~/account-02.json
# 重复至所需账号数量

# Windows
copy %USERPROFILE%\.aws\sso\cache\kiro-auth-token.json account-01.json
# 退出登录，用另一个账号登录
copy %USERPROFILE%\.aws\sso\cache\kiro-auth-token.json account-02.json
```

### 第二步：创建项目目录

```bash
# 创建目录结构
mkdir -p ~/kiro-api && cd ~/kiro-api
mkdir -p configs credentials logs cache

# 复制 Token 文件到 credentials 目录
cp ~/account-*.json ./credentials/

# 验证文件
ls -la credentials/
# 应该看到: account-01.json, account-02.json, ...
```

### 第三步：创建配置文件

#### 方案 A：使用 Docker Compose（推荐）

```bash
# 克隆项目或复制文件
git clone https://github.com/justlovemaki/AIClient-2-API.git
cd AIClient-2-API

# 复制 docker-compose.yml 和 .env.docker（如果还没有）
# 已经包含在项目中

# 复制环境变量
cp .env.docker .env

# 编辑 .env 文件（根据需要）
nano .env
```

#### 创建账号池配置

```bash
# 创建 configs/provider_pools.json
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

# 如果只有 1-2 个账号，删除多余的账号配置
nano configs/provider_pools.json
```

#### 创建主配置文件

```bash
# 创建 configs/config.json
cat > configs/config.json << 'EOF'
{
  "port": 3000,
  "modelProvider": "claude-kiro-oauth",
  "apiKey": "your-api-key-here",
  "providerPoolsFilePath": "/app/configs/provider_pools.json",
  "enableWebUI": true,
  "cronRefreshToken": true,
  "logLevel": "info"
}
EOF

# 编辑配置，设置你的 API 密钥
nano configs/config.json
```

### 第四步：启动服务

```bash
# 启动 Docker Compose
docker-compose up -d

# 查看启动日志
docker-compose logs -f aiclient-api

# 等待约 10-15 秒，看到 "API server running on port 3000" 消息
```

### 第五步：验证服务

```bash
# 健康检查
curl http://localhost:3000/health

# 应该返回: {"status":"ok"}

# 查看 Web UI
# 浏览器打开: http://localhost:3000
# 或 http://localhost:8085

# 测试 API（Anthropic 协议）
curl http://localhost:3000/v1/messages \
  -H "Authorization: Bearer your-api-key-here" \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{"model":"claude-sonnet-4-5","max_tokens":100,"messages":[{"role":"user","content":"你好"}]}'
```

## 🔑 环境变量配置

编辑 `.env` 文件：

```env
# 服务配置
NODE_ENV=production
API_PORT=3000
WEB_UI_PORT=8085

# Kiro 相关配置
MODEL_PROVIDER=claude-kiro-oauth
REQUIRED_API_KEY=your-secure-api-key-here

# Token 刷新（accessToken 自动刷新）
CRON_REFRESH_TOKEN=true

# 日志级别
LOG_LEVEL=info

# 路径
CONFIG_PATH=./configs
CREDENTIALS_PATH=./credentials
LOG_PATH=./logs
```

## 🔧 常用命令

### 日常操作

```bash
# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f aiclient-api

# 查看最后 100 行日志
docker-compose logs --tail=100 aiclient-api

# 进入容器调试
docker-compose exec aiclient-api sh

# 重启服务
docker-compose restart aiclient-api

# 停止服务
docker-compose down
```

### 账号管理

```bash
# 通过 Web UI 添加/修改账号
# http://localhost:3000 → Provider Pools → Add/Edit

# 或手动编辑配置文件
nano configs/provider_pools.json

# 编辑后重启服务
docker-compose restart aiclient-api
```

### Token 管理

```bash
# Token 自动刷新（accessToken）已在 CRON_REFRESH_TOKEN=true 时启用
# 无需手动操作

# 如果 refreshToken 过期（约 7-14 天）：
# 1. 重新登录 Kiro IDE（用该账号）
# 2. 复制新的 kiro-auth-token.json
# 3. 替换对应的 credentials/account-xx.json
# 4. 重启服务: docker-compose restart aiclient-api
```

## 📊 文件结构

```
kiro-api/
├── docker-compose.yml         # Docker 编排配置
├── .env                       # 环境变量（从 .env.docker 复制）
├── configs/
│   ├── config.json           # 主配置
│   └── provider_pools.json   # 账号池配置
├── credentials/
│   ├── account-01.json       # Kiro Token 1
│   ├── account-02.json       # Kiro Token 2
│   └── ...
├── logs/                      # 日志文件（自动生成）
└── cache/                     # 缓存文件（自动生成）
```

## 🌐 使用方式

### Claude Code

```bash
export ANTHROPIC_BASE_URL="http://localhost:3000"
export ANTHROPIC_API_KEY="your-api-key-here"
claude
```

### Python SDK（Anthropic 协议）

```python
from anthropic import Anthropic

client = Anthropic(
    base_url="http://localhost:3000",
    api_key="your-api-key-here"
)

message = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "你好，请自我介绍"}
    ]
)

print(message.content[0].text)
```

### Python SDK（OpenAI 协议）

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:3000/v1",
    api_key="your-api-key-here"
)

response = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "你好"}
    ]
)

print(response.choices[0].message.content)
```

### Node.js SDK

```javascript
const Anthropic = require('@anthropic-ai/sdk').default;

const client = new Anthropic({
    baseURL: 'http://localhost:3000',
    apiKey: 'your-api-key-here'
});

async function main() {
    const message = await client.messages.create({
        model: 'claude-sonnet-4-5',
        max_tokens: 1024,
        messages: [
            {
                role: 'user',
                content: '你好'
            }
        ]
    });
    console.log(message.content[0].text);
}

main();
```

## ⚙️ 核心能力

| 功能 | 状态 | 说明 |
|------|------|------|
| 多账号轮询 | ✅ | 自动在多个账号间轮询请求 |
| 故障转移 | ✅ | 账号失败自动切换到下一个 |
| Token 自动刷新 | ✅ | accessToken 自动刷新 |
| Web UI | ✅ | 管理界面，查看账号状态 |
| 健康检查 | ✅ | 自动监测服务状态 |
| Anthropic 协议 | ✅ | 完全兼容 Anthropic API |
| OpenAI 协议 | ✅ | 兼容 OpenAI API |
| refreshToken 管理 | ⚠️ | 约 7-14 天过期，需手动重登 |

## 🔐 安全建议

- [ ] 使用强密码作为 REQUIRED_API_KEY
- [ ] 不要在 .env 文件中暴露真实密钥
- [ ] 定期备份 credentials 目录
- [ ] 使用防火墙限制端口访问
- [ ] credentials 目录权限: `chmod 700 credentials`
- [ ] 定期检查日志发现异常

## 🐛 故障排除

### 容器启动失败

```bash
# 查看详细错误
docker-compose logs aiclient-api

# 检查配置文件语法
docker-compose config

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

### 无法连接到服务

```bash
# 验证容器是否运行
docker-compose ps

# 验证端口映射
docker-compose port aiclient-api 3000

# 测试连接
curl -v http://localhost:3000/health
```

### 账号无法工作

```bash
# 查看详细日志
docker-compose logs -f aiclient-api | grep -i "account\|error"

# 检查 Token 文件是否存在
docker-compose exec aiclient-api ls -la /app/credentials/

# 检查配置
docker-compose exec aiclient-api cat /app/configs/provider_pools.json

# Token 过期处理：重新获取并替换文件，然后重启
docker-compose restart aiclient-api
```

### API 返回 401 错误

```bash
# 确保使用了正确的 API 密钥
# 检查 .env 中的 REQUIRED_API_KEY
nano .env

# 确保请求头中包含正确的密钥
curl http://localhost:3000/health \
  -H "Authorization: Bearer your-api-key-here"
```

## 📚 完整文档

- **DOCKER_QUICK_REFERENCE.md** - 通用 Docker 命令快速参考
- **DOCKER.md** - 完整 Docker 使用指南
- **Kiro_API_Pool_Quick_SOP.md** - 原官方快速部署指南
- **README.md** - 项目详细说明

## 🔗 相关资源

- GitHub: https://github.com/justlovemaki/AIClient-2-API
- Docker Hub: https://hub.docker.com/r/justlikemaki/aiclient-2-api
- Kiro IDE: https://kiro.dev/downloads
- 官方文档: https://aiproxy.justlikemaki.vip/zh/

## 💡 常见问题

**Q: 能否添加或移除账号而不停止服务？**
A: 可以通过 Web UI 动态添加/修改，某些操作可能需要重启。

**Q: Token 过期了怎么办？**
A: 重新在 Kiro IDE 登录获取新 Token，替换 credentials 文件，重启服务。

**Q: 如何监控多个账号的使用情况？**
A: 访问 Web UI（http://localhost:3000），可以查看每个账号的状态。

**Q: 支持哪些模型？**
A: claude-sonnet-4-5, claude-opus-4-5 等，具体取决于你的 Kiro 账号权限。

---

**祝您使用愉快！** 🎉

有问题？查看日志或访问官方 GitHub Issues：
https://github.com/justlovemaki/AIClient-2-API/issues
