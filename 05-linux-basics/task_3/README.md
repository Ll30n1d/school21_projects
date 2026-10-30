# Задание 3: Настройка мониторинга Linux

## Условие задания

Настроить автоматическую отправку логов за предыдущий день с помощью **logwatch**, **postfix** и **crontab** на личную почту каждые сутки в 00:00. Детализация логов должна быть максимальной.

В репозиторий необходимо загрузить:
- конфигурационный файл `postfix main.cf`;
- файл `cron.txt`, содержащий строку конфигурации планировщика.

---

## Разбор конфигурации

### Строка crontab

```bash
0 0 * * * /usr/bin/logwatch --output mail --mailto mygmail@gmail.com --detail High --range yesterday
```

Разбор полей cron:

| Поле | Значение | Смысл |
|---|---|---|
| Минута | `0` | 0-я минута |
| Час | `0` | 0-й час (полночь) |
| День месяца | `*` | каждый день |
| Месяц | `*` | каждый месяц |
| День недели | `*` | любой день недели |

Итог: задание выполняется **каждые сутки в 00:00**.

Разбор параметров `logwatch`:

- `--output mail` — вывод отчёта в виде электронного письма.
- `--mailto mygmail@gmail.com` — адрес получателя.
- `--detail High` — **максимальный уровень детализации** (соответствует требованию задания).
- `--range yesterday` — отчёт за предыдущий день.

---

### Конфигурация Postfix

Файл `main.cf` должен содержать настройки для отправки почты через SMTP-сервер (например, Gmail). Типовые директивы:

```ini
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

- `relayhost` — SMTP-сервер, через который отправляется почта.
- `smtp_use_tls = yes` — использование шифрования TLS.
- `smtp_sasl_auth_enable = yes` — включение аутентификации SASL.
- `smtp_sasl_password_maps` — путь к файлу с логином и паролем.
- `smtp_tls_CAfile` — файл CA-сертификатов для проверки TLS.

Файл `/etc/postfix/sasl_passwd` содержит учётные данные:

```
[smtp.gmail.com]:587 mygmail@gmail.com:app_password
```

После создания файла выполняется:

```bash
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd
sudo systemctl restart postfix
```

---

## Проверка

Ручной запуск logwatch для проверки:

```bash
sudo /usr/bin/logwatch --output mail --mailto mygmail@gmail.com --detail High --range yesterday
```

Проверка статуса Postfix:

```bash
systemctl status postfix
```

Проверка очереди сообщений:

```bash
mailq
```

---

## Итоговый результат

После настройки каждые сутки в 00:00 на адрес `mygmail@gmail.com` приходит письмо с отчётом logwatch за предыдущий день с уровнем детализации `High`.

Файлы для сдачи:
- `main.cf` — конфигурация Postfix;
- `cron.txt` — строка crontab с расписанием и параметрами logwatch.
