#!/bin/bash
# 启动所有服务：Tailscale + AIClient-2-API

echo "=========================================="
echo "启动 AIClient-2-API 完整环境"
echo "=========================================="

# 1. 启动 Tailscale
echo ""
echo "[1/3] 启动 Tailscale..."
/home/sunrise/tailscale/start-tailscale.sh
sleep 3

# 2. 启动 Tailscale 监控
echo ""
echo "[2/3] 启动 Tailscale 监控..."
nohup /home/sunrise/tailscale/monitor-tailscale.sh > /home/sunrise/tailscale/monitor.log 2>&1 &
echo "✓ 监控进程已启动"

# 3. 启动 AIClient-2-API
echo ""
echo "[3/3] 启动 AIClient-2-API..."
cd /home/sunrise/AIClient-2-API
nohup node src/api-server.js > logs/api-server.log 2>&1 &
sleep 5

# 显示状态
echo ""
echo "=========================================="
echo "启动完成！当前状态："
echo "=========================================="
echo ""
echo "Tailscale 状态："
/home/sunrise/tailscale/ts status
echo ""
echo "API 服务状态："
curl -s http://localhost:3000/health | python3 -m json.tool
echo ""
echo "=========================================="
echo "访问地址："
echo "  Web UI: http://100.74.89.68:3000/"
echo "  API Key: your-secure-api-key-12345"
echo "=========================================="
