#!/bin/bash
# Q5：运行 launch.env 给定的启动前检查，保存 stdout/stderr、真实退出码和诊断报告。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

source "$input/launch.env"

if bash "$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" \
    > "$output/stdout.log" 2> "$output/stderr.log"; then
    exit_code=0
else
    exit_code=$?
fi

if [ "$exit_code" -eq 0 ]; then
    result=SUCCESS
    reason=NONE
elif [ "$exit_code" -eq 10 ]; then
    result=FAILED
    reason=MODEL_MISSING
else
    result=FAILED
    reason=CAMERA_DENIED
fi

echo "$exit_code" > "$output/exit-code.txt"

cat > "$output/report.txt" << EOF
result=$result
exit_code=$exit_code
reason=$reason
EOF
