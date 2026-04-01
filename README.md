# TF05 - Sistema de Monitoramento e Automação

## Aluno
- **Nome:** Gabriel Santiago de Andrade
- **RA:** 6324647
- **Curso:** Análise e Desenvolvimento de Sistemas

## Funcionalidades
- Healthchecks inteligentes (HTTP, TCP, Database)
- Dashboard de monitoramento em tempo real
- Sistema de alertas (email, webhook)
- Automação completa de deploy
- Rollback automático
- Scripts de manutenção
- Backup automatizado

## Arquitetura

```
dashboard (nginx:80 → :3000)
    └── api (flask:5000)
            ├── db (postgres:5432)
            └── redis (redis:6379)
```

## Como Executar

### Pré-requisitos
- Docker e Docker Compose
- Bash (para scripts de automação)

### Execução Completa
```bash
git clone <URL_DO_SEU_REPO>
cd TF05

# Build automatizado
./scripts/build.sh

# Deploy automatizado
./scripts/deploy.sh

# Acessar dashboard
open http://localhost:3000
```

### Execução Rápida (desenvolvimento)
```bash
docker compose up --build
```

## Endpoints da API

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/health` | Status da API |
| GET | `/api/stats` | Resumo geral |
| GET | `/api/services` | Lista de serviços |
| GET | `/api/services/:id/history` | Histórico de checks |
| GET | `/api/metrics` | Métricas de sistema |
| GET | `/api/alerts` | Alertas ativos |
| POST | `/api/alerts/:id/resolve` | Resolver alerta |

## Scripts de Automação

| Script | Descrição |
|--------|-----------|
| `scripts/build.sh` | Build das imagens Docker |
| `scripts/deploy.sh` | Deploy zero-downtime com rollback automático |
| `scripts/rollback.sh <tag>` | Rollback para versão anterior |
| `scripts/backup.sh` | Backup do banco e configurações |
| `scripts/cleanup.sh` | Limpeza de recursos e dados antigos |
| `scripts/health-monitor.sh` | Monitor contínuo com alertas e relatórios |

## Configuração de Alertas

Defina a variável `WEBHOOK_URL` para receber notificações:

```bash
export WEBHOOK_URL=https://hooks.slack.com/services/...
docker compose up -d
```

## Documentação
- [Automação](docs/automation.md)
- [Healthchecks](docs/healthchecks.md)
- [Manutenção](docs/maintenance.md)
