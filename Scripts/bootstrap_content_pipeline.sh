#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VENV="$ROOT/.content-pipeline-venv"

git -C "$ROOT" submodule update --init --recursive
python3 -m venv "$VENV"
"$VENV/bin/python" -m pip install --disable-pip-version-check --upgrade pip
"$VENV/bin/python" -m pip install --disable-pip-version-check -e "$ROOT/References/wordfreq"
"$VENV/bin/python" -m pip freeze > "$ROOT/ContentPipeline/Generated/python-environment.txt"

echo "Content pipeline environment is ready at $VENV"
