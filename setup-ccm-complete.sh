#!/bin/bash

################################################################################
# CCM Complete Setup Script for macOS
# 一条命令完成所有配置，安装后直接可用 ccm 命令
#
# 使用方法:
#   bash setup-ccm-complete.sh
#
# 支持参数:
#   bash setup-ccm-complete.sh --deepseek-key=sk-xxx --claude-key=sk-xxx
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 参数解析
DEEPSEEK_KEY=""
CLAUDE_KEY=""
KIMI_KEY=""
QWEN_KEY=""
GLM_KEY=""

for arg in "$@"; do
    case $arg in
        --deepseek-key=*)
            DEEPSEEK_KEY="${arg#*=}"
            ;;
        --claude-key=*)
            CLAUDE_KEY="${arg#*=}"
            ;;
        --kimi-key=*)
            KIMI_KEY="${arg#*=}"
            ;;
        --qwen-key=*)
            QWEN_KEY="${arg#*=}"
            ;;
        --glm-key=*)
            GLM_KEY="${arg#*=}"
            ;;
    esac
done

# 确定 Shell 配置文件
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_RC="$HOME/.bash_profile"
    SHELL_NAME="bash"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
else
    print_error "找不到 shell 配置文件"
    exit 1
fi

WORK_DIR=$(mktemp -d)
CONFIG_URL="https://github.com/jodykwong/AIClient-2-API/raw/main/ccm-export.tar.gz"

