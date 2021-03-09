import argparse
import os, random, fnmatch, csv
from collections import Counter

def get_filenames(out_root):
	fileids = []
	for root, dirnames, filenames in os.walk(out_root):
		for filename in fnmatch.filter(filenames, '*.txt'):
			fileids.append(os.path.join(root, filename))
	return (sorted(fileids))

def get_args():
	parser = argparse.ArgumentParser()
	parser.add_argument("--reg", default="cds", type=str, help="speech register")
	parser.add_argument("--merge_size", 
		default=2, 
		type=int, 
		help="number of sessions to be merged")
	parser.add_argument("--min_count",
		default=2,
		type=int,
		help="minimum count for vocabulary summary")
	args = parser.parse_args()
	return args

def main():
	args = get_args()
	os.remove("%s_vocab_stats.txt" % args.reg)
	fileids = get_filenames(args.reg)
	#print(fileids)
	for filename in fileids:
		name = filename.split("/")[-1].split("_")[0]
		age = filename.split("_")[1].split(".")[0]
		merge_files = [filename]
		for i in range(1, args.merge_size+1):
			merge_files.append("%s/%s_%s.txt" % (args.reg, name, int(age) - i))
		merge_files.reverse()
		
		outfile = open("merged-%s/%s_%s.txt" % (args.reg, name, age), "w+")

		try:
			vocab = Counter()
			counts = 0
			for f in merge_files:
				infile = open(f, "r")
				text = infile.read()
				outfile.write(text)
				vocab += Counter(text.split())

			for word in vocab:
				if (vocab[word] > args.min_count-1):
					counts += 1

			with open("%s_vocab_stats.txt" % args.reg,"a+") as vocab_file:
				vocab_file.write("%s\t%s\t%s\n" % (name,age,counts))

		except:
			os.remove("merged-%s/%s_%s.txt" % (args.reg, name, age))

	

main()


