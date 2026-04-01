# Manutenção

## Backup

```bash
./scripts/backup.sh
```

Gera em `./backups/<timestamp>/`:
- `db.sql.gz` — dump completo do PostgreSQL
- `config.tar.gz` — arquivos de configuração

Backups com mais de 7 dias são removidos automaticamente (configurável via `RETENTION_DAYS`).

## Restore

```bash
# Descompactar e restaurar o banco
gunzip -c ./backups/<timestamp>/db.sql.gz | \
  docker exec -i tf05-db-1 psql -U monitor monitoring
```

## Limpeza

```bash
./scripts/cleanup.sh
```

- Remove containers parados e imagens dangling
- Purga métricas e health_checks com mais de 90 dias
- Executa `VACUUM ANALYZE` no PostgreSQL

## Monitor Contínuo

```bash
./scripts/health-monitor.sh
```

- Verifica a API a cada 30s
- Envia webhook se houver serviços unhealthy
- Gera relatório JSON a cada hora em `./reports/`

## Rotação de Logs Docker

Adicione ao `/etc/docker/daemon.json` para limitar logs:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```
