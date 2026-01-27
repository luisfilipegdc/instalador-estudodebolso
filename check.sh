#!/bin/bash
# check.sh - Verificador de Saúde do Sistema Estudo no Bolso
# Versão 1.0.0

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Diagnóstico do Sistema Estudo no Bolso ===${NC}"
echo "Data: $(date)"
echo ""

# 1. Verificar Apache
echo -n "Apache Web Server: "
if systemctl is-active --quiet apache2; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${RED}[PARADO]${NC}"
fi

# 2. Verificar MySQL
echo -n "MySQL Database: "
if systemctl is-active --quiet mysql; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${RED}[PARADO]${NC}"
fi

# 3. Verificar Site (HTTP Response)
echo -n "Resposta HTTP (localhost): "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "301" ] || [ "$HTTP_CODE" == "302" ]; then
    echo -e "${GREEN}[OK] (Código $HTTP_CODE)${NC}"
else
    echo -e "${RED}[ERRO] (Código $HTTP_CODE)${NC}"
fi

# 4. Verificar Espaço em Disco
echo -n "Espaço em Disco (/): "
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
DISK_PERCENT=$(echo $DISK_USAGE | sed 's/%//')
if [ "$DISK_PERCENT" -lt 80 ]; then
    echo -e "${GREEN}[OK] ($DISK_USAGE usado)${NC}"
else
    echo -e "${YELLOW}[ALERTA] ($DISK_USAGE usado)${NC}"
fi

# 5. Tentar detectar instalação e verificar permissões
INSTALL_DIR=$(find /var/www -maxdepth 3 -name "config.php" -exec dirname {} \; | head -n 1)
INSTALL_DIR=$(dirname "$INSTALL_DIR")

if [ -n "$INSTALL_DIR" ]; then
    echo -n "Diretório de Instalação: "
    echo -e "${BLUE}$INSTALL_DIR${NC}"
    
    echo -n "Permissões de Escrita (uploads): "
    if [ -w "$INSTALL_DIR/uploads" ]; then
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${RED}[ERRO] Sem permissão de escrita${NC}"
    fi
    
    # 6. Conexão com Banco
    if [ -f "$INSTALL_DIR/config/config.php" ]; then
        DB_USER=$(grep "DB_USER" "$INSTALL_DIR/config/config.php" | cut -d "'" -f 4)
        DB_PASS=$(grep "DB_PASS" "$INSTALL_DIR/config/config.php" | cut -d "'" -f 4)
        DB_NAME=$(grep "DB_NAME" "$INSTALL_DIR/config/config.php" | cut -d "'" -f 4)
        
        echo -n "Conexão MySQL: "
        if mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT 1" &> /dev/null; then
            echo -e "${GREEN}[OK]${NC}"
        else
            echo -e "${RED}[FALHA]${NC}"
        fi
    fi
else
    echo -e "${YELLOW}[AVISO] Instalação não encontrada automaticamente.${NC}"
fi

# 7. Últimos erros do Apache
echo ""
echo -e "${BLUE}--- Últimos 5 erros do Apache ---${NC}"
tail -n 5 /var/log/apache2/error.log 2>/dev/null || echo "Log não acessível."

echo ""
echo "Diagnóstico concluído."
