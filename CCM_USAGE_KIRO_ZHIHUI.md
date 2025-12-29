# CCM 命令使用指南 - KIRO 和 ZhiHui 切换

这个指南说明如何使用 `ccm` 命令切换到 KIRO 和 ZhiHui 的 API Key。

---

## 📋 环境变量配置

首先，编辑 `~/.ccm_config` 文件，配置必要的 API 密钥：

```bash
# 编辑配置
nano ~/.ccm_config
```

### 1️⃣ ZhiHui 配置（智慧 API）

```bash
# ZhiHui API 配置
ZHIHUI_API_KEY=sk-your-zhihui-api-key
ZHIHUI_BASE_URL=https://cc.zhihuiapi.top
ZHIHUI_MODEL=claude-sonnet-4-5-20250929
ZHIHUI_SMALL_FAST_MODEL=claude-sonnet-4-5-20250929
```

### 2️⃣ KIRO 配置（本地 AIClient-2-API）

```bash
# KIRO (本地 AIClient-2-API 双账号池)
KIRO_API_KEY=your-kiro-auth-token
KIRO_BASE_URL=http://100.74.89.68:3000
KIRO_MODEL=claude-sonnet-4-5
KIRO_SMALL_FAST_MODEL=claude-haiku-4-5

# 或者本地访问
KIRO_LOCAL_BASE_URL=http://localhost:3000
```

---

## 🚀 切换命令

### 切换到 ZhiHui

```bash
# 方式 1: 直接切换
eval "$(ccm zhihui)"

# 方式 2: 使用短别名
eval "$(ccm zh)"
```

**输出示例：**
```
🔄 Switching to 智慧 API (ZhiHui) model...
✅ Switched to 智慧 API (ZhiHui)（official）
   BASE_URL: https://cc.zhihuiapi.top
   MODEL: claude-sonnet-4-5-20250929
   SMALL_MODEL: claude-sonnet-4-5-20250929
```

### 切换到 KIRO

```bash
# 切换到 KIRO
eval "$(ccm kiro)"
```

**输出示例：**
```
🔄 Switching to KIRO (AIClient-2-API Pool) model...
✅ Switched to KIRO (2 accounts LRU pool)
   BASE_URL: http://100.74.89.68:3000
   MODEL: claude-sonnet-4-5
   SMALL_MODEL: claude-haiku-4-5
   📊 Pool: account-01, account-02 (auto rotation)
```

---

## 📚 所有可用命令

```bash
# 查看所有可用模型
ccm list

# 查看当前状态
ccm status

# 查看帮助
ccm help

# 编辑配置
ccm config
```

### 完整模型列表

```bash
# Claude (Pro 订阅)
eval "$(ccm claude)"          # Claude Sonnet 4.5
eval "$(ccm haiku)"           # Claude Haiku 4.5
eval "$(ccm sonnet)"          # Claude Sonnet 4.5
eval "$(ccm opus)"            # Claude Opus 4.1

# API 中转服务
eval "$(ccm zhihui)"          # 智慧 API (ZhiHui)
eval "$(ccm zh)"              # ZhiHui 短别名

# 本地服务
eval "$(ccm kiro)"            # KIRO (AIClient-2-API)

# 其他模型
eval "$(ccm deepseek)"        # Deepseek
eval "$(ccm kimi)"            # KIMI
eval "$(ccm qwen)"            # Qwen
eval "$(ccm glm)"             # GLM 4.6
```

---

## 🎯 实际使用例子

### 例子 1: 切换到 ZhiHui 然后使用 Claude

```bash
# 1. 切换到 ZhiHui
eval "$(ccm zhihui)"

# 2. 验证切换成功
echo $ANTHROPIC_BASE_URL
# 输出: https://cc.zhihuiapi.top

# 3. 现在可以使用任何支持 ANTHROPIC_API_KEY 的工具
# 比如: claude-code, aider, continue.dev 等
```

### 例子 2: 切换到 KIRO 然后使用

```bash
# 1. 切换到 KIRO
eval "$(ccm kiro)"

# 2. 验证设置
echo $ANTHROPIC_BASE_URL
# 输出: http://100.74.89.68:3000

echo $ANTHROPIC_MODEL
# 输出: claude-sonnet-4-5

# 3. 现在会使用本地 AIClient-2-API 服务
# 自动轮询 account-01 和 account-02
```

### 例子 3: 快速切换模型

```bash
# 从 ZhiHui 切换到 Deepseek
eval "$(ccm zhihui)"
# ... 使用 ZhiHui ...

eval "$(ccm deepseek)"
# ... 使用 Deepseek ...

eval "$(ccm kiro)"
# ... 使用 KIRO ...
```

---

## 🔧 故障排除

### 问题 1: 切换后说找不到 API Key

**错误信息:**
```
❌ Missing API key: ZHIHUI_API_KEY
Please set in config: ZHIHUI_API_KEY
```

**解决方案:**
```bash
# 1. 编辑配置文件
nano ~/.ccm_config

# 2. 确保有以下行
ZHIHUI_API_KEY=sk-your-actual-key

# 3. 保存后重新加载
source ~/.zshrc

# 4. 再次尝试切换
eval "$(ccm zhihui)"
```

