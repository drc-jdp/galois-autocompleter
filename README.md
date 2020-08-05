# Usage
```sh
sudo docker run -d -p 2222:22 -p 3030:3030 --name dtp yqchenee/dtp-tensorflow:{tag}
sudo docker exec -it dtp bash
```
# TODO
*   VScode extension .vsix
*   model training ci in tsmc (cannot train in lab)
*   auto-complete running on server ci
*   pytest benchmark for each model