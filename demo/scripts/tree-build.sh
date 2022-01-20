#!/bin/bash

#SBATCH --account=PAS0471
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=20G
#SBATCH --output=slurm-tree-build-%j.out

## Help
Help() {
    echo
    echo "## $0: Align sequences and build a tree."
    echo
    echo "## Syntax: $0 -i <input-fasta> -o <output-fasta> -t <output-tree> [-p alignment-program] [-h]"
    echo
    echo "## Options:"
    echo "## -i STR     Input FASTA file (REQUIRED)"
    echo "## -o STR     Output (aligned) FASTA filename (REQUIRED)"
    echo "## -t STR     Output tree filename (REQUIRED)"
    echo
    echo "## -h         Print help."
    echo
    echo "## Example: $0 -i in.fa -o out.fa -t out.tree -p muscle"
    echo "## To submit the OSC queue, preface with 'sbatch': sbatch $0 ..."
    echo
}

## Software and scripts
source ~/.bashrc
[[ $(which conda) = ~/miniconda3/bin/conda ]] || module load python/3.6-conda5.2
conda activate mafft-env
conda activate --stack fasttree-env

## Bash strict mode
set -euo pipefail

## Parse command-line options
while getopts ':i:o:t:h' flag; do
    case "${flag}" in
    i) fa_in="$OPTARG" ;;
    o) aln="$OPTARG" ;;
    t) tree="$OPTARG" ;;
    h) Help && exit 0 ;;
    \?) echo "## $0: ERROR: Invalid option" >&2 && exit 1 ;;
    :) echo "## $0: ERROR: Option -$OPTARG requires an argument." >&2 && exit 1 ;;
    esac
done

## Create output dirs if needed
outdir_alignment=$(dirname "$aln")
outdir_fasttree=$(dirname "$tree")
mkdir -p "$outdir_alignment" "$outdir_fasttree"

## Report
echo "## Starting script tree-build.sh..."
date
echo "## Unaligned FASTA file (input):     $fa_in"
echo "## Aligned FASTA file (output):      $aln"
echo "## Tree file (output):               $tree"
echo -e "--------------------------\n"

## Check input
[[ ! -f "$fa_in" ]] && echo "## ERROR: Input FASTA $fa_in does not exist" && exit 1


# ALIGN ------------------------------------------------------------------------
echo "## Starting alignment with MAFFT..."
    
mafft --reorder \
      --auto \
      --adjustdirection \
      --leavegappyregion \
      "$fa_in" > "$aln"

## Remove extra info after space from FASTA header lines
## ... and remove "_R_" prefixes for reverse-complemented seqs
sed -i -E -e 's/(^>[^ ]+) .*/\1/' -e 's/^>_R_/>/' "$aln"


# BUILD TREE -------------------------------------------------------------------
echo -e "\n---------------------------"
echo -e "## Starting tree building with FastTree..."
cat "$aln" | FastTree -gamma -nt -gtr -out "$tree"


# WRAP UP ----------------------------------------------------------------------
echo -e "\n---------------------------"
echo -e "\n## Output files:"
ls -lh "$aln"
ls -lh "$tree"

echo -e "\n## Done with script tree.sh"
date
