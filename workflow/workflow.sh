## Dirs and settings
dir_refseq=results/refseq

conda activate blast-env

## Download EggNOG list
base_URL=http://eggnogapi5.embl.de/nog_data/file/extended_members

#TODO - Get list of COGS

cog_id="COG3501"

cog_tsv="$dir_refseq"/"$cog_id".tsv.gz
cog_fa="$dir_refseq"/"$cog_id".fa
loc_info="$dir_refseq"/"$cog_id"_locs.tsv

## Download EggNOG list
wget "$base_URL"/"$cog_id" -O "$cog_tsv" 

## Save columns with accession nr's, species names, and taxids
mapfile ACCESSIONS -t array < <(zcat "$cog_tsv" | cut -f 2)
mapfile SPECIES -t array < <(zcat "$cog_tsv" | cut -f 3)
mapfile TAXIDS -t array < <(zcat "$cog_tsv" | cut -f 4)

## Get genomic location for each accession
for i in "${!ACCESSIONS[@]}"; do
    acc="${ACCESSIONS[$i]}" #txid=1211579; acc=PP4_27770
    spec="${SPECIES[$i]}"
    txid="${TAXIDS[$i]}"
    echo "## i: $i" >&2
    printf "## Accession: %s" "$acc" >&2
    printf "## Species: %s" "$spec" >&2
    printf "%s\t%s\t%s\t" "${acc%$'\n'}" "${spec%$'\n'}" "${txid%$'\n'}"

    docsum=$(esearch -query "$acc AND txid${txid}[Organism:exp]" -db gene | efetch -format docsum)
    docsum=$(echo $docsum | sed -s 's@</DocumentSummary>.*@</DocumentSummary>@') # Only take first record

    if [ -n "$docsum" ]; then
        printf "## Hit found for: " >&2
        echo $docsum | xtract -pattern Organism -element ScientificName >&2
        echo $docsum | xtract -pattern GenomicInfoType -element ChrAccVer -1-based ChrStart ChrStop
    else
        echo "## No hit found" >&2
        printf "NA\tNA\tNA"
    fi
    printf "\n"
    echo >&2
done >"$loc_info".tmp

## Get rid of empty lines and sort by taxid, seqid, and start position
sed -e '/^$/d' $loc_info.tmp | sort -k3,3n -k4,4 -k5,5n > $loc_info

## Get FASTA files
while IFS=$'\t' read -r acc species txid seqid start stop; do
    echo "## Species: $species / seqid: $seqid / start: $start / stop: $stop" >&2
    efetch -db nuccore -id "$seqid" -seq_start "$start" -seq_stop "$stop" -format fasta |
        sed -E "s/(>.*)$/\1 -- accession:$acc taxid:$txid/"
done < <(grep -v "NA$" "$loc_info") >"$cog_fa"
