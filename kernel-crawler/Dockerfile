FROM golang:1.16 AS build

COPY main.go /go/src/main.go

RUN CGO_ENABLED=0 go build -o /go/bin/rhel-crawler /go/src/main.go

ARG p7zip="v17.03"
RUN apt-get update && apt-get install unzip && \
 wget "https://github.com/p7zip-project/p7zip/releases/download/${p7zip}/linux-cmake-p7zip.zip" \
 && unzip linux-cmake-p7zip.zip -d /p7zip

FROM python:3.7-slim

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    python3-lxml \
    python3-urllib3 \
    git \
 && rm -rf /var/lib/apt

COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt && rm -f /tmp/requirements.txt

COPY ["garden-crawler.py", "/"]
COPY ["minikube-crawler.py", "/"]
COPY ["kernel-crawler.py", "/"]
COPY ["repo-crawler.py", "/"]
COPY ["kope.io.asc", "/"]
COPY --from=build /go/bin/rhel-crawler /usr/bin/rhel-crawler
COPY --from=build /p7zip/7z* /usr/local/bin/

ENTRYPOINT ["python3", "kernel-crawler.py"]
