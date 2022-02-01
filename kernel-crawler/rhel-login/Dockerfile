FROM registry.access.redhat.com/ubi8/ubi:8.5

RUN yum --disablerepo='*' makecache \
 && yum install -y subscription-manager

# Obtained via https://access.redhat.com/labs/rhpc
COPY 69.pem /etc/pki/product-default/69.pem
COPY 290.pem /etc/pki/product/290.pem

COPY entrypoint /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
