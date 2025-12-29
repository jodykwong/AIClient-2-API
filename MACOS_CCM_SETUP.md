# macOS CCM 一键安装指南

这是在 macOS 上安装和配置 CCM (Claude Code Model Switcher) 的最快方式。

## 🚀 一键安装

### 方式 1: 直接从 GitHub 运行 (推荐)

在 macBook 终端中执行:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jodykwong/AIClient-2-API/main/install-ccm-macos.sh)
```

### 方式 2: 先下载后运行

```bash
# 1. 下载脚本
curl -fsSL https://raw.githubusercontent.com/jodykwong/AIClient-2-API/main/install-ccm-macos.sh -o install-ccm-macos.sh

# 2. 执行脚本
bash install-ccm-macos.sh
```

### 方式 3: 自定义配置源 URL

如果你有自己的 ccm-export.tar.gz，可以指定 URL:

```bash
bash install-ccm-macos.sh "https://your-server.com/ccm-export.tar.gz"
```

---

## ✨ 安装过程

脚本会自动执行以下操作:

1. ✅ 下载 CCM 配置包 (ccm-export.tar.gz)
2. ✅ 解压配置文件
3. ✅ 安装 ccm 脚本到 `~/.local/share/ccm/`
4. ✅ 复制语言文件和配置模板
5. ✅ 添加 `ccm` 别名到 shell 配置 (~/.zshrc 或 ~/.bash_profile)
6. ✅ 验证安装成功

---

## 📝 安装后配置

### 1. 重新加载 Shell 配置

安装完成后，重新加载 shell:

```bash
# 如果使用 zsh (macOS 默认)
source ~/.zshrc

# 如果使用 bash
source ~/.bash_profile
```

### 2. 编辑 API 密钥

编辑配置文件，填入你的 API 密钥:

```bash
nano ~/.ccm_config
```

**需要填入的关键信息:**

```bash
# Deepseek API (https://platform.deepseek.com)
DEEPSEEK_API_KEY=sk-your-deepseek-key

# Claude 中转站 (可选)
CLAUDE_API_KEY=sk-your-claude-key
CLAUDE_BASE_URL=https://cc.zhihuiapi.top

# KIMI API (https://api.moonshot.cn)
KIMI_API_KEY=your-kimi-key

# 阿里云 DashScope (Qwen)
QWEN_API_KEY=your-qwen-key

# 智谱清言 API
GLM_API_KEY=your-glm-key

# 本地 KIRO (可选)
KIRO_API_KEY=your-kiro-key
KIRO_BASE_URL=http://100.74.89.68:3000
# 或本地访问
KIRO_LOCAL_BASE_URL=http://localhost:3000
```

### 3. 验证安装

检查 ccm 是否成功安装:

```bash
ccm status
```

---

## 📚 常用命令

```bash
# 查看帮助
ccm help

# 查看当前状态
ccm status

# 切换到 Deepseek
eval "$(ccm deepseek)"

# 切换到 Claude Haiku
eval "$(ccm haiku)"

# 切换到 Claude Sonnet
eval "$(ccm sonnet)"

# 切换到 Kimi
eval "$(ccm kimi)"

# 切换到 Qwen
eval "$(ccm qwen)"

# 编辑配置
ccm config

# 列出所有可用模型
ccm list
```

---

## 🔐 macOS Keychain 集成 (可选)

如果你有 Claude Pro 账号，可以使用 Keychain 存储凭证:

```bash
# 保存 Claude Pro 账号到 Keychain
ccm save-account personal

# 列出所有保存的账号
ccm list-accounts

# 切换到不同的账号
ccm switch-account work

# 使用特定账号
eval "$(ccm switch-account personal && ccm haiku)"
```

---

## 🎯 KIRO 本地访问配置

如果你在本地运行 AIClient-2-API，可以配置本地访问:

### 选项 1: 本地 Localhost (推荐用于开发)

```bash
# 在 ~/.ccm_config 中配置
KIRO_BASE_URL=http://localhost:3000
KIRO_MODEL=claude-sonnet-4-5
KIRO_SMALL_FAST_MODEL=claude-haiku-4-5
```

然后在需要时切换到:
```bash
eval "$(ccm kiro)"
```

### 选项 2: Tailscale 网络访问 (推荐用于远程)

```bash
# 1. 在 macBook 安装 Tailscale
brew install tailscale
tailscale up

