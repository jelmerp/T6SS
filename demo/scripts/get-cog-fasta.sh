module load python
source activate blast-env

cog_id="COG3501"

## Download the EggNOG TSV file
eggnog_dir=results/eggnog
mkdir -p $eggnog_dir

cog_tsv=$eggnog_dir/$cog_id.tsv.gz

base_url=http://eggnogapi5.embl.de/nog_data/file/extended_members
wget $base_url/$cog_id -O $cog_tsv 

## Get the AA FASTA for a certain protein
#esearch -query "PP_3106" -db protein | efetch -format fasta
## Get the nucleotide FASTA for a certain protein
#esearch -query "PP_3106" -db protein | efetch -format fasta_cds_na

## Start contents of loop to get all sequences in a FASTA file
cog_fa="$eggnog_dir"/"$cog_id".fa

> $cog_fa
while IFS=$'\t' read -ru9 _ acc taxname taxid _; do
    ## Store the search result and how many hits were found
    res="$(esearch -query "$acc AND txid$taxid[Organism:exp]" -db protein)"
    nhits=$(echo $res | xtract -pattern ENTREZ_DIRECT -element Count)

    echo "Accession: $acc / taxon ID: $taxid / nhits: $nhits"
    
    ## If there is at least 1 hit, we download the nucleotide sequence in FASTA format
    if [ "$nhits" -gt 0 ]; then
        echo $res | efetch -format fasta_cds_na >> $cog_fa
    fi

done 9< <(zcat $cog_tsv | grep "putida" | head -n5)
