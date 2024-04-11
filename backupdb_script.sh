#!/bin/bash

MYSQL='mysql --skip-column-names'
BACKUP_DIR="/var/lib/mysql/backups/" 						# Указываем директорию для сохранения бекапов
BINLOG_POSITION_FILE="$BACKUP_DIR/binlog_position.txt" 		# Устанавливаем имя файла для хранения текущей позиции бинлога

mysql -e "STOP REPLICA;"
echo "SHOW REPLICA STATUS;" | $MYSQL > $BINLOG_POSITION_FILE	# Сохраняем текущую позицию бинлога в файл
for s in $($MYSQL -sN -e "SHOW DATABASES LIKE '%\_db'");		# Обрабатываем каждую базу данных
do
    db_backup_dir="$BACKUP_DIR/$s"							# Создаем поддиректорию для каждой базы данных
    mkdir -p "$db_backup_dir"
    $MYSQL $s -e "SHOW TABLES" | while read -r table;		# Переключаемся на базу данных
    do
															# Выполняем mysqldump для каждой таблицы с добавлением опций
        /usr/bin/mysqldump --master-data=2 --add-drop-table --add-locks --create-options --disable-keys --extended-insert --single-transaction --quick --set-charset --events --routines --triggers $s $table | gzip -1 > "$db_backup_dir/$table.sql.gz";
    done
done
mysql -e "START REPLICA;"
echo "Backup process completed."
