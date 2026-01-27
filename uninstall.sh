#!/bin/bash
# uninstall.sh - Desinstalador do Estudo no Bolso
# ATENÇÃO: ESTE SCRIPT REMOVE TUDO!

# Cores
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}!!! PERIGO !!!${NC}"
echo "Este script irá REMOVER COMPLETAMENTE o sistema Estudo no Bolso."
echo "Isso inclui:"
echo " - Diretório de instalação"
echo " - Banco de Dados"
echo " - Configurações do Apache"
echo ""
read -p "Tem certeza absoluta que deseja continuar? (digite 'DESTRUIR' para confirmar): " CONFIRM

if [ "$CONFIRM" != "DESTRUIR" ]; then
    echo "Operação cancelada."
    exit 0
fi

# Detectar diretório e banco
if [ -f config/config.php ]; then
    INSTALL_DIR=$(pwd)
    DB_NAME=$(grep "DB_NAME" config/config.php | cut -d "'" -f 4)
    DB_USER=$(grep "DB_USER" config/config.php | cut -d "'" -f 4)
    DOMAIN=$(grep "BASE_URL" config/config.php | cut -d "'" -f 4 | sed 's|https://||' | sed 's|http://||' | sed 's|/||g')
else
    read -p "Diretório de instalação: " INSTALL_DIR
    read -p "Nome do Banco de Dados: " DB_NAME
    read -p "Domínio (para remover config Apache): " DOMAIN
fi

echo "Removendo arquivos em $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"

echo "Removendo Banco de Dados $DB_NAME..."
mysql -u root -p -e "DROP DATABASE IF EXISTS $DB_NAME;"

echo "Removendo configuração do Apache..."
if [ -f "/etc/apache2/sites-available/$DOMAIN.conf" ]; then
    a2dissite "$DOMAIN.conf"
    rm "/etc/apache2/sites-available/$DOMAIN.conf"
    systemctl reload apache2
fi

echo -e "${YELLOW}Desinstalação concluída. Dependências (PHP, MySQL, Apache) foram mantidas.${NC}"
