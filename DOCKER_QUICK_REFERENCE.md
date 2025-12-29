# AIClient-2-API Docker 快速参考

## 🚀 一分钟启动

```bash
# 克隆项目
git clone https://github.com/justlovemaki/AIClient-2-API.git
cd AIClient-2-API

# 启动
docker-compose up -d

# 验证
curl http://localhost:3000/health
```

访问地址：
- **API**: http://localhost:3000
- **Web UI**: http://localhost:8085
- **健康检查**: http://localhost:3000/health

---

## 📋 常用命令速查

### 基础操作

| 命令 | 说明 |
|------|------|
| `docker-compose up -d` | 后台启动所有服务 |
| `docker-compose down` | 停止所有服务 |
| `docker-compose logs -f aiclient-api` | 实时查看日志 |
| `docker-compose restart aiclient-api` | 重启 API 服务 |
| `docker-compose ps` | 查看运行中的容器 |

### 进入容器

| 命令 | 说明 |
|------|------|
| `docker-compose exec aiclient-api sh` | 进入容器 shell |
| `docker-compose exec aiclient-api npm test` | 运行测试 |
| `docker-compose exec aiclient-api ls -la /app/configs` | 查看配置文件 |

### 可选服务

| 命令 | 说明 |
|------|------|
| `docker-compose --profile with-redis up -d` | 启用 Redis |
| `docker-compose --profile with-portainer up -d` | 启用 Portainer |
| `docker-compose --profile with-redis --profile with-portainer up -d` | 同时启用两个 |

### 镜像操作

| 命令 | 说明 |
|------|------|
| `docker-compose build` | 构建镜像 |
| `docker-compose build --no-cache` | 重新构建（不使用缓存） |
| `docker images \| grep aiclient` | 查看 aiclient 镜像 |
| `docker pull justlikemaki/aiclient-2-api:latest` | 拉取官方镜像 |

---

## 🔧 环境变量速查

```bash
# 复制环境配置
cp .env.docker .env

# 编辑环境变量
nano .env
```

常用变量：

```env
# 端口
API_PORT=3000
WEB_UI_PORT=8085

# 日志
LOG_LEVEL=info

# 路径
CONFIG_PATH=./configs
LOG_PATH=./logs
```

---

## 🐛 常见问题快速解决

### 问题 1: 端口被占用

```bash
# 更改端口
echo "API_PORT=3001" >> .env
docker-compose up -d
```

### 问题 2: 容器无法启动

```bash
# 查看错误日志
docker-compose logs aiclient-api

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

### 问题 3: 配置文件未生效

```bash
# 检查挂载
docker inspect aiclient-api | grep -A 10 Mounts

# 重启服务
docker-compose restart aiclient-api
```

### 问题 4: 权限错误

```bash
# 修复权限
sudo chown -R 1001:1001 configs logs
```

---

## 🎯 常见工作流

### 开发调试

```bash
# 查看实时日志
docker-compose logs -f aiclient-api

# 进入容器调试
docker-compose exec aiclient-api sh

# 运行测试
docker-compose exec aiclient-api npm test
```

### 生产部署

```bash
# 启动服务
docker-compose up -d

# 验证健康
curl http://localhost:3000/health

# 查看日志
docker-compose logs --tail=100 aiclient-api

# 监控资源
docker stats aiclient-api
```

### 配置更新

```bash
# 编辑配置
nano configs/config.json

# 不需要重启，直接生效（如果支持热重载）
# 或重启服务
docker-compose restart aiclient-api
```

### 备份和恢复

```bash
# 备份配置
tar czf configs-backup.tar.gz configs/

# 备份日志
docker-compose logs aiclient-api > app.log

# 恢复配置
tar xzf configs-backup.tar.gz
```

---

## 📊 资源监控

```bash
# 实时监控
docker stats aiclient-api

# 容器详细信息
docker inspect aiclient-api | jq '.[] | .HostConfig.Memory'

# 查看日志大小
du -h $(docker inspect --format='{{.LogPath}}' aiclient-api)
```

---

## 🔗 相关链接

| 链接 | 说明 |
|------|------|
| GitHub | https://github.com/justlovemaki/AIClient-2-API |
| Docker Hub | https://hub.docker.com/r/justlikemaki/aiclient-2-api |
| 文档 | https://aiproxy.justlikemaki.vip/zh/ |

---

## 💡 提示

- **配置文件在 `./configs/` 目录**（v2025.12.25+ 更新）
- **使用 `-v ./configs:/app/configs` 挂载配置**
- **访问 Web UI** 管理账号池和系统提示词
- **查看日志** 了解运行状态和故障信息
- **定期备份** 重要配置文件

---

## 🆘 获取帮助

```bash
# 查看完整文档
cat DOCKER.md

# 查看 docker-compose 帮助
docker-compose --help

# 查看容器日志
docker-compose logs -f aiclient-api

# 检查 docker 版本
docker --version
docker-compose --version
```
