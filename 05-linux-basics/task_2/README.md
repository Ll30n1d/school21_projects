# Задание 2: Скрипт настройки Linux

## Условие задания

Создать bash-скрипт, в котором создаются пользователи и группы с правами, ограниченными их функциональными задачами:

1. Создать пользователя `user` и группу `default_users` с правами по умолчанию.
2. Создать пользователей `secret_agent`, `secret_spy`, `secret_boss` — все в группе `secret_users`.
3. Пользователи группы `secret_users` должны иметь доступ к домашним директориям друг друга. Остальные — нет.
4. Сделать директорию `/var` доступной любым пользователям и любым группам.
5. Установить пакет `apache2` и проверить состояние сервиса `apache2` после установки.
6. Пользователи группы `default_users` должны иметь возможность вводить все команды от `sudo` без ввода пароля.

Скрипт запускается от root.

---

## Разбор кода по пунктам

### Проверка прав root

```bash
if [ "$EUID" -ne 0 ]; then
  echo "!Cкрипт должен быть запущен от имени root!" >&2
  exit 1
fi
```

`$EUID` — effective UID. У root равен `0`. Если условие не выполняется — вывод ошибки в `stderr` (`>&2`) и завершение с кодом `1`.

---

### 1. Создание пользователя user и группы default_users

```bash
groupadd -f default_users
id -u user &>/dev/null || useradd -m -g default_users user
```

- `groupadd -f default_users` — создаёт группу. Флаг `-f` (force) означает: если группа уже существует — не выдавать ошибку, завершиться успешно.
- `id -u user &>/dev/null` — проверка существования пользователя. Если пользователь есть, `id -u` вернёт его UID и код `0`; если нет — код `≠0`.
- `||` — оператор «ИЛИ»: правая часть выполнится только если левая завершилась с ошибкой (пользователя нет).
- `useradd -m -g default_users user`:
  - `-m` — создать домашнюю директорию (`/home/user`);
  - `-g default_users` — основная группа пользователя;
  - `user` — имя пользователя.

Итог: группа `default_users` и пользователь `user` в ней создаются идемпотентно (повторный запуск не ломает систему).

---

### 2. Создание группы secret_users и секретных пользователей

```bash
groupadd -f secret_users
for usr in secret_agent secret_spy secret_boss; do
    id -u "$usr" &>/dev/null || useradd -m -g secret_users "$usr"
done
```

- `groupadd -f secret_users` — создание группы `secret_users` (с той же защитой от повторного создания).
- Цикл `for usr in ...` проходит по трём именам.
- Для каждого: проверка существования через `id -u` и создание через `useradd -m -g secret_users` с домашней директорией и основной группой `secret_users`.

---

### 3. Настройка прав для домашних директорий secret_users

```bash
chmod 750 /home/secret_agent
chmod 750 /home/secret_spy
chmod 750 /home/secret_boss
chown -R secret_agent:secret_users /home/secret_agent
chown -R secret_spy:secret_users /home/secret_spy
chown -R secret_boss:secret_users /home/secret_boss
```

- `chmod 750` — восьмеричные права:
  - `7` (`rwx`) — владелец: чтение, запись, выполнение/вход;
  - `5` (`r-x`) — группа: чтение и вход, без записи;
  - `0` (`---`) — остальные: никакого доступа.
- `chown -R владелец:группа` — рекурсивно (`-R`) меняет владельца и группу всех файлов в директории.

Итог: члены группы `secret_users` могут заходить в домашние директории друг друга (права `r-x` для группы), а «остальные» — нет. Владелец имеет полный доступ.

---

### 4. Настройка прав для директории /var

```bash
chmod 777 /var
```

`777` (`rwxrwxrwx`) — полный доступ для владельца, группы и остальных. Это требование задания: «сделать директорию `/var` доступной любым пользователям и любым группам».

---

### 5. Установка веб-сервера и проверка сервиса

```bash
sudo pacman -S --noconfirm apache
systemctl enable --now httpd.service
systemctl status httpd.service --no-pager
```

- `pacman -S --noconfirm apache` — установка пакета `apache` без интерактивного подтверждения.
- `systemctl enable --now httpd.service` — одновременно включает автозапуск (`enable`) и запускает сервис прямо сейчас (`--now`).
- `systemctl status httpd.service --no-pager` — вывод статуса сервиса без постраничного просмотра (`less`), чтобы вывод остался в терминале/логе.

В дистрибутивах на базе Arch (CachyOS) служба называется `httpd.service`, а пакет — `apache` (в Debian/Kali — `apache2` и `apache2.service`).

---

### 6. Настройка беспарольного sudo для группы default_users

```bash
SUDOERS_LINE="%default_users ALL=(ALL) NOPASSWD: ALL"
if ! grep -q "$SUDOERS_LINE" /etc/sudoers; then
    echo "$SUDOERS_LINE" >> /etc/sudoers
    echo "Правило sudo успешно добавлено"
else
    echo "Правило sudo уже существует"
fi
```

- `SUDOERS_LINE` — строка правила sudoers:
  - `%default_users` — все члены группы `default_users` (символ `%` обозначает группу);
  - `ALL=(ALL)` — на любом хосте от любого пользователя;
  - `NOPASSWD: ALL` — любые команды без ввода пароля.
- `grep -q "$SUDOERS_LINE" /etc/sudoers` — тихая (`-q`) проверка наличия правила.
- `!` инвертирует результат: если правила нет — добавить через `>>`, иначе — сообщить, что уже есть. Это защита от дублирования при повторных запусках.
- Запись через `>>` дописывает правило в конец файла `/etc/sudoers`.

---

## Итоговый результат

После запуска `sudo ./configure_linux.sh`:

- Создана группа `default_users` и пользователь `user` в ней.
- Создана группа `secret_users` и пользователи `secret_agent`, `secret_spy`, `secret_boss`.
- Домашние директории секретных пользователей доступны только владельцу и группе `secret_users`.
- Директория `/var` доступна всем (`777`).
- Установлен и запущен веб-сервер (служба `httpd.service`), проверен его статус.
- Группе `default_users` разрешён `sudo` без пароля.

Проверка результата:

```bash
id user
id secret_agent
ls -ld /home/secret_agent /home/secret_spy /home/secret_boss /var
systemctl status httpd.service
sudo -l -U user
```
