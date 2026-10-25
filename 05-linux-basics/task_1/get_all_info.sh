#!/bin/bash

# Проверка, запущен ли скрипт от root
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: скрипт должен быть запущен от имени root." >&2
  exit 1
fi

echo "Текущая директория: $(pwd)"

INFO_FILE="info"
ARCHIVE_NAME="OS_RESULT.tar"

echo "=== Сбор системной информации ===" > "$INFO_FILE"


# 1. Установленные пакеты
echo -e "\n--- Установленные пакеты (20шт) ---" >> "$INFO_FILE"
pacman -Q | head -n 20 >> "$INFO_FILE"

# 2. Запущенные процессы
echo -e "\n--- Запущенные процессы (первые 10 процессов) ---" >> "$INFO_FILE"
ps aux | head -n 10 >> "$INFO_FILE"

# 3. Открытые порты
echo -e "\n--- Открытые порты (20шт) ---" >> "$INFO_FILE"
ss -tuln | head -n 20 >> "$INFO_FILE"

# 4. Установка пакетов
echo "[*] Установка пакетов cowsay и sl..."
pacman -S --noconfirm cowsay sl

# 5. Версия ядра и ОС
echo -e "\n--- Версия ОС и Ядра ---" >> "$INFO_FILE"
uname -a >> "$INFO_FILE"
if [ -f /etc/os-release ]; then
    cat /etc/os-release >> "$INFO_FILE"
fi

# 6. Архивация файла info 
echo "[*] Упаковка результатов в архив $ARCHIVE_NAME..."
tar -cvf "$ARCHIVE_NAME" "$INFO_FILE"

echo "  --Скрипт успешно выполнен, все данные в файлы info-- "
