for f in cds/*.txt; do rm $f; done
for f in child/*.txt; do rm $f; done
python3 parse_Manchester.py
