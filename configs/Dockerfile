#================================================================================
# Make conda base environment
#================================================================================
FROM rapidsai/rapidsai-dev:0.15-cuda10.1-devel-ubuntu18.04-py3.7 as anaconda-base
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
#Add user
RUN echo ${UNAME} ${GID} && \
    useradd -u ${UID} -g ${UNAME} -m ${UNAME} --create-home --shel /bin/bash && \
    usermod -aG sudo ${UNAME} && \
    echo "Set disable_coredump false" >> /etc/sudo.conf && \
    echo ${UNAME}:${UPASSWD} | chpasswd

USER ${UNAME}
WORKDIR /home/${UNAME}

RUN echo "export PATH=/opt/conda/bin/:$PATH" >> /home/${UNAME}/.bashrc &&\
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /home/${UNAME}/.bashrc &&\
    echo "conda activate rapids" >> /home/${UNAME}/.bashrc

RUN echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64' >> ~/.bashrc
#================================================================================
# Make conda jupyterlab environment
#================================================================================
FROM anaconda-base as dlenv-base


ARG UNAME

#activate conda rapids as a new shell
#https://pythonspeed.com/articles/activate-conda-dockerfile/
SHELL ["conda", "run", "-n","rapids","/bin/bash", "-c"]
RUN conda install -c anaconda pip
RUN conda info -e
RUN pwd
RUN pip install --no-cache-dir jupyterlab==2.1.4

COPY --chown=${UNAME}:${UNAME} ./files/jupyterlab-extensions.txt .tmp/
RUN cat .tmp/jupyterlab-extensions.txt | tr '\n' ' ' > .tmp/tmplist
RUN ls .tmp/
RUN jupyter labextension install `cat .tmp/tmplist`
#RUN cat .tmp/jupyterlab-extensions.txt | tr '\n' ' ' > .tmp/tmplist && \
#   jupyter labextension install `cat .tmp/tmplist`

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

RUN conda install -c conda-forge --file .tmp/conda-requirements.txt 
#RUN    conda install -c Anaconda --file .tmp/anaconda-requirements.txt 
RUN conda clean --all 
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

RUN echo ". /opt/conda/etc/profile.d/conda.sh" >> /home/${UNAME}/.bashrc &&\
    echo "conda activate rapids" >> /home/${UNAME}/.bashrc

USER root
RUN echo "PATH=/opt/conda/bin/:$PATH" >> /root/.bashrc && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /root/.bashrc && \
    echo "conda activate rapids" >> /root/bashrc 
RUN echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64' >> /root/.bashrc

RUN chown ${UNAME}:${UNAME} /home/${UNAME}/.gitconfig /home/${UNAME}/.local/bin/docker-entrypoint.sh && \
    mkdir /var/run/sshd


FROM setup
CMD /bin/bash
