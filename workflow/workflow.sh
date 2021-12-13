## Dirs and settings
dir_refseq=results/refseq

conda activate blast-env

## Get protein sequences for a gene
esearch -db protein -query "vgrG AND \"Pseudomonas putida\"[Organism]" | 
    efetch -format fasta > "$dir_refseq"/vgrG_Pputida_protein.fa
#esearch -db protein -query "vgrG AND \"Pseudomonas putida\"[Organism]"  # 652
#esearch -db protein -query "vgrG AND txid303[Organism:exp]"             # 652 = P. putida
#esearch -db protein -query "vgrG AND txid286[Organism:exp]"             # 54137 = genus Pseudomonas
#TODO - select only complete proteins

esearch -db gene -query "vgrG AND \"Pseudomonas putida\"[Organism]" |
    esummary |
    xtract -pattern DocumentSummary -element Id

## Get nucleotide FASTA from protein ID
esearch -query "ABY99126.1" -db gene |
    esummary |
    xtract -pattern GenomicInfoType -element ChrAccVer -1-based ChrStart ChrStop |
    xargs -n 3 sh -c 'efetch -db nuccore -id "$0" -seq_start "$1" -seq_stop "$2" -format fasta'
esearch -query "ABY99126.1" -db gene | efetch -format documentsummary
# esearch -query 108765232 -db protein | elink -target gene # alt

esearch -query "WP_010954844.1" -db gene |
    esummary

esearch -query "PP4_24660" -db gene | esummary

## Download EggNOG list
fCOG="COG3501"
wget http://eggnogapi5.embl.de/nog_data/file/extended_members/"$fCOG" -O "$fCOG.tsv.gz"
accessions=( $(zcat $fCOG.tsv.gz | grep "Pseudomonas putida" | cut -f 2) )


##
esearch -db gene -query "vgrG AND \"Pseudomonas putida\"[Organism] AND ALIVE[PROP]" |
    esummary |
    xtract -pattern GenomicInfoType -element ChrAccVer -1-based ChrStart ChrStop |
    xargs -n 3 sh -c 'efetch -db nuccore -id "$0" -seq_start "$1" -seq_stop "$2" -format fasta' \
    > "$dir_refseq"/vgrG_Pputida_gene.fa

esearch -db gene -query "vgrG AND \"Pseudomonas putida\"[Organism] AND ALIVE[PROP]" |
    esummary |
    xtract -pattern DocumentSummary -element Id


