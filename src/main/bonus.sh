#!/bin/bash
# Bonus：start 时创建分离的 tmux 会话和采集器；stop 时正常停止采集器并结束会话。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-start}

source "$input/bonus.env"

if [ "$action" = "stop" ]; then
    if ! tmux -L "$TMUX_SOCKET" has-session -t "$SESSION" 2> /dev/null; then
        exit 0
    fi

    tmux -L "$TMUX_SOCKET" send-keys -t "$SESSION" C-c

    for attempt in {1..20}; do
        if ! tmux -L "$TMUX_SOCKET" has-session -t "$SESSION" 2> /dev/null; then
            break
        fi
        sleep 0.1
    done

    if tmux -L "$TMUX_SOCKET" has-session -t "$SESSION" 2> /dev/null; then
        tmux -L "$TMUX_SOCKET" kill-session -t "$SESSION"
    fi
    exit 0
fi

if tmux -L "$TMUX_SOCKET" has-session -t "$SESSION" 2> /dev/null; then
    exit 0
fi

worker_command="python3 \"$WORKER_TOOL\" --token \"$TOKEN\" --log \"$output/bonus.log\""
tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION" "$worker_command"
