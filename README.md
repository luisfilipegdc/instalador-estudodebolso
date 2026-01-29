# Estudo de Bolso - VPS Setup

Este repositório contém scripts automatizados para instalar e manter o sistema **Estudo de Bolso** em uma VPS Linux (Ubuntu/Debian).

## Como usar

1. Crie um novo repositório privado no GitHub chamado `estudodebolso-vps-setup`.
2. Suba estes arquivos para lá.
3. Na sua VPS, clone este repositório de setup:
   ```bash
   git clone https://github.com/seu-usuario/estudodebolso-vps-setup.git
   cd estudodebolso-vps-setup
   ```
4. Dê permissão de execução aos scripts:
   ```bash
   chmod +x install.sh update.sh
   ```

## Instalação

Para a primeira instalação, execute:
```bash
./install.sh
```
O script irá:
- Instalar Docker e Docker Compose.
- Clonar o repositório principal do sistema.
- Configurar as variáveis de ambiente.
- Iniciar os containers.

## Atualização

Sempre que houver novidades no repositório do sistema, execute:
```bash
./update.sh
```
O script irá:
- Fazer o `git pull`.
- Reconstruir as imagens Docker.
- Reiniciar o sistema sem perda de dados (o banco está em um volume persistente).
