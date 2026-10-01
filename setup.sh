#!/usr/bin/env bash
#
# ds-sandbox 0.2.0a1
#
# Готовит локальный стенд: генерирует config.json из шаблона и создаёт
# рабочее дерево ds-data/. Идемпотентно — можно запускать повторно.
#
# Расположение чекаутов ds / ds-loader / ds-webui по умолчанию — рядом с этим
# репозиторием. Переопределяется переменными окружения:
#   DS_DIR=... DS_LOADER_DIR=... DS_WEBUI_DIR=... ./setup.sh
#
set -euo pipefail

SANDBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT="$(dirname "$SANDBOX_ROOT")"
DS_DIR="${DS_DIR:-$PARENT/ds}"
DS_LOADER_DIR="${DS_LOADER_DIR:-$PARENT/ds-loader}"
DS_WEBUI_DIR="${DS_WEBUI_DIR:-$PARENT/ds-webui}"

echo "sandbox  : $SANDBOX_ROOT"
echo "ds       : $DS_DIR"
echo "ds-loader: $DS_LOADER_DIR"
echo "ds-webui : $DS_WEBUI_DIR"

[ -f "$DS_DIR/src/cli/commands.py" ] || {
  echo "!! не найден $DS_DIR/src/cli/commands.py — укажи DS_DIR=..." >&2; exit 1; }
[ -f "$DS_LOADER_DIR/src/cli/main.py" ] || {
  echo "!! не найден $DS_LOADER_DIR/src/cli/main.py — укажи DS_LOADER_DIR=..." >&2; exit 1; }
[ -d "$DS_WEBUI_DIR" ] || {
  echo "!! не найден каталог $DS_WEBUI_DIR — укажи DS_WEBUI_DIR=..." >&2; exit 1; }

# config.json из шаблона. Порядок замен важен: длинные префиксы (ds-sandbox,
# ds-webui) раньше короткого ds\b, иначе ds\b «съест» ds-webui на дефисе.
sed -e "s|/home/<username>/ds-sandbox|$SANDBOX_ROOT|g" \
    -e "s|/home/<username>/ds-webui|$DS_WEBUI_DIR|g" \
    -e "s|/home/<username>/ds\\b|$DS_DIR|g" \
    "$SANDBOX_ROOT/config.template.json" > "$SANDBOX_ROOT/config.json"
echo "-> config.json"

mkdir -p "$SANDBOX_ROOT/ds-data/.ds-loader" \
         "$DS_WEBUI_DIR/data"
echo "-> ds-data/.ds-loader, ds-webui/data"
echo "   (upload/archive/quarantine на источник создаёт сам ds-loader под sources/<name>/)"

echo
echo "Готово. Дальше:"
echo "  ./feed.sh CRM_2026-01-01_00-00-00_000000.json   # положить образец в инбокс"
echo "  ./run-local.sh --once                            # один проход"
echo "  ./run-local.sh                                   # бесконечный цикл (Ctrl-C — выход)"
