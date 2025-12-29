#!/bin/bash

################################################################################
# CCM Configuration Auto-Installer for macOS
# 功能: 自动下载、安装和配置 CCM 模型切换工具
# 用法: bash install-ccm-macos.sh [config_url]
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印函数
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
    echo -e "${YELLOW}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# 参数
CONFIG_URL="${1:-https://github.com/jodykwong/AIClient-2-API/raw/main/ccm-export.tar.gz}"
WORK_DIR=$(mktemp -d)
SHELL_RC=""

# 确定 Shell 配置文件
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_RC="$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    print_error "找不到 shell 配置文件"
    exit 1
fi

print_header "CCM macOS 自动安装程序"

# 步骤 1: 下载配置包
print_step "正在下载 CCM 配置包..."
if command -v curl &> /dev/null; then
    curl -fsSL "$CONFIG_URL" -o "$WORK_DIR/ccm-export.tar.gz" || {
        print_error "下载失败: $CONFIG_URL"
        rm -rf "$WORK_DIR"
        exit 1
    }
elif command -v wget &> /dev/null; then
    wget -q "$CONFIG_URL" -O "$WORK_DIR/ccm-export.tar.gz" || {
        print_error "下载失败: $CONFIG_URL"
        rm -rf "$WORK_DIR"
        exit 1
    }
else
    print_error "需要 curl 或 wget，请先安装"
    rm -rf "$WORK_DIR"
    exit 1
fi

# 验证下载
if [ ! -f "$WORK_DIR/ccm-export.tar.gz" ]; then
    print_error "配置包下载失败"
    rm -rf "$WORK_DIR"
    exit 1
fi

print_success "配置包下载完成 ($(du -h "$WORK_DIR/ccm-export.tar.gz" | cut -f1))"

# 步骤 2: 解压文件
print_step "正在解压配置文件..."
mkdir -p "$WORK_DIR/extract"
tar -xzf "$WORK_DIR/ccm-export.tar.gz" -C "$WORK_DIR/extract" || {
    print_error "解压失败"
    rm -rf "$WORK_DIR"
    exit 1
}

# 找到解压后的目录
EXTRACT_DIR=$(ls -d "$WORK_DIR/extract"/*/ 2>/dev/null | head -1)
if [ -z "$EXTRACT_DIR" ]; then
    print_error "解压目录结构异常"
    rm -rf "$WORK_DIR"
    exit 1
fi

print_success "文件解压完成"

# 步骤 3: 检查必要文件
print_step "检查必要文件..."
if [ ! -f "$EXTRACT_DIR/.local/share/ccm/ccm.sh" ]; then
    print_error "找不到 ccm.sh"
    rm -rf "$WORK_DIR"
    exit 1
fi
print_success "ccm.sh 找到"

if [ ! -f "$EXTRACT_DIR/.ccm_config" ]; then
    print_error "找不到 .ccm_config"
    rm -rf "$WORK_DIR"
    exit 1
fi
print_success "配置文件找到"

# 步骤 4: 创建 ccm 目录
print_step "创建 ccm 安装目录..."
mkdir -p ~/.local/share/ccm
print_success "目录创建完成: ~/.local/share/ccm"

# 步骤 5: 复制脚本
print_step "复制 ccm 脚本..."
cp "$EXTRACT_DIR/.local/share/ccm/ccm.sh" ~/.local/share/ccm/
chmod +x ~/.local/share/ccm/ccm.sh
print_success "ccm.sh 已安装"

# 步骤 6: 复制语言文件
if [ -d "$EXTRACT_DIR/.local/share/ccm/lang" ]; then
    print_step "复制语言文件..."
    cp -r "$EXTRACT_DIR/.local/share/ccm/lang" ~/.local/share/ccm/
    print_success "语言文件已复制"
fi

# 步骤 7: 复制配置文件
print_step "复制配置文件..."
if [ ! -f ~/.ccm_config ]; then
    cp "$EXTRACT_DIR/.ccm_config" ~/.ccm_config
    print_success "配置文件已复制到 ~/.ccm_config"
else
    print_info "~/.ccm_config 已存在，跳过覆盖"
    print_info "备份已有配置到 ~/.ccm_config.backup"
    cp ~/.ccm_config ~/.ccm_config.backup
fi

# 步骤 8: 添加别名
print_step "配置 shell 别名..."
ALIAS_LINE="alias ccm='~/.local/share/ccm/ccm.sh'"

if grep -q "alias ccm=" "$SHELL_RC" 2>/dev/null; then
    print_info "别名已存在于 $SHELL_RC"
else
    echo "" >> "$SHELL_RC"
    echo "# CCM - Claude Code Model Switcher" >> "$SHELL_RC"
    echo "$ALIAS_LINE" >> "$SHELL_RC"
    print_success "别名已添加到 $SHELL_RC"
fi

# 步骤 9: 验证安装
print_step "验证安装..."
if [ ! -x ~/.local/share/ccm/ccm.sh ]; then
    print_error "ccm.sh 不是可执行文件"
    rm -rf "$WORK_DIR"
    exit 1
fi
print_success "ccm.sh 可执行"

if [ ! -f ~/.ccm_config ]; then
    print_error "配置文件不存在"
    rm -rf "$WORK_DIR"
    exit 1
fi
print_success "配置文件存在"

# 步骤 10: 清理临时文件
print_step "清理临时文件..."
rm -rf "$WORK_DIR"
print_success "清理完成"

# 完成信息
print_header "安装完成! 🎉"

echo ""
echo -e "${GREEN}CCM 已成功安装到 macOS${NC}"
echo ""
echo "📝 下一步操作:"
echo ""
echo "1️⃣  重新加载 shell 配置:"
echo -e "   ${YELLOW}source $SHELL_RC${NC}"
echo ""
echo "2️⃣  编辑 API 密钥配置:"
echo -e "   ${YELLOW}nano ~/.ccm_config${NC}"
echo ""
echo "3️⃣  验证安装:"
echo -e "   ${YELLOW}ccm status${NC}"
echo ""
echo "📚 常用命令:"
echo -e "   ${YELLOW}ccm help${NC}              # 查看帮助"
echo -e "   ${YELLOW}ccm status${NC}            # 查看当前状态"
echo -e "   ${YELLOW}ccm deepseek${NC}          # 切换到 Deepseek"
echo -e "   ${YELLOW}ccm haiku${NC}             # 切换到 Claude Haiku"
echo -e "   ${YELLOW}ccm config${NC}            # 编辑配置"
echo ""

echo -e "${BLUE}需要填入的关键 API 密钥:${NC}"
echo "  • DEEPSEEK_API_KEY    - Deepseek API"
echo "  • CLAUDE_API_KEY      - 中转站 API (可选)"
echo "  • KIMI_API_KEY        - KIMI API"
echo "  • QWEN_API_KEY        - 阿里云 DashScope"
echo ""

echo -e "${BLUE}提示:${NC}"
echo "  • 所有 API 密钥已被脱敏，需要手动填入"
echo "  • KIRO 配置可用于本地 AIClient-2-API 访问"
echo "  • 编辑完成后，使用 'eval \$(ccm <model>)' 切换模型"
echo ""

# 源配置文件
source "$SHELL_RC"

print_header "准备就绪"
echo ""
echo -e "${GREEN}现在可以执行以下命令来切换模型:${NC}"
echo ""
echo "eval \$(ccm deepseek)"
echo "eval \$(ccm haiku)"
echo ""
