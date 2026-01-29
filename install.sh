#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Estudo de Bolso - Instalador VPS ===${NC}"

# 1. Atualizar sistema
echo -e "${BLUE}Atualizando pacotes do sistema...${NC}"
RED='\033[0;31m'
sudo apt-get update && sudo apt-get upgrade -y

# 2. Instalar Docker se não existir
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}Instalando Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# 3. Instalar Docker Compose se não existir
if ! command -v docker-compose &> /dev/null; then
    echo -e "${BLUE}Instalando Docker Compose...${NC}"
    sudo apt-get install -y docker-compose-plugin
    # Criar alias se necessário
    sudo ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose 2>/dev/null
fi

# 4. Configuração do Repositório do Sistema
echo -e "${BLUE}Configurando repositório do sistema...${NC}"
# Limpa token se estiver vazio ou inválido
GITHUB_TOKEN=""
while [[ ! $GITHUB_TOKEN =~ ^ghp_ ]]; do
    read -p "Cole seu Personal Access Token do GitHub (ghp_...): " GITHUB_TOKEN
    if [[ ! $GITHUB_TOKEN =~ ^ghp_ ]]; then
        echo -e "${RED}Token inválido! O token deve começar com 'ghp_'.${NC}"
    fi
done

REPO_URL="https://x-token-auth:${GITHUB_TOKEN}@github.com/luisfilipegdc/estudodebolso.git"
PROJECT_DIR="estudodebolso"

if [ -d "$PROJECT_DIR" ]; then
    echo -e "${GREEN}Pasta já existe. Atualizando...${NC}"
    cd $PROJECT_DIR
    git remote set-url origin $REPO_URL
    git pull
else
    git clone $REPO_URL $PROJECT_DIR
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao clonar repositório. Verifique seu token e permissões.${NC}"
        exit 1
    fi
    cd $PROJECT_DIR
fi

# 5. Configuração do .env
if [ ! -f ".env" ]; then
    echo -e "${BLUE}Configurando variáveis de ambiente (.env)...${NC}"
    cp .env.example .env 2>/dev/null || touch .env
    
    read -p "NEXTAUTH_SECRET (gere um aleatório): " NEXT_SECRET
    read -p "OPENAI_API_KEY: " OPENAI_KEY
    
    echo "DATABASE_URL=postgresql://postgres:postgres@db:5432/estudodebolso" >> .env
    echo "NEXTAUTH_SECRET=$NEXT_SECRET" >> .env
    echo "NEXTAUTH_URL=https://estudodebolso.com.br" >> .env
    echo "OPENAI_API_KEY=$OPENAI_KEY" >> .env
fi

# 6. SSL Automático (Certbot)
echo -e "${BLUE}Configurando SSL para estudodebolso.com.br...${NC}"
docker compose up -d nginx
docker compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot -d estudodebolso.com.br --email seu-email@gmail.com --agree-tos --no-eff-email
docker compose restart nginx

# 7. Rodar o sistema
echo -e "${GREEN}Iniciando o sistema completo...${NC}"
docker compose up -d --build

echo -e "${GREEN}=== Instalação Concluída! ===${NC}"
echo -e "Acesse seu sistema em: $NEXT_URL"
