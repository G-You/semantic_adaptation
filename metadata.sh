for f in cds/*.txt; 
	do wc -wl $f | 
	xargs|
	awk -F '[ /._]' '{print $4,$5,$1,$2-2*$1}'; 
done > metadata_cds.txt

for f in child/*.txt; 
	do wc -wl $f | 
	xargs|
	awk -F '[ /._]' '{print $4,$5,$1,$2-2*$1}'; 
done > metadata_child.txt
