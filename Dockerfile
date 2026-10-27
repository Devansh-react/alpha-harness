# syntax=docker/dockerfile:1

FROM node:22-alpine AS frontend-builder
WORKDIR /workspace

COPY frontend ./frontend
COPY backend ./backend

WORKDIR /workspace/frontend
RUN corepack enable && pnpm install --frozen-lockfile
ENV ALPHA_HARNESS_BACKEND=http://127.0.0.1:8000
RUN pnpm run build

FROM python:3.14-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ALPHA_HARNESS_HOST=0.0.0.0 \
    ALPHA_HARNESS_PORT=8000 \
    ALPHA_HARNESS_HEADLESS=1
WORKDIR /app

RUN pip install --no-cache-dir uv

COPY backend ./backend
COPY --from=frontend-builder /workspace/backend/src/alpha_harness/web ./backend/src/alpha_harness/web

RUN cd /app/backend && uv sync --locked --no-dev

EXPOSE 8000

CMD ["sh", "-lc", "cd /app/backend && uv run python -m alpha_harness"]
