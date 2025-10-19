# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# >>> fishros initialize >>>
source /opt/ros/humble/setup.bash
# <<< fishros initialize <<<

mkcd () {
mkdir -p -- "$1"
cd -P -- "$1"
}

export ROS_ROOT="/opt/ros/humble"
. "$HOME/.cargo/env"

# ========== ROS2 工作空间管理 ==========
ROS_WS_FILE="$HOME/.ros_workspaces"

# 列举工作空间并跳转
rosws() {
    if [ ! -f "$ROS_WS_FILE" ]; then
        echo "工作空间文件不存在，请先用 rosws-add 添加工作空间"
        return 1
    fi

    if [ ! -s "$ROS_WS_FILE" ]; then
        echo "没有保存的工作空间，请用 rosws-add 添加"
        return 1
    fi

    echo "========== ROS2 工作空间 =========="
    local index=1
    while IFS= read -r ws; do
        if [ -d "$ws" ]; then
            echo "[$index] $ws"
            ((index++))
        fi
    done < "$ROS_WS_FILE"
    echo "===================================="

    if [ $index -eq 1 ]; then
        echo "没有有效的工作空间"
        return 1
    fi

    echo -n "选择工作空间编号 (回车取消): "
    read choice

    if [ -z "$choice" ]; then
        echo "已取消"
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "错误：请输入数字"
        return 1
    fi

    local current=1
    while IFS= read -r ws; do
        if [ -d "$ws" ]; then
            if [ $current -eq $choice ]; then
                cd "$ws" || return 1
                if [ -f "install/setup.bash" ]; then
                    source install/setup.bash
                    echo "✓ 已切换到: $ws"
                    echo "✓ 已 source: install/setup.bash"
                else
                    echo "✓ 已切换到: $ws"
                    echo "⚠ 警告：未找到 install/setup.bash"
                fi
                return 0
            fi
            ((current++))
        fi
    done < "$ROS_WS_FILE"

    echo "错误：无效的选择"
    return 1
}
# 为当前 ROS2 工作空间生成 .clangd 配置
rosws-clangd() {
    local ws_path="$(pwd)"
    local clangd_file="$ws_path/.clangd"

    # 检查是否在 ROS2 工作空间中
    if [ ! -d "src" ]; then
        echo "⚠ 警告：当前目录不像是 ROS2 工作空间（没有 src 目录）"
        echo -n "仍然创建 .clangd 配置？(y/N): "
        read confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "已取消"
            return 1
        fi
    fi

    # 查找所有 install 下的 include 目录
    local include_dirs=""
    if [ -d "install" ]; then
        while IFS= read -r dir; do
            local rel_path="${dir#$ws_path/}"
            include_dirs="$include_dirs    - \"-I\$\{workspaceFolder\}/$rel_path\"\n"
        done < <(find install -type d -name include 2>/dev/null)
    fi

    # 生成 .clangd 配置
    cat > "$clangd_file" << 'EOF'
CompileFlags:
  Add:
    - "-I/opt/ros/humble/include"
    - "-I${workspaceFolder}/install/include"
    - "-I${workspaceFolder}/src"
    - "-std=c++17"
  CompilationDatabase: build

Index:
  Background: Build

Diagnostics:
  UnusedIncludes: None
  MissingIncludes: None
EOF

    # 如果有特定的 install 子目录，追加更详细的配置
    if [ -n "$include_dirs" ]; then
        echo "" >> "$clangd_file"
        echo "# 自动检测到的 include 路径：" >> "$clangd_file"
        local install_paths=$(find install -type d -name include 2>/dev/null | sed 's|^|#   - |')
        if [ -n "$install_paths" ]; then
            echo "$install_paths" >> "$clangd_file"
        fi
    fi

    echo "✓ 已创建 .clangd 配置: $clangd_file"
    echo ""
    echo "建议操作："
    echo "  1. 重启 Cursor/VSCode"
    echo "  2. 或在 Cursor 中按 Ctrl+Shift+P，输入 'clangd: Restart'"
    echo ""
    echo "如需编译命令数据库，运行："
    echo "  colcon build --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
}

rosws-add() {
    local current_path="$(pwd)"

    if [ ! -f "$ROS_WS_FILE" ]; then
        touch "$ROS_WS_FILE"
    fi

    # 检查是否已存在
    if grep -Fxq "$current_path" "$ROS_WS_FILE" 2>/dev/null; then
        echo "⚠ 当前路径已在工作空间列表中: $current_path"
        return 0
    fi

    echo "$current_path" >> "$ROS_WS_FILE"
    echo "✓ 已添加工作空间: $current_path"

    # 询问是否生成 .clangd 配置
    if [ ! -f ".clangd" ]; then
        echo -n "是否为此工作空间生成 .clangd 配置？(Y/n): "
        read response
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            rosws-clangd
        fi
    else
        echo "ℹ .clangd 配置已存在"
    fi
}

# 删除工作空间
rosws-rm() {
    if [ ! -f "$ROS_WS_FILE" ] || [ ! -s "$ROS_WS_FILE" ]; then
        echo "没有保存的工作空间"
        return 1
    fi

    echo "========== ROS2 工作空间 =========="
    local index=1
    while IFS= read -r ws; do
        echo "[$index] $ws"
        ((index++))
    done < "$ROS_WS_FILE"
    echo "===================================="

    echo -n "选择要删除的工作空间编号 (回车取消): "
    read choice

    if [ -z "$choice" ]; then
        echo "已取消"
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "错误：请输入数字"
        return 1
    fi

    # 使用临时文件删除指定行
    local temp_file=$(mktemp)
    local current=1
    local deleted_ws=""

    while IFS= read -r ws; do
        if [ $current -ne $choice ]; then
            echo "$ws" >> "$temp_file"
        else
            deleted_ws="$ws"
        fi
        ((current++))
    done < "$ROS_WS_FILE"

    if [ -n "$deleted_ws" ]; then
        mv "$temp_file" "$ROS_WS_FILE"
        echo "✓ 已删除工作空间: $deleted_ws"
    else
        rm "$temp_file"
        echo "错误：无效的选择"
        return 1
    fi
}

# 快速创建函数（添加到 .bashrc）
rosws-colcon-config() {
    mkdir -p .colcon
    cat > .colcon/defaults.yaml << 'EOF'
build:
  cmake-args:
    - "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
EOF
    echo "✓ 已创建 .colcon/defaults.yaml"
    echo "现在 colcon build 会自动生成 compile_commands.json"
}

# 添加自动补全（可选）
alias rosws-list='cat $ROS_WS_FILE 2>/dev/null || echo "没有保存的工作空间"'
