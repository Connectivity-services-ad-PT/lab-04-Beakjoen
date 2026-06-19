#!/bin/sh
set -e

exec uvicorn iot_app.main:app \
    --app-dir src \
    --host "${APP_HOST:-0.0.0.0}" \
    --port "${APP_PORT:-8000}"
