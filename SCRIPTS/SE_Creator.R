cat("====================================================================================================
*                                        CREATE SUMMARIZED EXPERIMENT
*                                      --- for downstream analyses ---
*
* Version:      version 1.2
*
* Last update: 2018-04-21
* Written by: Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)
*                                                    
* Description: Script to be create SummarizedExperiment of CTMM data. Some important notes:
*              - Use bed file as expression file, the bed file is also used to create rowRanges
*              - Sample exclusion in not possible in this script, do this beforehand. 
*              - Only use first six columns of bed file to create a rowRanges datastructure.
*              - Remove the first six columns of bed file to be able to use the bed file as expression data.
*              - Number of columns need to match between expression and sample data files!
*
*
====================================================================================================")
cat("CLEAR THE BOARD")
rm(list = ls())

cat("====================================================================================================")
cat("GENERAL R SETUP ")

### FUNCTION TO INSTALL PACKAGES, VERSION A -- This is a function found by 
### Sander W. van der Laan online from @Samir: 
### http://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them
### Compared to VERSION 1 the advantage is that it will automatically check in both CRAN and Bioconductor
cat("Creating some functions and loading packages...")
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
install.packages.auto("Hmisc") # for some general statistics
install.packages.auto("foreign") # to read SPSS files
# BED to GRanges! Check this page for an explanation. ('https://davetang.org/muse/2013/01/02/iranges-and-genomicranges/')
# load the needed packages
install.packages.auto("GenomicRanges")
install.packages.auto("SummarizedExperiment")
install.packages.auto("data.table")
install.packages.auto("readr")
install.packages.auto("openxlsx")

# Create datestamp
Today = format(as.Date(as.POSIXlt(Sys.time())), "%Y%m%d")

###	UtrechtSciencePark Colours Scheme
###
### Website to convert HEX to RGB: http://hex.colorrrs.com.
### For some functions you should divide these numbers by 255.
###
###	No.	Color				HEX		RGB							CMYK					CHR		MAF/INFO
### --------------------------------------------------------------------------------------------------------------------
###	1	yellow				#FBB820 (251,184,32)				(0,26.69,87.25,1.57) 	=>	1 		or 1.0 > INFO
###	2	gold				#F59D10 (245,157,16)				(0,35.92,93.47,3.92) 	=>	2		
###	3	salmon				#E55738 (229,87,56) 				(0,62.01,75.55,10.2) 	=>	3 		or 0.05 < MAF < 0.2 or 0.4 < INFO < 0.6
###	4	darkpink			#DB003F ((219,0,63)					(0,100,71.23,14.12) 	=>	4		
###	5	lightpink			#E35493 (227,84,147)				(0,63,35.24,10.98) 	=>	5 		or 0.8 < INFO < 1.0
###	6	pink				#D5267B (213,38,123)				(0,82.16,42.25,16.47) 	=>	6		
###	7	hardpink			#CC0071 (204,0,113)					(0,0,0,0) 	=>	7		
###	8	lightpurple			#A8448A (168,68,138)				(0,0,0,0) 	=>	8		
###	9	purple				#9A3480 (154,52,128)				(0,0,0,0) 	=>	9		
###	10	lavendel			#8D5B9A (141,91,154)				(0,0,0,0) 	=>	10		
###	11	bluepurple			#705296 (112,82,150)				(0,0,0,0) 	=>	11		
###	12	purpleblue			#686AA9 (104,106,169)				(0,0,0,0) 	=>	12		
###	13	lightpurpleblue		#6173AD (97,115,173/101,120,180)	(0,0,0,0) 	=>	13		
###	14	seablue				#4C81BF (76,129,191)				(0,0,0,0) 	=>	14		
###	15	skyblue				#2F8BC9 (47,139,201)				(0,0,0,0) 	=>	15		
###	16	azurblue			#1290D9 (18,144,217)				(0,0,0,0) 	=>	16		 or 0.01 < MAF < 0.05 or 0.2 < INFO < 0.4
###	17	lightazurblue		#1396D8 (19,150,216)				(0,0,0,0) 	=>	17		
###	18	greenblue			#15A6C1 (21,166,193)				(0,0,0,0) 	=>	18		
###	19	seaweedgreen		#5EB17F (94,177,127)				(0,0,0,0) 	=>	19		
###	20	yellowgreen			#86B833 (134,184,51)				(0,0,0,0) 	=>	20		
###	21	lightmossgreen		#C5D220 (197,210,32)				(0,0,0,0) 	=>	21		
###	22	mossgreen			#9FC228 (159,194,40)				(0,0,0,0) 	=>	22		or MAF > 0.20 or 0.6 < INFO < 0.8
###	23	lightgreen			#78B113 (120,177,19)				(0,0,0,0) 	=>	23/X
###	24	green				#49A01D (73,160,29)					(0,0,0,0) 	=>	24/Y
###	25	grey				#595A5C (89,90,92)					(0,0,0,0) 	=>	25/XY	or MAF < 0.01 or 0.0 < INFO < 0.2
###	26	lightgrey			#A2A3A4	(162,163,164)				(0,0,0,0) 	=> 	26/MT
### 
### ADDITIONAL COLORS
### 27	midgrey				#D7D8D7
### 28	very lightgrey		#ECECEC
### 29	white				#FFFFFF
### 30	black				#000000
### --------------------------------------------------------------------------------------------------------------------