# 2. 在 ~/.ccm_config 中配置
KIRO_BASE_URL=http://100.74.89.68:3000
KIRO_MODEL=claude-sonnet-4-5
KIRO_SMALL_FAST_MODEL=claude-haiku-4-5

# 3. 测试连接
curl -s http://100.74.89.68:3000/api/status | jq .
```

---

## 🐛 常见问题与解决

### Q1: 命令找不到 "ccm"

**原因:** shell 配置未重新加载

**解决:**
```bash
# 重新加载 shell 配置
source ~/.zshrc
# 或
source ~/.bash_profile

# 验证别名
alias ccm
```

### Q2: 脚本下载失败

**原因:** 网络问题或 URL 不可用

**解决:**
```bash
# 使用 wget 而不是 curl
wget https://raw.githubusercontent.com/jodykwong/AIClient-2-API/main/install-ccm-macos.sh

# 或手动下载并运行
bash ./install-ccm-macos.sh
```

### Q3: 权限被拒绝

**原因:** 脚本没有执行权限

**解决:**
```bash
chmod +x install-ccm-macos.sh
bash install-ccm-macos.sh
```

### Q4: API 密钥设置后仍无效

**原因:** shell 未重新加载新的环境变量

**解决:**
```bash
# 编辑后重新加载
source ~/.zshrc

# 验证环境变量
echo $DEEPSEEK_API_KEY

# 使用 eval 切换模型
eval "$(ccm deepseek)"
```

### Q5: 在 macOS 上访问 Linux 上的 KIRO 服务

**如果在同一网络:**
```bash
# 测试连接
ping 100.74.89.68

# 配置 ccm_config
KIRO_BASE_URL=http://100.74.89.68:3000
```

**如果在不同网络:**
```bash
# 使用 Tailscale
brew install tailscale
tailscale up

# 然后配置
KIRO_BASE_URL=http://100.74.89.68:3000
```

---

## 📋 系统要求

- macOS 10.13+ (High Sierra 或更新)
- bash 或 zsh (macOS 默认)
- curl 或 wget (通常已预装)
- jq (可选，用于查看 API 响应)

### 安装缺失工具

```bash
# 安装 jq (用于 JSON 查看)
brew install jq

# 安装 Tailscale (可选)
brew install tailscale

# 验证安装
ccm status
```

---

## 🔒 安全建议

1. **不要在终端历史中暴露 API 密钥**
   ```bash
   # 用 nano 或 vim 编辑，不要用 echo
   nano ~/.ccm_config
   ```

2. **定期检查配置文件权限**
   ```bash
   chmod 600 ~/.ccm_config
   ls -la ~/.ccm_config
   ```

3. **使用 macOS Keychain 存储 Claude Pro 凭证**
   ```bash
   ccm save-account personal
   ```

4. **不要将 ~/.ccm_config 提交到 Git**
   ```bash
   # 将其加入 .gitignore
   echo "~/.ccm_config" >> ~/.gitignore
   ```

---

## 📞 获取帮助

```bash
# 查看 ccm 帮助
ccm help

# 查看当前配置状态
ccm status

# 编辑配置
ccm config

# 查看所有可用命令
ccm list
```

---

## ✅ 安装检查清单

- [ ] 脚本执行完成，无错误
- [ ] Shell 配置已重新加载 (`source ~/.zshrc`)
- [ ] `ccm` 命令可用 (`which ccm`)
- [ ] 配置文件已编辑 (`~/.ccm_config`)
- [ ] API 密钥已填入
- [ ] 验证安装成功 (`ccm status`)
- [ ] 已测试至少一个模型切换

---

## 🎉 完成

现在你可以在 macBook 上使用 CCM 来快速切换各种 AI 模型了!

```bash
eval "$(ccm deepseek)"      # 使用 Deepseek
eval "$(ccm haiku)"          # 使用 Claude Haiku
eval "$(ccm sonnet)"         # 使用 Claude Sonnet
```

祝你使用愉快! 🚀
