FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY main.py .


# change port for reach Dockerfile here
EXPOSE 1340

CMD ["python", "main.py"]