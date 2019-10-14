FROM golang:1.13.1 AS build

COPY main.go /go/src/main.go

RUN CGO_ENABLED=0 go build -o /go/bin/rhel-crawler /go/src/main.go

FROM python:2.7-slim

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    python3>=3.5 \
    python3-lxml \
 && rm -rf /var/lib/apt

RUN pip install --no-cache-dir \
    lxml==4.2.4

COPY ["kernel-crawler.py", "/"]
COPY ["repo-crawler.py", "/"]
COPY ["kope.io.asc", "/"]
COPY --from=build /go/bin/rhel-crawler /usr/bin/rhel-crawler

ENTRYPOINT ["python3", "kernel-crawler.py"]
