#!/bin/bash
/bin/bash download_model.sh $1 > .docker_log
python main.py &
/usr/sbin/sshd -D