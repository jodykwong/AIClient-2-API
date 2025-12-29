# AIClient-2-API Kiro-CLI Token 配置 SOP

本文档记录如何从 Kiro-CLI 提取 OAuth Token 并配置到 AIClient-2-API 服务。

## 前置条件

- 已安装 Kiro-CLI (`kiro-cli --version` 确认)
- 已安装 Node.js 22+
- 已安装 Python3 (用于提取 token)
- 已安装 SQLite3

## 第一步：Kiro-CLI 登录

### 1.1 执行登录命令

```bash
kiro-cli login --license free --use-device-flow
```

### 1.2 完成浏览器认证

系统会输出设备码和 URL，例如：
```
Confirm the following code in the browser
Code: XXXX-XXXX
Open this URL: https://view.awsapps.com/start/#/device?user_code=XXXX-XXXX
```

1. 打开提示的 URL
2. 输入设备码
3. 完成身份验证
4. 等待终端显示登录成功

### 1.3 验证登录状态

```bash
# 尝试重新登录会提示已登录
kiro-cli login --license free
# 输出: error: Already logged in, please logout with kiro-cli logout first
```

## 第二步：定位 Token 存储位置

### 2.1 关键发现

**Kiro-CLI 的 token 存储在 SQLite 数据库中，而不是 JSON 文件：**

```
~/.local/share/kiro-cli/data.sqlite3
```

> 注意：`~/.kiro/settings/cli.json` 文件为空 `{}`，不包含 token 信息。

### 2.2 查看数据库结构

```bash
sqlite3 ~/.local/share/kiro-cli/data.sqlite3 ".tables"
# 输出: auth_kv  conversations  history  migrations  state

sqlite3 ~/.local/share/kiro-cli/data.sqlite3 ".schema auth_kv"
# 输出: CREATE TABLE auth_kv (key TEXT PRIMARY KEY, value TEXT);
```

### 2.3 查看存储的认证数据

```bash
sqlite3 ~/.local/share/kiro-cli/data.sqlite3 "SELECT key FROM auth_kv"
# 输出:
# kirocli:odic:device-registration
# kirocli:odic:token
```

## 第三步：提取 Token 并创建凭证文件

### 3.1 创建目录结构

```bash
cd /path/to/AIClient-2-API
mkdir -p credentials configs logs cache
```

### 3.2 使用 Python 脚本提取 Token

创建并执行以下脚本：

```python
import sqlite3
import json

# 连接数据库
conn = sqlite3.connect('/home/sunrise/.local/share/kiro-cli/data.sqlite3')
cursor = conn.cursor()

# 获取 device-registration 数据
cursor.execute("SELECT value FROM auth_kv WHERE key = 'kirocli:odic:device-registration'")
reg_row = cursor.fetchone()
reg_data = json.loads(reg_row[0]) if reg_row else {}

# 获取 token 数据
cursor.execute("SELECT value FROM auth_kv WHERE key = 'kirocli:odic:token'")
token_row = cursor.fetchone()
token_data = json.loads(token_row[0]) if token_row else {}

conn.close()

# 构建 AIClient-2-API 需要的格式
kiro_auth_token = {
    "accessToken": token_data.get("access_token", ""),
    "refreshToken": token_data.get("refresh_token", ""),
    "clientId": reg_data.get("client_id", ""),
    "clientSecret": reg_data.get("client_secret", ""),
    "expiresAt": token_data.get("expires_at", ""),
    "region": token_data.get("region", "us-east-1"),
    "authMethod": "device"
}

# 保存到凭证文件
output_path = "./credentials/account-01.json"
with open(output_path, 'w') as f:
    json.dump(kiro_auth_token, f, indent=2)

print(f"Token saved to: {output_path}")
```

### 3.3 一行命令版本

```bash
python3 << 'EOF'
import sqlite3, json
conn = sqlite3.connect('/home/sunrise/.local/share/kiro-cli/data.sqlite3')
cursor = conn.cursor()
cursor.execute("SELECT value FROM auth_kv WHERE key = 'kirocli:odic:device-registration'")
reg_data = json.loads(cursor.fetchone()[0])
cursor.execute("SELECT value FROM auth_kv WHERE key = 'kirocli:odic:token'")
token_data = json.loads(cursor.fetchone()[0])
conn.close()
kiro_auth_token = {
    "accessToken": token_data.get("access_token", ""),
    "refreshToken": token_data.get("refresh_token", ""),
    "clientId": reg_data.get("client_id", ""),
    "clientSecret": reg_data.get("client_secret", ""),
    "expiresAt": token_data.get("expires_at", ""),
    "region": token_data.get("region", "us-east-1"),
    "authMethod": "device"
}
with open("./credentials/account-01.json", 'w') as f:
    json.dump(kiro_auth_token, f, indent=2)
print("Token extracted successfully!")
EOF
```

### 3.4 验证凭证文件

```bash
cat credentials/account-01.json | python3 -m json.tool
```

输出示例：
```json
{
    "accessToken": "aoaAAAAAGlRz0YbAKyUBNM4N...",
    "refreshToken": "aorAAAAAGnIaCY2mclGpm-ED...",
    "clientId": "tuxEQ-_fq3hS7o4Q1qlv2nVz...",
    "clientSecret": "eyJraWQiOiJrZXkt...",
    "expiresAt": "2025-12-29T00:46:00.042397797Z",
    "region": "us-east-1",
    "authMethod": "device"
}
```

