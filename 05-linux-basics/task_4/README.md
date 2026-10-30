# Задание 4: Защита операционной системы встроенными инструментами

## Условие задания

1. Настроить подключение к своему Linux по SSH с использованием приватного и публичного ключей, а не пароля.
2. Запретить подключаться к своему устройству по порту `80/tcp` извне.

В репозиторий необходимо загрузить:
- файл конфигурации `sshd_config` виртуальной машины;
- файл `authorized_keys`;
- файл `iptables.txt` с выводом одной цепочки iptables правил (той, куда было записано правило).

---

## Часть 1. SSH-аутентификация по ключам

### Генерация ключевой пары

На клиентской машине:

```bash
ssh-keygen -t ed25519 -C "xanskyx123@gmail.com"
```

- `-t ed25519` — тип ключа (современный, быстрый и безопасный алгоритм).
- `-C` — комментарий (обычно email для идентификации ключа).

Будут созданы два файла:
- `~/.ssh/id_ed25519` — **приватный** ключ (никому не передаётся);
- `~/.ssh/id_ed25519.pub` — **публичный** ключ (копируется на сервер).

### Копирование публичного ключа на сервер

```bash
ssh-copy-id user@server_ip
```

Или вручную:

```bash
cat ~/.ssh/id_ed25519.pub | ssh user@server_ip "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

На сервере публичный ключ должен оказаться в файле `~/.ssh/authorized_keys` пользователя, к которому выполняется подключение.

Права:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Настройка sshd_config

В файле `/etc/ssh/sshd_config` задаются ключевые директивы:

```ini
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
AuthorizedKeysFile .ssh/authorized_keys
```

- `PubkeyAuthentication yes` — разрешает аутентификацию по публичному ключу.
- `PasswordAuthentication no` — **отключает вход по паролю** (основное требование задания).
- `PermitRootLogin no` — запрещает прямой вход под root по SSH.
- `AuthorizedKeysFile` — путь к файлу с авторизованными ключами.

Перезапуск службы SSH:

```bash
sudo systemctl restart sshd
```

Проверка подключения:

```bash
ssh user@server_ip
```

Вход должен выполняться без запроса пароля, только по ключу.

---

## Часть 2. Блокировка порта 80/tcp извне

Порт `80/tcp` — стандартный порт HTTP (веб-сервер). Задание требует запретить подключения к нему **извне**, то есть из внешней сети, оставив возможность локальных подключений (с самой машины, через `localhost`).

### Правило в цепочке INPUT

```bash
sudo iptables -A INPUT -p tcp --dport 80 -j DROP
```

- `-A INPUT` — добавить правило в конец цепочки `INPUT` (входящий трафик на локальную машину).
- `-p tcp` — протокол TCP.
- `--dport 80` — порт назначения 80.
- `-j DROP` — отбросить пакет без ответа.

Более точный вариант — разрешить `localhost`, заблокировать остальное:

```bash
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j DROP
```

- `-i lo` — интерфейс loopback (локальные подключения).
- Внешние подключения к порту 80 будут отбрасываться.

### Сохранение правил

```bash
sudo iptables-save > /etc/iptables/rules.v4
```

или (для систем без `iptables-persistent`):

```bash
sudo sh -c "iptables-save > /etc/iptables.rules"
```

### Получение вывода цепочки для сдачи

```bash
sudo iptables -L INPUT -v -n
```

Или в формате сохранения:

```bash
sudo iptables -S INPUT
```

Вывод команды `iptables -L INPUT -v -n` (или `iptables -S INPUT`) сохраняется в файл `iptables.txt`:

```bash
sudo iptables -L INPUT -v -n > iptables.txt
```

- `-L INPUT` — вывод правил цепочки `INPUT`.
- `-v` — подробный формат (счётчики пакетов и байт).
- `-n` — числовые адреса и порты без резолва.

---

## Проверка результата

### SSH

```bash
ssh -o PreferredAuthentications=password user@server_ip
```

Должен получить отказ в аутентификации по паролю (пароль больше не принимается).

```bash
ssh user@server_ip
```

Должно пройти успешно по ключу.

### iptables

```bash
sudo iptables -L INPUT -v -n
```

В выводе должно присутствовать правило с `dpt:80` и действием `DROP` (или `REJECT`).

Проверка внешнего подключения к порту 80:

```bash
nc -zv server_ip 80
```

Соединение должно «зависать» (для `DROP`) или получать отказ (для `REJECT`).

Локальная проверка:

```bash
curl http://localhost:80
```

Должна работать (если на порту есть сервис).

---

## Итоговый результат

- SSH-подключение к серверу выполняется только по приватному ключу; вход по паролю отключён директивой `PasswordAuthentication no`.
- Входящий трафик на порт `80/tcp` извне блокируется правилом в цепочке `INPUT`.

Файлы для сдачи:
- `sshd_config` — конфигурация SSH-сервера;
- `authorized_keys` — файл с публичными ключами;
- `iptables.txt` — вывод цепочки `INPUT` с правилом блокировки порта 80.
