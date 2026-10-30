#!/usr/bin/env bash
set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
REPO_ROOT="$(git rev-parse --show-toplevel)"
LOCAL_DIR="${REPO_ROOT}/site/"

DRY_RUN=false
if [[ $# -gt 1 ]]; then
    echo "Ошибка: слишком много аргументов." >&2; exit 1
elif [[ $# -eq 1 ]]; then
    if [[ "$1" == "--dry-run" ]]; then DRY_RUN=true
    else echo "Ошибка: неизвестный аргумент '$1'" >&2; exit 1; fi
fi

if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: файл site/index.html отсутствует." >&2; exit 1
fi

if [[ -n "$(git -C "${REPO_ROOT}" status --porcelain)" ]]; then
    echo "Ошибка: в репозитории есть незафиксированные изменения." >&2; exit 1
fi

RSYNC_ARGS=(-avz --delete --chmod=D755,F644 -e "ssh -o BatchMode=yes -o ConnectTimeout=5")
[[ "${DRY_RUN}" == "true" ]] && RSYNC_ARGS+=(--dry-run)
rsync "${RSYNC_ARGS[@]}" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"
[[ "${DRY_RUN}" == "true" ]] && exit 0

if ! curl -fsS --cacert "${CA_CERT}" -o /dev/null "${SITE_URL}/"; then
    echo "Ошибка: ресурс ${SITE_URL} недоступен." >&2; exit 1
fi

echo "Деплой успешно завершён. Коммит: $(git -C "${REPO_ROOT}" rev-parse --short HEAD)"
