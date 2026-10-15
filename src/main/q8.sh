#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

source "$input/process.env"

if [ "$action" = "cleanup" ]; then
    service_pid=$(cat "$output/service/pid")
    kill "$service_pid"

    for attempt in {1..20}; do
        if ! ps -p "$service_pid" -o stat= 2> /dev/null | grep -q -v Z; then
            break
        fi
        sleep 0.1
    done

    if ps -p "$service_pid" -o stat= 2> /dev/null | grep -q -v Z; then
        exit 1
    fi
    exit 0
fi

read -r actual_pid actual_user actual_state actual_command \
    <<< "$(ps -ww -p "$TARGET_PID" \
        -o pid= -o user:32= -o stat= -o args=)"

cat > "$output/process.txt" << EOF
pid=$actual_pid
user=$actual_user
state=$actual_state
command=$actual_command
EOF

tail -n 5 "$WORKER_LOG" > "$output/collector-sample.log"

kill "$TARGET_PID"
for attempt in {1..20}; do
    if ! ps -p "$TARGET_PID" -o stat= 2> /dev/null | grep -q -v Z; then
        break
    fi
    sleep 0.1
done

if ps -p "$TARGET_PID" -o stat= 2> /dev/null | grep -q -v Z; then
    exit 1
fi

kill "$SERVICE_PID"
for attempt in {1..20}; do
    if ! ps -p "$SERVICE_PID" -o stat= 2> /dev/null | grep -q -v Z; then
        break
    fi
    sleep 0.1
done

if ps -p "$SERVICE_PID" -o stat= 2> /dev/null | grep -q -v Z; then
    exit 1
fi

cat > "$output/server.conf" << EOF
bind=127.0.0.1
port=$TARGET_PORT
route=/status
EOF

bash "$START_TOOL" "$output/server.conf" "$output/service"

ready=no
for attempt in {1..30}; do
    if curl --silent --max-time 1 \
        --output "$output/http-body.txt" \
        --write-out "%{http_code}\n" \
        "http://127.0.0.1:$TARGET_PORT/status" \
        > "$output/http-status.txt"; then
        if grep -q "^200$" "$output/http-status.txt"; then
            ready=yes
            break
        fi
    fi
    sleep 0.1
done

if [ "$ready" != yes ]; then
    exit 1
fi
