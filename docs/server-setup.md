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
