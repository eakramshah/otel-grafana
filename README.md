# OpenTelemetry + Grafana Observability Lab

A hands-on local observability lab for learning **Site Reliability Engineering (SRE), Observability, OpenTelemetry, Prometheus, Grafana and distributed tracing**.

This project starts with a simple FastAPI application and builds an end-to-end telemetry pipeline using the Grafana LGTM stack.

## Architecture

```text
                         ┌──────────────────────┐
                         │      FastAPI App     │
                         │                      │
                         │  /                  │
                         │  /health            │
                         │  /users             │
                         │  /orders            │
                         │  /error             │
                         └──────────┬───────────┘
                                    │
                            OpenTelemetry SDK
                                    │
                              OTLP HTTP :4318
                                    │
                                    ▼
                       ┌────────────────────────┐
                       │ OpenTelemetry Collector│
                       └────────────┬───────────┘
                                    │
                    ┌───────────────┼────────────────┐
                    │               │                │
                    ▼               ▼                ▼
              ┌───────────┐   ┌──────────┐    ┌──────────┐
              │Prometheus │   │  Tempo   │    │   Loki   │
              │  Metrics  │   │  Traces  │    │   Logs   │
              └─────┬─────┘   └────┬─────┘    └────┬─────┘
                    │              │               │
                    └──────────────┼───────────────┘
                                   ▼
                            ┌────────────┐
                            │  Grafana   │
                            │            │
                            │ Explore    │
                            │ Dashboards │
                            │ Alerting   │
                            └────────────┘
```

## Current Project Status

| Component | Status |
|---|---|
| Docker Desktop | ✅ Complete |
| Grafana | ✅ Complete |
| OpenTelemetry Collector | ✅ Complete |
| Prometheus | ✅ Complete |
| Tempo | ✅ Complete |
| Loki | ✅ Available |
| Pyroscope | ✅ Available |
| FastAPI application | ✅ Complete |
| OpenTelemetry SDK | ✅ Complete |
| FastAPI instrumentation | ✅ Complete |
| OTLP exporter | ✅ Complete |
| Traces | ✅ Working |
| Metrics | ✅ Working |
| Logs | ⏳ Next |
| Trace/Log correlation | ⏳ Next |
| Grafana dashboards | ⏳ Next |
| Alerting | ⏳ Next |
| SLI/SLO | ⏳ Next |
| Grafana Alloy | ⏳ Next |
| Docker Compose | ⏳ Next |
| Kubernetes | ⏳ Next |
| SRE troubleshooting scenarios | ⏳ Next |

---

# Prerequisites

You need the following installed locally.

## 1. Operating System

This project can be run on:

- macOS
- Linux
- Windows with Docker Desktop

The project was developed and tested on **macOS / Apple Silicon**.

---

## 2. Docker Desktop

Docker is required to run the Grafana LGTM observability stack.

Install Docker Desktop from the official Docker website:

https://www.docker.com/products/docker-desktop/

After installation, start Docker Desktop.

Verify:

```bash
docker --version
```

Example:

```text
Docker version 27.x.x
```

Also verify Docker is running:

```bash
docker run hello-world
```

You should see a successful Docker message.

### Important

If you see:

```text
Cannot connect to the Docker daemon
```

start Docker Desktop and try again.

---

# 3. Python

Python 3.10+ is recommended.

Check your version:

```bash
python3 --version
```

Example:

```text
Python 3.12.x
```

If `python3` is available but `python` is not, use `python3` in the commands below.

---

# 4. Git

Git is recommended if you want to clone this project.

Check:

```bash
git --version
```

Install Git if required.

---

# 5. Required Ports

Make sure these ports are available on your machine:

| Port | Purpose |
|---|---|
| `8000` | FastAPI application |
| `3000` | Grafana |
| `4317` | OpenTelemetry OTLP gRPC |
| `4318` | OpenTelemetry OTLP HTTP |

The LGTM container also contains internal services such as Prometheus, Tempo, Loki and Pyroscope.

> Note: In the current Docker command, Prometheus port `9090` is not published to the host. This is intentional and does not prevent Grafana from querying Prometheus internally.

---

# Getting Started

