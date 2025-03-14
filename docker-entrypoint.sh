#!/bin/bash
set -e

# Aguardar o PostgreSQL iniciar
echo "Aguardando o PostgreSQL iniciar..."
for i in {1..60}; do
  if PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USERNAME" -d "$DB_DATABASE" -c '\q' 2>/dev/null; then
    echo "PostgreSQL iniciado com sucesso!"
    break
  fi
  echo "PostgreSQL indisponível - aguardando... ($i/60)"
  sleep 5
  
  # Se chegou à última tentativa, sair com erro
  if [ $i -eq 60 ]; then
    echo "Timeout aguardando o PostgreSQL iniciar. Verifique se o banco de dados está funcionando corretamente."
    exit 1
  fi
done

# Instalar dependências do Composer se necessário
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
  echo "Instalando dependências do Composer..."
  composer install --no-interaction --no-dev --optimize-autoloader
fi

# Configurar o .env
if [ -f ".env" ]; then
  echo "Atualizando configurações do .env..."
  sed -i "s/DB_HOST=.*/DB_HOST=$DB_HOST/" .env
  sed -i "s/DB_PORT=.*/DB_PORT=$DB_PORT/" .env
  sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" .env
  sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" .env
  sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env
  sed -i "s#APP_URL=.*#APP_URL=$APP_URL#" .env
fi

# Verificar se o banco de dados está acessível
echo "Verificando conexão com o banco de dados..."
if ! PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USERNAME" -d "$DB_DATABASE" -c "SELECT 1;" > /dev/null 2>&1; then
  echo "AVISO: Não foi possível conectar ao banco de dados. Verifique as configurações."
fi

# Limpar cache
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# Definir permissões corretas
chown -R www-data:www-data /var/www/html/pvt2
chmod -R 755 /var/www/html/pvt2/storage
chmod -R 755 /var/www/html/pvt2/bootstrap/cache

# Executar o comando passado para o contêiner
exec "$@" 