#!/usr/bin/env bash
set -euo pipefail

# OpenTelemetry + Grafana Observability Lab
# macOS one-command setup and run script.
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
#
# The script:
#   1. Installs Homebrew if required
#   2. Installs Python and Docker Desktop if required
#   3. Starts Docker Desktop
#   4. Creates the Python virtual environment
#   5. Installs Python dependencies
#   6. Starts the Grafana LGTM container
#   7. Starts the FastAPI application

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"
CONTAINER_NAME="otel-lgtm"
FASTAPI_PORT="${FASTAPI_PORT:-8000}"

info()  { printf "\n\033[1;34m[INFO]\033[0m %s\n" "$1"; }
ok()    { printf "\033[1;32m[ OK ]\033[0m %s\n" "$1"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$1"; }
error() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$1" >&2; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  error "This installer is designed for macOS."
  exit 1
fi

if [[ ! -f "$PROJECT_DIR/app/main.py" ]]; then
  error "Cannot find app/main.py."
  error "Run this script from the root of the otel-grafana-lab project."
  exit 1
fi

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  info "Homebrew is not installed. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for this shell.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

ok "Homebrew is available: $(brew --version | head -n 1)"

# ------------------------------------------------------------
# Python
# ------------------------------------------------------------
if ! command -v python3 >/dev/null 2>&1; then
  info "Installing Python..."
  brew install python
fi

PYTHON_BIN="$(command -v python3)"
ok "Python: $($PYTHON_BIN --version)"

# ------------------------------------------------------------
# Docker Desktop
# ------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  info "Docker CLI not found. Installing Docker Desktop..."
  brew install --cask docker
fi

if ! command -v docker >/dev/null 2>&1; then
  error "Docker CLI is still unavailable after installation."
  exit 1
fi

ok "Docker CLI: $(docker --version)"

# Start Docker Desktop if the daemon is not ready.
if ! docker info >/dev/null 2>&1; then
  info "Starting Docker Desktop..."
  open -a Docker

  info "Waiting for Docker Engine to become ready..."
  for i in {1..60}; do
    if docker info >/dev/null 2>&1; then
      ok "Docker Engine is ready."
      break
    fi

    if [[ "$i" -eq 60 ]]; then
      error "Docker Engine did not become ready within 60 seconds."
      error "Please open Docker Desktop manually and run this script again."
      exit 1
    fi

    sleep 2
  done
else
  ok "Docker Engine is already running."
fi

# ------------------------------------------------------------
# Python virtual environment
# ------------------------------------------------------------
if [[ ! -d "$VENV_DIR" ]]; then
  info "Creating Python virtual environment..."
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

info "Upgrading pip..."
python -m pip install --upgrade pip >/dev/null

# Prefer requirements.txt when available.
if [[ -f "$PROJECT_DIR/requirements.txt" ]]; then
  info "Installing Python dependencies from requirements.txt..."
  python -m pip install -r "$PROJECT_DIR/requirements.txt"
else
  info "requirements.txt not found. Installing required packages..."
  python -m pip install \
    fastapi \
    uvicorn \
    opentelemetry-api \
    opentelemetry-sdk \
    opentelemetry-exporter-otlp \
    opentelemetry-instrumentation-fastapi
fi

ok "Python dependencies installed."

# ------------------------------------------------------------
# Grafana LGTM stack
# ------------------------------------------------------------
if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  if [[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" == "true" ]]; then
    ok "Grafana LGTM container '$CONTAINER_NAME' is already running."
  else
    info "Starting existing Grafana LGTM container..."
    docker start "$CONTAINER_NAME" >/dev/null
    ok "Grafana LGTM container started."
  fi
else
  info "Creating Grafana LGTM observability stack..."

  docker run -d \
    --name "$CONTAINER_NAME" \
    -p 3000:3000 \
    -p 4317:4317 \
    -p 4318:4318 \
    -p 9090:9090 \
    grafana/otel-lgtm:latest >/dev/null

  ok "Grafana LGTM container created."
fi

# ------------------------------------------------------------
# Wait for Grafana / Collector endpoints
# ------------------------------------------------------------
info "Waiting for Grafana..."

for i in {1..60}; do
  if curl -fsS http://localhost:3000/api/health >/dev/null 2>&1; then
    ok "Grafana is ready."
    break
  fi

  if [[ "$i" -eq 60 ]]; then
    warn "Grafana did not respond within the expected time."
    warn "The container may still be starting. Check:"
    warn "docker logs $CONTAINER_NAME"
    break
  fi

  sleep 2
done

# ------------------------------------------------------------
# Start FastAPI
# ------------------------------------------------------------
info "Starting FastAPI application..."

echo
echo "============================================================"
echo " OpenTelemetry + Grafana Observability Lab"
echo "============================================================"
echo
echo " FastAPI:              http://localhost:$FASTAPI_PORT"
echo " FastAPI Swagger:      http://localhost:$FASTAPI_PORT/docs"
echo " Grafana:              http://localhost:3000"
echo " Grafana login:        admin / admin"
echo " Prometheus:           http://localhost:9090"
echo " OTLP HTTP:            http://localhost:4318"
echo " OTLP gRPC:            http://localhost:4317"
echo
echo " Test endpoints:"
echo "   curl http://localhost:$FASTAPI_PORT/health"
echo "   curl http://localhost:$FASTAPI_PORT/users"
echo "   curl http://localhost:$FASTAPI_PORT/orders"
echo "   curl http://localhost:$FASTAPI_PORT/error"
echo
echo " Grafana:"
echo "   Explore -> Prometheus -> demo_app_requests_total"
echo "   Explore -> Tempo -> service.name = demo-app"
echo
echo " Press Ctrl+C to stop FastAPI."
echo " The LGTM Docker container will continue running."
echo "============================================================"
echo

cd "$PROJECT_DIR"
exec uvicorn app.main:app --reload --host 0.0.0.0 --port "$FASTAPI_PORT"
