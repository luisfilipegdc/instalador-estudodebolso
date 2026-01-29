#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Nome da pasta do projeto (ajuste se necessário )
PROJECT_DIR="estudodebolso"

echo -e "${BLUE}=== Estudo de Bolso - Atualizador ===${NC}"

if [ ! -d "$PROJECT_DIR" ]; then
    # Se rodar de dentro da pasta do projeto
    if [ -f "docker-compose.yml" ]; then
        PROJECT_DIR="."
    else
        echo -e "${RED}Erro: Pasta do projeto não encontrada.${NC}"
        exit 1
    fi
fi

cd $PROJECT_DIR

echo -e "${BLUE}Puxando últimas alterações do Git...${NC}"
# Verifica se o remote já tem o token, se não, solicita
CURRENT_REMOTE=$(git remote get-url origin)
if [[ $CURRENT_REMOTE != *"ghp_"* ]]; then
    echo -n "Cole seu Personal Access Token do GitHub para atualizar: "
    read -r GITHUB_TOKEN < /dev/tty
    git remote set-url origin "https://${GITHUB_TOKEN}@github.com/luisfilipegdc/estudodebolso.git"
fi
git pull

echo -e "${BLUE}Reconstruindo e reiniciando containers...${NC}"
docker compose up -d --build

echo -e "${BLUE}Limpando imagens antigas...${NC}"
docker image prune -f

echo -e "${GREEN}=== Sistema Atualizado com Sucesso! ===${NC}"
