import re, codecs, os, nltk, fnmatch, csv
from nltk.corpus.reader import CHILDESCorpusReader


##################################
# Collect the Manchester filenames
##################################
out_root = "data"
man_fileids = []

for root, dirnames, filenames in os.walk(out_root):
    for filename in fnmatch.filter(filenames, '*.xml'):
        man_fileids.append(os.path.join(root, filename))

man_fileids = sorted(man_fileids)

# Function for generator to push lines of BNC
def TextLoader(file_locations, cds):
    for loc in file_locations:
        dir = re.sub(r"(.+/)[^/]+$", r"\1", loc)
        fileid = re.sub(r".+/([^/]+)$", r"\1", loc)
        corpus = CHILDESCorpusReader(dir, fileid)
        age = corpus.age(fileids = fileid, month=True)
        name = loc.split("/")[-2]
        if (cds == 1):
            spkrs = [spkr for spkr in corpus.participants(fileid)[0].keys() \
                 if spkr != "CHI"]
        else:
            spkrs = ["CHI"]
        
        sents = corpus.sents(speaker = spkrs, stem=True, replace=True)
        for s in sents:

            yield (" ".join(s), age[0], name)

def CorpusWriter(cds, doc, age, name):

    if (doc.split()==[]):
        return
    else:
        doc = "^^ " + doc + " $$"

    if (cds == 1):
        write_file = open("cds/"+name+"_"+str(age)+".txt","a+")
    else:
        write_file = open("child/"+name+"_"+str(age)+".txt","a+")

    write_file.write(doc+"\n")


texts_cds = TextLoader(man_fileids, 1)
texts_child = TextLoader(man_fileids, 0)


for doc, age, name in texts_cds:
    #cds_writer.writerow([doc, age, name])
    CorpusWriter(1, doc, age, name)

for doc, age, name in texts_child:
    #child_writer.writerow([doc, age, name])
    CorpusWriter(0, doc, age, name)



