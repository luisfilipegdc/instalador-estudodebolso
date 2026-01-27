# 🚀 Instalador Automático - Estudo no Bolso

Bem-vindo ao repositório de automação de infraestrutura do projeto **Estudo no Bolso**. Este conjunto de scripts foi desenvolvido para facilitar a instalação, atualização e manutenção da plataforma em servidores Ubuntu.

## 📋 Conteúdo do Repositório

Este pacote inclui ferramentas completas para gerenciamento do ciclo de vida da aplicação:

| Arquivo | Descrição |
|---------|-----------|
| [`install.sh`](install.sh) | **Instalador Principal:** Configura todo o ambiente (LAMP), banco de dados, SSL e implanta o projeto do zero. |
| [`update.sh`](update.sh) | **Atualizador Automático:** Realiza backup, baixa novas versões, aplica migrations e limpa caches com segurança. |
| [`check.sh`](check.sh) | **Diagnóstico:** Verifica a saúde do servidor, status dos serviços e conexões. |
| [`uninstall.sh`](uninstall.sh) | **Remoção:** Script utilitário para remover a instalação completamente (use com cuidado). |
| [`INSTALL.md`](INSTALL.md) | **Documentação Técnica:** Guia detalhado de requisitos e procedimentos manuais. |

## 💻 Instalação Rápida

Em um servidor **Ubuntu 22.04 LTS** limpo, execute:

```bash
# Baixar o instalador
wget https://raw.githubusercontent.com/luisfilipegdc/instalador-estudodebolso/main/install.sh

# Dar permissão de execução
chmod +x install.sh

# Executar como root
sudo ./install.sh
```

Siga as instruções interativas na tela para configurar seu domínio e banco de dados.

## ⚙️ Funcionalidades

- **Stack Completa:** Instalação automática do PHP 8.2, MySQL 8.0 e Apache 2.4.
- **Segurança:** Configuração automática de SSL (Let's Encrypt) e permissões de arquivo.
- **Backups:** O script de atualização realiza backups automáticos do banco e arquivos antes de qualquer mudança.
- **Rollback:** Em caso de falha na atualização, o sistema é revertido automaticamente para o estado anterior.
- **Manutenção:** Página de manutenção automática durante atualizações.

## 📖 Documentação

Para detalhes sobre requisitos de hardware, troubleshooting e configurações avançadas, consulte o guia completo em [INSTALL.md](INSTALL.md).

---
Desenvolvido para o projeto Estudo no Bolso.
