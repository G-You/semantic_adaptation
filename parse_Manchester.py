import re, codecs, os, spacy, nltk, fnmatch, csv
from nltk.corpus.reader import CHILDESCorpusReader

##########################
# Load spaCy English model
##########################
#nlp = spacy.load('en_core_web_lg', disable=['ner'])

##################################
# Collect the Manchester filenames
##################################
out_root = "/Users/guanghao/Documents/UZH/CHILDES/Manchester"
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
        #sents = corpus.sents(speaker = spkrs)
        sents = corpus.sents(speaker = spkrs, stem=True, replace=True)
        for s in sents:
            #cleaned_sent = []
            #for stem in s:
                #stem = re.sub(r'-[^~]+', "", stem)
                #if "~" in stem:
                    #cleaned_sent += stem.split("~")
                #else:
                    #cleaned_sent.append(stem)

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

#parse_cds = open("cds_corpus.csv", "w+")
#parse_child = open("child_corpus.csv", "w+")
#cds_writer = csv.writer(parse_cds, delimiter="\t")
#child_writer = csv.writer(parse_child, delimiter="\t")

for doc, age, name in texts_cds:
    #cds_writer.writerow([doc, age, name])
    CorpusWriter(1, doc, age, name)

for doc, age, name in texts_child:
    #child_writer.writerow([doc, age, name])
    CorpusWriter(0, doc, age, name)


'''
for doc, fileid in texts:
    print()

for doc, fileid in texts:
    try:
        proc = nlp(doc)
        success = True
    except:
        proc = doc
        unprocessed_lines += 1
        success = False
    index = 0
    for w in proc:
        index += 1
        if success:
            form = w.orth_
            lemma = w.lemma_
            basic_tag = w.pos_
            refined_tag = w.tag_
            head_index = str(w.head.i)
            dependency = w.dep_
        else:
            form = w
            try:
                word_proc = nlp(w)
                lemma = word_proc.lemma_
                basic_tag = w.pos_
                refined_tag = w.tag_
                head_index = u"NA"
                dependency = u"NA"
            except:
                lemma = u"NA"
                basic_tag = u"NA"
                refined_tag = u"NA"
                head_index = u"NA"
                dependency = u"NA"
        parse_out.write(str(index) + u"\t" + form + u"\t" + lemma + u"\t" + basic_tag + u"\t" + refined_tag + u"\t" + u"NA" + u"\t" + head_index + u"\t" + dependency + u"\t" + fileid + u"\n")

    if (fileid != prev_fileid):
        print(fileid)
        prev_fileid = fileid

'''

#parse_out.close()

