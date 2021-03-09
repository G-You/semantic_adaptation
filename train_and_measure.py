import os, random, fnmatch, csv, argparse, math, warnings, pickle, statistics
import matplotlib.pyplot as plt
import networkx as nx
from gensim.models import Word2Vec as we
from networkx import betweenness_centrality, diameter
from statsmodels.distributions.empirical_distribution import ECDF

warnings.filterwarnings("ignore", category=UserWarning)
random.seed(42)

parser = argparse.ArgumentParser()
parser.add_argument("--reg", default="cds", type=str, help="speech register")
parser.add_argument("--build", default=False, action="store_true", help="whether or not to build embeddings")
args = parser.parse_args()

def form_graph(edges):
	G = nx.Graph()
	G.add_edges_from(edges)
	return G

def clean_nodes(graph):
	remove_node_set = []
	for node in graph.nodes():
		if (len(list(graph.neighbors(node)))==1):
			remove_node_set.append(node)
	for node in remove_node_set:
		graph.remove_node(node)
	return graph

def get_degree(graph):
	degrees = graph.degree()
	target_degrees = []
	target_degrees = [d[1] for d in degrees]
	if (len(target_degrees)!=0):
		return sum(target_degrees)/len(target_degrees)
	else:
		return 0.0

def read_sents(f):
	reader = open(f,"r")
	sents = [sent.split() for sent in reader if len(sent)>0]
	return sents

def initiate_we(sents, name):
	model = we(sentences=sents, size=200, window=1, min_count=2, workers=1, iter=100, sg=1)
	model.save(args.reg+"/models/"+name)
	return len(model.wv.vocab)

def train_we(sents, name):
	model = we.load(args.reg+"/models/"+name)
	model.build_vocab(sents, update=True)
	model.train(sentences=sents, total_examples=len(sents),epochs=model.epochs)
	model.save(args.reg+"/models/"+name)
	return len(model.wv.vocab)

def we_on_merged_sessions(sents, name):
	model = we(sentences=sents, size=200, window=1, min_count=2, workers=1, iter=100, sg=1)
	model.save("merged-"+args.reg+"/models/"+name)
	return len(model.wv.vocab)

def get_filenames(out_root):
	fileids = []
	for root, dirnames, filenames in os.walk(out_root):
		for filename in fnmatch.filter(filenames, '*.txt'):
			fileids.append(os.path.join(root, filename))
	return (sorted(fileids))

def get_largest_subgraph(graph):

	Gcc = sorted(nx.connected_components(graph), key=len, reverse=True)
	try:
		largest_G = graph.subgraph(Gcc[0])
	except:
		largest_G = graph

	return largest_G

def get_diameter(graph):

	d = diameter(graph)
	nodes = graph.number_of_nodes()
	if (nodes == 0):
		return 1
	else:
		return d/nodes

def get_measure(nodes):

	edges = []
	for row in nodes:
		edges += [(row[0],row[i]) for i in range(1, len(row))]

	G = form_graph(edges)
	G = clean_nodes(G)

	largest_G = get_largest_subgraph(G)

	#return largest_G.number_of_nodes()
	return largest_G.number_of_edges()
	#return get_degree(G)
	#return get_degree(largest_G)


def get_similarity(name, age, reg):
	embeddings = "merged-"+args.reg+"/models/" + name+"-"+age
	caus_list = ['begin', 'boil', 'break', 'burn', 'change', 'close', 'destroy', 'dry', 'fill', 'finish', 'freeze', 'gather', 'kill', 'lose', 'melt', 'open', 'raise', 'roll', 'sink', 'spread', 'stop', 'teach', 'turn']
	model = we.load(embeddings)

	vocab_size = len(model.wv.vocab)
	# ratio
	n = math.ceil(vocab_size/50)
	#n = math.ceil(math.log2(vocab_size))

	vocab = list(model.wv.vocab.keys())
	#write_f = open("merged-"+args.reg+"/results/"+name+"-"+age+".csv","w+")
	#result_writer = csv.writer(write_f, delimiter="\t")
	# how many causatives are there in each network
	caus_counter = 0
	similar_words_total = []

	# the caus graph
	for caus in caus_list:
		if caus not in vocab:
			continue

		similar_words = [row[0] for row in model.wv.most_similar(caus, topn=n)]
		#print([row[1] for row in model.wv.most_similar(caus, topn=n)])
		#result_writer.writerow([caus]+similar_words)
		caus_counter += 1
		similar_words_total.append([caus]+similar_words)

	#measure = get_measure(similar_words_total)
	try:
		measure = get_measure(similar_words_total)/caus_counter
	except:
		measure = 0
	
	return caus_counter, measure
	# the random graph

def baseline(name,age,caus_counter, iter, verb_counter,reg):

	embeddings = "merged-"+args.reg+"/models/" + name+"-"+age
	model = we.load(embeddings)
	vocab = list(model.wv.vocab.keys())
	vocab_size = len(model.wv.vocab)
	measures = []
	#n = math.ceil(math.log2(vocab_size))
	n = math.ceil(vocab_size/50)

	verbs = list(verb_counter[name][int(age)].keys())

	for i in range(iter):

		similar_words_total = []

		#random_words = random.sample(vocab, caus_counter) # all words for sampling
		# only sample the verbs
		random_words = random.sample(list(set(vocab)&set(verbs)), caus_counter)
		for word in random_words:
			similar_words = [row[0] for row in model.wv.most_similar(word, topn=n)]
			similar_words_total.append([word]+similar_words)
	
		try:
			measure = get_measure(similar_words_total)/caus_counter
		except:
			measure = 0

		measures.append(measure)

	#return sum(measures)/len(measures)
	return measures


def main():

	prev_child = ""
	### verbs

	with open("verbs/"+args.reg+"_verbs.pickle","rb") as f:
		verb_counter = pickle.load(f)

	fileids = get_filenames("merged-"+args.reg)
	results_file = open("%s_results.csv" % args.reg,"w+")
	results_csvwriter = csv.writer(results_file, delimiter="\t")
	results_csvwriter.writerow(["name","age","causative","random","percentile"])

	for f in fileids:
		print(f)
		name = f.split("/")[-1].split("_")[0]
		age = f.split("_")[1].split(".")[0]
		sents = read_sents(f)

		if (args.build):
			vocab_size = we_on_merged_sessions(sents, name+"-"+age)

		caus_counter, caus_result = get_similarity(name, age,args.reg)
		print(caus_counter)
		#random_result = baseline(name, age, caus_counter)
		random_results = baseline(name, age, caus_counter, 1000, verb_counter, args.reg)
		'''
		try:
			random_result = sum(random_results)/len(random_results)
		except:
			random_result = 0
			'''
		random_result = statistics.median(random_results)
		# percentile of causative in the distribution
		
		percentile = ECDF(random_results)(caus_result)
		
		print(percentile)
		
		results_csvwriter.writerow([name,
			age,
			caus_result,
			random_result,
			percentile])

main()