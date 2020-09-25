echo $1 | sudo -S /usr/sbin/sshd && \
. /opt/conda/etc/profile.d/conda.sh && \
conda activate rapids && \
jupyter-lab --port 8888 --ip 0.0.0.0 --allow-root --notebook-dir=~/workspace \
--NotebookApp.token='' --no-browser