## 1. Clone the repository

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd otel-grafana-lab
```

If you already have the project locally:

```bash
cd ~/otel-grafana-lab
```

---

# 2. Create a Python Virtual Environment

From the project directory:

```bash
python3 -m venv venv
```

Activate it:

### macOS / Linux

```bash
source venv/bin/activate
```

You should see something similar to:

```text
(venv)
```

in your terminal prompt.

---

# 3. Install Python Dependencies

Install the required packages:

```bash
pip install fastapi uvicorn
```

Install OpenTelemetry:

```bash
pip install \
  opentelemetry-api \
  opentelemetry-sdk \
  opentelemetry-exporter-otlp \
  opentelemetry-instrumentation-fastapi
```

Alternatively, if the repository contains a `requirements.txt`:

```bash
pip install -r requirements.txt
```

---

# 4. Start the Grafana LGTM Stack

Run:

```bash
docker run -d \
  --name otel-lgtm \
  -p 3000:3000 \
  -p 4317:4317 \
  -p 4318:4318 \
  grafana/otel-lgtm:latest
```

Check that the container is running:

```bash
docker ps
```

You should see:

```text
otel-lgtm
```

Check the startup logs:

```bash
docker logs otel-lgtm
```

Wait until you see messages indicating that the Grafana LGTM stack and OpenTelemetry Collector are running.

---

# 5. Start the FastAPI Application

Activate the virtual environment:

```bash
cd ~/otel-grafana-lab
source venv/bin/activate
```

Start FastAPI:

```bash
uvicorn app.main:app --reload --port 8000
```

The application should be available at:

```text
http://localhost:8000
```

---

# 6. Test the Application

Open another terminal.

Test the health endpoint:

```bash
curl http://localhost:8000/health
```

Expected:

```json
{"status":"healthy"}
```

Test users:

```bash
curl http://localhost:8000/users
```

Test orders:

```bash
curl http://localhost:8000/orders
```

Test the intentional error endpoint:

```bash
curl http://localhost:8000/error
```

Expected:

```text
Internal Server Error
```

The `/error` endpoint intentionally raises an exception so that we can practice observing application failures.

---

# OpenTelemetry Configuration

The application sends telemetry using OTLP HTTP.

## Trace endpoint

```text
http://localhost:4318/v1/traces
```

## Metric endpoint

```text
http://localhost:4318/v1/metrics
```

Because FastAPI is running directly on the Mac, `localhost` points to the Mac where the Collector port is published.

> If the application is later moved into Docker Compose, `localhost` should generally be replaced with the appropriate Docker service name, such as `otel-lgtm`.

---

# Application Resource Attributes

The application uses resource attributes similar to:

```python
resource = Resource.create({
    "service.name": "demo-app",
    "service.version": "1.0.0",
    "deployment.environment": "local"
})
```

These attributes identify the source of telemetry.

In a production environment, you might have:

```text
service.name = payment-service
service.version = 3.2.1
deployment.environment = production
```

---

# Tracing

FastAPI is automatically instrumented using:

```python
FastAPIInstrumentor.instrument_app(app)
```

Requests such as:

```text
GET /
GET /health
GET /users
GET /orders
GET /error
```

generate OpenTelemetry traces.

## View traces

Open Grafana:

```text
http://localhost:3000
```

Default credentials:

```text
Username: admin
Password: admin
```

Then:

```text
Grafana
  → Explore
  → Tempo
```

Search for:

```text
service.name = demo-app
```

You should see traces for the application endpoints.

---

# Metrics

The application currently creates a request counter:

```text
demo_app_requests_total
```

The counter is incremented for:

```text
/users
/orders
```

with an `endpoint` attribute.

Conceptually:

```text
demo_app_requests_total
    ├── endpoint="/users"
    └── endpoint="/orders"
```

---

# Generate Metric Traffic

Run:

```bash
for i in {1..10}; do
  curl -s http://localhost:8000/users > /dev/null
done
```

Then:

```bash
for i in {1..5}; do
  curl -s http://localhost:8000/orders > /dev/null
done
```

The OpenTelemetry metric reader exports metrics every few seconds.

---

# Query Metrics in Grafana

Open:

```text
Grafana
  → Explore
  → Prometheus
