FROM registry.access.redhat.com/ubi8/ubi:8.5

ARG REDHAT_USERNAME

RUN --mount=type=secret,id=REDHAT_PASSWORD \
    subscription-manager register --username "${REDHAT_USERNAME}" --password "$(</run/secrets/REDHAT_PASSWORD)" && \
	subscription-manager attach && \
    subscription-manager list --available && \
	# this pool id may be associated with the current test user account.
	# if the account changes, use: `subscription-manager list --available` to find a valid id.
	subscription-manager attach --pool=8a85f9a178d12e760178dba5bb1d2b43 && \
	dnf config-manager --enable rhel-8-for-x86_64-baseos-rpms && \
	dnf config-manager --enable rhel-8-for-x86_64-appstream-rpms && \
	dnf -y update && \
	dnf -y install \
        bison \ 
        binutils \ 
        bzip2 \
        clang-7.0.1 \
        cmake \
        cpio \
        elfutils-libelf \
        elfutils-libelf-devel \
        flex \
        gcc-c++ \
        git \
        kmod \
        llvm-7.0.1 \
        make \
        openssl-devel \
        patch \
        pigz \
        python3 \
        rsync && \
        zstd && \
    ln -s /usr/bin/gcc /usr/bin/gcc-8 && \
    subscription-manager remove --all && \
    subscription-manager unregister && \
    subscription-manager clean

COPY includes /etc/includes

COPY entrypoint /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
