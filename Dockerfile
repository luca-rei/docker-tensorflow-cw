FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu14.04
# https://hub.docker.com/r/nvidia/cuda/
# https://docs.nvidia.com/deeplearning/cudnn/sla/index.html

RUN rm /etc/apt/sources.list.d/cuda.list
RUN rm /etc/apt/sources.list.d/nvidia-ml.list
RUN apt-get update
#RUN apt-get install -y aptitude vim python3-all python3-pip gfal2 gfal2-plugin-gridftp gfal2-plugin-http  gfal2-plugin-lfc gfal2-plugin-rfio gfal2-plugin-srm libxt-dev
RUN apt-get install -y aptitude vim gfal2 gfal2-plugin-gridftp gfal2-plugin-http  gfal2-plugin-lfc gfal2-plugin-rfio gfal2-plugin-srm libxt-dev
RUN echo 'export LD_LIBRARY_PATH=/usr/local/cuda:/usr/local/cuda-10.0/compat/:$LD_LIBRARY_PATH' >> ~/.bashrc

# cvmfs
# https://cernvm.cern.ch/fs/
# https://opensciencegrid.org/docs/worker-node/install-cvmfs/#automount-setup
RUN mkdir /cvmfs
# RUN mkdir -p /cvmfs /hdfs /gpfs /ceph /hadoop
RUN apt-get install -y autofs attr gdb git sysv-rc-conf uuid libossp-uuid16 wget
RUN wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb
RUN dpkg -i cvmfs-release-latest_all.deb
RUN apt-get update
RUN apt-get install -y cvmfs
# missing ligo.osgstorage.org
RUN echo "CVMFS_REPOSITORIES=cms.cern.ch,oasis.opensciencegrid.org" >> /etc/cvmfs/default.local
RUN echo "CVMFS_QUOTA_LIMIT=2000000" >> /etc/cvmfs/default.local
RUN echo "CVMFS_HTTP_PROXY=\"DIRECT\"" >> /etc/cvmfs/default.local
RUN echo "/cvmfs /etc/auto.cvmfs" >> /etc/auto.master
RUN chown cvmfs:cvmfs /cvmfs

# pyenv & tensorflow 13.1
RUN git clone https://github.com/pyenv/pyenv.git ~/.pyenv
RUN echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
RUN echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
RUN echo 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc
RUN mkdir /script
RUN apt-get install -y zlib-bin zlib1g-dev libssl-dev libbz2-dev libreadline-dev libsqlite-dev
COPY script/pyenv /script/pyenv
RUN /script/pyenv

# voms
RUN apt-get install -y voms-clients myproxy

# /usr/local/MATLAB/MATLAB_Runtime/v90/archives
RUN wget https://ssd.mathworks.com/supportfiles/downloads/R2015b/deployment_files/R2015b/installers/glnxa64/MCR_R2015b_glnxa64_installer.zip && \
    unzip MCR_R2015b_glnxa64_installer.zip -d MCR_R2015b_glnxa64 && \
    cd MCR_R2015b_glnxa64 && \
    ./install -mode silent -agreeToLicense yes -outputFile ./install.log && \
    cd .. && \
    rm MCR_R2015b_glnxa64_installer.zip && \
    rm -rf MCR_R2015b_glnxa64

# cronjob & startup script
COPY script/cronjob /script/cronjob
RUN chmod 644 /script/cronjob
RUN crontab /script/cronjob
RUN touch /var/log/cron.log

# regenerate proxy
COPY script/regenerateproxy /script/regenerateproxy
RUN chmod 755 /script/regenerateproxy

# virgo cvmfs
COPY files/virgo.ego-gw.it.conf /cvmfs/config.d/virgo.ego-gw.it.conf

COPY script/startup /script/startup
ENTRYPOINT ["/script/startup"]
