cat("===========================================================================================
                             CREATE BED-FILES FOR (fast)QTLToolKit
                                             for
                   ILLUMINA DNA methylation (DNAm) ARRAYS (450K, 27K, EPIC)

Version:      v2.4

Last update:  2018-03-15
Written by:   Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl);
Jacco Schaap

Description:  Script to create bed-files for (fast)QTLToolKit of DNA methylation array data based
on Illumina 450K, 27K or EPIC BeadChips and processed using DNAmArray (https://github.com/molepi/DNAmArray).

Requirements: R version 3.4.1 (2017-06-30) -- 'Single Candle', Linux CentOS7, Mac OS X El Capitan+

===========================================================================================")
cat("\n===========================================================================================")
cat("CLEAR THE BOARD")
rm(list = ls())

cat("\n===========================================================================================")
cat("GENERAL R SETUP")
### FUNCTION TO INSTALL PACKAGES
### This function will automatically check in both CRAN and Bioconductor. This is 
### a function found by Sander W. van der Laan online from @Samir: 
### http://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them
### 
cat("\n* Creating funxtion to install and load packages...")
install.packages.auto <- function(x) { 
  x <- as.character(substitute(x)) 
  if (isTRUE(x %in% .packages(all.available = TRUE))) { 
    eval(parse(text = sprintf("require(\"%s\")", x)))
  } else { 
    # Update installed packages - this may mean a full upgrade of R, which in turn
    # may not be warrented. 
    #update.packages(ask = FALSE) 
    eval(parse(text = sprintf("install.packages(\"%s\", 
                              dependencies = TRUE, 
                              repos = \"https://cloud.r-project.org/\")", x)))
  }
  if (isTRUE(x %in% .packages(all.available = TRUE))) { 
    eval(parse(text = sprintf("require(\"%s\")", x)))
  } else {
    source("http://bioconductor.org/biocLite.R")
    # Update installed packages - this may mean a full upgrade of R, which in turn
    # may not be warrented.
    #biocLite(character(), ask = FALSE) 
    eval(parse(text = sprintf("biocLite(\"%s\")", x)))
    eval(parse(text = sprintf("require(\"%s\")", x)))
  }
}

# In this case I'm keeping track of the various packages, as versions and 
# actual loading of the libraries gave issues before.
cat("\n* General packages...\n")
install.packages.auto("data.table")
install.packages.auto("GenomicFeatures")
install.packages.auto("SummarizedExperiment")
install.packages.auto("IlluminaHumanMethylation450kmanifest")
install.packages.auto("IlluminaHumanMethylation450kanno.ilmn12.hg19")
install.packages.auto("FDb.InfiniumMethylation.hg19")
install.packages.auto("TxDb.Hsapiens.UCSC.hg19.knownGene")
install.packages.auto("org.Hs.eg.db")
install.packages.auto("AnnotationDbi")

### Create datestamp
Today=format(as.Date(as.POSIXlt(Sys.time())), "%Y%m%d")
Today.Report = format(as.Date(as.POSIXlt(Sys.time())), "%A, %B %d, %Y")

cat("===========================================================================================")
cat("\nSETUP ANALYSIS")
# Assess where we are
getwd()

# Set locations
### Operating System Version

### Mac Pro -- this is my desktop-version; edit this to your data location
ROOT_loc = "/Volumes/EliteProQx2Media"

### MacBook -- version to work on my MacBook
# ROOT_loc = "/Users/swvanderlaan"

### SOME VARIABLES WE NEED DOWN THE LINE
PROJECTDATASET = "AEMS450KBED"
PROJECTNAME = "BEDFILES"
SUBPROJECTNAME1 = "AEMS450K1"
SUBPROJECTNAME2 = "AEMS450K2"

INP_loc = paste0(ROOT_loc, "/PLINK/_AE_Originals")
INP_DNAMARRAY1_loc = paste0(INP_loc, "/AEMS450K1")
INP_DNAMARRAY2_loc = paste0(INP_loc, "/AEMS450K2")

cat("\nCreate a BED-files directory...")
ifelse(!dir.exists(file.path(INP_DNAMARRAY1_loc, "/",PROJECTNAME)), 
       dir.create(file.path(INP_DNAMARRAY1_loc, "/",PROJECTNAME)), 
       FALSE)
BED_DNAMARRAY1_loc = paste0(INP_DNAMARRAY1_loc,"/",PROJECTNAME)

ifelse(!dir.exists(file.path(INP_DNAMARRAY2_loc, "/",PROJECTNAME)), 
       dir.create(file.path(INP_DNAMARRAY2_loc, "/",PROJECTNAME)), 
       FALSE)
BED_DNAMARRAY2_loc = paste0(INP_DNAMARRAY2_loc,"/",PROJECTNAME)

cat("\n===========================================================================================")
cat("SAVE THE DATA")

save.image(paste0(INP_loc,"/",Today,".aems450k.createBED.RData"))

cat("===========================================================================================")
cat("\nLOAD ATHERO-EXPRESS METHYLATION STUDY DATASETS")
setwd(INP_loc)
list.files()

cat(paste0("\n\n* Load ",PROJECTDATASET," data..."))

# NOTEL: edit these names to match your data
cat("\n  - loading B/Mvalues of blood samples...") 
load(paste0(INP_DNAMARRAY1_loc,"/20171229.aems450k1.BvaluesQCIMP.blood.RData"))
load(paste0(INP_DNAMARRAY1_loc,"/20171229.aems450k1.MvaluesQCIMP.blood.RData"))

cat("\n  - loading B/Mvalues of plaque samples...")
load(paste0(INP_DNAMARRAY1_loc,"/20171229.aems450k1.BvaluesQCIMP.plaque.RData"))
load(paste0(INP_DNAMARRAY1_loc,"/20171229.aems450k1.MvaluesQCIMP.plaque.RData"))

load(paste0(INP_DNAMARRAY2_loc,"/20171229.aems450k2.BvaluesQCIMP.plaque.RData"))
load(paste0(INP_DNAMARRAY2_loc,"/20171229.aems450k2.MvaluesQCIMP.plaque.RData"))

cat("===========================================================================================")
cat("\n[ CREATING BED-FILES FOR (fast)QTLToolKit OF DNAmARRAY DATA ]")
# Reference: https://molepi.github.io/DNAmArray_workflow/06_EWAS.html

cat("\n* create bed files - B(eta)-values...")
# Perhaps this can be coded into a for-loop, in either case I was lazy, and made 
# two options: 
# - B(eta)-value based
# - M-value based
# for three datasets: 
# - aems450k1.[B/M]valuesQCblood, 
# - aems450k1.[B/M]valuesQCplaque, 
# - aems450k2.[B/M]valuesQCplaque.
# You should comment out what you need.


# dataset 1, blood, B(eta)-value
DATA450K = aems450k1.BvaluesQCblood
BEDFILENAME = paste0(Today,".AEMS450K1.BvaluesQCblood.qtl.bed")
FASTBEDFILENAME = paste0(Today,".AEMS450K1.BvaluesQCblood.fastqtl.bed")

# dataset 1, plaque, B(eta)-value
# DATA450K = aems450k1.BvaluesQCplaque
# BEDFILENAME = paste0(Today,".AEMS450K1.BvaluesQCplaque.qtl.bed")
# FASTBEDFILENAME = paste0(Today,".AEMS450K1.BvaluesQCplaque.fastqtl.bed")

# dataset 2, plaque, B(eta)-value
# DATA450K = aems450k2.BvaluesQCplaque
# BEDFILENAME = paste0(Today,".AEMS450K2.BvaluesQCplaque.qtl.bed")
# FASTBEDFILENAME = paste0(Today,".AEMS450K2.BvaluesQCplaque.fastqtl.bed")


cat("\n* create bed files - M-values...")

# dataset 1, blood, M-value
# DATA450K = aems450k1.MvaluesQCblood
# BEDFILENAME = paste0(Today,".AEMS450K1.MvaluesQCblood.qtl.bed")
# FASTBEDFILENAME = paste0(Today,".AEMS450K1.MvaluesQCblood.fastqtl.bed")

# dataset 1, plaque, M-value
# DATA450K = aems450k1.MvaluesQCplaque
# BEDFILENAME = paste0(Today,".AEMS450K1.MvaluesQCplaque.qtl.bed")
# FASTBEDFILENAME = paste0(Today,".AEMS450K1.MvaluesQCplaque.fastqtl.bed")

# dataset 2, plaque, M-value
# DATA450K = aems450k2.MvaluesQCplaque
# BEDFILENAME = paste0(Today,".AEMS450K2.MvaluesQCplaque.qtl.bed")
# FASTBEDFILENAME = paste0(Today,".AEMS450K2.MvaluesQCplaque.fastqtl.bed")

# location of the datasets 
BEDFILELOCATION = BED_DNAMARRAY1_loc
# BEDFILELOCATION = BED_DNAMARRAY2_loc

dim(DATA450K)
DATA450K
assay(DATA450K)[1:5, 1:5]
colData(DATA450K)[1:5, 1:5]

cat("\n* removing non-genotyped samples...")

### Please note that it is okay to have more (or different) samples in the *genotype* data 
### as compared to the *phenotype* data. However, it is *NOT* okay to have more 
### (or different) samples in the *phenotype* data as compared to the *genotype* data!!!
### In other words: remove from the BED files - *BEFORE* while making them!!! - the
### samples that do *NOT* have genotype data!!!

dim(DATA450K)
genotyped.samples <- as.data.frame(subset(colData(DATA450K), colData(DATA450K)$AEGS_type != "AE (not common SNP data)",
                                          select = (ID)))

DATA450Ksub <- DATA450K[, (DATA450K$ID %in% genotyped.samples$ID)]
dim(DATA450Ksub)

cat("\n* get a list of samples...")
samples <- data.frame(subset(colData(DATA450Ksub), select = c(2)))
samples[1:5, 1]

cat("\n* sort and get the chromome data...")
DATA450Ksub <- sortSeqlevels(DATA450Ksub)
DATA450Ksub <- sort(DATA450Ksub)
chrbp <- data.frame(rowRanges(DATA450Ksub))
chrbp$probe<-rownames(DATA450Ksub)
chrbp <- subset(chrbp, select = c(1,2,3,16))
chrbp[1:4,1:4]

cat("\n* concatenate all the annotations and parse them (externally)...")
# Map location information to CpGs -- very nice to have
# source("http://bioconductor.org/biocLite.R")
# biocLite("IlluminaHumanMethylation450kanno.ilmn12.hg19")
data(IlluminaHumanMethylation450kanno.ilmn12.hg19)
data("Locations")
data("Other")
data("Manifest")
data("SNPs.147CommonSingle")
data("SNPs.Illumina")
data("Islands.UCSC")
anno.450k <- IlluminaHumanMethylation450kanno.ilmn12.hg19@data$Other
# names(anno.450k)

anno.450k.Locations <- as.data.frame(Locations)
anno.450k.Locations$CpG <- rownames(anno.450k.Locations)
anno.450k.Manifest <- as.data.frame(Manifest)
anno.450k.Manifest$CpG <- rownames(anno.450k.Manifest)
anno.450k.Other <- as.data.frame(Other)
anno.450k.Other$CpG <- rownames(anno.450k.Other)
anno.450k.SNPs.147CommonSingle <- as.data.frame(SNPs.147CommonSingle)
anno.450k.SNPs.147CommonSingle$CpG <- rownames(anno.450k.SNPs.147CommonSingle)
anno.450k.SNPs.Illumina <- as.data.frame(SNPs.Illumina)
anno.450k.SNPs.Illumina$CpG <- rownames(anno.450k.SNPs.Illumina)
anno.450k.Islands.UCSC <- as.data.frame(Islands.UCSC)
anno.450k.Islands.UCSC$CpG <- rownames(anno.450k.Islands.UCSC)

anno.450k.temp1 <- merge.data.frame(anno.450k.Locations, anno.450k.Manifest, by = "CpG")
anno.450k.temp2 <- merge.data.frame(anno.450k.temp1, anno.450k.Other, by = "CpG")
anno.450k.temp3 <- merge.data.frame(anno.450k.temp2, anno.450k.SNPs.147CommonSingle, by = "CpG")
anno.450k.temp4 <- merge.data.frame(anno.450k.temp3, anno.450k.SNPs.Illumina, by = "CpG")
anno.450k.combined <- merge.data.frame(anno.450k.temp4, anno.450k.Islands.UCSC, by = "CpG")
dim(anno.450k.combined)
anno.450k.combined[1:4, 1:36]
anno.450k.combined$GeneName <- anno.450k.combined$UCSC_RefGene_Name

rm(anno.450k.temp1, anno.450k.temp2, anno.450k.temp3, anno.450k.temp4,
   anno.450k.Locations, anno.450k.Manifest, anno.450k.Other, anno.450k.SNPs.147CommonSingle,
   anno.450k.SNPs.Illumina, anno.450k.Islands.UCSC, 
   IlluminaHumanMethylation450kanno.ilmn12.hg19, Islands.UCSC, Locations, Manifest, 
   Other, SNPs.147CommonSingle, SNPs.Illumina)

anno.450k.combined[, "GeneName"] = as.character(lapply(anno.450k.combined[,"UCSC_RefGene_Name"], 
                                                              FUN = function(x){paste(unique(unlist(strsplit(x, split = ";"))), sep = "", collapse = ";")}))
dim(anno.450k.combined)
anno.450k.combined[1:50, 1:37]

anno.450k.combined.select <- subset(anno.450k.combined, select = c("CpG", "strand", "GeneName"))


cat("\n* get proper annotations...")
chrbp$strand <- NULL
chrbp.annot <- merge(chrbp, anno.450k.combined.select, by.x = "probe", by.y = "CpG", sort = FALSE)
dim(chrbp.annot)
chrbp.annot[1:5, 1:6]

cat("\n* Add leading 'zero' to chromosome.\n")
# https://stackoverflow.com/questions/5812493/adding-leading-zeros-using-r
# https://stackoverflow.com/questions/9704213/r-remove-part-of-string
library(stringr)
chrbp.annot$seqnames <- gsub("^chr*", '', chrbp.annot$seqnames)
dim(chrbp.annot)
chrbp.annot[1:5, 1:6]
chrbp.annot[483725:483731, 1:6]
chrbp.annot$pid <- chrbp.annot$probe
chrbp.annot$gid <- chrbp.annot$GeneName
chrbp.annot$GeneName <- NULL
chrbp.annot$probe <- NULL
names(chrbp.annot)[names(chrbp.annot) == "seqnames"] <- "#Chr"
chrbp.annot[1:5, 1:6]
chrbp.annot$`#Chr` <- str_pad(chrbp.annot$`#Chr`, width = 2, side = "left", pad = "0")

cat("\n* get the methylation data...")
DATA450KASSAY <- as.data.frame(assay(DATA450Ksub), keep.rownames = TRUE)
DATA450KASSAY[1:4,1:4]
DATA450KASSAYU <- setnames(DATA450KASSAY, old = c(colnames(DATA450KASSAY)), new = c(samples$SampleID))
# colnames(DATA450KASSAYU)[1:5]
DATA450KMERGED <- cbind.data.frame(chrbp.annot, DATA450KASSAYU)
dim(DATA450KMERGED)
DATA450KMERGED[1:5, 1:10]
DATA450KMERGEDFAST = DATA450KMERGED
DATA450KMERGEDFAST$gid <- NULL
DATA450KMERGEDFAST$strand <- NULL
names(DATA450KMERGEDFAST)[names(DATA450KMERGEDFAST) == "ID"] <- "pid"

fwrite(DATA450KMERGED, paste0(BEDFILELOCATION, "/",BEDFILENAME), 
       sep = '\t', 
       quote = FALSE, 
       row.names = FALSE)
fwrite(DATA450KMERGEDFAST, paste0(BEDFILELOCATION, "/",FASTBEDFILENAME), 
       sep = '\t', 
       quote = FALSE, 
       row.names = FALSE)

rm(DATA450K, DATA450Ksub, DATA450KASSAY, DATA450KASSAYU, 
   samples, chrbp, chrbp.annot, anno.450k, genotyped.samples, 
   DATA450KMERGED, BEDFILENAME)

cat("\n===========================================================================================")
cat("SAVE THE DATA")

# we don't need the loaded methylation data anymore...
rm(aems450k1.BvaluesQCblood, aems450k1.BvaluesQCplaque, aems450k2.BvaluesQCplaque,
   aems450k1.MvaluesQCblood, aems450k1.MvaluesQCplaque, aems450k2.MvaluesQCplaque)

save.image(paste0(INP_loc,"/",Today,".aems450k.createBED.RData"))