uithof_color = c("#FBB820","#F59D10","#E55738","#DB003F","#E35493","#D5267B",
                 "#CC0071","#A8448A","#9A3480","#8D5B9A","#705296","#686AA9",
                 "#6173AD","#4C81BF","#2F8BC9","#1290D9","#1396D8","#15A6C1",
                 "#5EB17F","#86B833","#C5D220","#9FC228","#78B113","#49A01D",
                 "#595A5C","#A2A3A4", "#D7D8D7", "#ECECEC", "#FFFFFF", "#000000")

uithof_color_legend = c("#FBB820", "#F59D10", "#E55738", "#DB003F", "#E35493",
                        "#D5267B", "#CC0071", "#A8448A", "#9A3480", "#8D5B9A",
                        "#705296", "#686AA9", "#6173AD", "#4C81BF", "#2F8BC9",
                        "#1290D9", "#1396D8", "#15A6C1", "#5EB17F", "#86B833",
                        "#C5D220", "#9FC228", "#78B113", "#49A01D", "#595A5C",
                        "#A2A3A4", "#D7D8D7", "#ECECEC", "#FFFFFF", "#000000")

cat("====================================================================================================")

cat("====================================================================================================")
cat("SETUP ANALYSIS")
# Assess where we are
getwd()
# Set locations
### Mac Pro
# ROOT_loc = "/Volumes/EliteProQx2Media"

### MacBook
ROOT_loc = "/Users/swvanderlaan"

CTMMROOT_loc = paste0(ROOT_loc,"/PLINK/_CTMM_Originals")
DATA_loc = paste0(ROOT_loc,"/PLINK/_CTMM_Originals/CTMMHumanHT12v4r2_15002873B/")
PHENO_loc = paste0(ROOT_loc,"/iCloud/Genomics/Projects/CTMM/Data/")
PROJECT_loc = paste0(ROOT_loc,"/PLINK/analyses/ctmm/cardiogramplusc4d/")
OUT_loc = DATA_loc

cat("====================================================================================================")
cat("LOAD DATASET")
setwd(OUT_loc)
list.files()
# read bed
data = as.data.table(read_tsv(paste0(DATA_loc,"ctmm.humanhtv4r2.qtl.bed"),
                              col_names = TRUE, progress = TRUE))
dim(data)
head(data)
names(data)[1] <- "chr"
# names(data)[names(data)== "start"] <- "start"
# names(data)[names(data)== "end"] <- "end"
names(data)[names(data) == "pid"] <- "probe"
names(data)[names(data) == "gid"] <- "gene"
# names(data)[names(data)== "strand"] <- "strand"

# set rowRanges
rowRanges <- with(data, GRanges(chr, IRanges(start + 1, end), strand, probe, id = gene))
rowRanges

