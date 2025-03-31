# Sistema PVT - Projeto Vida no Trânsito

Este repositório contém a configuração Docker para executar o sistema PVT (Projeto Vida no Trânsito), uma aplicação Laravel com banco de dados PostgreSQL.

## Arquivos do Sistema

### Dockerfile
Este arquivo contém as instruções para construir a imagem Docker da aplicação. Ele:
- Utiliza PHP 7.4.33 com Apache como base
- Instala as dependências necessárias (PostgreSQL, GD, ZIP, etc.)
- Configura o Apache para servir a aplicação em `/pvt`
- Define limites de upload (50MB) e memória (512MB)
- Configura permissões para os diretórios da aplicação

### docker-compose.yml
Este arquivo define os serviços que compõem a aplicação:
- **app**: O serviço da aplicação Laravel/PHP
  - Construído a partir do Dockerfile
  - Expõe a porta 80
  - Conecta-se ao banco de dados
  - Monta o código-fonte da aplicação como volume
- **db**: O serviço de banco de dados PostgreSQL
  - Utiliza a imagem postgres:16
  - Expõe a porta 5432
  - Configura usuário, senha e nome do banco de dados
  - Monta o arquivo de backup e script de restauração

### docker-entrypoint.sh
Este script é executado quando o contêiner da aplicação é iniciado. Ele:
- Aguarda o PostgreSQL iniciar
- Instala as dependências do Composer
- Configura o arquivo .env com as variáveis de ambiente
- Verifica a conexão com o banco de dados
- Limpa o cache da aplicação
- Define permissões corretas para os diretórios

### restore-db.sh
Este script é responsável por restaurar o banco de dados a partir de um arquivo de backup. Ele:
- Verifica se o arquivo de backup existe
- Cria um banco de dados limpo
- Tenta restaurar o backup usando pg_restore
- Se falhar, extrai o arquivo e tenta restaurar usando psql
- Registra o progresso e resultado da restauração

## Requisitos

- Docker
- Docker Compose
- Git

## Como Fazer o Sistema Funcionar

### 1. Clone o repositório

```bash
git clone https://github.com/ricmed/pvt.git
cd <diretorio-do-repositorio>
```

### 2. Configuração do ambiente

Verifique se o arquivo `.env` existe no diretório `pvt2/`. Se não existir, crie-o a partir do arquivo `.env.example`:

```bash
cp pvt2/.env.example pvt2/.env
```

Edite o arquivo `.env` para configurar as variáveis de ambiente necessárias:

```bash
APP_URL=http://localhost/pvt
DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=pvt
DB_USERNAME=pvt_owner
DB_PASSWORD=OptiPlex3070
QUEUE_CONNECTION=database
```

### 3. Dar permissão de execução aos scripts

```bash
chmod +x docker-entrypoint.sh restore-db.sh
```

### 4. Construir e iniciar os contêineres

```bash
docker compose up -d --build
```

Este comando irá:
- Construir a imagem Docker da aplicação
- Iniciar os contêineres da aplicação e do banco de dados
- Restaurar o banco de dados a partir do arquivo de backup
- Configurar o ambiente da aplicação

### 5. Verificar o status dos contêineres

```bash
docker compose ps
```

Certifique-se de que ambos os contêineres `pvt_app` e `pvt_db` estão em execução.

## Acesso à Aplicação

Após a inicialização bem-sucedida, a aplicação estará disponível em:

```
http://localhost/pvt
```


## Solução de Problemas

### Problemas de conexão com o banco de dados

Se houver problemas de conexão com o banco de dados:

1. Verifique se o contêiner do banco de dados está em execução:
   ```bash
   docker compose ps
   ```

2. Verifique os logs do banco de dados:
   ```bash
   docker compose logs db
   ```

3. Verifique as configurações de conexão no arquivo `.env`

### Permissões de arquivos

Se houver problemas de permissão:

```bash
docker exec -it pvt_app chown -R www-data:www-data /var/www/html/pvt2
docker exec -it pvt_app chmod -R 755 /var/www/html/pvt2/storage
docker exec -it pvt_app chmod -R 755 /var/www/html/pvt2/bootstrap/cache
```

## Manutenção

### Backup do banco de dados

Para criar um backup do banco de dados:

```bash
docker exec -it pvt_db pg_dump -U pvt_owner -d pvt -F t > backup_$(date +%Y%m%d).tar
```

### Atualização da aplicação

Para atualizar a aplicação após alterações no código:

```bash
docker-compose down
docker-compose up -d --build
```
