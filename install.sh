#!/bin/bash
# install.sh - Instalador Completo para o Estudo no Bolso
# Versão 1.0.0
# Autor: Trae AI (baseado no prompt do usuário)

# Configurações de segurança
set -e
trap 'echo "Erro na linha $LINENO. Instalação interrompida."; exit 1' ERR

# Arquivo de Log
LOG_FILE="/var/log/estudonobolso-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Cores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funções Auxiliares
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCESSO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
log_error() { echo -e "${RED}[ERRO]${NC} $1"; }

show_banner() {
    clear
    echo -e "${BLUE}"
    echo "  ███████╗███████╗████████╗██╗   ██╗██████╗  ██████╗ "
    echo "  ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗██╔═══██╗"
    echo "  █████╗  ███████╗   ██║   ██║   ██║██║  ██║██║   ██║"
    echo "  ██╔══╝  ╚════██║   ██║   ██║   ██║██║  ██║██║   ██║"
    echo "  ███████╗███████║   ██║   ╚██████╔╝██████╔╝╚██████╔╝"
    echo "  ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═════╝  ╚═════╝ "
    echo "                                NO BOLSO             "
    echo -e "${NC}"
    echo "  Sistema de Instalação Automatizada v1.0"
    echo "  ======================================="
    echo ""
}

# 1.2 Validações Iniciais
check_requirements() {
    log_info "Verificando requisitos do sistema..."

    # Execução como root
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script precisa ser executado como root."
        exit 1
    fi

    # Sistema Operacional (Ubuntu 22.04+)
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]]; then
            log_warn "Sistema detectado: $NAME. Este script foi otimizado para Ubuntu."
        fi
        # Checagem de versão simplificada (apenas aviso)
    else
        log_warn "Não foi possível detectar a versão do SO."
    fi

    # Espaço em disco (5GB)
    FREE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$FREE_DISK" -lt 5 ]; then
        log_error "Espaço em disco insuficiente. Mínimo de 5GB necessário."
        exit 1
    fi

    # Memória RAM (2GB)
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_MEM" -lt 2000 ]; then
        log_warn "Memória RAM detectada: ${TOTAL_MEM}MB. Recomendado: 2048MB+."
    fi

    # Conexão Internet
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "Sem conexão com a internet."
        exit 1
    fi

    log_success "Requisitos verificados."
}