elementMetadata(rowRanges)

# set summarized experiment, first a dirty conversion of the bed data. This is needed cause we need the 
# genes as row names.
temp <- data
temp$chr <- NULL
temp$start <- NULL
temp$end <- NULL
temp$gene <- NULL
temp$strand <- NULL
row.names(temp) <- temp$probe
temp$probe <- NULL
# Next option can also be used, but doesn't work with my data.
#temp = read.csv('chr1_new.bed', sep = '\t', header = F)
#drops <- c(1,2,3,5,6)

# Create matrix with expression / count data
count <- as.matrix(temp)
dim(count)
head(count)
# counts <- as.matrix(temp)

# read sample file, only include the samples u need! 
sampleFile <- fread(paste0(CTMMROOT_loc, "/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5/ctmm_phenocov.sample"), 
                    header = TRUE, showProgress = TRUE, verbose = TRUE)
# Phenotype data
rawphenoData = read.xlsx(paste0(PHENO_loc,"/20180307_CTMM_withPCA_CTMMGS_CTMMHT_withMed_Cells_Cytokines.xlsx"),
                         sheet = 1, skipEmptyRows = TRUE)
dim(rawphenoData)
rawphenoData[1:5,1:5]
# edit missing data
rawphenoData[ rawphenoData == "." ] = NA
rawphenoData[ rawphenoData == "Missing" ] = NA
rawphenoData[ rawphenoData == "missing" ] = NA
rawphenoData[ rawphenoData == "-999.0" ] = NA
rawphenoData[ rawphenoData == "-99.0" ] = NA
rawphenoData[ rawphenoData == "-888.0" ] = "not_relevant"
rawphenoData[ rawphenoData == "-88.0" ] = "not_relevant"
# edit identifier for merge with expression data
rawphenoData$CTMM_GS_HT_ID <- sub("^", "X", rawphenoData$CC_number)
phenoData <- rawphenoData[,c(ncol(rawphenoData),1:(ncol(rawphenoData) - 1))]
dim(phenoData)
phenoData[1:5,1:5]

phenoDataClean <- subset(phenoData, Conf_diag_revised != "silent ischemia" & Conf_diag_revised != "health control"  & Conf_diag_revised != "NA")
dim(phenoDataClean)
phenoDataClean[1:5,1:5]

# remove temporary data
rm(rawphenoData)
dim(sampleFile)

data.samples <- colnames(data[,7:314])

sample.exp <- sampleFile[sampleFile$ID_1 %in% data.samples,]
sample.exp.new <- phenoData[phenoData$AlternativeID %in% data.samples,]

colData <- DataFrame(sample.exp)
colData.new <- DataFrame(sample.exp.new)
library(SummarizedExperiment)
se <- SummarizedExperiment(assays = SimpleList(counts = count), 
                           rowRanges = rowRanges, 
                           colData = colData)
se.new <- SummarizedExperiment(assays = list(counts = count), 
                               rowRanges = rowRanges, 
                               colData = colData.new)
ctmm.humanhtv4r2.SE = se
ctmm.humanhtv4r2.SE.new = se.new
rm(se, count, colData, data, rowRanges, sample.exp, sample.exp.new, sampleFile, temp, se.new)

cat("\n*** Saving Final Datasets ***\n")
save(ctmm.humanhtv4r2.SE, file = paste0(DATA_loc,"/",Today,".ctmm.humanhtv4r2.SE.RData"))
save(ctmm.humanhtv4r2.SE, file = paste0(PROJECT_loc,"/",Today,".ctmm.humanhtv4r2.SE.RData"))

save(ctmm.humanhtv4r2.SE.new, file = paste0(DATA_loc,"/",Today,".ctmm.humanhtv4r2.SE.new.RData"))
save(ctmm.humanhtv4r2.SE.new, file = paste0(PROJECT_loc,"/",Today,".ctmm.humanhtv4r2.SE.new.RData"))

cat("====================================================================================================\n")
cat("SAVE THE DATA\n")
save.image(paste0(DATA_loc,"/",Today,".SE_Creator.RData"))


