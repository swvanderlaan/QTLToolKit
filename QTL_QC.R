#!/hpc/local/CentOS7/dhl_ec/software/R-3.4.0/bin/Rscript --vanilla

# Alternative shebang for local Mac OS X: "#!/usr/local/bin/Rscript --vanilla"
# Linux version for HPC: #!/hpc/local/CentOS7/dhl_ec/software/R-3.4.0/bin/Rscript --vanilla
cat("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                         QTL RESULTS QUALITY CONTROL & PARSER v2
\n
* Version: v2.2.2
* Last edit: 2018-02-23
* Created by: Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl
\n
* Description:  Results parsing and quality control from QTLTools results using your data, CTMM (eQTL) or 
Athero-Express (mQTL) data. The script should be usuable on both any Linux distribution with 
R 3+ installed, Mac OS X and Windows.

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")

# usage: ./QTL_QC.R -p projectdir -r resultfile -o outputdir -t resulttype -q qtltype -a annotfile -j genstatsfile [OPTIONAL: -v verbose (DEFAULT) -q quiet]
#        ./QTL_QC.R --projectdir projectdir --resultsfile resultfile --outputdir outputdir --resulttype resulttype --qtltype qtltype --annotfile annotfile --genstats genestatfile [OPTIONAL: --verbose verbose (DEFAULT) -quiet quiet]

#--------------------------------------------------------------------------
# 1. Phenotype ID
# 2. Phenotype chrID
# 3. Phenotype start
# 4. Variant ID
# 5. Variant chrID
# 6. Variant position
# 7. Nominal P-value of association
# 8. Dummy here. Field used in approximated mapping in trans
# 9. Regression slope
#--------------------------------------------------------------------------
cat("\n* Clearing the environment...\n\n")
### CLEAR THE BOARD
rm(list = ls())

cat("\n* Loading function to install packages...\n\n")
### Prerequisite: 'optparse'-library
### * Manual: http://cran.r-project.org/web/packages/optparse/optparse.pdf
### * Vignette: http://www.icesi.edu.co/CRAN/web/packages/optparse/vignettes/optparse.pdf

### Don't say "Loading required package: optparse"...
###suppressPackageStartupMessages(require(optparse))
###require(optparse)

### The part of installing (and loading) packages via Rscript doesn't properly work.
### FUNCTION TO INSTALL PACKAGES
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

cat("\n* Checking availability of required packages and installing if needed...\n\n")
### INSTALL PACKAGES WE NEED
install.packages.auto("optparse")
install.packages.auto("tools")
install.packages.auto("data.table")
install.packages.auto("qvalue") # Needed for multiple-testing correction

cat("\nDone! Required packages installed and loaded.\n\n")

cat("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")

cat("\n* Setting colours...\n\n")
uithof_color = c("#FBB820","#F59D10","#E55738","#DB003F","#E35493","#D5267B",
                 "#CC0071","#A8448A","#9A3480","#8D5B9A","#705296","#686AA9",
                 "#6173AD","#4C81BF","#2F8BC9","#1290D9","#1396D8","#15A6C1",
                 "#5EB17F","#86B833","#C5D220","#9FC228","#78B113","#49A01D",
                 "#595A5C","#A2A3A4", "#D7D8D7", "#ECECEC", "#FFFFFF", "#000000")
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
### OPTION LISTING
option_list = list(
  make_option(c("-p", "--projectdir"), action = "store", default = NA, type = 'character',
              help = "Path to the project directory."),
  make_option(c("-r", "--resultfile"), action = "store", default = NA, type = 'character',
              help = "Path to the results directory, relative to the project directory."),
  make_option(c("-t", "--resulttype"), action = "store", default = NA, type = 'character',
              help = "The result type, either [NOM/PERM] for nominal or permutation results, respectively."),
  make_option(c("-q", "--qtltype"), action = "store", default = NA, type = 'character',
              help = "The quantitative trait locus (QTL) analysis type , either [EQTL/MQTL] for expression or methylation QTL analysis, respectively."),
  make_option(c("-o", "--outputdir"), action = "store", default = NA, type = 'character',
              help = "Path to the output directory."),
  make_option(c("-a", "--annotfile"), action = "store", default = NA, type = 'character',
              help = "Path to the annotation file."),
  make_option(c("-j", "--genstats"), action = "store", default = NA, type = 'character',
              help = "Path to the summary statistics of the genotypes."),
  make_option(c("-z", "--analysetype"), action = "store", default = NA, type = 'character',
              help = "Cis or trans [CIS/TRANS] analyse ."), 
  make_option(c("-v", "--verbose"), action = "store_true", default = TRUE,
              help = "Should the program print extra stuff out? [default %default]"),
  make_option(c("-s", "--silent"), action = "store_false", dest = "verbose",
              help = "Make the program not be verbose.")
  #make_option(c("-c", "--cvar"), action="store", default="this is c",
  #            help="a variable named c, with a default [default %default]")  
)
opt = parse_args(OptionParser(option_list = option_list))
# 
# opt$projectdir = "/Users/swvanderlaan/PLINK/analyses/ctmm/cardiogramplusc4d/ctmm_eqtl/cardiogramplusc4d/EXCL_DEFAULT_qtl/rs7528419_cardiogramplusc4d/"
# opt$outputdir = "/Users/swvanderlaan/PLINK/analyses/ctmm/cardiogramplusc4d/ctmm_eqtl/cardiogramplusc4d/EXCL_DEFAULT_qtl/rs7528419_cardiogramplusc4d/"
# opt$resulttype = "NOM"
# opt$resulttype="PERM"
# opt$qtltype = "EQTL"

### QTLTool
# opt$analysetype = "CIS"
### nom
# opt$resultfile = "/Users/swvanderlaan/PLINK/analyses/ctmm/cardiogramplusc4d/ctmm_eqtl/cardiogramplusc4d/EXCL_DEFAULT_qtl/rs7528419_cardiogramplusc4d/ctmm_QC_qtlnom_rs7528419_excl_EXCL_DEFAULT.txt.gz"
# opt$genstats = "/Users/swvanderlaan/PLINK/analyses/ctmm/cardiogramplusc4d/ctmm_eqtl/cardiogramplusc4d/EXCL_DEFAULT_qtl/rs7528419_cardiogramplusc4d/ctmm_1kGp3GoNL5_QC_rs7528419_excl_EXCL_DEFAULT.stats"
### perm
# opt$resultfile="/Users/slidetoolkit/Desktop/Jacco/expression_analysis/first_qtltoolkit_data/ctmm_QC_qtlperm_clumped_rs10953541_excl_NONMONOCYTE.txt.gz"

# opt$analysetype="TRANS"
# opt$genstats="/Users/slidetoolkit/Desktop/Jacco/expression_analysis/data/ctmm_1kGp3GoNL5_RAW_chr7.stats"
### nom
# opt$resultfile="/Users/slidetoolkit/Desktop/Jacco/expression_analysis/data/final_chr7_p0.05_trans.txt.hits_cut.txt.gz"
# opt$resultfile="/Users/slidetoolkit/Desktop/Jacco/expression_analysis/data/chr7_nominal.hits.txt.gz"
### perm
# opt$resultfile="/Users/slidetoolkit/Desktop/Jacco/expression_analysis/data/chr7_permuted_cis.txt.gz"

### End result_data
# opt$annotfile = "/Users/swvanderlaan/PLINK/_CTMM_Originals/CTMMHumanHT12v4r2_15002873B/ctmm.humanhtv4r2.annotation.txt"

#genstatistics=read.table("/Users/slidetoolkit/Desktop/Jacco/expression_analysis/data/chr7.newstats.stats")

### OPTIONLIST | FOR LOCAL DEBUGGING

if (opt$verbose) {
  # You can use either the long or short name; so opt$a and opt$avar are the same.
  # Show the user what the variables are.
  cat("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
  cat("* Checking the settings as given through the flags.")
  cat("\nThe project directory....................: ")
  cat(opt$projectdir)
  cat("\n\nThe results file.........................: ")
  cat(opt$resultfile)
  cat("\n\nThe output directory.....................: ")
  cat(opt$outputdir)
  cat("\n\nThe annotation file......................: ")
  cat(opt$annotfile)
  cat("\n\nThe results type.........................: ")
  cat(opt$resulttype)
  cat("\n\nThe QTL analysis type....................: ")
  cat(opt$qtltype)
  cat("\n\nThe variant summary statistics...........: ")
  cat(opt$genstats)
  cat("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
  cat("\n\n")
}
cat("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
cat("Wow, we are all set. Starting \"QTL Results Quality Control & Parser\".")
#--------------------------------------------------------------------------
### START OF THE PROGRAM
# main point of program is here, do this whether or not "verbose" is set
if (!is.na(opt$projectdir) & !is.na(opt$resultfile) & !is.na(opt$outputdir) & !is.na(opt$annotfile) & !is.na(opt$resulttype) & !is.na(opt$qtltype) & !is.na(opt$genstats)) {
  cat(paste("\nWe are going to make some graphs for quality control of you fastQTL analysis. \n\nAnalysing these results...............: '",file_path_sans_ext(basename(opt$resultfile), compression = TRUE),"'\nParsed results will be saved here.....: '", opt$outputdir, "'.\n",sep = ''))
  
  #--------------------------------------------------------------------------
  ### GENERAL SETUP
  Today = format(as.Date(as.POSIXlt(Sys.time())), "%Y%m%d")
  cat(paste("\nToday's date is: ", Today, ".\n", sep = ''))
  
  #--------------------------------------------------------------------------
  #### DEFINE THE LOCATIONS OF DATA
  ROOT_loc = opt$projectdir # argument 1
  OUT_loc = opt$outputdir # argument 4
  
  cat("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")
  #--------------------------------------------------------------------------
  ### LOADING ANNOTATION AND RESULTS FILES DEPENDING ON RESULT TYPE
  cat("\nLoading annotations...\n")
  ### Location of is set by 'opt$annotfile' # argument 5
  ### The type of the analysis will determine what to load 'opt$qtltype' # argument 4
  if (opt$qtltype == "EQTL") { 
    cat("\n...for a CTMM based eQTL analysis in monocytes...\n")
    ANNOTATIONSFILE = read.table(opt$annotfile, header = TRUE, stringsAsFactors = FALSE, sep = "\t", na.strings = "")
    colnames(ANNOTATIONSFILE) = c("EntrezID", "ProbeID", "ArrayID", 
                                  "GeneName", "GeneInfo","Chr", "GeneTxStart", "GeneTxEnd")
  } else if (opt$qtltype == "MQTL") {
    cat("\n...for an Athero-Express based MQTL analysis...\n")
    ANNOTATIONSFILE = read.table(opt$annotfile, header = TRUE, stringsAsFactors = FALSE, sep = ",", na.strings = "")
    
    colnames(ANNOTATIONSFILE) = c("IlmnID", "ProbeID", 
                                  "AddressA_ID", "AlleleA_ProbeSeq", "AddressB_ID", "AlleleB_ProbeSeq", 
                                  "Infinium_Design_Type", "Next_Base", "Color_Channel", "Forward_Sequence", 
                                  "Genome_Build", "CHR", "MAPINFO", "SourceSeq", "Chromosome_36", "Coordinate_36", "Strand", 
                                  "Probe_SNPs", "Probe_SNPs_10", "Random_Loci", "Methyl27_Loci", 
                                  "UCSC_RefGene_Name", "UCSC_RefGene_Accession", "UCSC_RefGene_Group", "UCSC_CpG_Islands_Name", "Relation_to_UCSC_CpG_Island", 
                                  "Phantom", "DMR", "Enhancer", "HMM_Island", "Regulatory_Feature_Name", "Regulatory_Feature_Group", "DHS", 
                                  "UCSC_RefGene_Dist")
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
         file = stderr()) # print error messages to stder
  }
  
  cat("\nLoading variant statistics...\n")
  VARIANTSTATS.RAW = read.table(opt$genstats, header = TRUE, stringsAsFactors = FALSE)
  cat("\n* calculating 'minor allele count' (MAC)...")
  # calculate MAC
  VARIANTSTATS.RAW$MAC <- (VARIANTSTATS.RAW[,19]*VARIANTSTATS.RAW[,18]*2)
  
  cat("\n* calculating 'coded allele frequency' (CAF)...")
  # calculate caf
  VARIANTSTATS.RAW$CAF <- (((2*VARIANTSTATS.RAW[,16]) + VARIANTSTATS.RAW[,15])/(VARIANTSTATS.RAW[,18]*2))
  
  cat("\n* determining which variants are solely 'imputed'...")
  # make imputation column
  if (opt$analysetype == "TRANS") {
    VARIANTSTATS.RAW$Imputation <- ifelse(VARIANTSTATS.RAW$alternate_ids == "---", 
                                          c("imputed"), c("genotyped")) 
  }
  if (opt$analysetype == "CIS") {
    VARIANTSTATS.RAW$Imputation <- ifelse(VARIANTSTATS.RAW$alternate_ids == "---", 
                                          c("imputed"), c("genotyped")) 
  }
  
  cat("\n* selecting required variant statistics data...")
  # Select the columns we need
  VARIANTSTATS = VARIANTSTATS.RAW[,c(2,3,4,5,6, # chr bp
                                     15,        # maf
                                     20,        # mac, column 23
                                     21,        # caf, column 24
                                     18,19,16,23, # imputation quality, HWE and N
                                     22)]       # imputation, column 25
  
  # Change the column names
  colnames(VARIANTSTATS) = c("VARIANT", "Chr", "BP", "OtherAlleleA", "CodedAlleleA", 
                             "MAF", "MAC", "CAF", 
                             "AvgMAxPostCall", "Info", "HWE", "N", "Imputation")
  
  ### Loading *nominal* results
  RESULTS = read.table(opt$resultfile, header = FALSE, stringsAsFactors = FALSE)
  if (opt$resulttype == "NOM") { # argument 3
    cat("\n\nLoading data from 'nominal pass'...\n")
    
    if (opt$analysetype == "CIS") {
      # 1. The phenotype ID
      # 2. The chromosome ID of the phenotype
      # 3. The start position of the phenotype
      # 4. The end position of the phenotype
      # 5. The strand orientation of the phenotype
      # 6. The total number of variants tested in cis
      # 7. The distance between the phenotype and the tested variant (accounting for strand orientation)
      # 8. The ID of the tested variant
      # 9. The chromosome ID of the variant
      # 10. The start position of the variant
      # 11. The end position of the variant
      # 12. The nominal P-value of association between the variant and the phenotype
      # 13. The corresponding regression slope
      # 14. A binary flag equal to 1 is the variant is the top variant in cis
      RESULTS = RESULTS[ , c(1, 8, 7, 12, 13)]
    }
    if (opt$analysetype == "TRANS") {
      # 1. Phenotype ID
      # 2. Phenotype chrID
      # 3. Phenotype start
      # 4. Variant ID
      # 5. Variant chrID
      # 6. Variant position
      # 7. Nominal P-value of association
      # 8. Dummy here. Field used in approximated mapping in trans
      # 9. Regression slope
      RESULTS = RESULTS[ , c(1, 4, 6, 7, 9)]
    }
    colnames(RESULTS) = c("ProbeID", "VARIANT", "Distance_VARIANT_ProbeID", "Nominal_P", "Beta")
    
    #--------------------------------------------------------------------------
    ### PLOTTING NOMINAL RESULTS
    cat("\nPlotting results...\n") 
    ## To check that the beta approximated permutation p-values are well estimated.
    pdf(paste0(opt$outputdir, "/",# map to the output directory
               ###Today,"_", # add in Today's date -- removed as it causes issues in downstream projects when its the 'next day'
               file_path_sans_ext(basename(opt$resultfile), compression = TRUE), # get the basename file without the extension and any compression extensions
               "_histogram_nominal_beta.pdf"), onefile = TRUE)
      hist(RESULTS$Beta, 
           breaks = 10000,
           xlab = "Effect size", ylab = "Distribution", 
           main = "Overall distribution of effect size", 
           col = "#1290D9")
      abline(v = mean(RESULTS$Beta), col = "#E55738")
      abline(v = (mean(RESULTS$Beta) - 4*sd(RESULTS$Beta)), col = "#E55738", lty = 2)
      abline(v = (mean(RESULTS$Beta) + 4*sd(RESULTS$Beta)), col = "#E55738", lty = 2)
    dev.off()
    
  } else if (opt$resulttype == "PERM") { ### Loading *permutation* results 
    cat("\nLoading data from 'permutation pass'...\n")
    # old RESULTS = RESULTS[ , c(1, 4, 3, 7, 9)]
    # full pass
    if (opt$analysetype == "CIS") {
      # 1. The phenotype ID
      # 2. The chromosome ID of the phenotype
      # 3. The start position of the phenotype
      # 4. The end position of the phenotype
      # 5. The strand orientation of the phenotype
      # 6. The total number of variants tested in cis
      # 7. The distance between the phenotype and the tested variant (accounting for strand orientation)
      # 8. The ID of the top variant
      # 9. The chromosome ID of the top variant
      # 10. The start position of the top variant
      # 11. The end position of the top variant
      # 12. The number of degrees of freedom used to compute the P-values
      # 13. Dummy
      # 14. The first parameter value of the fitted beta distribution
      # 15. The second parameter value of the fitted beta distribution (it also gives the effective number of independent tests in the region)
      # 16. The nominal P-value of association between the phenotype and the top variant in cis
      # 17. The corresponding regression slope
      # 18. The P-value of association adjusted for the number of variants tested in cis given by the direct method (i.e. empirircal P-value)
      # 19. The P-value of association adjusted for the number of variants tested in cis given by the fitted beta distribution. We strongly recommend to use this adjusted P-value in any downstream analysis
      RESULTS = RESULTS[ , c(1, 6, 15, 15, 13, 8, 7, 16, 17, 18, 19)]
    }
    if (opt$analysetype == "TRANS") {
      # nog geen idee hoe de permuted results van QTLTools eruit zien
      RESULTS = RESULTS[ , c(1, 6, 15, 15, 13, 8, 7, 16, 17, 18, 19)]
    }  
    #RESULTS = read.table(opt$resultfile, head = FALSE, stringsAsFactors = FALSE)
    colnames(RESULTS) = c("ProbeID", "NVariants", "MLE_Beta_shape1", "MLE_Beta_shape2", "Dummy", 
                          "VARIANT", "Distance_VARIANT_ProbeID", "Nominal_P", "Beta", "Perm_P", "Approx_Perm_P")
    
    #--------------------------------------------------------------------------
    ### PLOTTING PERMUTATION RESULTS
    pdf(paste0(opt$outputdir, "/",# map to the output directory
               ###Today,"_", # add in Today's date -- removed as it causes issues in downstream projects when its the 'next day'
               file_path_sans_ext(basename(opt$resultfile), compression = TRUE), # get the basename file without the extension and any compression extensions
               "_comparing_permutation_pvalues.pdf"), onefile = TRUE)
    
      plot(RESULTS$Perm_P, RESULTS$Approx_Perm_P, 
           xlab = "Direct method", ylab = "Beta approximation", 
           main = "Comparing permuted p-values", bty = "n", 
           pch = 20, col = "#1290D9")
      abline(0, 1, col = "#E55738")
      hist(RESULTS$Beta, 
           breaks = 25,
           xlab = "Effect size", ylab = "Distribution", 
           main = "Overall distribution of effect size", 
           #bty = "n", 
           col = "#1290D9"
      )
      abline(v = mean(RESULTS$Beta), col = "#E55738")
      abline(v = (mean(RESULTS$Beta) - 4*sd(RESULTS$Beta)), col = "#E55738", lty = 2)
      abline(v = (mean(RESULTS$Beta) + 4*sd(RESULTS$Beta)), col = "#E55738", lty = 2)
    dev.off()
    
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
         file = stderr()) # print error messages to stder
  }
  
  #--------------------------------------------------------------------------
  ### GET Z-SCORES, SD & SEM
  cat("\nGet Z-scores, sd and sem from p-values...\n")
  ### references:
  ###     - http://stats.stackexchange.com/questions/101136/how-can-i-find-a-z-score-from-a-p-value
  RESULTS$Z = qnorm(RESULTS$Nominal_P)
  
  ### Get standard deviation (SD)
  RESULTS$SD = (RESULTS$Beta - mean(RESULTS$Beta))/RESULTS$Z
  
  ### Get standard error of the mean (SEM)
  RESULTS$SEM = RESULTS$Beta/RESULTS$Z
  
  #--------------------------------------------------------------------------
  #### APPLY MULTIPLE TESTING CORRECTION ###
  cat("\nApplying multiple testing correction methods.\n")
  
  cat("\n* Conservative correction: Bonferroni correction...\n")
  ### Bonferroni correction - Conservative
  ### references:
  ###     - http://en.wikipedia.org/wiki/Bonferroni_correction
  ###     - https://stat.ethz.ch/R-manual/R-devel/library/stats/html/p.adjust.html
  if (opt$resulttype == "NOM") {
    RESULTS$Bonferroni = p.adjust(RESULTS$Nominal_P, method = "bonferroni")
  } else if (opt$resulttype == "PERM") {
    RESULTS$Bonferroni = p.adjust(RESULTS$Approx_Perm_P, method = "bonferroni")
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
        file = stderr()) # print error messages to stder
  }
  
  cat("\n* Less conservative correction: Benjamini & Hochberg correction...\n")
  ### Benjamini & Hochberg correction - Less conservative
  ### references:
  ###     - http://en.wikipedia.org/wiki/False_discovery_rate
  ###     - https://stat.ethz.ch/R-manual/R-devel/library/stats/html/p.adjust.html
  if (opt$resulttype == "NOM") {
    RESULTS$BenjHoch = p.adjust(RESULTS$Nominal_P, method = "fdr")
  } else if (opt$resulttype == "PERM") {
    RESULTS$BenjHoch = p.adjust(RESULTS$Approx_Perm_P, method = "fdr")
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
        file = stderr()) # print error messages to stder
  }
  
  cat("\n* Least conservative correction: Storey & Tibshirani correction...\n")
  ### Storey & Tibshirani correction - Least conservative
  ### references:
  ###     - http://en.wikipedia.org/wiki/False_discovery_rate
  ###     - http://svitsrv25.epfl.ch/R-doc/library/qvalue/html/qvalue.html
  ### Requires a bioconductor package: "qvalue"
  # if(opt$resulttype == "NOM") {
  #   # min(RESULTS$Nominal_P)
  #   # install.packages("devtools")
  #   # library(devtools)
  #   # install_github("jdstorey/qvalue")  
  # RESULTS$Q = qvalue(RESULTS$Nominal_P)$qvalues
  # } else if(opt$resulttype == "PERM") {
  #  RESULTS$Q = qvalue(RESULTS$Approx_Perm_P)$qvalues
  # } else {
  #  cat ("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n",
  #       file=stderr()) # print error messages to stder
  # }
  RESULTS$Q = "not calculated due to a bug in the package"
  #--------------------------------------------------------------------------
  #### ADD IN THE ANNOTATIONS ###
  cat("\nApplying annotations.\n")
  cat("\n* First order based on Benjamini-Hochberg p-values...\n")
  RESULTS.toANNOTATE = RESULTS[order(RESULTS$BenjHoch),]
  
  cat("\n* Now annotating...\n")
  if (opt$qtltype == "EQTL") { 
    cat("\n...the results of a CTMM based eQTL analysis in monocytes.\n")
    RESULTS.toANNOTATE = cbind(RESULTS.toANNOTATE, ANNOTATIONSFILE[match(RESULTS.toANNOTATE[,1], ANNOTATIONSFILE$ProbeID ), 
                                                                   c("EntrezID","ArrayID", 
                                                                     "GeneName", "GeneInfo",
                                                                     "Chr", "GeneTxStart", "GeneTxEnd")])
    
  } else if (opt$qtltype == "MQTL") {
    cat("\n...the results of an Athero-Express based MQTL analysis.\n")
    RESULTS.toANNOTATE = cbind(RESULTS.toANNOTATE, ANNOTATIONSFILE[match(RESULTS.toANNOTATE[,1], ANNOTATIONSFILE$ProbeID ), 
                                                                   c("IlmnID", "ProbeID", 
                                                                     "AddressA_ID", "AlleleA_ProbeSeq", "AddressB_ID", "AlleleB_ProbeSeq", 
                                                                     "Infinium_Design_Type", "Next_Base", "Color_Channel", "Forward_Sequence", 
                                                                     "Genome_Build", "CHR", "MAPINFO", "SourceSeq", "Chromosome_36", "Coordinate_36", "Strand", 
                                                                     "Probe_SNPs", "Probe_SNPs_10", "Random_Loci", "Methyl27_Loci", 
                                                                     "UCSC_RefGene_Name", "UCSC_RefGene_Accession", "UCSC_RefGene_Group", "UCSC_CpG_Islands_Name", "Relation_to_UCSC_CpG_Island", 
                                                                     "Phantom", "DMR", "Enhancer", "HMM_Island", "Regulatory_Feature_Name", "Regulatory_Feature_Group", "DHS", 
                                                                     "UCSC_RefGene_Dist")])
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
        file = stderr()) # print error messages to stder
  }
  
  cat("\n* Merging results, genetic stats, and annotations...\n")
  if (opt$resulttype == "NOM") {
    RESULTS.toANNOTATE2 = cbind(RESULTS.toANNOTATE, VARIANTSTATS[match(RESULTS.toANNOTATE[,2], VARIANTSTATS$VARIANT ),])
  } else if (opt$resulttype == "PERM") {
    RESULTS.toANNOTATE2 = cbind(RESULTS.toANNOTATE, VARIANTSTATS[match(RESULTS.toANNOTATE[,6], VARIANTSTATS$VARIANT ),])
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
        file = stderr()) # print error messages to stder
  }
  
  if (opt$qtltype == "EQTL") { 
    cat("\n* Parsing annotated results for a CTMM eQTL analysis in monocytes...\n")
    if (opt$resulttype == "NOM") {
      cat("\n--- nominal results ---\n")
      RESULTS.ANNOTATE = RESULTS.toANNOTATE2[,c(1,2,20,21,22,23,24,25,26,29,28,31,30, # Variant information
                                                14,12,3,16,17,18, # Gene information
                                                5,8,4,9,10,11)] # association statistics
    } else if (opt$resulttype == "PERM") {
      cat("\n--- permuted results ---\n")
      RESULTS.ANNOTATE = RESULTS.toANNOTATE2[,c(1,6,26,27,28,29,30,31,32,35,34,37,36, # Variant information
                                                20,18,7,22,23,24, # Gene information
                                                9,14,8,10,11,15,16,17)] # association statistics
    } else {
      cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
          file = stderr()) # print error messages to stder
    }
    
  } else if (opt$qtltype == "MQTL") {
    cat("\n* Parsing annotated results for an Athero-Express mQTL analysis...\n")
    if (opt$resulttype == "NOM") {
      cat("\n--- nominal results ---\n")
      RESULTS.ANNOTATE = RESULTS.toANNOTATE2[,c(1,2,47,48,49,50,51,52,53,56,55,58,57, # Variant information
                                                3,23,24,18, # CpG information
                                                33,34,35,37,38,39,40,41,42,43,44, # CpG associated information
                                                5,8,4,9,10,11)] # association statistics
    } else if (opt$resulttype == "PERM") {
      cat("\n--- permuted results ---\n")
      RESULTS.ANNOTATE = RESULTS.toANNOTATE2[,c(1,6,53,54,55,56,57,58,59,62,61,64,63, # Variant information
                                                7,29,30,24, # CpG information
                                                39,40,41,43,44,45,46,47,48,49,50, # CpG associated information
                                                9,14,8,10,11,15,16,17)] # association statistics
    } else {
      cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
          file = stderr()) # print error messages to stder
    }
    
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
        file = stderr()) # print error messages to stder
  } 
  
  cat("\n* Remove duplicate gene names...\n")
  if (opt$qtltype == "EQTL") { 
    cat("\n...for results of a CTMM eQTL analysis in monocytes...\n")
    RESULTS.ANNOTATE[, "GeneName"] = as.character(lapply(RESULTS.toANNOTATE2[,"GeneName"], 
                                                         FUN = function(x){paste(unique(unlist(strsplit(x, split = ";"))), sep = "", collapse = ";")}))
  } else if (opt$qtltype == "MQTL") {
    cat("\n...for results of an Athero-Express mQTL analysis...\n")
    RESULTS.ANNOTATE[, "UCSC_RefGene_Name"] = as.character(lapply(RESULTS.toANNOTATE2[,"UCSC_RefGene_Name"], 
                                                                  FUN = function(x){paste(unique(unlist(strsplit(x, split = ";"))), sep = "", collapse = ";")}))
    RESULTS.ANNOTATE[, "UCSC_RefGene_Accession"] = as.character(lapply(RESULTS.toANNOTATE2[,"UCSC_RefGene_Accession"],
                                                                       FUN = function(x){paste(unique(unlist(strsplit(x, split = ";"))), sep = "", collapse = ";")}))
    RESULTS.ANNOTATE[, "UCSC_RefGene_Group"] = as.character(lapply(RESULTS.toANNOTATE2[,"UCSC_RefGene_Group"],
                                                                   FUN = function(x){paste(unique(unlist(strsplit(x, split = ";"))), sep = "", collapse = ";")}))
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
        file = stderr()) # print error messages to stder
  }
  
  cat("\n* Correct Colnames...\n")
  if (opt$qtltype == "EQTL") { 
    cat("\n...for results of a CTMM eQTL analysis in monocytes...\n")
    if (opt$resulttype == "NOM") {
      colnames(RESULTS.ANNOTATE) = c("ProbeID", "VARIANT", "Chr", "BP", "OtherAlleleA", "CodedAlleleA", "MAF", "MAC", "CAF", "HWE", "Info", "Imputation", "N", 
                                     "GeneName", "EntrezID", "Distance_VARIANT_GENE", "Chr_Gene", "GeneTxStart", "GeneTxEnd",
                                     "Beta", "SE", "Nominal_P", "Bonferroni","BenjHoch","Q")
    } else if (opt$resulttype == "PERM") {
      colnames(RESULTS.ANNOTATE) = c("ProbeID", "VARIANT", "Chr", "BP", "OtherAlleleA", "CodedAlleleA", "MAF", "MAC", "CAF", "HWE", "Info", "Imputation", "N", 
                                     "GeneName","EntrezID", "Distance_VARIANT_GENE", "Chr_Gene", "GeneTxStart", "GeneTxEnd",
                                     "Beta", "SE", "Nominal_P","Perm_P","ApproxPerm_P", "Bonferroni","BenjHoch","Q")
    } else {
      cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
          file = stderr()) # print error messages to stder
    }
    
  } else if (opt$qtltype == "MQTL") {
    cat("\n...for results of an Athero-Express mQTL analysis...\n")
    if (opt$resulttype == "NOM") {
      colnames(RESULTS.ANNOTATE) = c("ProbeID", "VARIANT", "Chr", "BP", "OtherAlleleA", "CodedAlleleA", "MAF", "MAC", "CAF", "HWE", "Info", "Imputation", "N", 
                                     "Distance_VARIANT_CpG", "Chr_CpG", "BP_CpG",
                                     "ProbeType", "GeneName_UCSC", "AccessionID_UCSC", "GeneGroup_UCSC", 
                                     "CpG_Island_Relation_UCSC", "Phantom", "DMR", "Enhancer", "HMM_Island",
                                     "RegulatoryFeatureName", "RegulatoryFeatureGroup", "DHS",
                                     "Beta", "SE", "Nominal_P", "Bonferroni","BenjHoch","Q")
    } else if (opt$resulttype == "PERM") {
      colnames(RESULTS.ANNOTATE) = c("ProbeID", "VARIANT", "Chr", "BP", "OtherAlleleA", "CodedAlleleA", "MAF", "MAC", "CAF", "HWE", "Info", "Imputation", "N", 
                                     "Distance_VARIANT_CpG", "Chr_CpG", "BP_CpG",
                                     "ProbeType", "GeneName_UCSC", "AccessionID_UCSC", "GeneGroup_UCSC", 
                                     "CpG_Island_Relation_UCSC", "Phantom", "DMR", "Enhancer", "HMM_Island",
                                     "RegulatoryFeatureName", "RegulatoryFeatureGroup", "DHS",
                                     "Beta", "SE", "Nominal_P","Perm_P","ApproxPerm_P", "Bonferroni","BenjHoch","Q")
    } else {
      cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
           file = stderr()) # print error messages to stder
    }
    
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
         file = stderr()) # print error messages to stder
  }
  
  cat("\n* Remove temporary files...\n")
  #rm(RESULTS.toANNOTATE, RESULTS.toANNOTATE2)
  
  #--------------------------------------------------------------------------
  ### SAVE NEW DATA ###
  cat("\n* Saving parsed data...\n")
  if (opt$resulttype == "NOM") {
    #write.table(RESULTS.ANNOTATE[which(RESULTS.ANNOTATE$Q <= 0.05), ], # with filtering on Q-value 
    write.table(RESULTS.ANNOTATE[which(RESULTS.ANNOTATE$BenjHoch <= 0.05), ], # without filtering on Q-value
                #paste0(opt$outputdir, "/", 
                #       ###Today,"_", # add in Today's date -- removed as it causes issues in downstream projects when its the 'next day'
                #       file_path_sans_ext(basename(opt$resultfile), compression = TRUE), 
                #       "_nominal.P0_05.txt"),
                paste0(opt$outputdir, "/", 
                       ###Today,"_", # add in Today's date -- removed as it causes issues in downstream projects when its the 'next day'
                       file_path_sans_ext(basename(opt$resultfile), compression = TRUE), 
                       "_nominal.all.txt"),
                quote = FALSE , row.names = FALSE, col.names = TRUE, sep = ",", na = "NA", dec = ".")
  } else if (opt$resulttype == "PERM") {
    write.table(RESULTS.ANNOTATE[which(RESULTS.ANNOTATE$BenjHoch <= 0.05), ], # with filtering on Q-value 
                #write.table(RESULTS.ANNOTATE[which(RESULTS.ANNOTATE$Q != "NA"), ], # without filtering on Q-value
                paste0(opt$outputdir, "/", 
                       ###Today,"_", # add in Today's date -- removed as it causes issues in downstream projects when its the 'next day'
                       file_path_sans_ext(basename(opt$resultfile), compression = TRUE), 
                       "_perm.P0_05.txt"),
                #paste0(opt$outputdir, "/", 
                #        ###Today,"_", # add in Today's date -- removed as it causes issues in downstream projects when its the 'next day' 
                #        file_path_sans_ext(basename(opt$resultfile), compression = TRUE), 
                #       "_perm.all.txt"),
                quote = FALSE , row.names = FALSE, col.names = TRUE, sep = ",", na = "NA", dec = ".")
  } else {
    cat("\n\n*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please.\n\n", 
         file = stderr()) # print error messages to stder
  }
  
} else {
  cat("*** ERROR *** You didn't specify all variables:\n
      - --p/projectdir : path to project directory\n
      - --r/resultdir  : path to results directory\n
      - --o/outputdir  : path to output directory\n
      - --t/resulttype : the results type (NOM for nominal; PERM for permutation)\n
      - --q/qtltype    : the QTL analysis type (EQTL for expression QTL; MQTL for methylation QTL)\n
      - --a/annotfile  : path to annotation file of genes\n
      - --j/genstats   : path to summary statistics of variants\n\n", 
      file = stderr()) # print error messages to stderr
}

#--------------------------------------------------------------------------
### CLOSING MESSAGE
cat(paste("All done parsing fastQTL data on",file_path_sans_ext(basename(opt$resultfile), compression = TRUE),".\n"))
cat(paste("\nToday's: ",Today, "\n"))
cat("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n")

#--------------------------------------------------------------------------
### SAVE ENVIRONMENT | FOR DEBUGGING
# if(opt$resulttype == "NOM")
#   save.image(paste0(opt$outputdir, "/",Today,"_",file_path_sans_ext(basename(opt$resultfile), compression = TRUE),"_NOM_DEBUG_FastQTL_analysis.RData"))
# if(opt$resulttype == "PERM")
#   save.image(paste0(opt$outputdir, "/",Today,"_",file_path_sans_ext(basename(opt$resultfile), compression = TRUE),"_PERM_DEBUG_FastQTL_analysis.RData"))

