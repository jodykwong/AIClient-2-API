# AIClient-2-API Docker 配置总结

已为 AIClient-2-API 项目完整配置了 Docker 支持。以下是设置内容的详细说明。

## ✅ 已完成的工作

### 1. 优化的 Dockerfile

**文件**: `Dockerfile`

**改进内容**:
- ✅ **多阶段构建** - 优化镜像大小
- ✅ **非 root 用户** - 使用 nodejs 用户（UID 1001）运行，提高安全性
- ✅ **dumb-init** - 正确的信号处理和进程管理
- ✅ **优化的分层** - 最大化构建缓存利用
- ✅ **完整的健康检查** - 自动监测服务健康状态
- ✅ **详细的注释** - 清晰的配置说明

**镜像信息**:
- 基础镜像: `node:20-alpine`
- 大小: ~500MB
- 用户: nodejs (非 root)

### 2. 完整的 Docker Compose 配置

**文件**: `docker-compose.yml`

**包含服务**:
- ✅ **aiclient-api** - 主 API 服务
  - 端口: 3000 (API) + 8085 (Web UI) + 8086 (管理后台) + 19876-19880 (流式)
  - 卷: 配置、日志、缓存目录持久化
  - 健康检查: 自动监测
  - 资源限制: 内存 2GB, CPU 2 核心

- ✅ **Redis** (可选)
  - 服务配置 profile: `with-redis`
  - 数据持久化
  - 密码保护

- ✅ **Portainer** (可选)
  - 服务配置 profile: `with-portainer`
  - 容器管理界面

**网络**: 自定义 bridge 网络 `aiclient-network`

### 3. 环境变量配置

**文件**: `.env.docker`

**包含内容**:
- ✅ 服务端口配置
- ✅ 文件路径配置
- ✅ API 选项配置
- ✅ Redis 配置
- ✅ Portainer 配置
- ✅ 日志配置

使用方法:
```bash
cp .env.docker .env
nano .env  # 根据需要修改
```

### 4. 完整的使用文档

#### DOCKER.md (完整指南)
- 快速开始
- Docker 镜像详情
- 常用命令总结
- 配置说明
- 高级用法
- 故障排除
- 监控维护

#### DOCKER_QUICK_REFERENCE.md (快速参考)
- 一分钟启动
- 常用命令速查表
- 环境变量速查
- 常见问题快速解决
- 常见工作流

### 5. 改进的 .dockerignore

**内容**: 优化的文件忽略清单，包括:
- 依赖目录
- Git 相关文件
- IDE 配置
- 测试文件
- 环境配置
- 凭证文件
- 文档
- 开发目录

---

## 📁 文件结构

```
AIClient-2-API/
├── Dockerfile                    # ✅ 多阶段优化镜像
├── docker-compose.yml            # ✅ 完整的编排配置
├── .dockerignore                 # ✅ 优化的忽略清单
├── .env.docker                   # ✅ 环境变量模板
├── DOCKER.md                     # ✅ 完整使用指南
├── DOCKER_QUICK_REFERENCE.md     # ✅ 快速参考卡
├── DOCKER_SETUP_SUMMARY.md       # ✅ 本文件
├── README.md                     # 原项目 README
└── src/
    └── api-server.js            # 应用主入口
```

---

## 🚀 快速开始

### 第一次使用（推荐）

```bash
# 1. 进入项目目录
cd AIClient-2-API

# 2. 复制环境变量文件
cp .env.docker .env

# 3. 启动容器
docker-compose up -d

# 4. 验证服务
curl http://localhost:3000/health

# 5. 访问 Web UI
# 浏览器访问: http://localhost:8085
```

### 使用官方 Docker Hub 镜像

```bash
docker pull justlikemaki/aiclient-2-api:latest

docker run -d \
  --name aiclient-api \
  -p 3000:3000 \
  -p 8085:8085 \
  -v $(pwd)/configs:/app/configs \
  -v $(pwd)/logs:/app/logs \
  justlikemaki/aiclient-2-api:latest
```

---

## 📊 配置参考

### 主要端口

| 端口 | 服务 | 说明 |
|------|------|------|
| 3000 | API | RESTful API 主端口 |
| 8085 | Web UI | 管理界面 |
| 8086 | 管理后台 | 可选管理端点 |
| 19876-19880 | 流式 | 流式响应端口 |
| 6379 | Redis | 可选缓存服务 |
| 9000 | Portainer | 可选容器管理 |

### 重要配置

```env
# 必需
API_PORT=3000
CONFIG_PATH=./configs

# 可选
ENABLE_WEB_UI=true
LOG_LEVEL=info
PROVIDER_POOLS_ENABLED=false
```

### 配置文件挂载