# 清理函数
cleanup() {
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

print_header "CCM macOS 完整安装"

# 步骤 1: 下载配置包
print_step "第 1/8 步: 下载 CCM 配置包..."
if ! curl -fsSL "$CONFIG_URL" -o "$WORK_DIR/ccm-export.tar.gz"; then
    print_error "下载失败"
    exit 1
fi
print_success "配置包已下载"

# 步骤 2: 解压文件
print_step "第 2/8 步: 解压配置文件..."
mkdir -p "$WORK_DIR/extract"
if ! tar -xzf "$WORK_DIR/ccm-export.tar.gz" -C "$WORK_DIR/extract"; then
    print_error "解压失败"
    exit 1
fi

EXTRACT_DIR=$(ls -d "$WORK_DIR/extract"/*/ 2>/dev/null | head -1)
if [ -z "$EXTRACT_DIR" ]; then
    print_error "解压目录结构异常"
    exit 1
fi
print_success "文件已解压"

# 步骤 3: 验证必要文件
print_step "第 3/8 步: 验证文件..."
if [ ! -f "$EXTRACT_DIR/.local/share/ccm/ccm.sh" ]; then
    print_error "找不到 ccm.sh"
    exit 1
fi
print_success "文件验证通过"

# 步骤 4: 创建目录并复制文件
print_step "第 4/8 步: 安装 ccm 脚本..."
mkdir -p ~/.local/share/ccm
cp "$EXTRACT_DIR/.local/share/ccm/ccm.sh" ~/.local/share/ccm/
chmod +x ~/.local/share/ccm/ccm.sh

if [ -d "$EXTRACT_DIR/.local/share/ccm/lang" ]; then
    cp -r "$EXTRACT_DIR/.local/share/ccm/lang" ~/.local/share/ccm/
fi

print_success "ccm 脚本已安装到 ~/.local/share/ccm/"

# 步骤 5: 配置文件处理
print_step "第 5/8 步: 配置 API 密钥..."

# 复制原始配置
cp "$EXTRACT_DIR/.ccm_config" "$WORK_DIR/.ccm_config.tmp"

# 如果提供了密钥，进行替换
if [ -n "$DEEPSEEK_KEY" ]; then
    sed -i.bak "s|DEEPSEEK_API_KEY=.*|DEEPSEEK_API_KEY=$DEEPSEEK_KEY|" "$WORK_DIR/.ccm_config.tmp"
    print_info "已配置 Deepseek API Key"
fi

if [ -n "$CLAUDE_KEY" ]; then
    sed -i.bak "s|CLAUDE_API_KEY=.*|CLAUDE_API_KEY=$CLAUDE_KEY|" "$WORK_DIR/.ccm_config.tmp"
    print_info "已配置 Claude API Key"
fi

if [ -n "$KIMI_KEY" ]; then
    sed -i.bak "s|KIMI_API_KEY=.*|KIMI_API_KEY=$KIMI_KEY|" "$WORK_DIR/.ccm_config.tmp"
    print_info "已配置 KIMI API Key"
fi

if [ -n "$QWEN_KEY" ]; then
    sed -i.bak "s|QWEN_API_KEY=.*|QWEN_API_KEY=$QWEN_KEY|" "$WORK_DIR/.ccm_config.tmp"
    print_info "已配置 Qwen API Key"
fi

if [ -n "$GLM_KEY" ]; then
    sed -i.bak "s|GLM_API_KEY=.*|GLM_API_KEY=$GLM_KEY|" "$WORK_DIR/.ccm_config.tmp"
    print_info "已配置 GLM API Key"
fi

# 复制到家目录
if [ ! -f ~/.ccm_config ]; then
    cp "$WORK_DIR/.ccm_config.tmp" ~/.ccm_config
    print_success "配置文件已创建: ~/.ccm_config"
else
    print_warn "~/.ccm_config 已存在，已备份到 ~/.ccm_config.backup"
    cp ~/.ccm_config ~/.ccm_config.backup
fi

print_success "API 密钥配置完成"

# 步骤 6: 添加 shell 别名
print_step "第 6/8 步: 配置 shell 别名..."

ALIAS_LINE="alias ccm='~/.local/share/ccm/ccm.sh'"

if ! grep -q "alias ccm=" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# CCM - Claude Code Model Switcher" >> "$SHELL_RC"
    echo "$ALIAS_LINE" >> "$SHELL_RC"
    print_success "别名已添加到 $SHELL_RC"
else
    print_info "别名已存在于 $SHELL_RC"
fi

print_success "Shell 别名配置完成"

# 步骤 7: 源配置文件
print_step "第 7/8 步: 重新加载 shell 配置..."
source "$SHELL_RC"
print_success "shell 配置已重新加载"

# 步骤 8: 验证安装
print_step "第 8/8 步: 验证安装..."

if ! command -v ccm &> /dev/null; then
    print_error "ccm 命令不可用"
    print_warn "请手动执行: source $SHELL_RC"
    exit 1
fi

if [ ! -x ~/.local/share/ccm/ccm.sh ]; then
    print_error "ccm.sh 不是可执行文件"
    exit 1
fi

if [ ! -f ~/.ccm_config ]; then
    print_error "配置文件不存在"
    exit 1
fi

print_success "安装验证通过"

# 显示完成信息
print_header "安装完成! 🎉"

echo ""
echo -e "${GREEN}✓ CCM 已成功安装并配置${NC}"
echo ""

# 现在测试 ccm 命令
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}当前系统状态:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 运行 ccm status
if command -v ccm &> /dev/null; then
    echo ""
    echo -e "${BLUE}运行 ccm status:${NC}"
    ccm status || print_warn "ccm status 返回错误，请检查配置"
fi

echo ""
echo -e "${YELLOW}📝 常用命令:${NC}"
echo ""
echo -e "${CYAN}  # 查看帮助${NC}"
echo -e "  ${YELLOW}ccm help${NC}"
echo ""
echo -e "${CYAN}  # 切换到 Deepseek${NC}"
echo -e "  ${YELLOW}eval \"\$(ccm deepseek)\"${NC}"
echo ""
echo -e "${CYAN}  # 切换到 Claude Haiku${NC}"
echo -e "  ${YELLOW}eval \"\$(ccm haiku)\"${NC}"
echo ""
echo -e "${CYAN}  # 切换到 Claude Sonnet${NC}"
echo -e "  ${YELLOW}eval \"\$(ccm sonnet)\"${NC}"
echo ""
echo -e "${CYAN}  # 查看当前状态${NC}"
echo -e "  ${YELLOW}ccm status${NC}"
echo ""
echo -e "${CYAN}  # 编辑配置${NC}"
echo -e "  ${YELLOW}ccm config${NC}"
echo ""

# 如果有未设置的密钥，提醒用户
if [ -z "$DEEPSEEK_KEY" ] || [ -z "$CLAUDE_KEY" ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  需要配置的 API 密钥:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "编辑配置文件:"
    echo -e "  ${YELLOW}nano ~/.ccm_config${NC}"
    echo ""
    echo "需要填入的密钥:"
    echo "  • DEEPSEEK_API_KEY        - Deepseek API"
    echo "  • CLAUDE_API_KEY          - Claude 中转站 API"
    echo "  • KIMI_API_KEY            - KIMI API"
    echo "  • QWEN_API_KEY            - 阿里云 DashScope"
    echo "  • GLM_API_KEY             - 智谱清言"
    echo ""
fi

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}现在可以直接使用 ccm 命令了! 🚀${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
