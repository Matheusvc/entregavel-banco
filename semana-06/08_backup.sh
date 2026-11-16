#!/usr/bin/env bash
# =============================================================================
# OXYGENI HUB  |  Sprint 6 - Backup lógico do PostgreSQL
# Arquivo: 08_backup.sh
# Objetivo: automatizar o backup lógico do banco com pg_dump no formato
#           customizado (-Fc), gerando nome com data, tratando erros e
#           aplicando retenção de 30 dias (apaga backups mais antigos).
#
# Uso:
#   ./08_backup.sh
# Variáveis de ambiente (opcionais, com defaults):
#   DB_NAME, DB_USER, DB_HOST, DB_PORT, BACKUP_DIR, RETENTION_DAYS, PG_BIN
# =============================================================================

# Falha cedo e com segurança:
#   -e  aborta em qualquer comando que falhe
#   -u  erro ao usar variável não definida
#   -o pipefail  propaga falha em pipelines
set -euo pipefail

# ----------------------------- Configuração ---------------------------------
DB_NAME="${DB_NAME:-oxygeni_hub}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
# PG_BIN permite apontar a pasta do pg_dump (ex.: no Windows). Vazio = usa o PATH.
PG_BIN="${PG_BIN:-}"
PG_DUMP="${PG_BIN:+$PG_BIN/}pg_dump"

# Nome do arquivo com data/hora -> nunca sobrescreve um backup anterior.
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump"

# Log simples com carimbo de tempo.
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ----------------------------- Tratamento de erro ---------------------------
# Em qualquer erro, remove o arquivo pela metade e avisa com código != 0.
trap 'log "ERRO na linha $LINENO. Abortando."; [ -f "$BACKUP_FILE" ] && rm -f "$BACKUP_FILE"; exit 1' ERR

# ----------------------------- Execução -------------------------------------
mkdir -p "$BACKUP_DIR"
log "Iniciando backup de '${DB_NAME}' em ${DB_HOST}:${DB_PORT}..."

# -Fc  = formato customizado: compactado e restaurável de forma seletiva com pg_restore.
# A senha deve vir de ~/.pgpass ou da variável PGPASSWORD (não fica no script).
"$PG_DUMP" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -Fc -f "$BACKUP_FILE" "$DB_NAME"

# Se chegou aqui, o dump terminou com sucesso.
BACKUP_SIZE="$(du -h "$BACKUP_FILE" | cut -f1)"
log "OK: backup criado -> ${BACKUP_FILE} (${BACKUP_SIZE})"

# ----------------------------- Retenção (30 dias) ---------------------------
# Remove backups deste banco com mais de RETENTION_DAYS dias.
log "Aplicando retenção de ${RETENTION_DAYS} dias..."
REMOVIDOS=0
while IFS= read -r -d '' antigo; do
    rm -f "$antigo"
    log "  removido (antigo): $antigo"
    REMOVIDOS=$((REMOVIDOS + 1))
done < <(find "$BACKUP_DIR" -name "${DB_NAME}_*.dump" -type f -mtime +"$RETENTION_DAYS" -print0)

log "Retenção concluída (${REMOVIDOS} arquivo(s) antigo(s) removido(s))."
log "Backup finalizado com sucesso."
exit 0
