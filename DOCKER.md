# AIClient-2-API Docker 部署指南

一个能将多种仅客户端内使用的大模型 API（Gemini CLI, Antigravity, Qwen Code, Kiro ...），模拟请求，统一封装为本地 OpenAI 兼容接口的强大代理。

## 📋 目录

- [快速开始](#快速开始)
- [Docker 镜像](#docker-镜像)
- [常用命令](#常用命令)
- [配置说明](#配置说明)
- [高级用法](#高级用法)
- [故障排除](#故障排除)

## 🚀 快速开始

### 最小化启动（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/justlovemaki/AIClient-2-API.git
cd AIClient-2-API

# 2. 复制环境变量文件
cp .env.docker .env

# 3. 启动容器
docker-compose up -d

# 4. 查看日志
docker-compose logs -f aiclient-api

# 5. 验证服务
curl http://localhost:3000/health
```

### 使用 Docker Hub 官方镜像

```bash
# 直接使用 Docker Hub 镜像（无需构建）
docker run -d \
  --name aiclient-api \
  -p 3000:3000 \
  -p 8085:8085 \
  -v $(pwd)/configs:/app/configs \
  -v $(pwd)/logs:/app/logs \
  justlikemaki/aiclient-2-api:latest
```

## 🐳 Docker 镜像

### 官方镜像信息

- **镜像名称**: `justlikemaki/aiclient-2-api`
- **标签**:
  - `latest` - 最新版本
  - `v2.0.0` - 特定版本号
  - `main` - 主分支最新构建

### 本地构建镜像

```bash
# 构建镜像
docker-compose build

# 强制重新构建（不使用缓存）
docker-compose build --no-cache

# 查看镜像
docker images | grep aiclient
```

### 镜像信息

- **基础镜像**: `node:20-alpine`
- **大小**: ~500MB
- **用户**: nodejs (uid: 1001)
- **工作目录**: `/app`

## 📦 Docker Compose 配置

### 基础服务配置

```yaml
services:
  aiclient-api:
    build: .
    ports:
      - "3000:3000"      # API 主端口
      - "8085:8085"      # Web UI 端口
      - "8086:8086"      # 管理后台（可选）
    volumes:
      - ./configs:/app/configs   # 配置文件
      - ./logs:/app/logs         # 日志文件
```

### 可选服务

#### 启用 Redis 缓存

```bash
# 启动包含 Redis 的所有服务
docker-compose --profile with-redis up -d

# 停止时也需要指定 profile
docker-compose --profile with-redis down
```

#### 启用 Portainer 监控

```bash
# 启动包含 Portainer 的所有服务
docker-compose --profile with-portainer up -d

# 访问 Portainer 界面
# http://localhost:9000
```

#### 同时启用两个可选服务

```bash
docker-compose --profile with-redis --profile with-portainer up -d
```

## 🔧 常用命令

### 启动和停止

```bash
# 启动所有服务（后台运行）
docker-compose up -d

# 启动并查看实时日志
docker-compose up

# 停止所有服务
docker-compose down

# 停止并删除所有数据卷
docker-compose down -v

# 重启特定服务
docker-compose restart aiclient-api
```

### 查看日志

```bash
# 实时查看 API 日志
docker-compose logs -f aiclient-api

# 查看最后 100 行日志
docker-compose logs --tail=100 aiclient-api

# 查看所有服务日志
docker-compose logs -f

# 查看特定时间范围的日志
docker-compose logs --since 2025-12-28 --until 2025-12-29
```

### 进入容器

```bash
# 进入 API 容器 shell
docker-compose exec aiclient-api sh

# 执行特定命令
docker-compose exec aiclient-api npm test

# 查看容器内的进程
docker-compose exec aiclient-api ps aux
```

### 管理容器

```bash
# 查看运行中的容器
docker-compose ps

# 查看容器详细信息
docker inspect aiclient-api

# 查看容器资源使用情况
docker stats

# 查看容器网络
docker network ls
docker network inspect aiclient-network
```

### 配置和文件

```bash
# 查看当前配置
docker-compose config

# 验证 docker-compose.yml 语法
docker-compose config --quiet

# 列出容器中的文件
docker-compose exec aiclient-api ls -la /app/configs
```

## ⚙️ 配置说明

### 环境变量

复制 `.env.docker` 为 `.env`，然后编辑配置：

```bash
cp .env.docker .env
nano .env
```

主要配置项：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `API_PORT` | 3000 | API 服务端口 |
| `WEB_UI_PORT` | 8085 | Web UI 管理界面端口 |
| `ENABLE_WEB_UI` | true | 是否启用 Web UI |
| `LOG_LEVEL` | info | 日志级别 (debug/info/warn/error) |
| `CONFIG_PATH` | ./configs | 配置文件本地路径 |
| `LOG_PATH` | ./logs | 日志文件本地路径 |
| `PROVIDER_POOLS_ENABLED` | false | 是否启用账号池 |

### 配置文件结构

```
configs/
├── config.json                 # 主配置文件
├── provider_pools.json        # 账号池配置（可选）
└── system_prompts.txt         # 系统提示词（可选）
```

**重要**: 自 v2025.12.25 起，所有配置文件应放在 `configs/` 目录中，使用 `-v ./configs:/app/configs` 挂载。

### 配置文件示例

见项目中的 `configs/` 目录或官方文档。

## 🔐 安全建议

### 生产环境检查清单

- [ ] 更改默认密码和 API 密钥
- [ ] 使用强密码保护 Redis
- [ ] 配置防火墙仅允许必要端口
- [ ] 启用日志持久化和监控
- [ ] 定期备份配置文件
- [ ] 使用非 root 用户运行（已默认配置）
- [ ] 启用健康检查和自动重启
- [ ] 配置资源限制防止滥用

### 权限配置

容器以 `nodejs` 用户（UID: 1001）运行：

```bash
# 确保本地目录权限正确
sudo chown -R 1001:1001 configs logs cache

# 或使用宽松权限
chmod 755 configs logs cache
```

## 🚀 高级用法

### 自定义启动参数

```bash
# 通过环境变量传递参数
docker-compose up -d
docker-compose exec aiclient-api node src/api-server.js --help

# 或在 docker-compose.yml 中修改 command
command: node src/api-server.js --api-key YOUR_KEY --port 8080
```

### 多容器编排

```bash
# 使用 docker-compose 覆盖文件
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 或环境变量
COMPOSE_PROJECT_NAME=aiclient docker-compose up -d
```

### 网络配置

```bash
# 连接到外部网络
docker network connect aiclient-network external-container

# 查看容器 IP
docker inspect --format='{{json .NetworkSettings.Networks}}' aiclient-api | jq
```

### 监控和告警

```bash
# 监控容器资源使用
docker stats --no-stream

# 查看容器事件
docker events --filter "container=aiclient-api"

# 导出日志供分析
docker-compose logs aiclient-api > logs-export.txt
```

### Kubernetes 部署

将 docker-compose 转换为 Kubernetes manifests：

```bash
# 安装 kompose
curl -L https://github.com/kubernetes/kompose/releases/latest/download/kompose-linux-amd64 -o kompose
chmod +x kompose

# 转换
./kompose convert -f docker-compose.yml -o k8s/
```

## 🔍 故障排除

### 常见问题

#### 1. 容器无法启动

```bash
# 查看详细错误
docker-compose logs aiclient-api

# 检查镜像是否存在
docker images | grep aiclient

# 尝试强制重新构建
docker-compose build --no-cache --pull
docker-compose up -d
```

#### 2. 端口已被占用

```bash
# 查找占用端口的进程
lsof -i :3000
sudo netstat -tulpn | grep :3000

# 修改 .env 中的端口
echo "API_PORT=3001" >> .env

# 或停止占用的服务
sudo systemctl stop nginx
```

#### 3. 配置文件未被应用

确保配置目录挂载正确：

```bash
# 检查挂载
docker inspect aiclient-api | grep -A 10 Mounts

# 进入容器检查文件
docker-compose exec aiclient-api ls -la /app/configs

# 重新启动应用
docker-compose restart aiclient-api
```

#### 4. 权限拒绝错误

```bash
# 检查文件权限
ls -la configs/

# 修复权限（使用 UID 1001）
sudo chown -R 1001:1001 configs logs cache
chmod 755 configs logs cache
```

#### 5. 内存或 CPU 不足

```bash
# 查看资源限制
docker inspect aiclient-api | grep -i "memory\|cpu"

# 查看实时使用
docker stats aiclient-api

# 增加资源限制（编辑 docker-compose.yml）
deploy:
  resources:
    limits:
      memory: 4G
      cpus: '4'
```

#### 6. 网络连接问题

```bash
# 检查容器网络
docker inspect aiclient-api | grep -A 5 "NetworkSettings"

# 测试容器间通信
docker-compose exec aiclient-api ping redis

# 检查 DNS
docker-compose exec aiclient-api nslookup redis
```

### 调试模式

```bash
# 启用调试日志
docker-compose exec aiclient-api sh -c 'LOG_LEVEL=debug node src/api-server.js'

# 交互式 shell
docker-compose exec aiclient-api sh

# 查看环境变量
docker-compose exec aiclient-api env | sort
```

### 日志分析

```bash
# 导出日志进行分析
docker-compose logs --timestamps aiclient-api > debug.log

# 查找错误
docker-compose logs aiclient-api | grep -i error

# 统计请求
docker-compose logs aiclient-api | grep "GET\|POST" | wc -l
```

## 📊 监控和维护

### 系统监控

```bash
# 实时监控
watch -n 1 'docker-compose ps && echo && docker stats --no-stream'

# 查看容器日志大小
du -h $(docker inspect --format='{{.LogPath}}' aiclient-api)

# 清理日志（如果占用空间过大）
docker exec aiclient-api sh -c 'echo "" > /app/logs/app.log'
```

### 定期维护

```bash
# 清理未使用的镜像和容器
docker system prune -a

# 清理未使用的卷
docker volume prune

# 备份配置
tar czf configs-backup-$(date +%Y%m%d).tar.gz configs/

# 导出日志
docker-compose logs aiclient-api > logs-$(date +%Y%m%d).txt
```

### 更新和升级

```bash
# 检查新版本
docker pull justlikemaki/aiclient-2-api:latest

# 升级服务
docker-compose pull
docker-compose up -d

# 验证升级
docker-compose logs aiclient-api | head -20
```

## 📚 相关资源

- [GitHub 项目](https://github.com/justlovemaki/AIClient-2-API)
- [Docker Hub 镜像](https://hub.docker.com/r/justlikemaki/aiclient-2-api)
- [项目文档](https://aiproxy.justlikemaki.vip/zh/)
- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)

## 💬 获取帮助

- GitHub Issues: [报告问题](https://github.com/justlovemaki/AIClient-2-API/issues)
- 查看日志：`docker-compose logs -f aiclient-api`
- 测试端点：`curl http://localhost:3000/health`
- Web UI：访问 `http://localhost:8085`

## 📝 版本信息

- **当前版本**: v2.0+
- **最后更新**: 2025-12-28
- **更新内容**: 配置文件统一到 `configs/` 目录

---

**祝您使用愉快！** 🎉
