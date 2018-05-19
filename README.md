# Weaviate Vectors

These bash files generate the CBOR files used by Weaviate based on the [GloVe Algo](https://nlp.stanford.edu/pubs/glove.pdf).

Run:

```
$ chmod +x *.sh
$ nohup ./createVectors.sh
```

# Google Cloud

- Machine: (14 vCPUs, 450 GB memory) 250gig
- Should render within 24 hours so preemptive is possible.
- Make sure to enable storage API for the instance (Full)
- Make sure to enable compute engine API for the instance (Read/Write)