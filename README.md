# ds-sandbox

Изолированный стенд для запуска [`ds`](https://github.com/A1eksMa/ds) +
[`ds-loader`](https://github.com/A1eksMa/ds-loader) в связке — чтобы разобраться,
как устроен поток «источник → загрузчик → ядро», не трогая рабочие данные.

Что даёт:

- готовый конфиг `ds-loader` (генерируется из шаблона под твои пути);
- рабочее дерево `ds-data/` (инбокс, архив, карантин, журнал, БД) — вне git;
- пример источника `CRM` и пара образцов выгрузок с корректными именами;
- обёртки для запуска (`setup.sh`, `run-local.sh`, `feed.sh`, `peek.sh`), которые
  снимают грабли с пакетом `src`.

## Требования

- Python **>= 3.9** (зависимостей нет, ставить ничего не нужно).
- Чекауты `ds` и `ds-loader`. По умолчанию ожидаются рядом с этим репозиторием:

  ```
  <родитель>/
  ├── ds/
  ├── ds-loader/
  └── ds-sandbox/   ← этот репозиторий
  ```

  Лежат иначе — укажи через переменные окружения (см. ниже).

## Быстрый старт

```bash
./setup.sh                                       # генерирует config.json, создаёт ds-data/
./feed.sh CRM_2026-01-01_00-00-00_000000.json    # кладёт образец в инбокс
./run-local.sh --once                            # один проход загрузчика
```

Ожидаемый вывод:

```
[ingest] ok changed=1
  CRM_2026-01-01_00-00-00_000000.json: loaded — loaded 6 transaction(s)
```

После этого файл — в `ds-data/archive/CRM/`, запись — в `ds-data/.ds-loader/ledger.jsonl`,
транзакции — в `ds-data/data.db`.

Бесконечный цикл (опрос каждые 5 c, лог в stderr, `Ctrl-C` — чистый выход):

```bash
./run-local.sh
```

Второй образец (`CRM_2026-02-01_...`) — более поздний по бизнес-времени: `customer_id=102`
уже был → перезапись, `104` — впервые. Тип операции `ds` выбирает сам.

## Посмотреть результат

`peek.sh` вызывает `ds get` — свёрнутое состояние источника на дату:

```bash
./peek.sh --src CRM
./peek.sh --src CRM --dt 1769000000   # состояние на конкретный момент
```

После двух образцов у `customer_id=102` будет обновлённый email, а `104` появится
как новая запись.

## Ветка в `ds-webui`

Автоматической подачи данных в [`ds-webui`](https://github.com/A1eksMa/ds-webui) в
`ds-loader` пока нет (стадия из roadmap). Вручную — тем же `ds get`:

```bash
./peek.sh --out ../ds-webui/data      # по <source>.json на источник
# затем открыть ../ds-webui/index.html в браузере
```

## Раскладка

| Путь | Что это | В git |
|---|---|---|
| `config.template.json` | шаблон конфига с плейсхолдером `<username>` | да |
| `config.json` | реальный конфиг, генерирует `setup.sh` | нет |
| `setup.sh` | генерация конфига + создание `ds-data/` | да |
| `run-local.sh` | запуск `ds-loader` против стенда | да |
| `feed.sh` | положить образец из `samples/` в инбокс | да |
| `peek.sh` | `ds get` — свёрнутое состояние источника | да |
| `sources/CRM/source.json` | пример конфига источника | да |
| `samples/*.json` | образцы выгрузок (имя `<src>_YYYY-MM-DD_HH-MM-SS_<µs>.json`) | да |
| `ds-data/upd/` | инбокс: сюда попадают файлы для загрузки | нет |
| `ds-data/archive/` | успешно загруженные (`archive/<src>/`) | нет |
| `ds-data/quarantine/` | ошибка `ds` или битая метка + `.err`-сайдкар | нет |
| `ds-data/.ds-loader/ledger.jsonl` | журнал обработанных (основа exactly-once) | нет |
| `ds-data/data.db` | БД `ds` | нет |

## Пути к `ds` / `ds-loader`

```bash
DS_DIR=/opt/ds DS_LOADER_DIR=/opt/ds-loader ./setup.sh
DS_LOADER_DIR=/opt/ds-loader ./run-local.sh
```

`setup.sh` вписывает `DS_DIR` в `config.json` как `ds_pythonpath` (нужно, потому что
дочерний процесс `ds` запускается как `python3 -m src.cli.commands`).

## Сброс

```bash
rm -rf ds-data config.json && ./setup.sh
```

## Про запуск из нейтральной директории

`ds` и `ds-loader` оба используют пакет верхнего уровня `src`. Если запустить загрузчик
из корня любого чекаута, дочерний `ds` подхватит не тот `src` и упадёт с
`No module named src.cli.commands`. Поэтому `run-local.sh` делает `cd ds-data/` (там
пакета `src` нет) и только оттуда зовёт `python3 -m src.cli.main`.

## Лицензия

MIT — см. [`LICENSE`](LICENSE).
