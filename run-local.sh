#!/usr/bin/env bash
#
# Запуск ds-loader против стенда.
#
# Рабочая директория — ds-data/ (в ней нет пакета `src`). Это принципиально:
# и ds, и ds-loader используют пакет верхнего уровня `src`, поэтому запуск из
# корня любого из чекаутов заставил бы дочерний процесс `ds` подхватить чужой
# `src` и упасть с `No module named src.cli.commands`.
#
# Расположение чекаута ds-loader: рядом с этим репозиторием, либо DS_LOADER_DIR=...
#
set -euo pipefail

SANDBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT="$(dirname "$SANDBOX_ROOT")"
DS_LOADER_DIR="${DS_LOADER_DIR:-$PARENT/ds-loader}"

[ -f "$SANDBOX_ROOT/config.json" ] || {
  echo "!! нет config.json — запусти ./setup.sh" >&2; exit 1; }

cd "$SANDBOX_ROOT/ds-data"
exec env PYTHONPATH="$DS_LOADER_DIR" \
  python3 -m src.cli.main run --config "$SANDBOX_ROOT/config.json" "$@"
