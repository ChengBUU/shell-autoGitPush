#!/bin/bash

# ==================== GitHub自动上传脚本（Windows Git Bash 兼容版）
set -eo pipefail

# 基础配置
LOG_FILE="$HOME/auto_git_push.log"
CONFIG_FILE="./config.conf"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色


# ==================== 通用函数模块（日志+帮助文档）
# 日志函数
info() {
    echo -e "${GREEN}[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*${NC}" | tee -a $LOG_FILE
}
warn() {
    echo -e "${YELLOW}[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*${NC}" | tee -a $LOG_FILE
}
error() {
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*${NC}" | tee -a $LOG_FILE
    exit 1
}

# 帮助文档函数
show_help() {
    cat << EOF
用法：./auto_git_push.sh [选项]
选项：
  -m, --message  提交信息（必填建议）
  -b, --branch   推送分支（默认main）
  -h, --help     显示帮助文档
示例：
  ./auto_git_push.sh -m "feat: 完成自动上传脚本开发"
  ./auto_git_push.sh -m "fix: 修复路径问题" -b master
EOF
}


# ==================== 环境检查函数
env_check() {
    info "开始环境检查..."
    # 检查git是否安装
    if ! command -v git &> /dev/null; then
        error "未检测到git命令，请先安装Git并配置环境变量"
    fi
    # 检查当前目录是否为git仓库
    if [ ! -d ".git" ]; then
        error "当前目录不是Git仓库，请先执行 git init 初始化"
    fi
    # 检查是否配置远程仓库
    if ! git remote get-url origin &> /dev/null; then
        error "未配置origin远程仓库，请执行 git remote add origin 你的仓库SSH地址"
    fi
    # 检查SSH免密登录是否正常
    if ! ssh -T git@github.com &> /dev/null; then
        warn "GitHub SSH免密登录验证失败，可能会导致推送失败，请检查公钥配置"
    fi
    info "环境检查完成，全部通过"
}


# ==================== 参数解析与配置加载
# 初始化默认值
DEFAULT_BRANCH="main"
DEFAULT_COMMIT_MSG="auto: 自动提交更新"

# 加载配置文件
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        info "加载配置文件 $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        warn "未找到配置文件$CONFIG_FILE，将使用默认值"
    fi
}

# 解析命令行参数
# 优先级：命令行参数 > 配置文件 > 默认值
parse_args() {
    # 先给变量赋默认值/配置文件值
    BRANCH=${DEFAULT_BRANCH}
    COMMIT_MSG=${DEFAULT_COMMIT_MSG}

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message)
                COMMIT_MSG="$2"
                shift 2
                ;;
            -b|--branch)
                BRANCH="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "未知参数 $1，请使用 -h 查看帮助"
                ;;
        esac
    done
}


# ==================== 核心业务逻辑（自动上传全流程）
do_git_push() {
    info "==================== 开始自动上传流程 ===================="

    # 1. 拉取最新代码，避免冲突
    info "拉取远程仓库最新代码"
    git pull origin "$BRANCH" || error "git pull 失败，请解决冲突后重试"

    # 2. 添加所有变更文件
    info "添加变更文件到暂存区"
    git add . || error "git add 失败"

    # 敏感文件检查，git add后调用
    sensitive_file_check

    # 3. 提交代码
    info "提交代码，提交信息：$COMMIT_MSG"

    commit_msg_check "$COMMIT_MSG"
    git commit -m "$COMMIT_MSG" || {
        warn "没有检测到可提交的变更，流程结束"
        exit 0
    }

    # 4. 推送到远程仓库
    info "推送代码到远程分支 $BRANCH"
    git push origin "$BRANCH" || error "git push 失败"

    info "==================== 自动上传流程全部完成 ===================="
}


# ==================== 提交信息规范检查
commit_msg_check() {
    local msg="$1"
    if [[ ! "$msg" =~ ^(feat|fix|docs|style|refactor|test|chore|perf|build|ci): ]]; then
        warn "提交信息不符合Conventional Commits规范，建议格式：feat: 新增xxx功能 / fix: 修复xxxbug"
    fi
}


# ==================== 敏感文件检查
sensitive_file_check() {
    info "开始敏感文件检查"
    # 敏感文件黑名单
    local sensitive_list=("id_rsa" "id_dsa" "*.pem" "*.key" ".env" "*.secret" "password*" "token*")
    for pattern in "${sensitive_list[@]}"; do
        # 检查当前目录及一级子目录
        if find . -maxdepth 2 -name "$pattern" | grep -q .; then
            error "检测到敏感文件【$pattern】，为避免信息泄露，已终止上传"
        fi
    done
    info "敏感文件检查通过，无风险文件"
}


# ==================== 自动生成.gitignore文件
auto_gen_gitignore() {
    info "自动生成.gitignore文件"
    # 检查是否已有.gitignore
    if [ -f ".gitignore" ]; then
        warn ".gitignore文件已存在，跳过生成"
        return
    fi
    # 调用gitignore.io API，生成常用规则
    curl -sL https://www.toptal.com/developers/gitignore/api/shell,linux,windows > .gitignore
    if [ $? -eq 0 ]; then
        info ".gitignore文件生成成功"
    else
        warn ".gitignore文件生成失败，请手动创建"
    fi
}

main() {
    load_config
    parse_args "$@"
    env_check
    # 可选：取消下面注释，开启自动生成.gitignore
    # auto_gen_gitignore
    do_git_push
}


main "$@"