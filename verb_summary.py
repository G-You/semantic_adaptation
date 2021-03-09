import re, codecs, os, spacy, nltk, fnmatch, csv, argparse, pickle
from nltk.corpus.reader import CHILDESCorpusReader
from collections import Counter

##########################
# Load spaCy English model
##########################
#nlp = spacy.load('en_core_web_lg', disable=['ner'])

##################################
# Collect the Manchester filenames
##################################


# Function for generator to push lines of BNC
def TextLoader(file_locations, cds):
    verb_counter = {}

    for loc in file_locations:
        dir = re.sub(r"(.+/)[^/]+$", r"\1", loc)
        fileid = re.sub(r".+/([^/]+)$", r"\1", loc)
        corpus = CHILDESCorpusReader(dir, fileid)
        age = corpus.age(fileids = fileid, month=True)
        name = loc.split("/")[-2]
        if name not in verb_counter:
            verb_counter[name] = {}

        if (cds == True):
            spkrs = [spkr for spkr in corpus.participants(fileid)[0].keys() \
                 if spkr != "CHI"]
        else:
            spkrs = ["CHI"]
        #sents = corpus.sents(speaker = spkrs)
        tagged_words = corpus.tagged_words(speaker = spkrs, stem=True, replace=True)
        words = [word[0] for word in tagged_words if (len(word[1])>0 and word[1][0] == "v")]

        try:
            age = int(age[0])
            if age not in verb_counter[name]:
                verb_counter[name][age] = Counter(words)
            else:
                verb_counter[name][age] += Counter(words)
        except:
            None
        '''
        for word in words:
            if (word[1][0] == "v"):
                yield(word[0], age[0], name)
                '''
            #cleaned_sent = []
            #for stem in s:
                #stem = re.sub(r'-[^~]+', "", stem)
                #if "~" in stem:
                    #cleaned_sent += stem.split("~")
                #else:
                    #cleaned_sent.append(stem)

            #yield (" ".join(s), age[0], name)
    return verb_counter

'''
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


    '''
def FileidReader(in_root):
    
    man_fileids = []

    for root, dirnames, filenames in os.walk(in_root):
        for filename in fnmatch.filter(filenames, '*.xml'):
            man_fileids.append(os.path.join(root, filename))

    man_fileids = sorted(man_fileids)
    return man_fileids

def merge_verb_counters(counters, merge_size):

    merged_counter = {}
    for child in counters:
        merged_counter[child] = {}
        for age in counters[child]:
            try:
                merged_counter[child][age] = counters[child][age]
                for i in range(1,merge_size+1):
                    merged_counter[child][age] += counters[child][age-i]
            except:
                merged_counter[child].pop(age,None)

    return merged_counter

def main():

    root = "/Users/guanghao/Documents/UZH/CHILDES/Manchester"
    fileids = FileidReader(root)

    # get verb counters for each age 

    # argparser
    parser = argparse.ArgumentParser()
    parser.add_argument("--merge_size", default=2, type=int, 
        help="number of sessions to be merged")
    parser.add_argument("--reg", default="cds", type=str,
        help="cds or child")
    args = parser.parse_args()

    verbs = TextLoader(fileids, args.reg=="cds")
    with open("verbs/"+args.reg+"_verbs.pickle","wb+") as f:
        pickle.dump(merge_verb_counters(verbs, args.merge_size), f)


main()


#parse_cds = open("cds_corpus.csv", "w+")
#parse_child = open("child_corpus.csv", "w+")
#cds_writer = csv.writer(parse_cds, delimiter="\t")
#child_writer = csv.writer(parse_child, delimiter="\t")
'''
for doc, age, name in texts_cds:
    #cds_writer.writerow([doc, age, name])
    CorpusWriter(1, doc, age, name)

for doc, age, name in texts_child:
    #child_writer.writerow([doc, age, name])
    CorpusWriter(0, doc, age, name)
'''

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

