#!/usr/bin/env bash
#
# Кладёт образец из samples/ в инбокс загрузчика (ds-data/upd/).
# mtime сдвигается на минуту назад, чтобы файл сразу считался «стабильным»
# (см. stable_after_seconds в конфиге) — иначе первый проход его пропустит.
#
#   ./feed.sh CRM_2026-01-01_00-00-00_000000.json
#   ./feed.sh                       # список доступных образцов
#
set -euo pipefail

SANDBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -eq 0 ]; then
  echo "образцы в samples/:"
  ls -1 "$SANDBOX_ROOT/samples"
  exit 0
fi

name="$1"
src="$SANDBOX_ROOT/samples/$name"
dst="$SANDBOX_ROOT/ds-data/upd/$name"

[ -f "$src" ] || { echo "!! нет образца $src" >&2; exit 1; }
[ -d "$SANDBOX_ROOT/ds-data/upd" ] || { echo "!! нет ds-data/upd — запусти ./setup.sh" >&2; exit 1; }

cp "$src" "$dst"
touch -d "1 minute ago" "$dst"
echo "-> ds-data/upd/$name"
