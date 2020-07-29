FROM tensorflow/tensorflow:1.15.2-gpu-py3-jupyter
# FROM ubuntu:18.04
ARG DOWNLOAD_MODEL

RUN apt-get update 
RUN apt-get install -y openssh-server
RUN apt-get install -y vsftpd
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

EXPOSE 22 

# build ftpserver 
RUN mkdir -p /var/run/vsftpd/empty

RUN mkdir /home/tensorflow/ftpdir
RUN sed -i '$apasv_enable=YES\npasv_min_port=40000\npasv_max_port=40010' /etc/vsftpd.conf
RUN sed -i '$alocal_enable=YES\nlocal_root=/home/tensorflow/ftpdir\nallow_writeable_chroot=YES' /etc/vsftpd.conf
RUN sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf
RUN sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf

RUN chown tensorflow /home/tensorflow/ftpdir/
RUN chgrp tensorflow /home/tensorflow/ftpdir/

EXPOSE 21 40000-40010

# boot up and setting files
COPY boot.sh /bin
COPY .setenv /
RUN cat .setenv >> /etc/bash.bashrc

RUN mkdir /home/tensorflow/ftpdir/galois
WORKDIR /home/tensorflow/ftpdir/galois
COPY *.py ./
COPY requirements.txt .
RUN pip install -r requirements.txt

RUN mkdir model
COPY download_model.sh .
# if nothing input, download model from 
# https://medium.com/@ngwaifoong92/beginners-guide-to-retrain-gpt-2-117m-to-generate-custom-text-content-8bb5363d8b7f
RUN /bin/bash download_model.sh ${DOWNLOAD_MODEL:-} 

EXPOSE 3030
CMD ["/bin/bash", "/bin/boot.sh"]