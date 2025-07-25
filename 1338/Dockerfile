FROM public.ecr.aws/q6s4e1n8/nukudo/rate-limiter-python3.11 

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY main.py .


# change port for reach Dockerfile here
EXPOSE 1338

CMD ["python", "main.py"]