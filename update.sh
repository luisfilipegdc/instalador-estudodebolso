#!/bin/bash
# update.sh - Sistema de Atualização Automática para o Estudo no Bolso
# Versão 1.0.0

set -e

# Configurações
LOG_FILE="/var/log/estudonobolso-update.log"
BACKUP_ROOT="/root/backups/estudonobolso"
exec > >(tee -a "$LOG_FILE") 2>&1

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCESSO]${NC} $1"; }
log_error() { echo -e "${RED}[ERRO]${NC} $1"; }

# 2.1 Detecção Automática
detect_installation() {
    log_info "Detectando instalação..."
    
    # Tenta encontrar em locais comuns se não estiver definido
    if [ -z "$INSTALL_DIR" ]; then
        # Procura por config.php em subdiretórios de /var/www
        FOUND_CONFIG=$(find /var/www -maxdepth 3 -name "config.php" | head -n 1)
        if [ -n "$FOUND_CONFIG" ]; then
            INSTALL_DIR=$(dirname $(dirname "$FOUND_CONFIG"))
            log_info "Instalação encontrada em: $INSTALL_DIR"
        else
            log_error "Não foi possível detectar a instalação automaticamente."
            read -p "Informe o diretório de instalação: " INSTALL_DIR
        fi
    fi

    if [ ! -d "$INSTALL_DIR/.git" ]; then
        log_error "$INSTALL_DIR não é um repositório Git válido."
        exit 1
    fi

    # Ler configurações do config.php para acesso ao banco
    CONFIG_FILE="$INSTALL_DIR/config/config.php"
    if [ -f "$CONFIG_FILE" ]; then
        DB_USER=$(grep "DB_USER" "$CONFIG_FILE" | cut -d "'" -f 4)
        DB_PASS=$(grep "DB_PASS" "$CONFIG_FILE" | cut -d "'" -f 4)
        DB_NAME=$(grep "DB_NAME" "$CONFIG_FILE" | cut -d "'" -f 4)
    else
        log_error "Arquivo de configuração não encontrado."
        exit 1
    fi
}

# 2.2 Backup Completo
perform_backup() {
    log_info "Iniciando backup..."
    mkdir -p "$BACKUP_ROOT"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    # Backup Banco
    mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_ROOT/db_$TIMESTAMP.sql"
    
    # Backup Arquivos
    tar -czf "$BACKUP_ROOT/files_$TIMESTAMP.tar.gz" \
        --exclude='.git' --exclude='cache/*' --exclude='logs/*' \
        -C "$(dirname "$INSTALL_DIR")" "$(basename "$INSTALL_DIR")"
        
    log_success "Backup realizado: db_$TIMESTAMP.sql e files_$TIMESTAMP.tar.gz"
}

# 2.3 Modo Manutenção
enable_maintenance() {
    log_info "Ativando modo manutenção..."
    cat > "$INSTALL_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>Estudo no Bolso - Manutenção</title>
    <style>
        body {
            font-family: 'Inter', Arial, sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            color: white;
        }
        .container { text-align: center; padding: 2rem; }
        h1 { font-size: 3em; margin: 0 0 1rem 0; }
        p { font-size: 1.2em; opacity: 0.9; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔧 Em Manutenção</h1>
        <p>Voltamos em alguns minutos!</p>
        <p><small>Estamos atualizando para melhor te servir.</small></p>
    </div>
</body>
</html>
EOF
}

# 2.4 Atualização Git
update_code() {
    log_info "Baixando atualizações do Git..."
    cd "$INSTALL_DIR"
    
    git fetch origin
    
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        log_info "Sistema já está atualizado."
        # Mesmo se estiver atualizado, pode ser útil rodar migrations/limpeza, 
        # mas vamos continuar o fluxo normal
    fi
    
    # Salvar config
    cp config/config.php /tmp/config.backup
    
    # Atualizar
    git pull origin main
    
    # Restaurar config (caso tenha sido sobrescrito, embora git pull tentaria merge)
    if [ -f /tmp/config.backup ]; then
        cp /tmp/config.backup config/config.php
    fi
}

# 2.5 Migrations Incrementais
run_migrations() {
    log_info "Verificando e aplicando migrations..."
    
    # Criar tabela de controle se não existir
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    CREATE TABLE IF NOT EXISTS migrations (
        id INT PRIMARY KEY AUTO_INCREMENT,
        migration VARCHAR(255) NOT NULL UNIQUE,
        applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );"
    
    if [ -d "database/migrations" ]; then
        for migration in database/migrations/*.sql; do
            if [ -f "$migration" ]; then
                FILENAME=$(basename "$migration")
                
                # Verificar se já foi aplicada
                APPLIED=$(mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "SELECT COUNT(*) FROM migrations WHERE migration='$FILENAME'")
                
                if [ "$APPLIED" = "0" ]; then
                    log_info "Aplicando migration: $FILENAME"
                    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$migration"
                    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "INSERT INTO migrations (migration) VALUES ('$FILENAME')"
                    echo "✓ $FILENAME aplicada"
                fi
            fi
        done
    fi
}

# 2.6 Limpeza e Reinicialização
cleanup() {
    log_info "Limpando cache e reiniciando serviços..."
    
    rm -rf "$INSTALL_DIR/cache/"*
    rm -rf "$INSTALL_DIR/logs/"*.log
    
    # Permissões novamente (garantir)
    chown -R www-data:www-data "$INSTALL_DIR"
    
    # Remover modo manutenção
    rm -f "$INSTALL_DIR/index.html"
    
    systemctl reload apache2
    log_success "Sistema atualizado com sucesso!"
}

# 2.7 Rollback em Caso de Erro
rollback() {
    log_error "Falha na atualização! Iniciando rollback..."
    
    cd "$INSTALL_DIR"
    # Reverter código
    git reset --hard "$LOCAL"
    
    # Restaurar banco
    if [ -f "$BACKUP_ROOT/db_$TIMESTAMP.sql" ]; then
        mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$BACKUP_ROOT/db_$TIMESTAMP.sql"
    fi
    
    # Restaurar config
    if [ -f /tmp/config.backup ]; then
        cp /tmp/config.backup config/config.php
    fi
    
    # Remover manutenção
    rm -f "$INSTALL_DIR/index.html"
    
    log_info "Rollback concluído. O sistema voltou ao estado anterior."
    exit 1
}

# Tratamento de Erros
trap 'rollback' ERR

# Execução
if [ "$EUID" -ne 0 ]; then
    log_error "Execute como root."
    exit 1
fi

detect_installation
perform_backup
enable_maintenance
update_code
run_migrations
cleanup
