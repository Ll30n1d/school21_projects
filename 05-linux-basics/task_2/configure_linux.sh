#!/bin/bash

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo "!Cкрипт должен быть запущен от имени root!" >&2
  exit 1
fi

echo "[1/6] Создание пользователя user и группы default_users"
groupadd -f default_users
id -u user &>/dev/null || useradd -m -g default_users user

echo "[2/6] Создание группы secret_users и секретных пользователей"
groupadd -f secret_users
for usr in secret_agent secret_spy secret_boss; do
    id -u "$usr" &>/dev/null || useradd -m -g secret_users "$usr"
done

echo "[3/6] Настройка прав для домашниx директорий secret_users"
chmod 750 /home/secret_agent
chmod 750 /home/secret_spy
chmod 750 /home/secret_boss
chown -R secret_agent:secret_users /home/secret_agent
chown -R secret_spy:secret_users /home/secret_spy
chown -R secret_boss:secret_users /home/secret_boss

echo "[4/6] Настройка прав для директории /var"
chmod 777 /var

echo "[5/6] Установка веб-сервера и проверка сервиса"
# В CachyOS служба называется httpd.service
sudo pacman -S --noconfirm apache
systemctl enable --now httpd.service
systemctl status httpd.service --no-pager

echo "[6/6] Настройка беспарольного sudo для группы default_users"
SUDOERS_LINE="%default_users ALL=(ALL) NOPASSWD: ALL"
if ! grep -q "$SUDOERS_LINE" /etc/sudoers; then
    echo "$SUDOERS_LINE" >> /etc/sudoers
    echo "Правило sudo успешно добавлено"
else
    echo "Правило sudo уже существует"
fi

echo "Настройка системы успешно завершена !"