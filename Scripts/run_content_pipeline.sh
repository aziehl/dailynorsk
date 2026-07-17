#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PYTHON="$ROOT/.content-pipeline-venv/bin/python"

if [ ! -x "$PYTHON" ]; then
  echo "Missing content environment. Run Scripts/bootstrap_content_pipeline.sh first." >&2
  exit 1
fi

"$PYTHON" "$ROOT/Scripts/build_candidates.py"
"$PYTHON" "$ROOT/Scripts/build_phrase_candidates.py"
"$PYTHON" "$ROOT/Scripts/validate_content.py"
