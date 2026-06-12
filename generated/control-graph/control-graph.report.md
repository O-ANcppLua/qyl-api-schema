# Telemetry Control Graph v1

- Schema version: 1
- Services: 2
- Signals: 4
- Attributes: 8
- Export edges: 2

## Services

### qyl.collector

- Profile: qyl-default
- Declared signals: 3
- Export edges: 1

| Signal | Attributes | Exporters |
| --- | ---: | --- |
| log:qyl.collector.ingest | 1 | collector-primary |
| metric:http.server.request.duration | 2 | collector-primary |
| span:http.server.request | 3 | collector-primary |

### qyl.dashboard

- Profile: qyl-default
- Declared signals: 1
- Export edges: 1

| Signal | Attributes | Exporters |
| --- | ---: | --- |
| span:http.client.request | 2 | collector-primary |
