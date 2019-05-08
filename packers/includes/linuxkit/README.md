Kernel config extracted from docker image `linuxkit/kernel:4.9.125`
 - `docker create --name=kernel-4.9.125 linuxkit/kernel:4.9.125 true`
 - `docker cp kernel-4.9.125:/kernel-dev.tar .`
 - `mkdir ./kernel-dev && tar -C ./kernel-dev -xf ./kernel-dev.tar`
 - `cp ./kernel-dev/usr/src/linux-headers-4.9.125-linuxkit/.config 4.9.125-config`
