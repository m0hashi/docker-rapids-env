#================================================================================
# Make conda base environment
#================================================================================
#FROM pytorch/pytorch:1.4-cuda10.1-cudnn7-devel as pytorch-base
#FROM ubuntu:20.04 as anaconda-base
FROM tensorflow/tensorflow:2.2.0-gpu as anaconda-base
SHELL ["/bin/bash", "-c"]

#eNV TZ Asia/Tokyo
#RUN apt-get update \
#  && apt-get install -y tzdata \
#  && rm -rf /var/lib/apt/lists/* \
#  && echo "${TZ}" > /etc/timezone \
#  && rm /etc/localtime \
#  && ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
#  && dpkg-reconfigure -f noninteractive tzdata \
#  && apt-get clean

COPY ./files/apt-packagelist.txt .tmp/
RUN apt-get update --fix-missing && \
    apt-get install -y $(grep -vE "^\s*#" .tmp/apt-packagelist.txt  | tr "\n" " ") && \
    apt-get clean

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean

ARG UNAME
ARG GID
ARG UID 
ARG UPASSWD

RUN groupadd  ${UNAME} -g ${GID}
RUN chgrp -R ${UNAME} /opt/ && \
    chmod 770 -R /opt/
#Add user
RUN echo ${UNAME} ${GID} && \
    useradd -u ${UID} -g ${UNAME} -m ${UNAME} --create-home --shel /bin/bash && \
    usermod -aG sudo ${UNAME} && \
    echo "Set disable_coredump false" >> /etc/sudo.conf && \
    echo ${UNAME}:${UPASSWD} | chpasswd
USER ${UNAME}
WORKDIR /home/${UNAME}

#Install Anaconda
ENV PATH /opt/conda/bin:$PATH
RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh -O ~/anaconda.sh && \
    bash ~/anaconda.sh -b -p  /opt/conda && \
    rm ~/anaconda.sh && \
    echo "PATH=/opt/conda/bin/:$PATH" >> ~/.bashrc && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy

RUN echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64' >> ~/.bashrc
#================================================================================
# Make conda jupyterlab environment
#================================================================================
FROM anaconda-base as dlenv-base


ARG UNAME
#install jupyter lab extensions
#for  details, see -> https://qiita.com/canonrock16/items/d166c93087a4aafd2db4
RUN conda update conda
#RUN source ~/.bashrc && conda install -c conda-forge jupyterlab
RUN pip install --no-cache-dir jupyterlab==2.1.4

COPY --chown=${UNAME}:${UNAME} ./files/jupyterlab-extensions.txt .tmp/
RUN cat .tmp/jupyterlab-extensions.txt | tr '\n' ' ' > .tmp/tmplist && \
   jupyter labextension install `cat .tmp/tmplist`

#install Lightgbm
RUN git clone --recursive https://github.com/microsoft/LightGBM 
RUN mkdir -p LightGBM/build
WORKDIR /home/${UNAME}/LightGBM/build
RUN cmake ..
RUN make -j4
WORKDIR /home/${UNAME}/LightGBM/python-package
RUN python setup.py install
WORKDIR /home/${UNAME}

#install ML library
COPY --chown=${UNAME}:${UNAME} ./files/conda-requirements.txt ./files/pip-requirements.txt ./files/anaconda-requirements.txt ./files/conda-pytorch.txt .tmp/
#RUN conda install -c pytorch --file .tmp/conda-pytorch.txt
RUN pip install --no-cache-dir torch==1.5.0+cu101 torchvision==0.6.0+cu101 -f https://download.pytorch.org/whl/torch_stable.html
RUN conda install -c conda-forge --file .tmp/conda-requirements.txt && \
    conda install -c Anaconda --file .tmp/anaconda-requirements.txt && \
    conda clean --all 
RUN pip install --no-cache-dir -r .tmp/pip-requirements.txt

#================================================================================
# Set startup configurations
#================================================================================
FROM dlenv-base as setup

ARG UNAME
ARG GID
ARG UID 
ARG UPASSWD

USER ${UNAME}
WORKDIR /home/${UNAME}

RUN mkdir ~/.local && \
    mkdir ~/workspace && \
    mkdir ~/.ssh && \
    mkdir ~/.kaggle && \
    mkdir ~/.aws

COPY --chown=${UNAME}:${UNAME} ./files/docker-entrypoint.sh /home/${UNAME}/.local/bin/docker-entrypoint.sh
COPY --chown=${UNAME}:${UNAME} ./files/.gitconfig /home/${UNAME}/

USER root
RUN echo "PATH=/opt/conda/bin/:$PATH" >> /root/.bashrc && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /root/.bashrc && \
    echo "conda activate base" >> /root/bashrc 
RUN echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64' >> /root/.bashrc

RUN chown ${UNAME}:${UNAME} /home/${UNAME}/.gitconfig /home/${UNAME}/.local/bin/docker-entrypoint.sh && \
    mkdir /var/run/sshd


FROM setup
CMD /bin/bash
