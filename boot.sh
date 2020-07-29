#!/bin/bash
vsftpd &
/usr/sbin/sshd &
python main.py -D