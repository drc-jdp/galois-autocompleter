# Usage
fill in the {url} and {tag}  
url: your model url  
- if url is blank, will check your `/home/tensorflow/galois/model` and find if the file is existed or not
- if url = "gpt-2", download the origin model

----

```sh
sudo docker run -id -p 2222:22 -p 3030:3030 -e DOWNLOAD_MODEL={url} \
-v {_local_dir_to_save_your_model_}:/home/tensorflow/galois/model \
--name dtp yqchenee/dtp-tensorflow:{tag}
```
```sh
sudo docker exec -it dtp bash
```
```sh
curl -X POST   http://localhost:3030/autocomplete   -H 'Content-Type: application/json'   -d '{"text":"your text"}'
```
# TODO
*   VScode extension .vsix
*   model training ci in tsmc (cannot train in lab)
*   auto-complete running on server ci
*   pytest benchmark for each model
