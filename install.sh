#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Estudo de Bolso - Instalador VPS ===${NC}"

# 1. Atualizar sistema
echo -e "${BLUE}Atualizando pacotes do sistema...${NC}"
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
GITHUB_TOKEN="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"
REPO_URL="https://${GITHUB_TOKEN}@github.com/luisfilipegdc/estudodebolso.git"
PROJECT_DIR="estudodebolso"

if [ -d "$PROJECT_DIR" ]; then
    echo -e "${GREEN}Pasta já existe. Atualizando...${NC}"
    cd $PROJECT_DIR
    git pull
else
    git clone $REPO_URL $PROJECT_DIR
    cd $PROJECT_DIR
fi

# 5. Configuração do .env
if [ ! -f ".env" ]; then
    echo -e "${BLUE}Configurando variáveis de ambiente (.env)...${NC}"
    cp .env.example .env 2>/dev/null || touch .env
    
    read -p "NEXTAUTH_SECRET (gere um aleatório): " NEXT_SECRET
    read -p "NEXTAUTH_URL (ex: http://seu-ip:3000): " NEXT_URL
    read -p "OPENAI_API_KEY: " OPENAI_KEY
    
    echo "DATABASE_URL=postgresql://postgres:postgres@db:5432/estudodebolso" >> .env
    echo "NEXTAUTH_SECRET=$NEXT_SECRET" >> .env
    echo "NEXTAUTH_URL=$NEXT_URL" >> .env
    echo "OPENAI_API_KEY=$OPENAI_KEY" >> .env
fi

# 6. Rodar o sistema
echo -e "${GREEN}Iniciando o sistema com Docker Compose...${NC}"
docker compose up -d --build

echo -e "${GREEN}=== Instalação Concluída! ===${NC}"
echo -e "Acesse seu sistema em: $NEXT_URL"