```

Run:

```promql
demo_app_requests_total
```

You should see separate time series for:

```text
endpoint="/users"
endpoint="/orders"
```

---

# PromQL: Request Rate

A counter gives us the cumulative number of requests.

For an SRE use case, request rate is often more useful.

Use:

```promql
rate(demo_app_requests_total[1m])
```

This calculates the average requests per second over the previous minute.

This is the beginning of the **RED methodology**:

```text
R = Rate
E = Errors
D = Duration
```

---

# Troubleshooting

## Docker is not running

Error:

```text
Cannot connect to the Docker daemon
```

Solution:

Start Docker Desktop and verify:

```bash
docker run hello-world
```

---

## Port 3000 is already in use

Check:

```bash
lsof -i :3000
```

Either stop the application using that port or choose another host port.

---

## Port 8000 is already in use

Check:

```bash
lsof -i :8000
```

You can also run FastAPI on another port:

```bash
uvicorn app.main:app --reload --port 8001
```

---

## Check LGTM container

```bash
docker ps --filter name=otel-lgtm
```

View logs:

```bash
docker logs otel-lgtm --tail 100
```

---

## Stop the observability stack

```bash
docker stop otel-lgtm
```

## Start it again

```bash
docker start otel-lgtm
```

There is no need to recreate the container every time.

## Remove the container

Only do this if you intentionally want to recreate the environment:

```bash
docker rm -f otel-lgtm
```

Then run the `docker run` command again.

---

# Important Docker Networking Concept

The current architecture has the FastAPI application running directly on the Mac:

```text
Mac
 ├── FastAPI :8000
 │
 └── Docker
      └── otel-lgtm
           ├── Collector :4317
           ├── Collector :4318
           ├── Grafana :3000
           └── Prometheus
```

Therefore the application uses:

```text
localhost:4318
```

for OTLP.

Later, when we move everything to Docker Compose, the architecture will become:

```text
Docker Network

FastAPI
   │
   │ http://otel-lgtm:4318
   ▼
OTel Collector
   │
   ├── Prometheus
   ├── Tempo
   └── Loki
```

This distinction is important when troubleshooting containerized applications.

---

# What You Will Learn From This Project

This lab is designed to progressively cover:

## Observability

- Metrics
- Logs
- Traces
- Profiles
- Telemetry pipelines
- Signal correlation

## OpenTelemetry

- OpenTelemetry SDK
- Instrumentation
- Resources
- Spans
- Traces
- Metrics
- OTLP
- OpenTelemetry Collector
- Exporters
- Processors

## Prometheus

- Metrics
- Labels
- Counters
- Histograms
- PromQL
- `rate()`
- Error rate
- Latency
- Recording rules

## Grafana

- Explore
- Prometheus queries
- Tempo
- Loki
- Dashboards
- Variables
- Alerting

## SRE

- RED methodology
- Golden Signals
- SLIs
- SLOs
- Error budgets
- Alert design
- Incident troubleshooting

---

# Roadmap

The project will evolve through several stages.

### Phase 1 — Foundation

- [x] Docker
- [x] Grafana
- [x] OpenTelemetry Collector
- [x] Prometheus
- [x] Tempo
- [x] FastAPI
- [x] OpenTelemetry SDK

### Phase 2 — Traces

- [x] FastAPI instrumentation
- [x] OTLP trace export
- [x] Tempo
- [x] Grafana trace exploration

### Phase 3 — Metrics

- [x] OpenTelemetry metrics
- [x] Request counter
- [x] Prometheus
- [x] PromQL
- [x] Request rate

### Phase 4 — Logs

- [ ] Application logs
- [ ] Loki
- [ ] Structured logging
- [ ] Log levels
- [ ] Error investigation

### Phase 5 — Correlation

- [ ] Trace IDs in logs
- [ ] Metric → trace investigation
- [ ] Trace → logs
- [ ] Logs → traces

### Phase 6 — SRE Dashboards

- [ ] RED dashboard
- [ ] Request rate
- [ ] Error rate
- [ ] P50/P90/P95/P99 latency
- [ ] Service health dashboard

### Phase 7 — Alerting

- [ ] High error-rate alert
- [ ] High-latency alert
- [ ] Availability alert
- [ ] Alert routing
- [ ] Alert troubleshooting

### Phase 8 — Reliability Engineering

- [ ] SLIs
- [ ] SLOs
- [ ] Error budgets
- [ ] Burn-rate alerts

### Phase 9 — Production-Like Setup

- [ ] Grafana Alloy
- [ ] Docker Compose
- [ ] Kubernetes
- [ ] Kubernetes telemetry
- [ ] Production troubleshooting scenarios

---

# SRE Troubleshooting Scenarios

Once the basic telemetry pipeline is complete, this project will be used to simulate real incidents.

Examples:

### Scenario 1 — High latency

```text
Users report that /orders is slow.

