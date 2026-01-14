FROM python:3.12-slim AS builder

WORKDIR /backend
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN python -m pip install --upgrade pip && \
    pip install --prefix=/install --no-cache-dir --no-warn-script-location -r requirements.txt

COPY . .

# stage two , production
FROM python:3.12-slim


WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1


RUN apt-get update && \
    apt-get install -y --no-install-recommends libgomp1 && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r appuser && useradd -r -g appuser appuser
    
COPY --from=builder /install /usr/local
COPY --from=builder /backend /app

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4000/health || exit 1

ENV APP_MODULE=app.main:app PORT=4000 PYTHONPATH=/app:/app/backend
CMD ["/bin/sh", "-c", "python -m uvicorn ${APP_MODULE} --host 0.0.0.0 --port ${PORT}"]
CMD ["/bin/sh", "-c", "python -m uvicorn ${APP_MODULE} --host 0.0.0.0 --port ${PORT}"]


