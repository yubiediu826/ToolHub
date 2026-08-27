"""
启动 ToolHub 应用

用法：
    python script-start.py            # 完整启动（编译翻译+资源，再跑主程序）
    python script-start.py fast      # 跳过翻译/资源编译，直接跑
    python script-start.py init      # 只初始化 venv（首次）
    python script-start.py clean     # 清掉编译产物（保留 venv）

设计：自检 venv → 不存在则自动 init（首次）
"""
import os
import subprocess
import sys
from pathlib import Path

import env

REPO_ROOT = Path(__file__).resolve().parent


def _venv_python():
    """venv 内 python 解释器路径（含 .exe 后缀 for Windows）"""
    py = env.python()
    if sys.platform.startswith("win") and not py.endswith(".exe"):
        py = py + ".exe"
    return py


def ensure_venv():
    """检查 venv 是否存在，不存在则自动 init"""
    if os.path.exists(_venv_python()):
        return

    print("[INFO] venv missing. Initializing...")
    print("       (first time may take 5-10 minutes to install dependencies)")
    print("       Run `py -3.11 script-init-venv.py` manually if this hangs.")
    print()

    init_script = REPO_ROOT / "script-init-venv.py"
    result = subprocess.run([sys.executable, str(init_script)], check=False)

    if result.returncode != 0 or not os.path.exists(_venv_python()):
        print("\n[FAIL] venv init failed (exit code: %d)" % result.returncode)
        print("       Try manually: py -3.11 %s" % init_script)
        sys.exit(1)

    print("\n[OK] venv init complete")


def clean_artifacts():
    """清理编译产物（不删 venv）"""
    import shutil

    targets = [
        REPO_ROOT / env.projectName / "imports/resource_rc.py",
    ]
    for cache in REPO_ROOT.rglob("__pycache__"):
        if cache.is_dir():
            targets.append(cache)

    for t in targets:
        if t.exists():
            try:
                if t.is_dir():
                    shutil.rmtree(t, ignore_errors=True)
                else:
                    t.unlink()
                print("  [CLEAN] %s" % t.relative_to(REPO_ROOT))
            except Exception as e:
                print("  [WARN] failed to clean %s: %s" % (t, e))

    print("[OK] clean complete")


def main():
    args = sys.argv[1:]

    if "init" in args:
        ensure_venv()
        return
    if "clean" in args:
        clean_artifacts()
        return

    is_fast = "fast" in args

    ensure_venv()

    if not is_fast:
        print("[1/3] Updating translations...")
        subprocess.run([_venv_python(), str(REPO_ROOT / "script-update-translations.py")], check=False)
        print("[2/3] Updating resources...")
        subprocess.run([_venv_python(), str(REPO_ROOT / "script-update-resource.py")], check=False)
    else:
        print("[FAST] Skipping translation/resource update")

    main_script = REPO_ROOT / env.projectName / "main.py"
    print("[3/3] Running %s..." % env.projectName)
    subprocess.run(
        [_venv_python(), str(main_script)],
        env=env.environment(),
        check=False,
    )


if __name__ == "__main__":
    main()
