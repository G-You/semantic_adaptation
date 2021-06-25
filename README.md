# Repository for the paper "Adults adapt to child speech in semantic use"

Corresponding author: [Guanghao You](mailto:guanghao.you@uzh.ch?subject=[GitHub]%20Paper%20on%20semantic%20adaptation)

## Data

Corpus files are already prepared in folders */cds* and */child*

If you wish to replicate data retrieval and parsing, the original Manchester corpus data can be retrieved via the link below:\
[Manchester corpus](https://childes.talkbank.org/data-xml/Eng-UK/Manchester.zip)\
Please place the folders under a directory called "data" (to be processed by the parser), and run

```bash
chmod +x parse.sh
./parse.sh
```

Before you run the parsing, two corrections should be done:

### 1. CHILDES reader correction 
In the source code for nltk.corpus.reader.childes (childes.py)\
After line 391, add:
```python
word = ""
```

### 2. Age correction in Manchester corpus
Session _Nicole 020806.xml_: age corrected from 07M12D to 08M06D\
Session _Nicole 020730.xml_: age corrected from 08M29D to 07M30D

## For quick replication of figures and tables

Please check out the R scripts main_analyses.R and the markdown of supplementary materials.

## Full replication

For fetching data and building models, run the bash script:

```bash
chmod +x full.sh
./full.sh
```

Some empty folders might need to be first created to proceed.

For the break-point analyses, run:

```bash
chmod +x bp_analyses.sh
./bp_analyses.sh
```

This might take days to finish.
