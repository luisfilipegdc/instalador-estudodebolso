# Guia de Instalação - Estudo no Bolso

Este documento descreve como instalar, atualizar e monitorar a plataforma **Estudo no Bolso** em um servidor Ubuntu 22.04 LTS.

## Requisitos do Sistema

- **Sistema Operacional:** Ubuntu 22.04 LTS (Recomendado)
- **Processador:** 1 vCPU (mínimo)
- **Memória RAM:** 2GB (mínimo)
- **Disco:** 5GB de espaço livre
- **Acesso:** Privilégios de root ou sudo
- **Rede:** Domínio apontado para o IP do servidor e portas 80/443 liberadas

## 🚀 Instalação Rápida

1. Baixe o script de instalação (ou clone este repositório):
   ```bash
   wget https://raw.githubusercontent.com/luisfilipegdc/instalador-estudodebolso/main/install.sh
   chmod +x install.sh
   ```

2. Execute o instalador como root:
   ```bash
   sudo ./install.sh
   ```

3. Siga as instruções interativas na tela. Você precisará informar:
   - Domínio do site (ex: `estudonobolso.com.br`)
   - Email do administrador
   - Credenciais desejadas para o Banco de Dados
   - **Repositório:** O script já vem configurado para o repositório oficial (`luisfilipegdc/estudodebolso`). Se for privado, tenha em mãos seu usuário do GitHub e um **Personal Access Token (PAT)**.

### O que o instalador faz?
- Instala Apache, MySQL, PHP 8.2 e extensões necessárias.
- Configura o Virtual Host do Apache.
- Clona o código-fonte do GitHub.
- Cria o banco de dados e usuário MySQL.
- Aplica as migrations iniciais.
- Configura SSL gratuito (Let's Encrypt).
- Gera um usuário administrador inicial.

Após a instalação, as credenciais de acesso serão salvas em `/root/estudonobolso-credentials.txt`.

---

## 🔄 Atualização Automática

Para atualizar o sistema (baixar código novo, aplicar migrations e limpar cache), utilize o script `update.sh`:

```bash
sudo ./update.sh
```

### Funcionalidades do Atualizador:
- **Backup Automático:** Cria backup do banco e arquivos em `/root/backups/estudonobolso` antes de qualquer alteração.
- **Modo Manutenção:** Exibe uma página amigável de manutenção para os usuários durante o processo.
- **Segurança:** Em caso de erro, realiza rollback automático para a versão anterior.

---

## 🩺 Diagnóstico e Monitoramento

Se encontrar problemas, execute o verificador de saúde:

```bash
sudo ./check.sh
```

Este script verifica:
- Status dos serviços (Apache, MySQL)
- Conectividade do site
- Permissões de arquivos
- Conexão com o Banco de Dados
- Logs de erro recentes

---

## Troubleshooting (Resolução de Problemas)

### Erro 500 (Internal Server Error)
Verifique os logs do Apache para detalhes:
```bash
tail -f /var/log/apache2/error.log
```
Geralmente causado por erros de sintaxe no PHP ou permissões incorretas no arquivo `.htaccess`.

### Erro de Conexão com Banco de Dados
Verifique se as credenciais em `config/config.php` estão corretas e se o serviço MySQL está rodando:
```bash
systemctl status mysql
```

### Falha no SSL (Let's Encrypt)
Certifique-se de que o domínio está apontando corretamente para o IP do servidor. O comando `ping seu-dominio.com` deve retornar o IP do seu servidor.

### Permissões
Se houver erro ao fazer upload de arquivos, corrija as permissões:
```bash
chown -R www-data:www-data /var/www/seu-dominio
chmod -R 775 /var/www/seu-dominio/uploads
```

---

**Suporte:** Entre em contato com o administrador do sistema ou abra uma issue no repositório GitHub.
