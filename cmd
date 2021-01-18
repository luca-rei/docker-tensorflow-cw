docker build -t my-cw-ubuntu .
docker run --rm -it --cap-add SYS_ADMIN --device /dev/fuse --privileged -v /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro my-cw-ubuntu /bin/bash
