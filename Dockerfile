FROM tensorflow/tensorflow:1.15.2-gpu-py3-jupyter
ARG DEFAULT_DOWNLOAD_MODEL
ENV DOWNLOAD_MODEL=${DEFAULT_DOWNLOAD_MODEL}

RUN apt-get update 
RUN apt-get install -y openssh-server
#RUN apt-get install -y vsftpd
RUN apt-get install -y net-tools
RUN apt-get install -y vim
RUN apt-get install -y sudo
RUN apt-get install -y --no-install-recommends curl

WORKDIR /

# user tensorflow
RUN useradd -m -G sudo -s /bin/bash -d /home/tensorflow tensorflow
RUN echo tensorflow:tensorflow | chpasswd 

# build SSH server
RUN mkdir /var/run/sshd

RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile 
# sftp server
RUN sed -i '$aMatch group tensorflow\nAllowTcpForwarding yes' /etc/ssh/sshd_config
RUN sed -i 's\^Subsys.*$\Subsystem sftp internal-sftp /usr/lib/openssh/sftp-server\ ' /etc/ssh/sshd_config
EXPOSE 22 

# boot up and setting files
COPY boot.sh /bin
COPY .setenv /
RUN cat .setenv >> /etc/bash.bashrc

RUN mkdir /home/tensorflow/galois
WORKDIR /home/tensorflow/galois
COPY *.py ./
COPY requirements.txt .
RUN pip install -r requirements.txt
RUN chown tensorflow *

RUN mkdir model
COPY download_model.sh .
# if nothing input, download model from 
# https://medium.com/@ngwaifoong92/beginners-guide-to-retrain-gpt-2-117m-to-generate-custom-text-content-8bb5363d8b7f

EXPOSE 3030
CMD /bin/bash /bin/boot.sh ${DOWNLOAD_MODEL:-} 