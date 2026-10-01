# ds-sandbox

Изолированный стенд для запуска [`ds`](https://github.com/A1eksMa/ds) +
[`ds-loader`](https://github.com/A1eksMa/ds-loader) +
[`ds-webui`](https://github.com/A1eksMa/ds-webui) в связке — чтобы разобраться,
как устроен поток «источник → загрузчик → ядро → вьюшка», не трогая рабочие данные.

Что даёт:

- готовый конфиг `ds-loader` со стадиями `ingest` + `publish` (генерируется из шаблона);
- рабочее дерево на источник — `sources/<name>/{upload,archive,quarantine}/` — и общее
  `ds-data/` (журнал, БД, отпечатки публикации) — всё вне git;
- публикацию в `../ds-webui/data/` (`<Source>.js` + `manifest.js`) — вьюшка подхватывает;
- пример источника `CRM` (с `labels[]`, помеченными `publish: true`) и пара образцов
  выгрузок с корректными именами;
- обёртки для запуска (`setup.sh`, `run-local.sh`, `feed.sh`, `peek.sh`), которые
  снимают грабли с пакетом `src`.

## Требования

- Python **>= 3.9** (зависимостей нет, ставить ничего не нужно).
- Чекауты `ds`, `ds-loader`, `ds-webui`. По умолчанию ожидаются рядом с этим репозиторием:

  ```
  <родитель>/
  ├── ds/
  ├── ds-loader/
  ├── ds-webui/
  └── ds-sandbox/   ← этот репозиторий
  ```

  Лежат иначе — укажи через переменные окружения (см. ниже).

## Быстрый старт

```bash
./setup.sh                                       # генерирует config.json, создаёт ds-data/
./feed.sh CRM_2026-01-01_00-00-00_000000.json    # кладёт образец в sources/CRM/upload/
./run-local.sh --once                            # один проход загрузчика
```

Ожидаемый вывод:

```
[ingest] ok changed=1
  CRM_2026-01-01_00-00-00_000000.json: loaded — uploaded 6 transaction(s)
[publish] ok changed=1
  CRM: пересобран
```

После этого файл — в `sources/CRM/archive/`, запись — в `ds-data/.ds-loader/ledger.jsonl`,
транзакции — в `ds-data/data.db`, а выгрузка для вьюшки — в `../ds-webui/data/CRM.js` +
`../ds-webui/data/manifest.js`.

Бесконечный цикл (опрос каждые 5 c, лог в stderr, `Ctrl-C` — чистый выход):

```bash
./run-local.sh
```

Второй образец (`CRM_2026-02-01_...`) — более поздний по бизнес-времени: `customer_id=102`
уже был → перезапись, `104` — впервые. Тип операции `ds` выбирает сам.

`ingest` вызывает `ds upload`, а не `ds load` — строгая загрузка, отказывает целиком, если
в файле нашёлся показатель, не объявленный в `source.json`. Поэтому `sources/CRM/source.json`
заранее объявляет `email`/`phone` в `labels[]`; добавляя новый показатель в образцы — сначала
допиши его туда же (и отметь `"publish": true`, если он должен быть виден в `ds-webui`, см.
ниже).

## Посмотреть результат в терминале

`peek.sh` вызывает `ds get` — свёрнутое состояние источника на дату:

```bash
./peek.sh --src CRM
./peek.sh --src CRM --dt 1769000000   # состояние на конкретный момент
```

После двух образцов у `customer_id=102` будет обновлённый email, а `104` появится
как новая запись.

## Вьюшка `ds-webui`

Стадия `publish` (включена в шаблоне конфига) на каждом проходе кладёт в
`../ds-webui/data/` файлы `<Source>.js` + `manifest.js`. Открой `../ds-webui/index.html`
в браузере — страница предпочитает `data/` закоммиченному `sample-data/`.

Публикуется только то, что в `source.json` источника помечено `"publish": true` (ключевая
колонка — всегда); остальное `ds-webui` не увидит. В примере CRM оба показателя (`email`,
`phone`) уже так помечены — выключи `publish` у одного из них в `sources/CRM/source.json` и
пересобери (`./run-local.sh --once --force-publish`), чтобы увидеть эффект фильтра на себе.

Публикация идемпотентна: без новых данных `run-local.sh --once` печатает
`[publish] ok` / `без изменений` и файлы не переписывает. Принудительно пересобрать выгрузку
без изменения БД — `./run-local.sh --once --force-publish`.

## Раскладка

| Путь | Что это | В git |
|---|---|---|
| `config.template.json` | шаблон конфига с плейсхолдером `<username>` | да |
| `config.json` | реальный конфиг, генерирует `setup.sh` | нет |
| `setup.sh` | генерация конфига + создание `ds-data/.ds-loader/` и `../ds-webui/data/` | да |
| `run-local.sh` | запуск `ds-loader` против стенда | да |
| `feed.sh` | положить образец из `samples/` в инбокс нужного источника | да |
| `peek.sh` | `ds get` — свёрнутое состояние источника | да |
| `../ds-webui/data/*.js` | вывод стадии `publish` (в git `ds-webui` — нет) | нет |
| `sources/CRM/source.json` | конфиг источника (`labels[]` с `publish: true` — иначе `ds upload` отклонит файл целиком, см. ниже) | да |
| `samples/*.json` | образцы выгрузок (имя `<src>_YYYY-MM-DD_HH-MM-SS_<µs>.json`) | да |
| `sources/CRM/upload/` | инбокс источника: сюда `feed.sh` кладёт файлы, `ingest` создаёт сам, если нет | нет |
| `sources/CRM/archive/` | успешно загруженные | нет |
| `sources/CRM/quarantine/` | ошибка `ds` или битая метка + `.err`-сайдкар | нет |
| `ds-data/.ds-loader/ledger.jsonl` | журнал обработанных (основа exactly-once, общий на все источники) | нет |
| `ds-data/.ds-loader/publish.json` | отпечатки опубликованного (идемпотентность `publish`) | нет |
| `ds-data/data.db` | БД `ds` | нет |

## Пути к `ds` / `ds-loader` / `ds-webui`

```bash
DS_DIR=/opt/ds DS_LOADER_DIR=/opt/ds-loader DS_WEBUI_DIR=/opt/ds-webui ./setup.sh
DS_LOADER_DIR=/opt/ds-loader ./run-local.sh
```

`setup.sh` вписывает `DS_DIR` в `config.json` как `ds_pythonpath` (нужно, потому что
дочерний процесс `ds` запускается как `python3 -m src.cli.commands`), а `DS_WEBUI_DIR/data`
— как `webui_data_dir` для стадии `publish`.

## Сброс

```bash
rm -rf ds-data config.json sources/*/upload sources/*/archive sources/*/quarantine && ./setup.sh
```

## Про запуск из нейтральной директории

`ds` и `ds-loader` оба используют пакет верхнего уровня `src`. Если запустить загрузчик
из корня любого чекаута, дочерний `ds` подхватит не тот `src` и упадёт с
`No module named src.cli.commands`. Поэтому `run-local.sh` делает `cd ds-data/` (там
пакета `src` нет) и только оттуда зовёт `python3 -m src.cli.main`.

## Лицензия

MIT — см. [`LICENSE`](LICENSE).
