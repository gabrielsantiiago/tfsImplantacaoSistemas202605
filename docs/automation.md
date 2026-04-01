# Automação de Deploy

## Scripts Disponíveis

| Script | Descrição |
|--------|-----------|
| `build.sh [tag]` | Build das imagens Docker com tag opcional |
| `deploy.sh` | Deploy com zero-downtime + rollback automático |
| `rollback.sh <tag>` | Reverte para uma versão anterior |
| `backup.sh` | Backup do banco e configurações |
| `cleanup.sh` | Limpeza de recursos e dados antigos |
| `health-monitor.sh` | Monitor contínuo com relatórios horários |

## Fluxo de Deploy

```
build.sh → backup.sh → tag rollback → scale api=2 → health check → scale api=1
                                                          ↓ falha
                                                      rollback.sh
```

## Zero-Downtime

O `deploy.sh` escala a API para 2 réplicas antes de atualizar, garantindo que sempre haja uma instância saudável respondendo durante a transição.

## Variáveis de Ambiente

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `WEBHOOK_URL` | — | URL para notificações de alerta |
| `DB_CONTAINER` | `tf05-db-1` | Nome do container do banco |
| `RETENTION_DAYS` | `7` | Retenção de backups (dias) |
| `METRICS_RETENTION_DAYS` | `90` | Retenção de métricas no banco |
| `INTERVAL` | `30` | Intervalo do health-monitor (segundos) |
