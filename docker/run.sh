#!/bin/bash

sudo docker stop ftp && sudo docker rm ftp
sudo docker run -d -p 2220:21 -p 2222:22 -p 40000-40010:40000-40010 --name ftp ftpserver
sudo docker exec -it ftp bash