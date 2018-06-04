# Weaviate Vectors

These bash files generate the CBOR files used by Weaviate based on the [GloVe Algo](https://nlp.stanford.edu/pubs/glove.pdf).

Run:

```
$ chmod +x *.sh
$ nohup ./createVectors.sh
```

# Download CBOR files

- EN: https://storage.googleapis.com/weaviate-vectors/vectors-en-300.cbor.gz
- EN MD5 :https://storage.googleapis.com/weaviate-vectors/vectors-en-300.md5
- DE: https://storage.googleapis.com/weaviate-vectors/vectors-de-300.cbor.gz
- DE MD5: https://storage.googleapis.com/weaviate-vectors/vectors-de-300.md5
- NL: https://storage.googleapis.com/weaviate-vectors/vectors-nl-300.cbor.gz
- NL MD5: https://storage.googleapis.com/weaviate-vectors/vectors-nl-300.md5

Vectors saved as: `type Vectors map[string][]float64`

# Google Cloud

- Machine: (14 vCPUs, 450 GB memory) 250gig
- Should render within 24 hours so preemptive is possible.
- Make sure to enable storage API for the instance (Full)
- Make sure to enable compute engine API for the instance (Read/Write)

```
gcloud beta compute --project=some_project instances create vectors-creator --zone=us-west1-b --machine-type=custom-14-460800-ext --subnet=default --network-tier=PREMIUM --metadata=startup-script=\#\!/bin/bash$'\n'wget\ https://raw.githubusercontent.com/creativesoftwarefdn/weaviate-vector-generator/master/createVectors.sh$'\n'chmod\ \+x\ createVectors.sh$'\n'./createVectors.sh --no-restart-on-failure --maintenance-policy=TERMINATE --preemptible --service-account=something@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.full_control --image=ubuntu-1804-bionic-v20180426b --image-project=ubuntu-os-cloud --boot-disk-size=250GB --boot-disk-type=pd-standard --boot-disk-device-name=vectors-creator
```

_Note I: Change `some_project` to your project id!_
_Note II: Change `something@developer.gserviceaccount.com` to your service account!_
_Note III: Logs: /var/log/syslog_
