#!/bin/bash
set -e

echo "Iniciando script de restauração do banco de dados..."

# Verificar se o arquivo de backup existe
if [ ! -f "/docker-entrypoint-initdb.d/backup.tar" ]; then
    echo "Arquivo de backup não encontrado!"
    exit 1
fi

echo "Arquivo de backup encontrado, criando banco de dados limpo..."

# Criar um banco de dados limpo
psql -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"
psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;"

echo "Tentando restaurar o backup diretamente..."

# Tentar restaurar o backup diretamente
if pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v "/docker-entrypoint-initdb.d/backup.tar"; then
    echo "Backup restaurado com sucesso usando pg_restore!"
else
    echo "Falha ao restaurar usando pg_restore, tentando método alternativo..."
    
    # Criar diretório temporário para extração
    mkdir -p /tmp/backup
    
    # Extrair o arquivo TAR
    tar -xf /docker-entrypoint-initdb.d/backup.tar -C /tmp/backup
    
    echo "Arquivo extraído, procurando por arquivos SQL..."
    
    # Procurar por arquivos SQL no diretório extraído
    BACKUP_FILES=$(find /tmp/backup -type f -name "*.sql" | sort)
    
    if [ -n "$BACKUP_FILES" ]; then
        for BACKUP_FILE in $BACKUP_FILES; do
            echo "Tentando restaurar o arquivo: $BACKUP_FILE"
            if psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$BACKUP_FILE"; then
                echo "Backup restaurado com sucesso usando psql!"
                break
            fi
        done
    else
        echo "Nenhum arquivo SQL encontrado após a extração."
        echo "Falha na restauração do banco de dados."
    fi
    
    # Limpar arquivos temporários
    rm -rf /tmp/backup
fi

echo "Restauração do banco de dados concluída com sucesso!" 