#!/bin/bash

# Encerra o script se houver erro
set -e

echo "=== 1. Instalando o Rclone ==="
sudo apt update && sudo apt install -y curl unzip
curl https://rclone.org/install.sh | sudo bash

echo ""
echo "=== 2. Configurando o Google Drive ==="
echo "Execute o comando abaixo no terminal para criar o acesso ao Google Drive:"
echo "----------------------------------------------------"
echo "rclone config"
echo "----------------------------------------------------"
echo "Siga os passos:"
echo " - Digite 'n' para Nova Remote"
echo " - Nome da remote: gdrive"
echo " - Escolha o número correspondente a 'Google Drive'"
echo " - Deixe 'client_id' e 'client_secret' em branco (pressione Enter)"
echo " - Escolha o acesso total (opção 1)"
echo " - Avance até abrir o navegador para autorizar a conta"
echo ""

# Criar o script de backup automatizado
BACKUP_SCRIPT="$HOME/executar_backup.sh"

echo "=== 3. Criando o script de execução do backup ==="
cat << 'EOF' > "$BACKUP_SCRIPT"
#!/bin/bash

# Diretores e arquivos
PASTA_ORIGEM="$HOME/n8n-stack"
NOME_PASTA=$(basename "$PASTA_ORIGEM")
DATA_HOJE=$(date +%Y-%m-%d)

PASTA_TMP=/tmp/backups
NOME_ARQUIVO="backup_${NOME_PASTA}_${DATA_HOJE}.tar.gz
CAMINHO_COMPACTADO="${PASTA_TMP}/${NOME_ARQUIVO}"

DRIVE_REMOTE="gdrive:backup_oracle" # Nome do remote no rclone + pasta no Drive
LOG_FILE="$HOME/rclone_backup.log"

echo "[$(date)] Iniciando backup..." >> "$LOG_FILE"

mkdir -p "$PASTA_TMP"

echo "[$(date)] Iniciando backup do n8n..." >> "$LOG_FILE"

docker exec -t postgres_n8n pg_dump -U n8n -Fc n8n > ${PASTA_ORIGEM}/backup_postgres.sql

tar -czf "$CAMINHO_COMPACTADO" -C "$(dirname "PASTA_ORIGEM")" --exclude="postgres_data" "NOME_PASTA" >> "$LOG_FILE" 2>&1

rclone copy "$CAMINHO_COMPACTADO" "$DRIVE_REMOTE" --log-file="$LOG_FILE" --log-level INFO

rm -f "$CAMINHO_COMPACTADO"

echo "[$(date)] Backup do n8n concluído com sucesso!" >> "$LOG_FILE"
EOF

chmod +x "$BACKUP_SCRIPT"

echo "Script de execução criado em: $BACKUP_SCRIPT"
echo ""

echo "=== 4. Configurando o agendamento no Cron (03:30 AM) ==="
# Adiciona a tarefa ao crontab do usuário sem duplicar
(crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT"; echo "30 3 * * * $BACKUP_SCRIPT") | crontab -

echo "Agendamento concluído com sucesso!"
echo "Para verificar os agendamentos, use: crontab -l"
