# Created by Jacco Schaap - 27-6-17
rm(list = ls())

'''
Some important notes:
- Use bed file as expression file, the bed file is also used to create rowRanges
- Sample exclusion in not possible in this script, do this beforehand. 
- Only use first six columns of bed file to create a rowRanges datastructure.
- Remove the first six columns of bed file to be able to use the bed file as expression data.
- Number of columns need to match between expression and sample data files!
'''

# BED to GRanges! Check this page for an explanation. ('https://davetang.org/muse/2013/01/02/iranges-and-genomicranges/')
# load the needed packages
library(GenomicRanges)
library(SummarizedExperiment)

# Only include samples u need, can't be changed in the experiment.
#########
# read bed
data <- read.table("ctmm_with_monocytes.bed", sep = '\t',header = TRUE)
head(data)
# if needed, change colnames
#colnames(data) <- c('chr','start','end','probe','gene','strand')
# set rowRanges
rowRanges <- with(data, GRanges(Chr, IRanges(Bp_start+1, Bp_end), strand., ProbeID, id=GeneName))
rowRanges

elementMetadata(rowRanges)

# set summarized experiment, first a dirty conversion of the bed data. This is needed cause we need the 
# genes as row names.
temp <- data
temp$Chr <- NULL
temp$Bp_start <- NULL
temp$Bp_end <- NULL
temp$GeneName <- NULL
temp$strand. <- NULL
row.names(temp) <- temp[, 1]
temp$ProbeID <- NULL
# Next option can also be used, but doesn't work with my data.
#temp = read.csv('chr1_new.bed', sep = '\t', header = F)
#drops <- c(1,2,3,5,6)

# Create matrix with expression / count data
count <- as.matrix(temp)
dim(count)
# counts <- as.matrix(temp)

# read sample file, only include the samples u need! 
sample <- read.table('new_ctmmphenocov.sample', sep="\t", header = TRUE)
dim(sample)
colData <- DataFrame(sample)
library(SummarizedExperiment)
se <- SummarizedExperiment(assays=list(counts=count), rowRanges=rowRanges, colData=colData)


# extra code to calculate correlation in expression data
resultaat = list()
dat = data.frame()
#i = 1
for (i in 1:length(rowRanges(se))) {
  score <- assays(se)[[1]][i, 0:273]
  probe <- rownames(se)[i]
  phenotype <- sample$Diagnosis_P
  correlatie <- cor.test(score,phenotype)
  dat <- data.frame(gen = probe, correlation = correlatie$estimate, pval = correlatie$p.value)
  resultaat[[i]] <- dat
}
big_data_file = do.call(rbind, resultaat)
max(big_data_file$correlation)
min(big_data_file$correlation)

write.table(big_data_file, file = "FIlE.txt", sep = '\t', col.names = TRUE)
# save 
NAME <- big_data_file

