
# remove old files
rm merged-cds/*.txt
rm merged-child/*.txt
rm merged-cds/models/*
rm merged-child/models/*

# merge and summarize vocabulary
python3 vocab_stats.py --reg cds --merge_size 1
python3 vocab_stats.py --reg child --merge_size 1

# verb summary
python3 verb_summary.py --reg cds --merge_size 1
python3 verb_summary.py --reg child --merge_size 1

# train and measure
PYTHONHASHSEED=1 python3 train_and_measure.py --reg cds
PYTHONHASHSEED=1 python3 train_and_measure.py --reg child