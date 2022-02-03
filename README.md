# gcp-test
1. create workspace, API driven
2. 

## Registering a new device

    gcloud auth login

    gcloud config set project <project ID>

    openssl ecparam -genkey -name prime256v1 -noout -out ec_private.pem
    
    openssl ec -in ec_private.pem -pubout -out ec_public.pem

    gcloud iot devices create arduino-reader --region=us-central1 --registry=arduino-registry --public-key path=ec_public.pem,type=es256