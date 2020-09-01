#!/bin/bash
/bin/bash download_model.sh $1 > .docker_log
/usr/sbin/sshd
python main.py