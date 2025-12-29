#!/bin/bash

################################################################################
# CCM Bash Function Setup
# 在 ~/.zshrc 或 ~/.bash_profile 中添加 ccm 函数
# 这样就可以直接使用 ccm kiro, ccm zhihui 等，不需要 eval
################################################################################

# 确定 shell 配置文件
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_RC="$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    echo "找不到 shell 配置文件"
    exit 1
fi

# CCM 函数定义
read -r -d '' CCM_FUNCTION << 'EOF' || true
# ============================================
# CCM Function - 直接切换模型，无需 eval
# 使用方式:
#   ccm kiro         # 切换到本地 KIRO 服务
#   ccm zhihui       # 切换到 ZhiHui API
#   ccm deepseek     # 切换到 Deepseek
#   ccm haiku        # 切换到 Claude Haiku
#   ccm status       # 查看当前状态
#   ccm help         # 查看帮助
# ============================================

ccm() {
    local cmd="${1:-help}"

    # 如果 ccm.sh 脚本存在，使用脚本
    if [ -x ~/.local/share/ccm/ccm.sh ]; then
        # 对于需要改变环境的命令，需要 eval
        case "$cmd" in
            deepseek|haiku|sonnet|opus|kiro|zhihui|zh|kimi|qwen|glm|claude)
                eval "$($HOME/.local/share/ccm/ccm.sh "$@")"
                ;;
            *)
                # 其他命令直接执行
                $HOME/.local/share/ccm/ccm.sh "$@"
                ;;
        esac
    else
        echo "❌ 错误: 找不到 ccm.sh 脚本"
        echo "请先执行: bash <(curl -fsSL https://raw.githubusercontent.com/jodykwong/AIClient-2-API/main/setup-ccm-complete.sh)"
        return 1
    fi
}
EOF

# 检查是否已经存在 ccm 函数
if grep -q "^ccm()" "$SHELL_RC" 2>/dev/null; then
    echo "✓ ccm 函数已存在于 $SHELL_RC"
    exit 0
fi

# 添加函数到 shell 配置
echo "" >> "$SHELL_RC"
echo "# CCM 函数定义 - 允许直接使用: ccm kiro, ccm zhihui 等" >> "$SHELL_RC"
echo "$CCM_FUNCTION" >> "$SHELL_RC"

echo "✓ ccm 函数已添加到 $SHELL_RC"
echo ""
echo "现在执行:"
echo "  source $SHELL_RC"
echo ""
echo "然后就可以直接使用:"
echo "  ccm kiro"
echo "  ccm zhihui"
echo "  ccm status"
