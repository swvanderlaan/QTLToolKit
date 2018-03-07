cat("====================================================================================================
*                                      BED-FILE & ANNOTATION CREATOR
*                                            --- CTMM DATA ---
*
* Version:      version 1.0
*
* Last update: 2018-03-07
* Written by: Sander W. van der Laan (s.w.vanderlaan-2@umcutrecht.nl)
*                                                    
* Description: Script to create and annotate the phenotype file.
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
install.packages.auto("data.table")
install.packages.auto("illuminaHumanv4.db") # for CTMM we used the Illumina HumanHT12 v4.0 R2
install.packages.auto("openxlsx") 
install.packages.auto("GenomicRanges")
install.packages.auto("AnnotationDbi")
install.packages.auto("org.Hs.eg.db")
install.packages.auto("stringr")

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
ROOT_loc = "/Users/swvanderlaan"
INP_loc = paste0(ROOT_loc, "/PLINK/_CTMM_Originals/CTMMHumanHT12v4r2_15002873B/")
OUT_loc = INP_loc
PHENO_loc = paste0(ROOT_loc, "/iCloud/Genomics/Projects/CTMM eQTL/Data/")

cat("====================================================================================================")
cat("LOAD DATASET")
setwd(INP_loc)
list.files()
# Gene expression data
rawnormData = fread(paste0(INP_loc,"/20151004_CTMM_expression_normalized.csv"), 
                    header = TRUE, verbose = TRUE, showProgress = TRUE)
dim(rawnormData)
rawnormData[1:5,1:5]
names(rawnormData)[names(rawnormData) == "V1"] <- "ArrayAddress"
normData = rawnormData
dim(normData)
normData[1:5,1:5]

processedData = fread(paste0(INP_loc,"/ctmm.humanhtv4r2.fastqtl.bed.original.forR"), 
                      header = TRUE, na.strings = c("NA", "missing"), 
                      verbose = TRUE, showProgress = TRUE)
dim(processedData)
processedData[1:5,1:5]

# Keys data
rawkeyData = read.xlsx(paste0(PHENO_loc,"/20170522_CTMM_CTMMGS_CTMMHT_Keys.xlsx"),
                       sheet = 1, skipEmptyRows = TRUE)
rownames(rawkeyData) <- rawkeyData$CC_number
rawkeyData$Index <- NULL
keyData = rawkeyData

# Phenotype data
rawphenoData = read.xlsx(paste0(PHENO_loc,"/20180221_CTMM_withPCA_CTMMGS_CTMMHT_withMed.xlsx"),
                         sheet = 3, skipEmptyRows = TRUE)
dim(rawphenoData)
rawphenoData[1:5,1:5]
# edit missing data
rawphenoData[ rawphenoData == "." ] = NA
rawphenoData[ rawphenoData == "Missing" ] = NA
rawphenoData[ rawphenoData == "missing" ] = NA
rawphenoData[ rawphenoData == "-999.0" ] = NA
# edit identifier for merge with expression data
rawphenoData$CTMM_GS_HT_ID <- sub("^", "X", rawphenoData$CC_number)
phenoData <- rawphenoData[,c(ncol(rawphenoData),1:(ncol(rawphenoData) - 1))]
dim(phenoData)
phenoData[1:5,1:5]

# remove temporary data
rm(rawphenoData, rawnormData, rawkeyData)


### -----------------------------------------------------------------------------------
### MAKE ANNOTATION FILE
# list of annotation data package -- Illumina Human HT12 v4.0
# ls("package:illuminaHumanv4.db")
#"illuminaHumanv4"                    "illuminaHumanv4_dbconn"             "illuminaHumanv4_dbfile"            
#"illuminaHumanv4_dbInfo"             "illuminaHumanv4_dbschema"           "illuminaHumanv4.db"                
#"illuminaHumanv4ACCNUM"              "illuminaHumanv4ALIAS2PROBE"         "illuminaHumanv4ARRAYADDRESS"       
#"illuminaHumanv4CHR"                 "illuminaHumanv4CHRLENGTHS"          "illuminaHumanv4CHRLOC"             
#"illuminaHumanv4CHRLOCEND"           "illuminaHumanv4CODINGZONE"          "illuminaHumanv4ENSEMBL"            
#"illuminaHumanv4ENSEMBL2PROBE"       "illuminaHumanv4ENSEMBLREANNOTATED"  "illuminaHumanv4ENTREZID"           
#"illuminaHumanv4ENTREZREANNOTATED"   "illuminaHumanv4ENZYME"              "illuminaHumanv4ENZYME2PROBE"       
#"illuminaHumanv4fullReannotation"    "illuminaHumanv4GENENAME"            "illuminaHumanv4GENOMICLOCATION"    
#"illuminaHumanv4GO"                  "illuminaHumanv4GO2ALLPROBES"        "illuminaHumanv4GO2PROBE"           
#"illuminaHumanv4listNewMappings"     "illuminaHumanv4MAP"                 "illuminaHumanv4MAPCOUNTS"          
#"illuminaHumanv4NUID"                "illuminaHumanv4OMIM"                "illuminaHumanv4ORGANISM"           
#"illuminaHumanv4ORGPKG"              "illuminaHumanv4OTHERGENOMICMATCHES" "illuminaHumanv4OVERLAPPINGSNP"     
#"illuminaHumanv4PATH"                "illuminaHumanv4PATH2PROBE"          "illuminaHumanv4PFAM"               
#"illuminaHumanv4PMID"                "illuminaHumanv4PMID2PROBE"          "illuminaHumanv4PROBEQUALITY"       
#"illuminaHumanv4PROBESEQUENCE"       "illuminaHumanv4PROSITE"             "illuminaHumanv4REFSEQ"             
#"illuminaHumanv4REPEATMASK"          "illuminaHumanv4REPORTERGROUPID"     "illuminaHumanv4REPORTERGROUPNAME"  
#"illuminaHumanv4SECONDMATCHES"       "illuminaHumanv4SYMBOL"              "illuminaHumanv4SYMBOLREANNOTATED"  
#"illuminaHumanv4UNIGENE"             "illuminaHumanv4UNIPROT"

cat("\n* Getting probe annotations.\n")
allLocs <- unlist(as.list(illuminaHumanv4GENOMICLOCATION))
chrs <- unlist(lapply(allLocs, function(x) strsplit(as.character(x), ":")[[1]][1]))
spos <- as.numeric(unlist(lapply(allLocs, function(x) strsplit(as.character(x), ":")[[1]][2])))
epos <- as.numeric(unlist(lapply(allLocs, function(x) strsplit(as.character(x), ":")[[1]][3])))
strand <- substr(unlist(lapply(allLocs , function(x) strsplit(as.character(x), ":")[[1]][4])), 1, 1)
validPos <- !is.na(spos)
Humanv2RD <- RangedData(chr = chrs[validPos], 
                        ranges = IRanges(start = spos[validPos],
                                         end = epos[validPos]), 
                        names = names(allLocs)[validPos], 
                        strand = strand[validPos])
Humanv2RD

Humanv2RD.df <- as.data.frame(Humanv2RD)
dim(Humanv2RD.df)
Humanv2RD.df[1:5, 1:7]

illuminaToSymbol = toTable(illuminaHumanv4SYMBOLREANNOTATED) # gets symbol
illuminaToENTREZID = toTable(illuminaHumanv4ENTREZREANNOTATED) # gets EntrezGeneID
illuminaToArrayID = toTable(illuminaHumanv4ARRAYADDRESS) # gets arrayID
illuminaToGeneName = toTable(illuminaHumanv4GENENAME) # gets gene name
adrToMap = toTable(illuminaHumanv4MAP) # gets cytogenic map
adrToChr = toTable(illuminaHumanv4CHR) # gets chromosome of gene
adrToStart = toTable(illuminaHumanv4CHRLOC) # gets start of gene in bp
adrToEnd = toTable(illuminaHumanv4CHRLOCEND) # gets end of gene in bp
probeQC = toTable(illuminaHumanv4PROBEQUALITY) # gets probe quality

temp <- merge(adrToChr, adrToStart, by = "probe_id")
temp$Chromosome <- NULL
temp2 <- merge(temp, adrToEnd, by = "probe_id")
temp2$Chromosome <- NULL
temp3 <- merge(temp2, adrToMap, by = "probe_id")
temp4 <- merge(temp3, probeQC, by.x = "probe_id", by.y = "IlluminaID")
temp5 <- merge(temp4, illuminaToSymbol, by.x = "probe_id", by.y = "IlluminaID")
temp6 <- merge(temp5, illuminaToENTREZID, by.x = "probe_id", by.y = "IlluminaID")
temp7 <- merge(temp6, Humanv2RD.df, by.x = "probe_id", by.y = "names")
dim(temp7)
temp7[1:5, 1:14]
temp7$chr <- NULL
temp7$space <- NULL
names(temp7)[names(temp7) == "probe_id"] <- "IlluminaID"
names(temp7)[names(temp7) == "chromosome"] <- "Chr"
# names(temp7)[names(temp7) == "start_location"] <- "GeneStart"
# names(temp7)[names(temp7) == "end_location"] <- "GeneEnd"
names(temp7)[names(temp7) == "start"] <- "ProbeStart"
names(temp7)[names(temp7) == "end"] <- "ProbeEnd"
names(temp7)[names(temp7) == "width"] <- "ProbedWidth"
names(temp7)[names(temp7) == "SymbolReannotated"] <- "Symbol"
names(temp7)[names(temp7) == "EntrezReannotated"] <- "EntrezID"
names(temp7)[names(temp7) == "cytogenetic_location"] <- "cytoMap"
temp7[1:5, 1:12]

library(dplyr)
temp8 <- distinct(temp7)
IlluminaHumanHTV4R2 = temp8
IlluminaHumanHTV4R2$GeneStart <- abs(IlluminaHumanHTV4R2$start_location)
IlluminaHumanHTV4R2$GeneEnd <- abs(IlluminaHumanHTV4R2$end_location)
IlluminaHumanHTV4R2$start_location <- NULL
IlluminaHumanHTV4R2$end_location <- NULL
IlluminaHumanHTV4R2[1:5, 1:12]

cat("\n* Creating updated annotation file.\n")
# Example
# EntrezID	ProbeID	ArrayID	GeneName	GeneInfo	Chr	Bp_start	Bp_end
# 23117	ILMN_1725881	1710221	LOC23117	PREDICTED: Homo sapiens KIAA0220-like protein, transcript variant 11 (LOC23117), mRNA.	16	21413455	21436658
# 2213	ILMN_1804174	2480717	FCGR2B	PREDICTED: Homo sapiens Fc fragment of IgG, low affinity IIb, receptor (CD32) (FCGR2B), mRNA.	1	161632905	161648444

temp <- merge(illuminaToArrayID, illuminaToSymbol, by.x = "IlluminaID", by.y = "IlluminaID")
temp2 <- merge(temp, illuminaToENTREZID, by.x = "IlluminaID", by.y = "IlluminaID")
temp3 <- merge(temp2, illuminaToGeneName, by.x = "IlluminaID", by.y = "probe_id")
dim(temp3)
temp3[1:5, 1:5]

# If you haven't already installed devtools...
install.packages.auto("devtools")

# Use devtools to install the package
devtools::install_github("stephenturner/annotables")
library("annotables")

ls("package:annotables")
?grch37
# ?grch37_tx2gene
head(grch37)

temp4 <- merge(temp3, grch37, by.x = "EntrezReannotated", by.y = "entrez", sort = FALSE)
dim(temp4)
temp4[1:5,1:13]
names(temp4)[names(temp4) == "EntrezReannotated"] <- "EntrezID"
names(temp4)[names(temp4) == "IlluminaID"] <- "ProbeID"
names(temp4)[names(temp4) == "ArrayAddress"] <- "ArrayID"
names(temp4)[names(temp4) == "SymbolReannotated"] <- "GeneName"
names(temp4)[names(temp4) == "gene_name"] <- "GeneInfo"
names(temp4)[names(temp4) == "chr"] <- "Chr"
names(temp4)[names(temp4) == "start"] <- "Bp_start"
names(temp4)[names(temp4) == "end"] <- "Bp_end"

ctmm.humanhtv4r2.annotation <- subset(temp4, select = c("EntrezID", "ProbeID", "ArrayID",
                                                        "GeneName", "GeneInfo",
                                                        "Chr", "Bp_start", "Bp_end"))
dim(ctmm.humanhtv4r2.annotation)
ctmm.humanhtv4r2.annotation[1:5, 1:8]
str(ctmm.humanhtv4r2.annotation)
ctmm.humanhtv4r2.annotation$EntrezID <- as.numeric(ctmm.humanhtv4r2.annotation$EntrezID)
ctmm.humanhtv4r2.annotation$ArrayID <- as.numeric(ctmm.humanhtv4r2.annotation$ArrayID)
cat("\n* Writing new annotation file\n")
# Note: we added a new column to the back of the dataframe, hence [,2:315]!!!
fwrite(ctmm.humanhtv4r2.annotation, file = paste0(OUT_loc, "/ctmm.humanhtv4r2.annotation.csv"), 
       sep = ",", col.names = TRUE, row.names = FALSE, na = "NA", quote = TRUE,
       showProgress = TRUE, verbose = TRUE)


cat("\n* Creating updated phenotype file.\n")
# Phenotype data [BED]
# 
# Phenotype data are specified using an extended UCSC BED format. It is a standard BED file with 
# some additional columns. Hereafter a general example of 4 molecular phenotypes for 4 samples.
# #Chr	start	end	pid	gid	strand	UNR1	UNR2	UNR3	UNR4 
# chr1	99999	100000	pheno1	pheno1	+	-0.50	0.82	-0.71	0.83
# chr1	199999	201000	pheno2	pheno2	+	1.18	-2.84	1.34	-1.56
# chr1	299999	300000	exon1	gene1	+	-1.13	1.18	-0.03	0.11
# chr1	299999	300000	exon2	gene1	+	-1.18	1.32	-0.36	1.26
# This file is TAB delimited. Each line corresponds to a single molecular phenotype. The first 6 columns are:
#   - Chromosome ID [string]
#   - Start genomic position of the phenotype (here the TSS of gene1) [integer, 0-based]
#   - End genomic position of the phenotype (here the TSS of gene1) [integer, 1-based]
#   - Phenotype ID (here the exon IDs) [string].
#   - Phenotype group ID (here the gene IDs, multiple exons belong to the same gene) [string]
#   - Strand orientation [+/-]
# Then each additional column gives the quantification for a sample. Quantifications are encoded 
# with floating numbers. This file should have P lines and N+6 columns where P and N are the numbers 
# of phenotypes and samples, respectively.
#
# THIS FILE FORMAT EXTENDS THE FASTQTL FILE FORMAT BY ADDING 2 COLUMNS! THIS MEANS THAT QTLTOOLS 
# CANNOT WORK WITH FASTQTL BED FILES! To make a quick and dirty conversion, you can use this command:
#
#   zcat myFastQTLphenotypes.bed.gz | awk '{ $4=$4" . +"; print $0 }' | tr " " "\t" | bgzip -c > myQTLtoolsPhenotypes.bed.gz
#
# The small example above gives 3 different ways of encoding phenotype data:
#   - pheno1/pheno1 [line1]: the most standard way for encoding a molecular phenotype. 
#     It has a unique ID (pheno1) and spans 1bp.
#   - pheno2/pheno2 [line2]: alternative way of specifying a molecular phenotype. It has a 
#     unique ID (pheno2) but spans a region of 1kb.
#   - gene1 [line3-4]: these two lines specify a group (gene1) of 2 molecular phenotypes 
#     (exon1 and exon2). Importantly, both phenotypes need to share the same coordinate otherwise 
#     QTLtools will not be able to determine that they belong to the same group.
#
# Sample IDs are specified in the header line. This line needs to start with a hash key (i.e. #).
#
# This BED file needs to be indexed with tabix as follows:
#  bgzip myPhenotypes.bed && tabix -p bed phenotypes.bed.gz
# If this doesn't work, this probably means that your BED file is not sorted, so sort it using sort.

# phenotype (expression data)
ExpData = processedData

ExpData$Chr <- NULL
ExpData$Bp_start <- NULL
ExpData$Bp_end <- NULL
ExpData[1:5,1:5]

IlluminaHumanHTV4R2[1:5, 1:12]

annot <- subset(IlluminaHumanHTV4R2, 
                select = c("Chr", "GeneStart", "GeneStart", "IlluminaID", "Symbol", "strand"))
names(annot)[names(annot) == "Chr"] <- "#Chr"
names(annot)[names(annot) == "GeneStart"] <- "start"
names(annot)[names(annot) == "GeneStart.1"] <- "end"
annot$end <- annot$start + 1
names(annot)[names(annot) == "IlluminaID"] <- "pid"
names(annot)[names(annot) == "Symbol"] <- "gid"
annot$key <- annot$pid
dim(annot)
annot[1:5,1:7]

pheno.temp <- merge(annot, ExpData, by.x = "key", by.y = "ProbeID")
dim(pheno.temp)
pheno.temp[1:5,1:9]

library(dplyr)
phenoDataNew <- distinct(pheno.temp)
phenoDataNew[1:5,1:9]
pheno.probe.list <- phenoDataNew$key

cat("\n * Checking out the overall number of probes per quality grade...\n")
# illuminaHumanv4PROBEQUALITY
# Quality grade assigned to the probe: 
# - “Perfect” if it perfectly and uniquely matches the target transcript; 
# - “Good” if the probe, although imperfectly matching the target transcript, is still 
#     likely to provide considerably sensitive signal (up to two mismatches are allowed, based on 
#     empirical evidence that the signal intensity for 50-mer probes with less than 95% identity to the 
#     respective targets is less than 50% of the signal associated with perfect matches *); 
# - “Bad” if the probe matches repeat sequences, intergenic or intronic regions, or is unlikely to 
#     provide specific signal for any transcript; 
# - “No match” if it does not match any genomic region or transcript.
IlluminaHumanHTV4R2.inphenoDataNew <- IlluminaHumanHTV4R2[IlluminaHumanHTV4R2$IlluminaID %in% pheno.probe.list,]
dim(IlluminaHumanHTV4R2.inphenoDataNew)
levels(as.factor(IlluminaHumanHTV4R2.inphenoDataNew$ProbeQuality))

bad.QC <- as.numeric(nrow(unique(subset(IlluminaHumanHTV4R2.inphenoDataNew, ProbeQuality == "Bad", select = "IlluminaID"))))
good.QC <- as.numeric(nrow(unique(subset(IlluminaHumanHTV4R2.inphenoDataNew, ProbeQuality == "Good", select = "IlluminaID"))))
good.star.QC <- as.numeric(nrow(unique(subset(IlluminaHumanHTV4R2.inphenoDataNew, ProbeQuality == "Good****", select = "IlluminaID"))))
nomatch.QC <- as.numeric(nrow(unique(subset(IlluminaHumanHTV4R2.inphenoDataNew, ProbeQuality == "No match", select = "IlluminaID"))))
perfect.QC <- as.numeric(nrow(unique(subset(IlluminaHumanHTV4R2.inphenoDataNew, ProbeQuality == "Perfect", select = "IlluminaID"))))
perfect.star.QC <- as.numeric(nrow(unique(subset(IlluminaHumanHTV4R2.inphenoDataNew, ProbeQuality == "Perfect****", select = "IlluminaID"))))

counts <- c(nomatch.QC, bad.QC, good.QC + good.star.QC, perfect.QC + perfect.star.QC)
category <- c("No match", "Bad", "Good", "Perfect")
probeQC <- data.frame(category, counts)

pdf(paste0(OUT_loc,"/",Today,".probequality.pdf"))
  barplot(counts, 
          names = c("No match\n5", "Bad\n3,102", "Good\n803", "Perfect\n25,384"),
          col = c("#595A5C", "#E55738", "#1290D9", "#49A01D"),
          border = NA,
          main = "Probe quality in CTMM\n(after QC)")
dev.off()

cat("\n* Which probes have good quality and are in the phenotype data?\n")
pheno.probe.list <- unique(phenoDataNew$key)
perfect.list <- unique(subset(IlluminaHumanHTV4R2.inphenoDataNew, ProbeQuality == "Perfect" | ProbeQuality == "Perfect****", select = "IlluminaID"))$IlluminaID

probes.intersect <- intersect(perfect.list, pheno.probe.list)
length(probes.intersect)

cat("\n* Filter CTMM expression data.\n")
phenoDataNewQC <- phenoDataNew[phenoDataNew$key %in% probes.intersect,]
dim(phenoDataNew)
dim(phenoDataNewQC)
phenoDataNewQC[1:5,1:9]
sample.list <- colnames(phenoDataNewQC[8:315])
phenoDataNewQC$AvgGeneExp <- apply(subset(phenoDataNewQC, 
                                          select = sample.list), 1, mean, na.rm = TRUE)

pdf(paste0(OUT_loc,"/",Today,".log2_gene_expression.pdf"))
hist(phenoDataNewQC$AvgGeneExp, breaks = 100,
     col = "#1290D9", border = "#FFFFFF",
     main = "Average Gene Expression\nperfect matching probes only",
     xlab = expression(log[2]~(quantile~normalized~gene~expression)))
dev.off()

# phenoDataNewQC.perGene <- ddply(phenoDataNewQC, .(gid), summarize,  AvgGeneExpPerGene = mean(AvgGeneExp))

cat("\n* Re-order to chromosome-basepair position.\n")
phenoDataNewQCsort <- arrange(phenoDataNewQC, `#Chr`, start)
dim(phenoDataNewQCsort)
phenoDataNewQCsort[1:5,1:9]
phenoDataNewQCsort[37166:37171,1:9]

cat("\n* Add leading 'zero' to chromosome.\n")
# https://stackoverflow.com/questions/5812493/adding-leading-zeros-using-r

library(stringr)
phenoDataNewQCsort$`#Chr` <- str_pad(phenoDataNewQCsort$`#Chr`, width = 2, side = "left", pad = "0")
dim(phenoDataNewQCsort)
phenoDataNewQCsort[1:5,1:9]
phenoDataNewQCsort[37166:37171,1:9]

cat("\n* Writing new data.\n")
# Note: we added a new column to the back of the dataframe, hence [,2:315]!!!
fwrite(phenoDataNewQCsort[,2:315], file = paste0(OUT_loc, "/ctmm.humanhtv4r2.qtl.bed"), 
       sep = "\t", col.names = TRUE, row.names = FALSE, na = "NA",
       showProgress = TRUE, verbose = TRUE)

cat("====================================================================================================")
cat("SAVE THE DATA")
save.image(paste0(INP_loc,"/",Today,".ctmm.pheno.creator.v2.RData"))

rm(temp, temp2, temp3, temp4, temp5, temp6, temp7, temp8,
   adrToChr, adrToEnd, adrToMap, adrToStart, 
   illuminaToENTREZID, illuminaToSymbol, 
   Humanv2RD, Humanv2RD.df,
   probeQC,
   allLocs, chrs, strand, validPos, spos, epos,
   pheno.temp, ExpData, annot)

