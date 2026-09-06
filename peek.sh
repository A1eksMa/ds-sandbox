#!/usr/bin/env bash
#
# Свёрнутое состояние источника на дату (`ds get`). Аргументы пробрасываются как есть.
#
#   ./peek.sh                          # все источники, на текущий момент
#   ./peek.sh --src CRM
#   ./peek.sh --src CRM --dt 1769000000
#   ./peek.sh --src CRM --out ../ds-webui/data   # выгрузка для ds-webui
#
set -euo pipefail

SANDBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT="$(dirname "$SANDBOX_ROOT")"
DS_DIR="${DS_DIR:-$PARENT/ds}"

[ -f "$SANDBOX_ROOT/ds-data/data.db" ] || {
  echo "!! нет ds-data/data.db — сначала что-нибудь загрузи" >&2; exit 1; }

cd "$SANDBOX_ROOT/ds-data"
exec env PYTHONPATH="$DS_DIR" python3 -m src.cli.commands --db data.db get "$@"
