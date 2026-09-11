from fastapi import FastAPI
import time
import random

from opentelemetry import trace
from opentelemetry import metrics
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter

from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor


# --------------------------------------------------
# OpenTelemetry configuration
# --------------------------------------------------

resource = Resource.create({
    "service.name": "demo-app",
    "service.version": "1.0.0",
    "deployment.environment": "local"
})

trace_provider = TracerProvider(resource=resource)

trace_exporter = OTLPSpanExporter(
    endpoint="http://localhost:4318/v1/traces"
)

trace_provider.add_span_processor(
    BatchSpanProcessor(trace_exporter)
)

trace.set_tracer_provider(trace_provider)

tracer = trace.get_tracer(__name__)

# --------------------------------------------------
# OpenTelemetry Metrics
# --------------------------------------------------

metric_exporter = OTLPMetricExporter(
    endpoint="http://localhost:4318/v1/metrics"
)

metric_reader = PeriodicExportingMetricReader(
    metric_exporter,
    export_interval_millis=5000
)

meter_provider = MeterProvider(
    resource=resource,
    metric_readers=[metric_reader]
)

metrics.set_meter_provider(meter_provider)

meter = metrics.get_meter("demo-app")
request_counter = meter.create_counter(
    "demo_app_requests_total",
    description="Total number of demo application requests",
    unit="1"
)

# --------------------------------------------------
# FastAPI application
# --------------------------------------------------

app = FastAPI()

FastAPIInstrumentor.instrument_app(app)


# --------------------------------------------------
# Endpoints
# --------------------------------------------------

@app.get("/")
def home():
    return {
        "message": "Hello from OpenTelemetry demo",
        "service": "demo-app"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }


@app.get("/users")
def users():

    request_counter.add(1, {
        "endpoint": "/users"
    })

    time.sleep(random.uniform(0.05, 0.5))

    return {
        "users": [
            {"id": 1, "name": "John"},
            {"id": 2, "name": "Sarah"},
            {"id": 3, "name": "David"}
        ]
    }


@app.get("/orders")
def orders():

    request_counter.add(1, {
        "endpoint": "/orders"
    })

    time.sleep(random.uniform(0.1, 1.0))

    return {
        "orders": [
            {"id": 101, "amount": 100},
            {"id": 102, "amount": 250}
        ]
    }

@app.get("/error") 
def error():

    raise Exception("Something went wrong!")
