# Документация настройки сервера devops-vm

## 8. Веб-сервер

- **Устанавливаемый пакет**: `nginx` (`sudo apt update && sudo apt install -y nginx`, служба `nginx` активна).
- **Путь к конфигурации ресурса**: `/etc/nginx/sites-available/devops-site` (символическая ссылка в `/etc/nginx/sites-enabled/devops-site`, файл `default` отключён).
- **Каталог ресурса**: `/var/www/devops-site`, владелец `devops:devops`, права каталогов `755`, файлов `644`.
- **Сертификат и закрытый ключ TLS**:
  - Сертификат: `/etc/ssl/certs/devops.crt` (владелец `root:root`, права `644`, срок `365` дней, `SAN=DNS:devops.local`).
  - Закрытый ключ: `/etc/ssl/private/devops.key` (владелец `root:root`, права `600`).
- **Команда формирования сертификата**:
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/devops.key \
  -out /etc/ssl/certs/devops.crt \
  -subj "/CN=devops.local" \
  -addext "subjectAltName=DNS:devops.local"
```

## 9. Контейнеризация

- **Способ установки Docker Engine**: установка официальных пакетов Docker Engine из репозитория download.docker.com (`docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`). Дистрибутивный пакет `docker.io` исключён.
- **Версия Docker**: Docker Engine Community, Docker Compose v2.
- **Пользователи**: учётная запись `devops` добавлена в группу `docker` (доступ без `sudo`).
- **Расположение проекта на сервере**: `/home/devops/app` (приложение на Flask, Gunicorn, Dockerfile, docker-compose.yml).
- **Конфигурация окружения (.env)**: расположен в `/home/devops/app/.env` с правами доступа `600` (чтение/запись только пользователю devops). Исключён из git (`.gitignore`) и rsync (`--exclude=.env`).
- **Сетевая публикация портов**: порт веб-приложения привязан исключительно к петлевому интерфейсу хоста `127.0.0.1:5000:5000`; порт PostgreSQL `5432` не опубликован наружу и доступен только внутри сети `backend`.
- **Именованные тома**: `db_data` смонтирован в каталог `/var/lib/postgresql/data` контейнера базы данных для персистентного хранения данных между перезапусками Compose.
- **Обратный прокси-сервер**: Nginx (`/etc/nginx/sites-available/devops-site`) терминирует HTTPS на порту 443 и проксирует запросы `/app/` на `http://127.0.0.1:5000/`.
