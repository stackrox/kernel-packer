FROM registry.access.redhat.com/ubi8/python-39:1-27

COPY requirements.txt .

RUN pip install -r requirements.txt && \
    rm requirements.txt

COPY crawler.py .

CMD python crawler.py
