FROM python:3.10-slim

# Copy everything into /app
WORKDIR /app
COPY ./app /app/app
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# ✅ Set PYTHONPATH so that `app` is recognized as a top-level module
ENV PYTHONPATH=/app

# ✅ Run from top-level and import app.main:app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]