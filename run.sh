#!/bin/bash
# 启动 ToolHub —— bash/zsh
set -e
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$SCRIPT_DIR"

# 优先用环境变量 PYTHON，否则用 python3
if [ -n "$PYTHON" ]; then
    PYTHON_CMD="$PYTHON"
else
    PYTHON_CMD=python3
fi
exec "$PYTHON_CMD" script-start.py "$@"