Check:
    ↓
Metrics
    ↓
Latency
    ↓
Trace
    ↓
Slow dependency
    ↓
Logs
    ↓
Root cause
```

### Scenario 2 — Increased 5xx errors

```text
Error rate increases
        ↓
Prometheus
        ↓
Identify affected endpoint
        ↓
Tempo
        ↓
Find failing requests
        ↓
Loki
        ↓
Investigate application error
```

### Scenario 3 — Traffic spike

```text
Request rate increases
        ↓
CPU/memory
        ↓
Latency
        ↓
Error rate
        ↓
Capacity analysis
        ↓
Scaling decision
```

---

# Learning Objectives

By completing this project, you should be able to explain:

1. What observability means.
2. The difference between metrics, logs and traces.
3. What OpenTelemetry does.
4. What OTLP is.
5. What the OpenTelemetry Collector does.
6. How telemetry moves from an application to a backend.
7. How Prometheus stores and queries metrics.
8. How PromQL works.
9. How Grafana visualizes telemetry.
10. How Tempo is used for tracing.
11. How Loki is used for logs.
12. How to correlate metrics, traces and logs.
13. How to build RED dashboards.
14. How observability supports SRE incident troubleshooting.
15. How to turn telemetry into SLIs and SLOs.

---

# Useful Commands

## Check Docker

```bash
docker ps
```

## Check LGTM container

```bash
docker ps --filter name=otel-lgtm
```

## View LGTM logs

```bash
docker logs otel-lgtm --tail 100
```

## Stop LGTM

```bash
docker stop otel-lgtm
```

## Start LGTM

```bash
docker start otel-lgtm
```

## Check FastAPI

```bash
curl http://localhost:8000/health
```

## Generate users traffic

```bash
for i in {1..10}; do
  curl -s http://localhost:8000/users > /dev/null
done
```

## Generate orders traffic

```bash
for i in {1..10}; do
  curl -s http://localhost:8000/orders > /dev/null
done
```

---

# Project Structure

The project is organized approximately as follows:

```text
otel-grafana-lab/
│
├── app/
│   └── main.py
│
├── venv/
│
├── README.md
│
└── requirements.txt        # recommended
```

The `venv/` directory is local to your machine and should normally be excluded from Git.

Recommended `.gitignore`:

```text
venv/
__pycache__/
*.pyc
.env
.DS_Store
```

---

# Recommended requirements.txt

For reproducible setup, create a `requirements.txt` containing:

```text
fastapi
uvicorn
opentelemetry-api
opentelemetry-sdk
opentelemetry-exporter-otlp
opentelemetry-instrumentation-fastapi
```

Then future installations become:

```bash
pip install -r requirements.txt
```

---

# Contributing

This project is primarily a learning lab.

Feel free to experiment with:

- New endpoints
- Additional metrics
- Custom spans
- Structured logs
- PromQL queries
- Grafana dashboards
- Alerts
- Failure scenarios

Breaking the application intentionally is encouraged — the goal is to learn how to **observe and troubleshoot the failure**.

---

# Author

**Eakram Shah**

SRE / Observability / Platform Engineering

This project is part of a hands-on learning journey covering:

```text
SRE
Observability
OpenTelemetry
Prometheus
Grafana
Kubernetes
Cloud Native
Reliability Engineering
```

---

# Final Goal

The final objective of this project is not simply to run Grafana.

The goal is to build the ability to answer a production incident question such as:

> **"Users are reporting that the application is slow. What is happening, where is the problem, and why?"**

Using:

```text
Metrics
   ↓
Traces
   ↓
Logs
   ↓
Correlation
   ↓
Root Cause
   ↓
SRE Action
```

That is the real purpose of observability.

---

## License

This project is intended for learning and experimentation.
