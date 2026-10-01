#!/usr/bin/env bash
#
# Кладёт образец из samples/ в инбокс нужного источника
# (sources/<source>/upload/, source — всё до первого "_" в имени файла, как и
# в ds-loader/src/domain/naming.py). ds-loader создаёт upload/ сам при первом
# проходе, но feed.sh на это не полагается — создаёт сам, чтобы работать и
# до самого первого ./run-local.sh.
#
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
source_name="${name%%_*}"
src="$SANDBOX_ROOT/samples/$name"
dst_dir="$SANDBOX_ROOT/sources/$source_name/upload"
dst="$dst_dir/$name"

[ -f "$src" ] || { echo "!! нет образца $src" >&2; exit 1; }
[ -f "$SANDBOX_ROOT/sources/$source_name/source.json" ] || {
  echo "!! нет sources/$source_name/source.json — этот источник ingest не увидит" >&2; exit 1; }

mkdir -p "$dst_dir"
cp "$src" "$dst"
touch -d "1 minute ago" "$dst"
echo "-> sources/$source_name/upload/$name"
