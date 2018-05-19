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