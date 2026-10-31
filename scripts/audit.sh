#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0

check() {
  local desc="$1"
  shift
  if [[ $# -eq 2 && "$1" != "bash" && "$1" != "systemctl" && "$1" != "sudo" && "$1" != "openssl" ]]; then
    local expected="$1" actual="$2"
    if [[ "$actual" == "$expected" ]]; then
      echo "  [OK] $desc"; ((PASS++))
    else
      echo "  [FAIL] $desc (ожидалось: '$expected', получено: '$actual')"; ((FAIL++))
    fi
  else
    if "$@" >/dev/null 2>&1; then
      echo "  [OK] $desc"; ((PASS++))
    else
      echo "  [FAIL] $desc"; ((FAIL++))
    fi
  fi
}

echo "Аудит конфигурации: $(hostname -f), $(date '+%Y-%m-%d %H:%M')"

echo "[1] Служба SSH"
check "Вход root запрещён" "no" "$(sudo sshd -T 2>/dev/null | awk '/^permitrootlogin/{print $2}')"
check "Пароли отключены" "no" "$(sudo sshd -T 2>/dev/null | awk '/^passwordauthentication/{print $2}')"
check "Порт отличен от 22" "true" "$(sudo sshd -T 2>/dev/null | awk '/^port/{if ($2 != 22) print "true"; else print "false"}')"
check "MaxAuthTries равен 3" "3" "$(sudo sshd -T 2>/dev/null | awk '/^maxauthtries/{print $2}')"

echo "[2] Межсетевой экран"
check "UFW активен" "active" "$(sudo ufw status 2>/dev/null | awk '/^Status:/{print $2}')"
check "Default входящий deny" "deny" "$(sudo ufw status verbose 2>/dev/null | awk '/Default:/{print $2}')"

echo "[3] Учётные записи"
awk -F: '$3>=1000 && $3<65534 {printf "  %s (uid=%s)\n",$1,$3}' /etc/passwd

echo "[4] Веб-сервер"
check "Служба nginx активна" systemctl is-active --quiet nginx
check "Конфигурация nginx синтаксически корректна" sudo nginx -t
check "Сертификат действителен не менее 30 дней" openssl x509 -in /etc/ssl/certs/devops.crt -noout -checkend 2592000
check "Права каталога ресурса и закрытого ключа безопасны" bash -c '[[ -z "$(find /var/www/devops-site -perm -o+w 2>/dev/null)" ]] && [[ "$(sudo stat -c "%a" /etc/ssl/private/devops.key)" == "600" ]]'

echo "[5] Контейнеризация"
check "Служба docker активна" "active" "$(systemctl is-active docker)"
check "Контейнер СУБД healthy" "healthy" "$(docker inspect -f '{{.State.Health.Status}}' app-db-1 2>/dev/null || docker inspect -f '{{.State.Health.Status}}' app_db_1 2>/dev/null)"
CHECK_PORTS="ok"
if ss -tln | grep -E ':(5000|5432)\b' | grep -v '127\.0\.0\.1' >/dev/null; then
  CHECK_PORTS="exposed"
fi
check "Порты 5000 и 5432 изолированы на 127.0.0.1" "ok" "$CHECK_PORTS"
ENV_PERMS="$(stat -c '%a' /home/devops/app/.env 2>/dev/null || echo 'not_found')"
check "Права файла .env равны 600" "600" "$ENV_PERMS"

echo "Пройдено: $PASS, не пройдено: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
