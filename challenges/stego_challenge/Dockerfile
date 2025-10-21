FROM python:3.11-slim
WORKDIR /app
COPY app.py challenge.txt flag.enc /app/
RUN pip install Flask pycryptodomex
EXPOSE 8080
CMD ["python3","app.py"]
