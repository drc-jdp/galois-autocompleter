
```sh
sudo docker run -d -p 2220:22 -p 2222:21 -p 40000-40010:40000-40010 -p 3030:3030 --name dtp dtp-tensorflow
sudo docker exec -it dtp bash
```