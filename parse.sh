for f in cds/*.txt; do rm $f; done
for f in child/*.txt; do rm $f; done
python3 parse_Manchester.py
PYTHONHASHSEED=1 python3 training.py --reg cds
PYTHONHASHSEED=1 python3 training.py --reg child

python3 betweenness.py --reg cds
python3 betweenness.py --reg child

#for f in cds/results/*.csv; do python3 betweenness.py --graph $f; done
#for f in child/results/*.csv; do python3 betweenness.py --graph $f; done