**重要**: 自 v2025.12.25 起，所有配置文件应放在 `configs/` 目录中。

```bash
# 确保目录存在
mkdir -p configs logs cache

# 挂载配置
-v ./configs:/app/configs
-v ./logs:/app/logs
-v ./cache:/app/cache
```

---

## 🔧 常用命令

```bash
# 启动/停止
docker-compose up -d          # 启动
docker-compose down           # 停止

# 查看日志
docker-compose logs -f aiclient-api

# 进入容器
docker-compose exec aiclient-api sh

# 可选服务
docker-compose --profile with-redis up -d
docker-compose --profile with-portainer up -d
```

详见 `DOCKER_QUICK_REFERENCE.md` 获取完整命令列表。

---

## 🎯 部署场景

### 本地开发

```bash
docker-compose up -d
docker-compose logs -f aiclient-api
# 修改代码后自动重新加载（如果支持）
```

### 生产环境

```bash
# 使用官方镜像
docker pull justlikemaki/aiclient-2-api:latest

# 配置环境变量
cp .env.docker .env
nano .env  # 设置安全密码和密钥

# 启动服务
docker-compose up -d

# 验证并监控
docker-compose ps
docker stats aiclient-api
```

### 高可用部署（使用 Docker Swarm 或 Kubernetes）

```bash
# 生成 Kubernetes manifests
kompose convert -f docker-compose.yml -o k8s/

# 或使用 Docker Stack
docker stack deploy -c docker-compose.yml aiclient
```

---

## 🔐 安全建议

- [ ] 更改 Redis 密码
- [ ] 配置强密钥
- [ ] 使用非 root 用户（已默认配置）
- [ ] 启用防火墙规则
- [ ] 定期更新镜像
- [ ] 备份配置文件
- [ ] 监控日志和错误
- [ ] 设置资源限制

详见 `DOCKER.md` 的"安全建议"章节。

---

## 📚 文档导航

| 文档 | 用途 | 长度 |
|------|------|------|
| **DOCKER.md** | 完整参考指南 | 长 (~400 行) |
| **DOCKER_QUICK_REFERENCE.md** | 速查表 | 短 (~150 行) |
| **DOCKER_SETUP_SUMMARY.md** | 本文件，快速总结 | 中 (~200 行) |
| **README.md** | 项目原始文档 | 详细 |

---

## 🆘 故障排除

### 常见问题

| 问题 | 解决方案 |
|------|---------|
| 容器无法启动 | 查看日志: `docker-compose logs aiclient-api` |
| 端口被占用 | 修改 `.env` 中的端口号 |
| 配置文件未生效 | 检查挂载: `docker inspect aiclient-api` |
| 权限错误 | 修复权限: `sudo chown -R 1001:1001 configs` |

详见 `DOCKER.md` 的"故障排除"章节。

---

## 📞 获取帮助

- **GitHub Issues**: [提交问题](https://github.com/justlovemaki/AIClient-2-API/issues)
- **官方文档**: https://aiproxy.justlikemaki.vip/zh/
- **Docker Hub**: https://hub.docker.com/r/justlikemaki/aiclient-2-api
- **本地帮助**:
  - 查看日志: `docker-compose logs -f`
  - 进入容器: `docker-compose exec aiclient-api sh`
  - 验证健康: `curl http://localhost:3000/health`

---

## 🎉 下一步

1. **复制环境变量**: `cp .env.docker .env`
2. **编辑配置**: `nano .env`
3. **启动服务**: `docker-compose up -d`
4. **验证运行**: `curl http://localhost:3000/health`
5. **访问 Web UI**: http://localhost:8085
6. **查看文档**: `cat DOCKER.md` 或 `cat DOCKER_QUICK_REFERENCE.md`

---

## 📝 版本信息

- **配置创建日期**: 2025-12-28
- **AIClient-2-API 版本**: v2.0+（支持 configs/ 目录）
- **Node.js 版本**: ≥20.0.0
- **Docker 版本**: ≥20.10
- **Docker Compose**: ≥2.0

---

## 📋 更新日志

### 2025-12-28
- ✅ 优化 Dockerfile（多阶段、非 root 用户、dumb-init）
- ✅ 创建完整 docker-compose.yml 配置
- ✅ 添加 Redis（可选）和 Portainer（可选）服务
- ✅ 创建 .env.docker 环境变量模板
- ✅ 编写完整的 DOCKER.md 指南
- ✅ 编写 DOCKER_QUICK_REFERENCE.md 快速参考
- ✅ 改进 .dockerignore 文件
- ✅ 创建本文件 DOCKER_SETUP_SUMMARY.md

---

**祝您使用愉快！** 🚀

有任何问题或建议，欢迎提交 GitHub Issues。
