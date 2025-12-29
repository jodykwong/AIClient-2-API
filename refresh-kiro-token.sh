#!/bin/bash
# Kiro Token自动刷新脚本
# 每小时从kiro-cli提取最新token并更新AIClient-2-API credentials

LOG_FILE="/home/sunrise/AIClient-2-API/logs/token-refresh.log"
CREDENTIALS_DIR="/home/sunrise/AIClient-2-API/credentials"

echo "[$(date)] 开始刷新Kiro token..." >> "$LOG_FILE"

# 提取token
python3 << 'EOF'
import sqlite3, json, os, sys

try:
    conn = sqlite3.connect('/home/sunrise/.local/share/kiro-cli/data.sqlite3')
    cursor = conn.cursor()

    cursor.execute("SELECT value FROM auth_kv WHERE key = 'kirocli:odic:device-registration'")
    reg_row = cursor.fetchone()
    if not reg_row:
        print("ERROR: No device-registration found", file=sys.stderr)
        sys.exit(1)
    reg_data = json.loads(reg_row[0])

    cursor.execute("SELECT value FROM auth_kv WHERE key = 'kirocli:odic:token'")
    token_row = cursor.fetchone()
    if not token_row:
        print("ERROR: No token found", file=sys.stderr)
        sys.exit(1)
    token_data = json.loads(token_row[0])

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

    for i in [1, 2]:
        creds_file = f"/home/sunrise/AIClient-2-API/credentials/account-0{i}.json"
        with open(creds_file, 'w') as f:
            json.dump(kiro_auth_token, f, indent=2)

    print(f"SUCCESS: Token expires at {kiro_auth_token['expiresAt']}")

except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo "[$(date)] ✅ Token刷新成功" >> "$LOG_FILE"
else
    echo "[$(date)] ❌ Token刷新失败" >> "$LOG_FILE"
    exit 1
fi
