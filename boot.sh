#!/bin/bash
/bin/bash download_model.sh $1
python main.py &
/usr/sbin/sshd -D