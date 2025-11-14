FROM python:3.12-slim AS builder

WORKDIR /backend

RUN apt-get update && \
    apt-get install -y build-essential gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --prefix=/install --no-warn-script-location -r requirements.txt


COPY . .

# stage two , production

FROM python:3.12-slim

WORKDIR /backend

COPY  --from=builder /install /usr/local

COPY --from=builder . .

EXPOSE 4000


