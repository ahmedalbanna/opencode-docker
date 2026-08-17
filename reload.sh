#!/bin/bash
# reload.sh - Restart ONLY the opencode process inside the container.
# This re-reads the config from the mounted config dir. The container and
# its network are untouched.
#
# Installed at /usr/local/bin/reload.sh (mounted). Run from host via:
#   docker compose exec opencode /usr/local/bin/reload.sh

PIDFILE="/var/run/opencode.pid"
PORT="${OPENCODE_PORT:-3000}"
HOST="${OPENCODE_HOST:-0.0.0.0}"

PID=""
[ -f "${PIDFILE}" ] && PID=$(cat "${PIDFILE}")

echo "Stopping opencode (PID ${PID:-none})..."
if [ -n "${PID}" ] && kill -0 "${PID}" 2>/dev/null; then
    kill "${PID}" 2>/dev/null
    for _ in $(seq 1 20); do
        kill -0 "${PID}" 2>/dev/null || break
        sleep 0.5
    done
fi

# The supervisor (PID 1) in entrypoint.sh will automatically detect the stop
# and restart opencode with the current config within ~5 seconds.
echo "Waiting for supervisor to restart opencode..."
for _ in $(seq 1 30); do
    NEWPID=$(cat "${PIDFILE}" 2>/dev/null)
    if [ -n "${NEWPID}" ] && kill -0 "${NEWPID}" 2>/dev/null && [ "${NEWPID}" != "${PID}" ]; then
        echo "opencode restarted (new PID ${NEWPID}) on ${HOST}:${PORT}"
        exit 0
    fi
    sleep 0.5
done

echo "WARNING: opencode did not auto-restart; starting manually..."
opencode serve --port "${PORT}" --hostname "${HOST}" --mdns false &
echo $! > "${PIDFILE}"
echo "opencode started manually (PID $(cat ${PIDFILE}))"