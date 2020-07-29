
```sh
sudo docker run -d -p 2222:22 -p 2221:21 -p 40000-40010:40000-40010 -p 3030:3030 --name dtp yqchenee/dtp-tensorflow:{tag}
sudo docker exec -it dtp bash
```