# 1.3 Coleta de Dados Interativa
collect_data() {
    echo ""
    log_info "Por favor, forneça as informações para instalação:"
    
    read -p "1. Domínio principal (ex: estudonobolso.com.br): " DOMAIN
    while [[ -z "$DOMAIN" ]]; do
        log_warn "Domínio não pode ser vazio."
        read -p "1. Domínio principal (ex: estudonobolso.com.br): " DOMAIN
    done

    read -p "2. Email do administrador: " ADMIN_EMAIL
    while [[ -z "$ADMIN_EMAIL" ]]; do
        log_warn "Email não pode ser vazio."
        read -p "2. Email do administrador: " ADMIN_EMAIL
    done

    read -p "3. Nome do banco de dados [estudonobolso]: " DB_NAME
    DB_NAME=${DB_NAME:-estudonobolso}

    read -p "4. Usuário do banco [enb_user]: " DB_USER
    DB_USER=${DB_USER:-enb_user}

    while true; do
        read -s -p "5. Senha do banco (min 8 chars, letras+números): " DB_PASS
        echo ""
        if [[ ${#DB_PASS} -ge 8 && "$DB_PASS" =~ [a-zA-Z] && "$DB_PASS" =~ [0-9] ]]; then
            read -s -p "Confirme a senha do banco: " DB_PASS_CONFIRM
            echo ""
            if [ "$DB_PASS" == "$DB_PASS_CONFIRM" ]; then
                break
            else
                log_warn "As senhas não conferem."
            fi
        else
            log_warn "Senha deve ter no mínimo 8 caracteres e conter letras e números."
        fi
    done

    read -s -p "6. Senha root do MySQL (se já definida, caso contrário deixe em branco): " MYSQL_ROOT_PASS
    echo ""

    read -p "7. Instalar SSL via Let's Encrypt? (s/n) [s]: " INSTALL_SSL
    INSTALL_SSL=${INSTALL_SSL:-s}

    read -p "8. Diretório de instalação [/var/www/$DOMAIN]: " INSTALL_DIR
    INSTALL_DIR=${INSTALL_DIR:-/var/www/$DOMAIN}

    read -p "9. Repositório GitHub [https://github.com/seu-usuario/estudonobolso.git]: " REPO_URL
    REPO_URL=${REPO_URL:-https://github.com/seu-usuario/estudonobolso.git}

    echo ""
    log_info "Resumo da Instalação:"
    echo "Domínio: $DOMAIN"
    echo "Diretório: $INSTALL_DIR"
    echo "Banco de Dados: $DB_NAME"
    echo "Usuário DB: $DB_USER"
    echo "SSL: $INSTALL_SSL"
    echo ""
    read -p "Confirmar instalação? (s/n): " CONFIRM
    if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
        log_info "Instalação cancelada pelo usuário."
        exit 0
    fi
}

# 1.4 Instalação de Dependências
install_dependencies() {
    log_info "Atualizando sistema e instalando dependências..."
    
    export DEBIAN_FRONTEND=noninteractive
    apt-get update && apt-get upgrade -y

    # Apache
    apt-get install apache2 -y
    systemctl enable apache2

    # MySQL
    apt-get install mysql-server -y
    systemctl enable mysql

    # PHP 8.2 e Extensões
    if ! command -v php8.2 &> /dev/null; then
        add-apt-repository ppa:ondrej/php -y
        apt-get update
    fi
    apt-get install php8.2 php8.2-cli php8.2-fpm php8.2-mysql \
        php8.2-curl php8.2-gd php8.2-mbstring php8.2-xml \
        php8.2-zip php8.2-intl php8.2-bcmath php8.2-opcache \
        libapache2-mod-php8.2 -y

    # Ferramentas
    apt-get install git curl wget unzip htop -y

    # Módulos Apache
    a2enmod rewrite headers ssl php8.2 deflate
    
    log_success "Dependências instaladas."
}

# 1.5 Clone do Repositório
setup_files() {
    log_info "Configurando arquivos do projeto..."

    if [ -d "$INSTALL_DIR" ]; then
        BACKUP_NAME="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        log_warn "Diretório já existe. Fazendo backup em $BACKUP_NAME"
        mv "$INSTALL_DIR" "$BACKUP_NAME"
    fi

    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR" || exit 1
}

# 1.6 Configuração do Banco de Dados
setup_database() {
    log_info "Configurando banco de dados..."

    # Configuração inicial do MySQL (segurança básica seria ideal, mas vamos focar na criação)
    
    SQL_CMDS="
    CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
    GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
    FLUSH PRIVILEGES;
    "

    if [ -n "$MYSQL_ROOT_PASS" ]; then
        mysql -u root -p"$MYSQL_ROOT_PASS" -e "$SQL_CMDS"
    else
        mysql -u root -e "$SQL_CMDS"
    fi

    # Migrations
    log_info "Aplicando migrations..."
    if [ -d "database/migrations" ]; then
        for migration in database/migrations/*.sql; do
            if [ -f "$migration" ]; then
                mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$migration"
                echo "✓ $(basename "$migration") aplicada"
            fi
        done
    else
        log_warn "Diretório database/migrations não encontrado."
    fi
    
    # Criar tabela de controle de migrations se não existir (para o update script funcionar depois)
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    CREATE TABLE IF NOT EXISTS migrations (
        id INT PRIMARY KEY AUTO_INCREMENT,
        migration VARCHAR(255) NOT NULL UNIQUE,
        applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    "
    # Registrar as migrations já aplicadas (opcional, mas bom para consistência)
    if [ -d "database/migrations" ]; then
        for migration in database/migrations/*.sql; do
            if [ -f "$migration" ]; then
                FILENAME=$(basename "$migration")
                mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "INSERT IGNORE INTO migrations (migration) VALUES ('$FILENAME');"
            fi
        done
    fi
}

# 1.7 Configuração de Arquivos
configure_project() {
    log_info "Ajustando configurações..."

    if [ -f config/config.example.php ]; then
        cp config/config.example.php config/config.php
        sed -i "s/DB_HOST', '.*'/DB_HOST', 'localhost'/g" config/config.php
        sed -i "s/DB_NAME', '.*'/DB_NAME', '$DB_NAME'/g" config/config.php
        sed -i "s/DB_USER', '.*'/DB_USER', '$DB_USER'/g" config/config.php
        sed -i "s/DB_PASS', '.*'/DB_PASS', '$DB_PASS'/g" config/config.php
        sed -i "s|BASE_URL', '.*'|BASE_URL', 'https://$DOMAIN'|g" config/config.php
    else
        log_warn "Arquivo config/config.example.php não encontrado."
    fi

    # .htaccess
    if [ ! -f .htaccess ]; then
        cat > .htaccess << 'EOF'
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php?page=$1 [QSA,L]
EOF
    fi

    # Diretórios
    mkdir -p uploads/{redacoes,perfis,temp}
    mkdir -p cache logs
}

# 1.8 Virtual Host Apache
setup_apache() {
    log_info "Configurando Apache..."

    VHOST_CONF="/etc/apache2/sites-available/$DOMAIN.conf"

    cat > "$VHOST_CONF" << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    ServerAdmin $ADMIN_EMAIL
    
    DocumentRoot $INSTALL_DIR
    
    <Directory $INSTALL_DIR>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    <Directory $INSTALL_DIR/uploads>
        Options -Indexes
        AllowOverride None
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN}_access.log combined
    
    # PHP Settings
    php_value upload_max_filesize 50M
    php_value post_max_size 50M
    php_value max_execution_time 300
    php_value memory_limit 256M
    php_value max_input_vars 3000
</VirtualHost>
EOF

    a2ensite "$DOMAIN.conf"
    systemctl reload apache2
}

# 1.9 SSL
setup_ssl() {
    if [[ "$INSTALL_SSL" == "s" || "$INSTALL_SSL" == "S" ]]; then
        log_info "Configurando SSL com Let's Encrypt..."
        apt-get install certbot python3-certbot-apache -y
        certbot --apache --non-interactive --agree-tos \
            --email "$ADMIN_EMAIL" \
            -d "$DOMAIN" -d "www.$DOMAIN" \
            --redirect
    fi
}

# 1.10 Permissões
setup_permissions() {
    log_info "Ajustando permissões..."
    chown -R www-data:www-data "$INSTALL_DIR"
    find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
    find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
    
    # Permissões específicas de escrita
    if [ -d "$INSTALL_DIR/uploads" ]; then chmod -R 775 "$INSTALL_DIR/uploads"; fi
    if [ -d "$INSTALL_DIR/cache" ]; then chmod -R 775 "$INSTALL_DIR/cache"; fi
    if [ -d "$INSTALL_DIR/logs" ]; then chmod -R 775 "$INSTALL_DIR/logs"; fi
}

# 1.11 Criar Usuário Admin
create_admin() {
    log_info "Criando usuário administrador..."
    
    ADMIN_PASS=$(openssl rand -base64 12)
    ADMIN_PASS_HASH=$(php -r "echo password_hash('$ADMIN_PASS', PASSWORD_DEFAULT);")
    
    # Assumindo que a tabela users já foi criada via migrations
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" << EOF
INSERT INTO users (nome, email, senha, role, ativo, created_at) 
VALUES ('Administrador', '$ADMIN_EMAIL', '$ADMIN_PASS_HASH', 'admin', 1, NOW());
EOF

    # Salvar credenciais
    cat > /root/estudonobolso-credentials.txt << EOF
ESTUDO NO BOLSO - CREDENCIAIS
=============================
URL: https://$DOMAIN
Email Admin: $ADMIN_EMAIL
Senha Admin: $ADMIN_PASS

Banco de Dados:
  Nome: $DB_NAME
  Usuário: $DB_USER
  Senha: $DB_PASS

Instalado em: $(date)
EOF
    chmod 600 /root/estudonobolso-credentials.txt
    
    log_success "Credenciais salvas em /root/estudonobolso-credentials.txt"
}

# 1.12 Otimizações PHP
optimize_php() {
    log_info "Aplicando otimizações PHP..."
    
    PHP_INI="/etc/php/8.2/apache2/php.ini"
    if [ -f "$PHP_INI" ]; then
        # Fazer backup
        cp "$PHP_INI" "${PHP_INI}.bak"
        
        # Ajustes simples usando sed (pode precisar de ajustes dependendo do formato do arquivo)
        sed -i 's/;opcache.enable=1/opcache.enable=1/' "$PHP_INI"
        sed -i 's/;opcache.memory_consumption=128/opcache.memory_consumption=128/' "$PHP_INI"
        sed -i 's/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=8/' "$PHP_INI"
        sed -i 's/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=10000/' "$PHP_INI"
        sed -i 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=60/' "$PHP_INI"
        # fast_shutdown foi removido no PHP 7.2+, ignorando
    fi
}

# 1.13 Finalização
finalize() {
    systemctl restart apache2
    
    echo ""
    log_success "Instalação Concluída com Sucesso!"
    echo "-----------------------------------------------------"
    echo "Acesse seu sistema em: https://$DOMAIN"
    echo "As credenciais de admin foram salvas em /root/estudonobolso-credentials.txt"
    echo "-----------------------------------------------------"
    
    # Exibir credenciais na tela uma vez
    echo "Senha do Admin Gerada: $ADMIN_PASS"
    echo "POR FAVOR, COPIE ESTA SENHA AGORA."
}

# Execução Principal
show_banner
check_requirements
collect_data
install_dependencies
setup_files
setup_database
configure_project
setup_apache
setup_ssl
setup_permissions
create_admin
optimize_php
finalize
