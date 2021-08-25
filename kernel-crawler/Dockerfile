FROM golang:1.16 AS build

COPY main.go /go/src/main.go

RUN CGO_ENABLED=0 go build -o /go/bin/rhel-crawler /go/src/main.go

ARG p7zip="v17.03"
RUN wget "https://github.com/jinfeihan57/p7zip/archive/${p7zip}.tar.gz" \
 && mkdir p7zip && tar xzf "${p7zip}.tar.gz" -C p7zip --strip-components=1 \
 && cd p7zip && make -j 4 all3 && make install

FROM python:3.7-slim

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    python3-lxml \
    python3-urllib3 \
    git \
 && rm -rf /var/lib/apt

RUN pip install --no-cache-dir \
    lxml==4.2.4 urllib3==1.26.3

COPY ["kernel-crawler.py", "/"]
COPY ["repo-crawler.py", "/"]
COPY ["kope.io.asc", "/"]
COPY ["gardenlinux-crawler.sh", "/"]
COPY ["docker-desktop-filter-kernels.sh", "/"]
COPY --from=build /go/bin/rhel-crawler /usr/bin/rhel-crawler
COPY --from=build /usr/local/bin/7z* /usr/local/bin/
COPY --from=build /usr/local/lib/p7zip /usr/local/lib/p7zip

ENTRYPOINT ["python3", "kernel-crawler.py"]
