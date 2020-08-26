
download_model()
{
    if ! curl "$1" > "$2" ; then
        exit 1
    fi
}

if [ -z "$1" ]; then
    if [ -f "model/checkpoint" ]; then
        echo "model exist"
    else
        echo "please give env variable to docker"
    fi
elif [ "$1" = "gpt-2" ]; then
    curl http://storage.googleapis.com/gpt-2/models/117M/checkpoint > model/checkpoint
    curl http://storage.googleapis.com/gpt-2/models/117M/encoder.json > model/encoder.json
    curl http://storage.googleapis.com/gpt-2/models/117M/hparams.json > model/hparams.json
    curl http://storage.googleapis.com/gpt-2/models/117M/model.ckpt.data-00000-of-00001 > model/model.ckpt.data-00000-of-00001
    curl http://storage.googleapis.com/gpt-2/models/117M/vocab.bpe > model/vocab.bpe
    curl http://storage.googleapis.com/gpt-2/models/117M/model.ckpt.meta > model/model.ckpt.meta
    curl http://storage.googleapis.com/gpt-2/models/117M/model.ckpt.index > model/model.ckpt.index
else 
    echo "download model from $1"
    download_model "$1"/checkpoint model/checkpoint
    download_model "$1"/encoder.json model/encoder.json
    download_model "$1"/hparams.json model/hparams.json
    download_model "$1"/model.ckpt.data-00000-of-00001 model/model.ckpt.data-00000-of-00001
    download_model "$1"/vocab.bpe model/vocab.bpe
    download_model "$1"/model.ckpt.meta model/model.ckpt.meta
    download_model "$1"/model.ckpt.index model/model.ckpt.index
fi
