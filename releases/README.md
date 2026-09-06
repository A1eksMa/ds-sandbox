# Changelog

Архивы в этой папке — рабочая версия стенда (без `.git`), готовая к распаковке. Имя архива
содержит номер версии: `ds-sandbox-<version>.tar.gz`. Он же — в шапке `setup.sh`.

Для машины без git: скачать один архив вместо файлов по отдельности.

## Распаковка

```bash
mkdir -p /path/to/target/folder
tar -xzf ds-sandbox-<version>.tar.gz -C /path/to/target/folder
```

Внутри: `setup.sh`, `run-local.sh`, `feed.sh`, `peek.sh`, `config.template.json`,
`sources/`, `samples/`, `LICENSE`, `README.md`.

## Запуск

Рядом должны лежать чекауты (или архивы) `ds`, `ds-loader`, `ds-webui` — по умолчанию
как соседние каталоги, иначе через `DS_DIR=` / `DS_LOADER_DIR=` / `DS_WEBUI_DIR=`.

```bash
./setup.sh                                       # генерирует config.json, создаёт ds-data/
./feed.sh CRM_2026-01-01_00-00-00_000000.json    # кладёт образец в инбокс
./run-local.sh --once                            # проход: ingest + publish
```

Подробно — `README.md`.

---

## 0.1.0a1 — `ds-sandbox-0.1.0a1.tar.gz`

Первая версия стенда для связки `ds` + `ds-loader` + `ds-webui`.

- `setup.sh` — генерация `config.json` из `config.template.json` (плейсхолдер `<username>`),
  создание рабочего дерева `ds-data/` и `../ds-webui/data/`.
- `run-local.sh` — запуск `ds-loader run` из нейтральной директории (обход конфликта
  пакета `src` между чекаутами `ds` и `ds-loader`).
- `feed.sh` — положить образец из `samples/` в инбокс (mtime задним числом).
- `peek.sh` — `ds get` для разовых выборок в терминал.
- Конфиг со стадиями `["ingest", "publish"]`: проход пишет БД `ds` и раскладывает
  `../ds-webui/data/<Source>.js` + `manifest.js`.
- Пример источника `CRM` + два образца выгрузок с корректными именами.
