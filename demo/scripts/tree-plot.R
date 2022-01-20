#!/usr/bin/env Rscript

#SBATCH --account=PAS0471
#SBATCH --time=5
#SBATCH --output=slurm-tree-plot-%j.out

# SET-UP -----------------------------------------------------------------------
## Load (and install, if necessary) packages
if (!"pacman" %in% installed.packages()) install.packages("pacman")
packages <- c("tidyverse", "here", "ape", "ggtree")
pacman::p_load(char = packages, install = TRUE)

## Process command-line arguments
args <- commandArgs(trailingOnly = TRUE)
tree_file <- args[1]
aln_file <- args[2]
fig_file <- args[3]

# tree_file <- "results/alignments/COG3501.tre"
# aln_file <- "results/alignments/COG3501.fa"
# fig_file <- "results/alignments/COG3501.png"

## Report
message("\n## Starting script tree-plot.R")
message(Sys.time())
message("## Tree file: ", tree_file)
message("## Alignment file: ", aln_file)
message("## Tree figure file: ", fig_file)
message("--------------------------------\n\n")

## Test
stopifnot(file.exists(tree_file))
stopifnot(file.exists(aln_file))

## Process args
fig_dir <- dirname(fig_file)
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)


# CREATE TREE ------------------------------------------------------------------
## Read the tree file
tree <- read.tree(tree_file)

p <- ggtree(tree) +
    geom_tiplab() +
    theme(plot.margin = margin(0.2, 1, 0.2, 0.2, "cm")) +
    coord_cartesian(clip = "off")
    
## Add Multiple Sequence Alignment (MSA) visualization
msaplot(p, aln_file, offset = 3, width = 3)
    
## Save the plot to file
ggsave(fig_file, width = 14, height = 7)


# WRAP UP ----------------------------------------------------------------------
message("## Listing output file:")
system(paste("ls -lh", fig_file))
message("## Done with script tree-plot.R")
message(Sys.time())
message("\n")