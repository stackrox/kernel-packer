FROM python:3.7-slim as unittest

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    git \
 && rm -rf /var/lib/apt \
 && pip install --no-cache-dir \
    lxml==4.2.4 urllib3==1.26.3

COPY ["kernel-crawler.py", "/"]
COPY ["tests/crawler.py", "/"]
RUN python3 /crawler.py