### 问题 2: KIRO 连接失败

**可能原因:**
- KIRO 服务未启动
- IP 地址不正确
- 网络不可达

**解决方案:**
```bash
# 1. 测试连接
curl -s http://100.74.89.68:3000/api/status | jq .

# 2. 如果本地运行，使用 localhost
# 编辑 ~/.ccm_config，改为:
KIRO_BASE_URL=http://localhost:3000

# 3. 重新加载并切换
source ~/.zshrc
eval "$(ccm kiro)"
```

### 问题 3: 环境变量未生效

**问题:**
```bash
eval "$(ccm zhihui)"
# 执行后，$ANTHROPIC_API_KEY 仍然是旧值
```

**解决方案:**
```bash
# 使用 eval 而不是简单的执行
eval "$(ccm zhihui)"

# 验证
echo $ANTHROPIC_API_KEY
echo $ANTHROPIC_BASE_URL
echo $ANTHROPIC_MODEL
```

---

## 💡 高级用法

### 在脚本中使用

```bash
#!/bin/bash

# 在脚本中切换模型
eval "$(ccm kiro)"

# 现在脚本会使用 KIRO 服务
your-claude-tool --some-option
```

### 创建快捷别名

在 `~/.zshrc` 或 `~/.bash_profile` 中添加：

```bash
# 快速切换别名
alias use-zhihui='eval "$(ccm zhihui)"'
alias use-kiro='eval "$(ccm kiro)"'
alias use-deepseek='eval "$(ccm deepseek)"'
alias use-haiku='eval "$(ccm haiku)"'

# 然后就可以直接用:
# use-zhihui
# use-kiro
```

### 查看所有导出的环境变量

```bash
# 切换到 KIRO
eval "$(ccm kiro)"

# 查看所有 ANTHROPIC 相关的环境变量
env | grep ANTHROPIC
```

**输出示例:**
```
ANTHROPIC_BASE_URL=http://100.74.89.68:3000
ANTHROPIC_API_KEY=your-kiro-key
ANTHROPIC_AUTH_TOKEN=your-kiro-key
ANTHROPIC_MODEL=claude-sonnet-4-5
ANTHROPIC_SMALL_FAST_MODEL=claude-haiku-4-5
```

---

## 📊 ZhiHui vs KIRO 对比

| 特性 | ZhiHui | KIRO |
|------|--------|------|
| **服务位置** | 云端中转 | 本地 Tailscale |
| **API 端点** | https://cc.zhihuiapi.top | http://100.74.89.68:3000 |
| **默认模型** | claude-sonnet-4-5 | claude-sonnet-4-5 |
| **小模型** | claude-sonnet-4-5 | claude-haiku-4-5 |
| **账号管理** | 单 Token | 双账号池 (LRU 轮询) |
| **适用场景** | 远程访问 | 本地高频访问 |
| **延迟** | 较高 (网络转发) | 较低 (直连) |

---

## 🔐 安全建议

1. **不要在代码中硬编码 API Key**
   ```bash
   # ❌ 不要这样做
   export ZHIHUI_API_KEY="sk-xxx" in script

   # ✅ 应该这样做
   # 在 ~/.ccm_config 中配置
   ```

2. **保护配置文件权限**
   ```bash
   chmod 600 ~/.ccm_config
   ```

3. **定期检查和轮换 API Key**
   ```bash
   # 编辑配置
   nano ~/.ccm_config
   # 更新 API Key
   ```

---

## ✅ 完整使用流程

### 第一次安装和配置

```bash
# 1. 运行安装脚本
bash <(curl -fsSL https://raw.githubusercontent.com/jodykwong/AIClient-2-API/main/setup-ccm-complete.sh)

# 2. 编辑配置，添加 API Key
nano ~/.ccm_config

# 3. 在配置中添加:
# ZHIHUI_API_KEY=sk-your-key
# KIRO_API_KEY=your-kiro-key
# KIRO_BASE_URL=http://100.74.89.68:3000

# 4. 重新加载 shell
source ~/.zshrc

# 5. 验证
ccm status
```

### 日常使用

```bash
# 切换到 ZhiHui
eval "$(ccm zhihui)"

# 使用 Claude 工具
some-claude-tool

# 切换到 KIRO
eval "$(ccm kiro)"

# 再次使用 Claude 工具（现在使用本地 KIRO）
some-claude-tool

# 查看当前模型
ccm status
```

---

## 📞 获取帮助

```bash
# 查看所有可用命令
ccm help

# 列出所有可用模型
ccm list

# 查看当前配置状态
ccm status

# 编辑配置文件
ccm config

# 查看环境变量
env | grep ANTHROPIC
```

---

## 🎉 现在你可以使用 KIRO 和 ZhiHui 了！

```bash
# 快速开始
eval "$(ccm zhihui)"      # 使用智慧 API
eval "$(ccm kiro)"        # 使用本地 KIRO 服务
```

祝你使用愉快! 🚀
