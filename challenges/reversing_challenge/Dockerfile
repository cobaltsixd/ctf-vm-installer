FROM ubuntu:22.04
RUN apt-get update && apt-get install -y gcc python3 python3-pip && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY checker.c run.py challenge.txt flag.enc /app/
RUN gcc -O2 -s -o checker checker.c
RUN pip3 install flask pycryptodome
EXPOSE 8080
CMD ["python3","run.py"]
