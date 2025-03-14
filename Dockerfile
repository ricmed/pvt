#FROM php:7.4.33-apache
FROM php:7.2-apache

# Instalar dependências
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl \
    libxml2-dev \
    libonig-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensões PHP necessárias
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_pgsql \
    pgsql \
    zip \
    gd \
    bcmath \
    opcache \
    mbstring \
    xml \
    soap \
    exif

# Instalar Composer
COPY --from=composer:2.0 /usr/bin/composer /usr/bin/composer

# Configurar o Apache
RUN a2enmod rewrite
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Configurar o VirtualHost para servir a aplicação em /pvt
RUN echo '<VirtualHost *:80>\n\
    ServerAdmin webmaster@localhost\n\
    DocumentRoot /var/www/html\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
    Alias /pvt /var/www/html/pvt2/public\n\
    <Directory /var/www/html/pvt2/public>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Configurar PHP
RUN echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory-limit.ini \
    && echo "upload_max_filesize=50M" > /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "post_max_size=50M" >> /usr/local/etc/php/conf.d/upload-limit.ini

# Copiar o projeto para o diretório do Apache
COPY ./pvt2 /var/www/html/pvt2

# Definir permissões corretas
RUN chown -R www-data:www-data /var/www/html/pvt2 \
    && chmod -R 755 /var/www/html/pvt2/storage \
    && chmod -R 755 /var/www/html/pvt2/bootstrap/cache

# Definir diretório de trabalho
WORKDIR /var/www/html/pvt2

# Expor a porta 80
EXPOSE 80

# Script de inicialização
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
