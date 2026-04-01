# Healthchecks

## Tipos de Verificação

### HTTP Check
Realiza uma requisição GET ao endpoint configurado e mede o tempo de resposta.
- Status `healthy`: HTTP < 400
- Status `unhealthy`: timeout, erro de conexão ou HTTP >= 400

### TCP Check
Abre uma conexão TCP ao host:porta configurado.
- Útil para Redis, serviços sem HTTP, etc.

### Database Check
Executa `SELECT 1` no PostgreSQL para validar conectividade e latência.

## Endpoints da API

| Endpoint | Descrição |
|----------|-----------|
| `GET /health` | Health da própria API |
| `GET /api/services` | Lista serviços e status atual |
| `GET /api/services/:id/history` | Histórico de checks de um serviço |
| `GET /api/stats` | Resumo geral (healthy/unhealthy/alertas) |
| `GET /api/metrics` | Métricas de sistema mais recentes |
| `GET /api/alerts` | Alertas ativos |
| `POST /api/alerts/:id/resolve` | Resolve um alerta |

## Thresholds

Configurados em `config/thresholds.yml`. Os valores padrão são:

| Métrica | Warning | Critical |
|---------|---------|----------|
| Response time | 1000ms | 2000ms |
| CPU | 70% | 90% |
| Memória | 75% | 90% |
| Disco | 80% | 95% |
| Taxa de erro | 5% | 10% |

## Intervalo de Checks

Os checks são executados a cada **30 segundos** pelo scheduler interno da API.
