# ========================================
# Build Stage - 编译和依赖安装
# ========================================
FROM node:20-alpine AS builder

WORKDIR /app

# 复制 package 文件
COPY package*.json ./

# 安装所有依赖（包括开发依赖）
RUN npm ci

# ========================================
# Runtime Stage - 生产运行时
# ========================================
FROM node:20-alpine

# 设置标签
LABEL maintainer="AIClient2API Team"
LABEL description="Docker image for AIClient2API server - An OpenAI-compatible API proxy for multiple AI models"
LABEL version="2.0"

# 安装 dumb-init 进程管理工具
RUN apk add --no-cache dumb-init

# 创建非 root 用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# 从 builder 阶段复制 node_modules
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# 复制源代码
COPY --chown=nodejs:nodejs . .

# 创建日志目录
RUN mkdir -p /app/logs && \
    chown -R nodejs:nodejs /app/logs

# 切换到非 root 用户
USER nodejs

# 暴露端口
# 3000: 主 API 端口
# 8085: Web UI 端口
# 8086: 管理后台端口（可选）
# 19876-19880: 流式响应相关端口
EXPOSE 3000 8085 8086 19876-19880

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD node healthcheck.js || exit 1

# 使用 dumb-init 作为 PID 1 进程，确保正确的信号处理
ENTRYPOINT ["dumb-init", "--"]

# 设置启动命令
# 默认启动 API 服务器，支持通过环境变量 ARGS 传递额外参数
# 示例: docker run -e ARGS="--api-key mykey --port 8080" aiclient-2-api
CMD ["node", "src/api-server.js"]