## 第四步：配置 AIClient-2-API

### 4.1 创建 provider_pools.json

```bash
cat > configs/provider_pools.json << 'EOF'
{
  "claude-kiro-oauth": [
    {
      "name": "account-01",
      "uuid": "account-01",
      "enabled": true,
      "priority": 1,
      "KIRO_OAUTH_CREDS_FILE_PATH": "./credentials/account-01.json",
      "isHealthy": true,
      "isDisabled": false,
      "usageCount": 0,
      "errorCount": 0
    }
  ]
}
EOF
```

> **重要**：`KIRO_OAUTH_CREDS_FILE_PATH` 必须放在顶层，不要嵌套在 `config` 对象中。

### 4.2 创建 config.json

```bash
cat > configs/config.json << 'EOF'
{
  "REQUIRED_API_KEY": "your-secure-api-key-12345",
  "SERVER_PORT": 3000,
  "HOST": "0.0.0.0",
  "MODEL_PROVIDER": "claude-kiro-oauth",
  "PROVIDER_POOLS_FILE_PATH": "configs/provider_pools.json",
  "CRON_REFRESH_TOKEN": true,
  "CRON_NEAR_MINUTES": 10,
  "REQUEST_MAX_RETRIES": 3,
  "REQUEST_BASE_DELAY": 1000,
  "MAX_ERROR_COUNT": 3
}
EOF
```

### 4.3 配置说明

| 配置项 | 说明 | 示例值 |
|--------|------|--------|
| `REQUIRED_API_KEY` | API 访问密钥 | `your-secure-api-key-12345` |
| `SERVER_PORT` | 服务端口 | `3000` |
| `HOST` | 监听地址 | `0.0.0.0` |
| `MODEL_PROVIDER` | 默认模型提供者 | `claude-kiro-oauth` |
| `CRON_REFRESH_TOKEN` | 自动刷新 token | `true` |
| `CRON_NEAR_MINUTES` | 提前刷新时间(分钟) | `10` |

## 第五步：安装依赖并启动服务

### 5.1 安装 npm 依赖

```bash
npm install
```

### 5.2 启动服务

```bash
node src/api-server.js
```

### 5.3 后台运行

```bash
# 使用 nohup
nohup node src/api-server.js > logs/api-server.log 2>&1 &

# 或使用 pm2
pm2 start src/api-server.js --name "aiclient-api"
```

## 第六步：验证服务

### 6.1 健康检查

```bash
curl -s http://localhost:3000/health
```

预期输出：
```json
{"status":"healthy","timestamp":"2025-12-29T00:02:42.159Z","provider":"claude-kiro-oauth"}
```

### 6.2 测试 API 请求

```bash
curl -s http://localhost:3000/v1/messages \
  -H "Authorization: Bearer your-secure-api-key-12345" \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5",
    "max_tokens": 100,
    "messages": [{"role": "user", "content": "Hello, say hi in one sentence"}]
  }'
```

预期输出：
```json
{
  "id": "8d5e066a-...",
  "type": "message",
  "role": "assistant",
  "model": "claude-sonnet-4-5",
  "content": [{"type": "text", "text": "Hello, it's great to meet you!"}]
}
```

## 附录

### A. 目录结构

```
AIClient-2-API/
├── configs/
│   ├── config.json              # 主配置文件
│   └── provider_pools.json      # 账号池配置
├── credentials/
│   └── account-01.json          # Kiro OAuth token
├── logs/                        # 日志目录
├── cache/                       # 缓存目录
└── src/
    └── api-server.js            # 主程序入口
```

### B. 支持的 API 格式

| 格式 | 端点 |
|------|------|
| OpenAI | `/v1/chat/completions`, `/v1/models` |
| Claude | `/v1/messages` |
| Gemini | `/v1beta/models/{model}:generateContent` |

### C. 多账号配置

添加多个账号到 `provider_pools.json`：

```json
{
  "claude-kiro-oauth": [
    {
      "name": "account-01",
      "uuid": "account-01",
      "enabled": true,
      "priority": 1,
      "KIRO_OAUTH_CREDS_FILE_PATH": "./credentials/account-01.json"
    },
    {
      "name": "account-02",
      "uuid": "account-02",
      "enabled": true,
      "priority": 2,
      "KIRO_OAUTH_CREDS_FILE_PATH": "./credentials/account-02.json"
    }
  ]
}
```

### D. 常见问题

#### Q1: Token 在哪里？
A: Kiro-CLI 将 token 存储在 SQLite 数据库 `~/.local/share/kiro-cli/data.sqlite3` 中，不是 `~/.kiro/settings/cli.json`。

#### Q2: 提示 "No access token available"
A: 检查 `provider_pools.json` 中的 `KIRO_OAUTH_CREDS_FILE_PATH` 是否正确设置，且必须放在顶层配置中。

#### Q3: Token 过期怎么办？
A: 设置 `CRON_REFRESH_TOKEN: true` 后，服务会自动刷新 token。手动刷新可重新执行第三步提取新 token。

---

*文档版本: 1.0*
*最后更新: 2025-12-29*
