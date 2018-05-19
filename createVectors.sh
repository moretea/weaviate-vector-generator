#!/bin/bash

##
# This script creates the Weaviate vectors
##

# Install python3 and python2 deps
sudo apt-get update
sudo apt-get -y install unzip gcc make python-setuptools python-dev build-essential python3-pip

# Install packages for python2 & 3
pip3 install numpy gensim
pip install numpy

# Get most recent corpi
wget https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles.xml.bz2

# Take enwiki-latest-pages-articles.xml.bz2 as input and output enwiki-latest-pages-articles.txt
python3 <<EOL
import sys
from gensim.corpora import WikiCorpus

output = open("enwiki-latest-pages-articles.txt", 'w')
wiki = WikiCorpus("enwiki-latest-pages-articles.xml.bz2")

i = 0
for text in wiki.get_texts():
    output.write(bytes(' '.join(text), 'utf-8').decode('utf-8') + '\n')
    i = i + 1
    if (i % 1000 == 0):
        print('Processed ' + str(i) + ' articles')
output.close()
print('Processed ' + str(i) + ' articles')
print('Processing complete!')
EOL

# Download and unzip GloVe
wget https://github.com/stanfordnlp/GloVe/archive/master.zip && \
unzip master.zip && \
mv GloVe-master/* ./

# Render vectors
make

# Set VARs
CORPUS=enwiki-latest-pages-articles.txt
VOCAB_FILE=vocab.txt
COOCCURRENCE_FILE=cooccurrence.bin
COOCCURRENCE_SHUF_FILE=cooccurrence.shuf.bin
BUILDDIR=build
SAVE_FILE=vectors
VERBOSE=2
MEMORY=350.0
VOCAB_MIN_COUNT=6
VECTOR_SIZE=300
MAX_ITER=28
WINDOW_SIZE=15
BINARY=2
NUM_THREADS=8
X_MAX=10

# Run!
echo "$ $BUILDDIR/vocab_count -min-count $VOCAB_MIN_COUNT -verbose $VERBOSE < $CORPUS > $VOCAB_FILE"
$BUILDDIR/vocab_count -min-count $VOCAB_MIN_COUNT -verbose $VERBOSE < $CORPUS > $VOCAB_FILE
echo "$ $BUILDDIR/cooccur -memory $MEMORY -vocab-file $VOCAB_FILE -verbose $VERBOSE -window-size $WINDOW_SIZE < $CORPUS > $COOCCURRENCE_FILE"
$BUILDDIR/cooccur -memory $MEMORY -vocab-file $VOCAB_FILE -verbose $VERBOSE -window-size $WINDOW_SIZE < $CORPUS > $COOCCURRENCE_FILE
echo "$ $BUILDDIR/shuffle -memory $MEMORY -verbose $VERBOSE < $COOCCURRENCE_FILE > $COOCCURRENCE_SHUF_FILE"
$BUILDDIR/shuffle -memory $MEMORY -verbose $VERBOSE < $COOCCURRENCE_FILE > $COOCCURRENCE_SHUF_FILE
echo "$ $BUILDDIR/glove -save-file $SAVE_FILE -threads $NUM_THREADS -input-file $COOCCURRENCE_SHUF_FILE -x-max $X_MAX -iter $MAX_ITER -vector-size $VECTOR_SIZE -binary $BINARY -vocab-file $VOCAB_FILE -verbose $VERBOSE"
$BUILDDIR/glove -save-file $SAVE_FILE -threads $NUM_THREADS -input-file $COOCCURRENCE_SHUF_FILE -x-max $X_MAX -iter $MAX_ITER -vector-size $VECTOR_SIZE -binary $BINARY -vocab-file $VOCAB_FILE -verbose $VERBOSE
if [ "$CORPUS" = 'text8' ]; then
   if [ "$1" = 'matlab' ]; then
       matlab -nodisplay -nodesktop -nojvm -nosplash < ./eval/matlab/read_and_evaluate.m 1>&2 
   elif [ "$1" = 'octave' ]; then
       octave < ./eval/octave/read_and_evaluate_octave.m 1>&2
   else
       echo "$ python eval/python/evaluate.py"
       python eval/python/evaluate.py
   fi
fi

# Create GZIP CBOR file
wget https://storage.googleapis.com/weaviate-vectors/bin/csvToCbor && \
chmod +x csvToCbor && \
./csvToCbor

# Create MD5
md5sum vectors.cbor.gz | awk '{ print $1 }' > md5.txt

# create distro folder
mkdir distro && \
mv vectors.cbor.gz ./distro/vectors.cbor.gz && \
mv md5.txt ./distro/md5.txt

# Send distro to Google Storage Bucket
cd distro
gsutil rm gs://weaviate-vectors/*
gsutil cp *.* gs://weaviate-vectors
gsutil acl ch -u AllUsers:R gs://weaviate-vectors/*.*

# All is done, shut down Gcloud
gcloud -q compute instances delete $(curl "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google") --zone $(curl "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google") --delete-disks all