#!/bin/bash
# 停止所有服务：AIClient-2-API + Tailscale 监控 + Tailscale

echo "=========================================="
echo "停止所有服务"
echo "=========================================="

# 1. 停止 API 服务
echo "[1/3] 停止 AIClient-2-API..."
kill $(lsof -t -i:3000) 2>/dev/null && echo "✓ API 服务已停止" || echo "✓ API 服务未运行"

# 2. 停止监控进程
echo "[2/3] 停止 Tailscale 监控..."
pkill -f "monitor-tailscale.sh" 2>/dev/null && echo "✓ 监控进程已停止" || echo "✓ 监控进程未运行"

# 3. 停止 Tailscale
echo "[3/3] 停止 Tailscale..."
pkill tailscaled 2>/dev/null && echo "✓ Tailscale 已停止" || echo "✓ Tailscale 未运行"

echo ""
echo "=========================================="
echo "所有服务已停止"
echo "=========================================="
