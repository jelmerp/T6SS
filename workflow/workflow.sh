conda activate blast-env
export NCBI_API_KEY=34618c91021ccd7f17429b650a087b585f08 # See https://support.nlm.nih.gov/knowledgebase/article/KA-05317/en-us, https://www.ncbi.nlm.nih.gov/books/NBK179288/

## Specify COG
#TODO - Get list of COGS
cog_id="COG3501"

## Set up output files
dir_refseq=results/refseq
cog_tsv="$dir_refseq"/"$cog_id".tsv.gz
cog_fa="$dir_refseq"/"$cog_id".fa
cog_acc="$dir_refseq"/"$cog_id"_accessions.tsv

## Download EggNOG list
base_URL=http://eggnogapi5.embl.de/nog_data/file/extended_members
wget "$base_URL"/"$cog_id" -O "$cog_tsv" 

## Download FASTA
printf "%s\t%s\t%s\t%s\n" "fa_id"  "accession" "species" "txid" >"$cog_acc"  # Print header for file
while IFS=$'\t' read -ru9 _ acc spec txid _; do
    ## Search for the focal accession and store the nr of hits in the database
    res=$(esearch -query "$acc AND txid${txid}[Organism:exp]" -db protein)
    nhits=$(echo $res | xtract -pattern ENTREZ_DIRECT -element Count)
    
    ## If there are 1 or more hits, print the FASTA to stdout and accession, species, and taxid to stderr
    if [ "$nhits" -gt 0 ]; then
        fa="$(echo $res | efetch -format fasta_cds_na | sed -E "s/(>.*)$/\1 [accession=$acc] [taxid=$txid]/")"
        fa_id=$(echo "$fa" | grep ">" | sed -E 's/>([^ ]+) .*/\1/')  # Save FASTA ID
        echo "$fa"
        printf "%s\t%s\t%s\t%s\n" "$fa_id" "$acc" "$spec" "$txid" >&2
    fi
done 9< <(zcat "$cog_tsv" | grep "putida") >"$cog_fa" 2> >(tee -a "$cog_acc" >&2)
#TODO - all taxa instead of putida only

## Align and build a tree
cog_aln=results/trees/"$cog_id".fa
cog_tree=results/trees/"$cog_id".tre
sbatch mcic-scripts/trees/tree-build.sh -i "$cog_fa" -o "$cog_aln" -t "$cog_tree" -l

fig=results/trees/COG3501.png
Rscript mcic-scripts/trees/tree-plot.R -t "$cog_tree" -a "$cog_aln" -o "$fig" -n "$cog_acc" -c species 