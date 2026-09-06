#!/usr/bin/env bash
#
# Готовит локальный стенд: генерирует config.json из шаблона и создаёт
# рабочее дерево ds-data/. Идемпотентно — можно запускать повторно.
#
# Расположение чекаутов ds / ds-loader по умолчанию — рядом с этим репозиторием.
# Переопределяется переменными окружения:
#   DS_DIR=/path/to/ds  DS_LOADER_DIR=/path/to/ds-loader  ./setup.sh
#
set -euo pipefail

SANDBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT="$(dirname "$SANDBOX_ROOT")"
DS_DIR="${DS_DIR:-$PARENT/ds}"
DS_LOADER_DIR="${DS_LOADER_DIR:-$PARENT/ds-loader}"

echo "sandbox : $SANDBOX_ROOT"
echo "ds      : $DS_DIR"
echo "ds-loader: $DS_LOADER_DIR"

[ -f "$DS_DIR/src/cli/commands.py" ] || {
  echo "!! не найден $DS_DIR/src/cli/commands.py — укажи DS_DIR=..." >&2; exit 1; }
[ -f "$DS_LOADER_DIR/src/cli/main.py" ] || {
  echo "!! не найден $DS_LOADER_DIR/src/cli/main.py — укажи DS_LOADER_DIR=..." >&2; exit 1; }

# config.json из шаблона: сначала путь стенда (длиннее), потом путь ядра.
sed -e "s|/home/<username>/ds-sandbox|$SANDBOX_ROOT|g" \
    -e "s|/home/<username>/ds\\b|$DS_DIR|g" \
    "$SANDBOX_ROOT/config.template.json" > "$SANDBOX_ROOT/config.json"
echo "-> config.json"

mkdir -p "$SANDBOX_ROOT/ds-data/upd" \
         "$SANDBOX_ROOT/ds-data/archive" \
         "$SANDBOX_ROOT/ds-data/quarantine" \
         "$SANDBOX_ROOT/ds-data/.ds-loader"
echo "-> ds-data/{upd,archive,quarantine,.ds-loader}"

echo
echo "Готово. Дальше:"
echo "  ./feed.sh CRM_2026-01-01_00-00-00_000000.json   # положить образец в инбокс"
echo "  ./run-local.sh --once                            # один проход"
echo "  ./run-local.sh                                   # бесконечный цикл (Ctrl-C — выход)"
