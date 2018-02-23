#!/bin/bash
#
# CHANGES MADE BY JACCO SCHAAP 
# - Removed rootdir path in region and covariate file specification 
# - Also for v3 changed dataset to a pruned one
# - Besides that the jobnames aren't unique so we can't run multiple QTL analyses at the same time

### REGARDING NOTES ###
### Please note that uncommented notes can be found at the end of this script.
###

### MoSCoW FEATURE LIST ###
###
###

### Creating display functions
### Setting colouring
NONE='\033[00m'
OPAQUE='\033[2m'
FLASHING='\033[5m'
BOLD='\033[1m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
STRIKETHROUGH='\033[9m'

RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'

function echobold { #'echobold' is the function name
    echo -e "${BOLD}${1}${NONE}" # this is whatever the function needs to execute, note ${1} is the text for echo
}
function echoitalic { 
    echo -e "${ITALIC}${1}${NONE}" 
}
function echonooption { 
    echo -e "${OPAQUE}${RED}${1}${NONE}"
}
function echoerrorflash { 
    echo -e "${RED}${BOLD}${FLASHING}${1}${NONE}" 
}
function echoerror { 
    echo -e "${RED}${1}${NONE}"
}
# errors no option
function echoerrornooption { 
    echo -e "${YELLOW}${1}${NONE}"
}
function echoerrorflashnooption { 
    echo -e "${YELLOW}${BOLD}${FLASHING}${1}${NONE}"
}

script_copyright_message() {
	echo ""
	THISYEAR=$(date +'%Y')
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "+ The MIT License (MIT)                                                                                 +"
	echo "+ Copyright (c) 2015-${THISYEAR} Sander W. van der Laan                                                        +"
	echo "+                                                                                                       +"
	echo "+ Permission is hereby granted, free of charge, to any person obtaining a copy of this software and     +"
	echo "+ associated documentation files (the \"Software\"), to deal in the Software without restriction,         +"
	echo "+ including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, +"
	echo "+ and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, +"
	echo "+ subject to the following conditions:                                                                  +"
	echo "+                                                                                                       +"
	echo "+ The above copyright notice and this permission notice shall be included in all copies or substantial  +"
	echo "+ portions of the Software.                                                                             +"
	echo "+                                                                                                       +"
	echo "+ THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT     +"
	echo "+ NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                +"
	echo "+ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES  +"
	echo "+ OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN   +"
	echo "+ CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                            +"
	echo "+                                                                                                       +"
	echo "+ Reference: http://opensource.org.                                                                     +"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

script_arguments_error() {
	echoerror "Number of arguments found "$#"."
	echoerror ""
	echoerror "$1" # additional error message
	echoerror ""
	echoerror "========================================================================================================="
	echoerror "                                              OPTION LIST"
	echoerror ""
	echoerror " * Argument #11  configurationfile: qtl.config."
# 	echoerror " * Argument #1   indicate which study type you want to analyze, so either [AEMS450K1/AEMS450K2/CTMM]:"
# 	echoerror "                 - AEMS450K1: methylation quantitative trait locus (mQTL) analysis "
# 	echoerror "                              on plaques or blood in the Athero-Express Methylation "
# 	echoerror "                              Study 450K prune100 1."
# 	echoerror "                 - AEMS450K2: mQTL analysis on plaques or blood in the Athero-Express"
# 	echoerror "                              Methylation Study 450K prune100 2."
# 	echoerror "                 - CTMM:      expression QTL (eQTL) analysis in monocytes from CTMM."
# 	echoerror " * Argument #2   the sample type must be [AEMS450K1: PLAQUES/BLOOD], "
# 	echoerror "                 [AEMS450K2: PLAQUES], or [CTMM: MONOCYTES]."
# 	echoerror " * Argument #3   the root directory, e.g. /hpc/dhl_ec/svanderlaan/projects/test_qtl."
# 	echoerror " * Argument #4   where you want stuff to be save inside the rootdir, "
# 	echoerror "                 e.g. mqtl_aems450k1"
# 	echoerror " * Argument #5   project name, e.g. 'CAD'."
# 	echoerror " * Argument #6   text file with on each line the regions of interest, refer to "
# 	echoerror "                 example file."
# 	echoerror " * Argument #7   the type of exclusion to apply: "
# 	echoerror "                 - AEMS/CTMM:     DEFAULT/SMOKER/NONSMOKER/MALES/FEMALES/T2D/NONT2D/NONMONOCYTE "
# 	echoerror "                 - AEMS-specific: CKD/NONCKD/PRE2007/POST2007/NONAEGS/NONAEGSFEMALES/NONAEGSMALES."
# 	echoerror " * Argument #8   text file with excluded covariates, refer to example file."
# 	echoerror " * Argument #9   qsub e-mail address, e.g. s.w.vanderlaan-2@umcutrecht.nl."
# 	echoerror " * Argument #10  qsub mail settings, e.g. 'beas' - refer to qsub manual."
# 	echoerror " * Argument #11  configurationfile: qtl.config."
# 	echoerror " * Argument #12  CIS or TRANS? [CIS/TRANS]"
# 	echoerror " * Argument #13  plot clumped set? [Y/N]"
# 	echoerror " * Argument #14  Threshold for rsquared, optional"
	echoerror ""
	echoerror " An example command would be: "
	echoerror "./QTLAnalyzer.sh [arg1]"
	echoerror ""
	echoerror "========================================================================================================="
  	# The wrong arguments are passed, so we'll exit the script now!
  	script_copyright_message
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "+                                       QUANTITATIVE TRAIT LOCUS ANALYZER                               +"
echobold "+                                                                                                       +"
echobold "+                                                                                                       +"
echobold "+ * Written by  : Sander W. van der Laan; Jacco Schaap                                                  +"
echobold "+ * E-mail      : s.w.vanderlaan-2@umcutrecht.nl; jacco_schaap@hotmail.com                              +"
echobold "+ * Last update : 2018-02-21                                                                            +"
echobold "+ * Version     : 2.2.0                                                                                 +"
echobold "+                                                                                                       +"
echobold "+ * Description : This script will set some directories, and execute a cis- or -trans-QTL analysis      +"
echobold "+                 according to your specifications and using either [your/AE/CTMM] methylation          +"
echobold "+                 or expression data.                                                                   +"
echobold "+                                                                                                       +"
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Today's date and time: "$(date)
TODAY=$(date +"%Y%m%d")
echo ""

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 1 ]]; then 
	echoerrorflash "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "You must supply at least [1] argument when running a mQTL or eQTL analysis using Athero-Express 
or CTMM data!"
	
elif [[ (${STUDY_TYPE} = "AEMS450K1" || ${STUDY_TYPE} = "AEMS450K2") && ${SAMPLE_TYPE} = "MONOCYTES" ]]; then 
	echoerrorflash "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "When running a *** mQTL analysis *** using ${STUDY_TYPE}, you must supply 'PLAQUES' or 'BLOOD' 
as SAMPLE_TYPE!"
	
elif [[ ${STUDY_TYPE} = "AEMS450K2" && ${SAMPLE_TYPE} = "BLOOD" ]]; then 
	echoerrorflash "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "When running a *** mQTL analysis *** using ${STUDY_TYPE}, you must supply 'PLAQUES' as 
SAMPLE_TYPE!"
	
elif [[ ${STUDY_TYPE} = "CTMM" && (${SAMPLE_TYPE} = "PLAQUES" || ${SAMPLE_TYPE} = "BLOOD") ]]; then 
	echoerrorflash "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "When running a *** eQTL analysis *** using ${STUDY_TYPE}, you must supply 'MONOCYTES' as 
SAMPLE_TYPE!"
	
else

	### LOADING CONFIGURATION FILE
	# Loading the configuration file (please refer to the QTLToolKit-Manual for specifications of this file). 
	source "$1" # Depends on arg1.
	
	### REQUIRED | GENERALS	
	CONFIGURATIONFILE="$1" # Depends on arg1 -- but also on where it resides!!!
	
	### MAIL SETTINGS
	EMAIL=${YOUREMAIL}
	MAILTYPE=${MAILSETTINGS}
	
	### QSUB SETTINGS
	QUEUE_QCTOOL=${QUEUE_QCTOOL_CONFIG}
	VMEM_QCTOOL=${VMEM_QCTOOL_CONFIG}
	QUEUE_NOM=${QUEUE_NOM_CONFIG}
	VMEM_NOM=${VMEM_NOM_CONFIG}
	QUEUE_PERM=${QUEUE_PERM_CONFIG}
	VMEM_PERM=${VMEM_PERM_CONFIG}

	### QTL SETTINGS
	SEEDNO=${SEEDNO_CONFIG}
	PERMSTART=${PERMSTART_CONFIG}
	PERMEND=${PERMEND_CONFIG}
	
	### QCTOOL SETTINGS
	MAF=${MAF_CONFIG}
	INFO=${INFO_CONFIG}
	HWE=${HWE_CONFIG}
	
	### SET STUDY AND SAMPLE TYPE
	### Note: All analyses with AE data are presumed to be constrained to CEA-patients only.
	###       You can set the exclusion criteria 'NONAEGS/FEMALES/MALES' if you want to analyse
	###       all AE data!
	### Set the analysis type.
	STUDY_TYPE=${STUDY_TYPE} # AEMS450K1/AEMS450K2/CTMM
	
	### Set the analysis type.
	SAMPLE_TYPE=${SAMPLE_TYPE} # AE: PLAQUES/BLOOD; CTMM: MONOCYTES
	
	### GENERIC SETTINGS
	SOFTWARE=${SOFTWARE}
	QTLTOOLKIT=${QTLTOOLKIT}
	### FOR DEBUG
	### QTLTOOLKIT=/hpc/dhl_ec/jschaap/QTLToolKit
	### FOR DEBUG
	QCTOOL=${QCTOOL}
	SNPTEST252=${SNPTEST252}
	QTLTOOLS=${QTLTOOLS}
	LZ13=${LZ13}
	BGZIP=${BGZIP}
	TABIX=${TABIX}
	PLINK=${PLINK}
	PYTHON=${PYTHON}

	### PROJECT SPECIFIC 
	ROOTDIR=${ROOTDIR} # the root directory, e.g. /hpc/dhl_ec/svanderlaan/projects/test_qtl
	PROJECTNAME=${PROJECTNAME} # e.g. "CAD"
	PROJECTDIR=${ROOTDIR}/${PROJECTNAME} # where you want stuff to be save inside the rootdir, e.g. mqtl_aems450k1
	
	if [ ! -d ${ROOTDIR}/${PROJECTDIR} ]; then
				echo "The project directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${ROOTDIR}/${PROJECTDIR}
			else
				echo "The project directory '${PROJECTDIR}' already exists."
			fi
	PROJECT=${ROOTDIR}/${PROJECTDIR}

	### DEFINE REGION(S)
	REGIONS=${REGIONS_FILE} # regions_for_eqtl.txt OR regions_for_qtl.small.txt
	
	### SET EXCLUSION TYPE & COVARIATES
	EXCLUSION_TYPE=${EXCLUSION_TYPE} # e.g. "DEFAULT" -- DEFAULT/SMOKER/NONSMOKER/MALES/FEMALES/T2D/NONT2D [CKD/NONCKD/PRE2007/POST2007/NONAEGS/NONAEGSFEMALES/NONAEGSMALES -- these are AE-specific!!!]
	EXCLUSION_LIST=${EXCLUSION_LIST} # e.g. exclusion list to use
	EXCLUSION_COV=${EXCLUSION_COV} # e.g. "excl_cov.txt"
	
	### SETTING STUDY AND SAMPLE TYPE SPECIFIC THINGS
	ORIGINALS=${ORIGINALS}
	GENETICDATA=${GENETICDATA}
	OMICSDATA=${OMICSDATA}
	SNPTESTDATA=${SNPTESTDATA}
	SNPTESTOUTPUTDATA=${SNPTESTOUTPUTDATA}
	QTLDATA=${QTLDATA}
	QTLINDEX=${QTLINDEX}
	ANALYSISTYPE=${ANALYSISTYPE} # indicates the type of analysis, needed for the QC-R-script [MQTL/EQTL]
	QTL_TYPE=${QTL_TYPE} # CIS or TRANS

	### COVARIATES FILE
	COVARIATES=${COVARIATES}

	### ANNOTATION FILE
	ANNOTATIONFILE=${ANNOTATIONFILE}


	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "The following is set:"
	echo ""
	echo "Software directory                                                    ${SOFTWARE}"
	echo "Where \"qctool\" resides                                                ${QCTOOL}"
	echo "Where \"QTLTools\" resides.                                             ${QTLTOOLS}"
	echo "Where \"bgzip\" resides                                                 ${BGZIP}"
	echo "Where \"tabix\" resides                                                 ${TABIX}"
	echo "Where \"snptest 2.5.2\" resides                                         ${LZ13}"
	echo "Where \"LocusZoom 1.3\" resides                                         ${SNPTEST252}"
	echo "Where \"PLINK\" resides                                                 ${PLINK}"
	echo "Where \"Python\" resides                                                ${PYTHON}"
	echo ""

	echo "Original Omics/Athero-Express/CTMM data directory                     ${ORIGINALS}"
	echo "Omics/AEGS/CTMM genetic data directory (1kGp3v5+GoNL5)                ${GENETICDATA}"
	echo ""
	echo "Expression or methylation data directory                              ${OMICSDATA}"
	echo ""     
	echo "Annotation file accompanying expression or methylation data           ${ANNOTATIONFILE}"
	echo ""     
	echo "Project directory                                                     ${PROJECT}"
	echo ""
	echo "The analysis type and QTL type are                                    ${QTL_TYPE}-${ANALYSISTYPE}"
	echo ""
	
	echo "Additional QTLTools specific settings:"     
	echo ""     
	echo "Seed number                                                           ${SEEDNO}"
	
	echo ""     
	echo "We will run this script on [ ${TODAY} ] and check some things before we start."
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	echo ""
	echo "Checking some parameters and creating directories along the way."
	### Check parameters for content 
	if [ -s ${REGIONS} ]; then
		echo 'Text file with regions of interest exists and is not empty.'
	else
		echo '!!! Text file with regions of interest does not exist or is empty('${REGIONS}'). Please change this parameter!'
		exit
	fi
	if [ -a ${EXCLUSION_COV} ]; then
		echo 'Text file with excluded covariates is not empty.'
	else
		echo '!!! Text file with excluded covariates does not exist ('${EXCLUSION_COV}'). Please change this parameter!'
		exit
	fi
	
	# Create results directory
	if [ ! -d ${PROJECT}/${EXCLUSION_TYPE}_qtl ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/${EXCLUSION_TYPE}_qtl
		else
			echo "The regional directory already exists."
		fi
	RESULTS=${PROJECT}/${EXCLUSION_TYPE}_qtl
	# Summary directory
	if [ ! -d ${PROJECT}/${EXCLUSION_TYPE}_qtl_summary ]; then
		echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
		mkdir -v ${PROJECT}/${EXCLUSION_TYPE}_qtl_summary
	else
		echo "The regional directory already exists."
	fi
	SUMMARY=${PROJECT}/${EXCLUSION_TYPE}_qtl_summary
	
	### OVERVIEW OF REGIONS
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "The list of regions to investigate:"
		echo "* Variant	Locus	Chr	BP	StartRange	EndRange	WindowSize	Type	Phenotype"
		while IFS='' read -r REGION || [[ -n "$REGION" ]]; do
		LINE=${REGION}
		echo "* ${LINE}"
		done < ${REGIONS}
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


	###EXTRACTION OF DATA AND ANALYSIS
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Extracting loci with the specified bp range."
	while IFS='' read -r REGIONOFINTEREST || [[ -n "$REGIONOFINTEREST" ]]; do
		###1		2		3	4	5		6		7			8		9
		###Variant	Locus	Chr	BP	StartRange	EndRange	WindowSize	Type	Phenotype
		LINE=${REGIONOFINTEREST}
		# Check for empty line, the script doesn't like these
		[ -z "${LINE}" ] && continue
		VARIANT=$(echo "${LINE}" | awk '{print $1}')
		LOCUS=$(echo "${LINE}" | awk '{print $2}')
		CHR=$(echo "${LINE}" | awk '{print $3}')
		BP=$(echo "${LINE}" | awk '{print $4}')
		START=$(echo "${LINE}" | awk '{print $5}')
		END=$(echo "${LINE}" | awk '{print $6}')
		WINDOWSIZE=$(echo "${LINE}" | awk '{print $7}')
		TYPE=$(echo "${LINE}" | awk '{print $8}')
		PHENOTYPE=$(echo "${LINE}" | awk '{print $9}')
	
		echo ""
		echo ""
		echo "========================================================================================================="
		echo "Processing ${VARIANT} locus on ${CHR} between ${START} and ${END}..."
		echo "========================================================================================================="
		###Make directories for script if they do not exist yet (!!!PREREQUISITE!!!)
		if [ ! -d ${RESULTS}/${VARIANT}_${PROJECTNAME} ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${RESULTS}/${VARIANT}_${PROJECTNAME}
			mkdir -v ${RESULTS}/clumps
		else
			echo "The regional directory already exists."
		fi
		
		REGIONALDIR=${RESULTS}/${VARIANT}_${PROJECTNAME}
		CLUMPDIR=${RESULTS}/clumps
		
		### Extraction relevant regions for QTL analysis using QTLTools
		# Checking existence input file(s)
		if [ ! -s "${GENETICDATA}/${SNPTESTDATA}${CHR}.bgen" ]; then
			echo "BGEN inputfile for QCTool doesn't exist or is empty, let's die"
			exit 1
		fi
		# Checking existence input file(s)
		if [ ! -s "${GENETICDATA}/${SNPTESTDATA}${CHR}.sample" ]; then
			echo "Input samplefile for QCTool doesn't exist is empty, let's die"
			exit 1
		fi
		echo ""
		echo "* Creating bash-script to submit qctool extraction of region ${CHR}:${START}-${END} near ${LOCUS}..."
		### FOR DEBUGGING
		###${QCTOOL} -g ${GENETICDATA}/${SNPTESTDATA}${CHR}.bgen -s ${GENETICDATA}/${SNPTESTDATA}${CHR}.sample -og ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -os ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -incl-range ${CHR}:${START}-${END}
		### echo "${QCTOOL} -g ${GENETICDATA}/${SNPTESTDATA}${CHR}_pruned.bgen -s ${GENETICDATA}/${SNPTESTDATA}${CHR}_pruned.sample -og ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -os ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -incl-range ${CHR}:${START}-${END} "> ${REGIONALDIR}/${STUDYNAME}_genex_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		echo "${QCTOOL} -g ${GENETICDATA}/${SNPTESTDATA}${CHR}.bgen -s ${GENETICDATA}/${SNPTESTDATA}${CHR}.sample -og ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -os ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -incl-range ${CHR}:${START}-${END} "> ${REGIONALDIR}/${STUDYNAME}_genex_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		qsub -S /bin/bash -N GENEX${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_genex_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_genex_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_genex_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		
		### Applying some QC metrics on the extracted data -- exclude samples: -excl-samples ${EXCLUSION_NONAEMS450K1} 
		echo "* Creating bash-script to submit qctool filtering of the ${LOCUS} based on MAF > ${MAF}, INFO > ${INFO} and HWE -log10(p) > ${HWE}..."
		### FOR DEBUGGING
		###${QCTOOL} -g ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -s ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -og ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -os ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -maf ${MAF} 1 -info ${INFO} 1 -hwe ${HWE} 
		### echo "${QCTOOL} -g ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -s ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -og ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -os ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -maf ${MAF} 1 -info ${INFO} 1 -hwe ${HWE} "> ${REGIONALDIR}/${STUDYNAME}_genqc_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		echo "${QCTOOL} -g ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -s ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_RAW_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -og ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -os ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -maf ${MAF} 1 -info ${INFO} 1 -hwe ${HWE} "> ${REGIONALDIR}/${STUDYNAME}_genqc_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		qsub -S /bin/bash -N GENQC${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid GENEX${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_genqc_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_genqc_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_genqc_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		
		### Calculating statistics 
		echo "* Creating bash-script to submit to calculate summary statistics of region ${CHR}:${START}-${END}..."
		### FOR DEBUGGING -- to exclude samples: -exclude_samples ${EXCLUSION_NONAEMS450K1} 
		###${SNPTEST252} -data ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -summary_stats_only -hwe -o ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats 
		echo "${SNPTEST252} -data ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -summary_stats_only -hwe -o ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats "> ${REGIONALDIR}/${STUDYNAME}_genstats_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		qsub -S /bin/bash -N GENSTAT${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid GENQC${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_genstats_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_genstats_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_genstats_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		
		### Make VCF
		### example: qctool_v15 -g ctmm_1kGp3GoNL5_QC_chr7.7q22.gen.gz -s ctmm_phenocov.sample -og ctmm_1kGp3GoNL5_QC_chr7.7q22.vcf
		echo "* Creating bash-script to submit VCF-file generation..."
		### FOR DEBUGGING
		###${QCTOOL} -g ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -s ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -og ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf 
		echo "${QCTOOL} -g ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.gen.gz -s ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.sample -og ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf " > ${REGIONALDIR}/${STUDYNAME}_gen2vcf_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		qsub -S /bin/bash -N GEN2VCF${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid GENQC${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_gen2vcf_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_gen2vcf_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_gen2vcf_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		
		### Index using Tabix & BGZIP
		### example: bgzip ${STUDYNAME}_combo_1000g_QC_chr7.7q22.vcf && tabix_v026 -p vcf ${STUDYNAME}_combo_1000g_QC_chr7.7q22.vcf.gz
		echo "* Creating bash-script to submit indexing and gzipping of VCF-file..."
		### FOR DEBUGGING
		###${BGZIP} ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf && ${TABIX} ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz 
		echo "${BGZIP} ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf && ${TABIX} ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz " > ${REGIONALDIR}/${STUDYNAME}_vcfgz_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		qsub -S /bin/bash -N VCFGZ${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid GEN2VCF${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_vcfgz_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_vcfgz_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_vcfgz_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
	
		echo ""	
		### Running QTLTool -- without clumping
		if [[ ${CHR} -lt 10 ]]; then 
			echo "Processing a variant in region 0${CHR}:${START}-${END}."
			### Running nominal and permutation passes of QTLTools, respectively
			echo "Creating bash-script to submit nominal pass for 'cis-eQTLs'..."
			### FOR DEBUGGING
			### ${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-3 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log
			echo "${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-3 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid VCFGZ${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.output -l h_rt=${QUEUE_NOM} -l h_vmem=${VMEM_NOM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			echo "Creating bash-script to submit permutation pass for 'cis-eQTLs'..."
			### FOR DEBUGGING
			### ${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			echo "${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid VCFGZ${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.output -l h_rt=${QUEUE_PERM} -l h_vmem=${VMEM_PERM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
		elif  [[ ${CHR} -ge 10 ]]; then
			echo "Processing a variant in region ${CHR}:${START}-${END}."
			###Running nominal and permutation passes of QTLTools, respectively
			echo "Creating bash-script to submit nominal pass for 'cis-eQTLs'..."
			### FOR DEBUGGING
			### ${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-3 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log
			echo "${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-3 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid VCFGZ${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.output -l h_rt=${QUEUE_NOM} -l h_vmem=${VMEM_NOM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			echo ""
			echo "Creating bash-script to submit permutation pass for 'cis-eQTLs'..."
			### FOR DEBUGGING
			### ${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			echo "${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid VCFGZ${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.output -l h_rt=${QUEUE_PERM} -l h_vmem=${VMEM_PERM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
		else
			echo "*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please."	
			exit 1
		fi
		
# 		echo ""
# 		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
# 		echo "Extracting LD buddies of ${VARIANT} from *nominal* analysis results file and creating new files."
# 		### FOR DEBUGGING
# 		### ${PYTHON} ${QTLTOOLKIT}/QTLClumpanator.py ${VARIANT} ${CHR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped ${CLUMPDIR} /hpc/dhl_ec/data/_ctmm_originals/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5/ctmm_1kGp3GoNL5_RAW_chr${CHR} /home/dhl_ec/jschaap/datacheck/results/ctmm_1kGp3GoNL5_RAW_chr${CHR}.list ${CLUMP} ${CLUMP_THRESH}
# 		echo "${PYTHON} ${QTLTOOLKIT}/QTLClumpanator.py ${VARIANT} ${CHR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped ${CLUMPDIR} /hpc/dhl_ec/data/_ctmm_originals/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5/ctmm_1kGp3GoNL5_RAW_chr${CHR} /home/dhl_ec/jschaap/datacheck/results/ctmm_1kGp3GoNL5_RAW_chr${CHR}.list ${CLUMP} ${CLUMP_THRESH}"> ${REGIONALDIR}/clump_${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.py
# 		qsub -S /bin/bash -N CLUMP_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_clump.errors -o ${REGIONALDIR}/${STUDYNAME}_clump.output -l h_rt=00:20:00 -l h_vmem=6G -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/clump_${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.py
# 		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
# 		
# 		### Running QTLTool -- with clumping
# 		if [[ ${CHR} -lt 10 ]]; then 
# 			echo "Processing a variant in clumped region of 0${CHR}:${START}-${END}."
# 			### Running nominal and permutation passes of QTLTools, respectively
# 			echo "Creating bash-script to submit nominal pass with the clumped dataset for 'cis-eQTLs'..."
# 			### FOR DEBUGGING
# 			### ${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-3 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
# 			echo "${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-3 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
# 			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_clumped_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid CLUMP_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.output -l h_rt=${QUEUE_NOM} -l h_vmem=${VMEM_NOM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
# 			echo "Creating bash-script to submit permutation pass for 'cis-eQTLs'..."
# 			### FOR DEBUGGING
# 			### ${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
# 			echo "${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
# 			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_clumped_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid CLUMP_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.output -l h_rt=${QUEUE_PERM} -l h_vmem=${VMEM_PERM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
# 		elif  [[ ${CHR} -ge 10 ]]; then
# 			echo "Processing a variant in clumped region ${CHR}:${START}-${END}."
# 			###Running nominal and permutation passes of QTLTools, respectively
# 			echo "Creating bash-script to submit nominal pass for 'cis-eQTLs'..."
# 			### FOR DEBUGGING
# 			### ${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-3 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
# 			echo "${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-3 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
# 			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_clumped_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid CLUMP_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.output -l h_rt=${QUEUE_NOM} -l h_vmem=${VMEM_NOM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
# 			echo ""
# 			echo "Creating bash-script to submit permutation pass with the clumped dataset for 'cis-eQTLs'..."
# 			### FOR DEBUGGING
# 			### ${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
# 			echo "${QTLTOOLS} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
# 			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_clumped_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid CLUMP_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.output -l h_rt=${QUEUE_PERM} -l h_vmem=${VMEM_PERM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
# 		else
# 			echo "*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please."	
# 			exit 1
# 		fi
	
	done < ${REGIONS}
	
	### PUT THE QTLChecker.sh here
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Checking QTLTools results -- reporting all failures and successes."
	echo ""
	### Creating a job that will aid in summarizing the data.
	### FOR DEBUGGING
	###${QTLTOOLKIT}/QTLChecker.sh ${STUDYNAME} ${EXCLUSION_TYPE} ${ROOTDIR} ${RESULTS} ${SUMMARY} ${PROJECTNAME} ${REGIONS}
	echo "${QTLTOOLKIT}/QTLChecker.sh ${STUDYNAME} ${EXCLUSION_TYPE} ${ROOTDIR} ${RESULTS} ${SUMMARY} ${PROJECTNAME} ${REGIONS} "> ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.sh
	### Hold for clumping
	qsub -S /bin/bash -N QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTL_${STUDYJOBNAME}_clumped_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.errors -o ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.sh

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


	### DATA QUALITY CONTROL AND PARSING
	echo ""
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Quality control and parsing of QTLTools results."
	
	while IFS='' read -r REGIONOFINTEREST || [[ -n "$REGIONOFINTEREST" ]]; do
		###	1		2		3	4	5		6		7			8		9
		###Variant	Locus	Chr	BP	BP-1Mb	BP+1Mb	WindowSize	Type	Phenotype
		LINE=${REGIONOFINTEREST}
		VARIANT=$(echo "${LINE}" | awk '{print $1}')
		LOCUS=$(echo "${LINE}" | awk '{print $2}')
		CHR=$(echo "${LINE}" | awk '{print $3}')
		BP=$(echo "${LINE}" | awk '{print $4}')
		START=$(echo "${LINE}" | awk '{print $5}')
		END=$(echo "${LINE}" | awk '{print $6}')
		WINDOWSIZE=$(echo "${LINE}" | awk '{print $7}')
		TYPE=$(echo "${LINE}" | awk '{print $8}')
		PHENOTYPE=$(echo "${LINE}" | awk '{print $9}')
	
		echo "===================================================================="
		echo "Processing ${VARIANT} locus on ${CHR} between ${START} and ${END}..."
		### Make directories for script if they do not exist yet (!!!PREREQUISITE!!!)
		if [ ! -d ${RESULTS}/${VARIANT}_${PROJECTNAME} ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${RESULTS}/${VARIANT}_${PROJECTNAME}
		else
			echo "The regional directory already exists."
		fi
		
		REGIONALDIR=${RESULTS}/${VARIANT}_${PROJECTNAME}
	
		### PERFORMING fastQTL RESULTS QUALITY CONTROL & PARSING
		### Processing NOMINAL results
		echo "Creating bash-script to submit 'QTLTools RESULTS QUALITY CONTROL & PARSER v2' on >>> nominal <<< pass results..."
		# On the non-clumped data
		### FOR DEBUGGING
		### Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t NOM -q ${ANALYSISTYPE} -o ${REGIONALDIR}/ -a ${ANNOTATIONFILE} -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE}
		echo "Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t NOM -q ${ANALYSISTYPE} -o ${REGIONALDIR}/ -a ${ANNOTATIONFILE} -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} "> ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
#
#		# On the clumped data
#		echo "Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t NOM -q ${ANALYSISTYPE} -o ${REGIONALDIR}/ -a ${ANNOTATIONFILE} -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} "> ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
#		qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_clumped${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
#		
		#jacco
		#echo "Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped.txt.gz -t NOM -q EQTL -o ${REGIONALDIR}/ -a ${ANNOTATIONFILE} -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats  "> ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped.sh
		#qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped.sh
		
		### Processing PERMUTATION results		
		echo ""
		echo "Creating bash-script to submit 'QTLTools RESULTS QUALITY CONTROL & PARSER v2' on >>> permutation <<< pass results..."
		# On the non-clumped data
		### FOR DEBUGGING
		### Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t PERM -q ${ANALYSISTYPE} -o ${REGIONALDIR}/ -a ${ANNOTATIONFILE} -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} 
		echo "Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t PERM -q ${ANALYSISTYPE} -o ${REGIONALDIR}/ -a ${ANNOTATIONFILE} -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} "> ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
		qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
#
#		# On the clumped data
#		echo "Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t PERM -q ${ANALYSISTYPE} -o ${REGIONALDIR}/ -a ${ANNOTATIONFILE} -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} "> ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
#		qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
#			
	done < ${REGIONS}
 
	
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Summarizing fastQTL results."
	echo ""
	### Creating a job that will aid in summarizing the data.
	### FOR DEBUGGING
	### ${QTLTOOLKIT}/QTLSummarizer.sh ${STUDY_TYPE} ${SAMPLE_TYPE} ${STUDYNAME} ${PROJECT} ${PROJECTNAME} ${SUMMARY} ${RESULTS} ${REGIONS} ${EXCLUSION_TYPE} ${CLUMPDIR} ${QTL_TYPE} 
	### updated for clumping, last parameter is for Summarizer script
	echo "${QTLTOOLKIT}/QTLSummarizer.sh ${STUDY_TYPE} ${SAMPLE_TYPE} ${STUDYNAME} ${PROJECT} ${PROJECTNAME} ${SUMMARY} ${RESULTS} ${REGIONS} ${EXCLUSION_TYPE} ${CLUMPDIR} ${QTL_TYPE} "> ${SUMMARY}/${STUDYNAME}_QTLSum_excl_${EXCLUSION_TYPE}.sh
	qsub -S /bin/bash -N QTLSum_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/${STUDYNAME}_QTLSum_excl_${EXCLUSION_TYPE}.errors -o ${SUMMARY}/${STUDYNAME}_QTLSum_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_QTLSum_excl_${EXCLUSION_TYPE}.sh
	
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Creating SNP info file for easy reading."
	echo ""
    if [[ ${CLUMP} == "Y" ]]; then
        echo "${PYTHON} ${QTLTOOLKIT}/QTLSumParser.py Y ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt.gz ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz ${SUMMARY} ${QTL_TYPE} "> ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.sh
        qsub -S /bin/bash -N QTLParser_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLSum_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.errors -o ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.log -l h_rt=00:15:00 -l h_vmem=12G -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.sh
	else
	    echo "${PYTHON} ${QTLTOOLKIT}/QTLSumParser.py N ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt.gz ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt.gz ${SUMMARY} ${QTL_TYPE} "> ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.sh
        qsub -S /bin/bash -N QTLParser_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLSum_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.errors -o ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.log -l h_rt=00:15:00 -l h_vmem=12G -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.sh
	fi

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	echo ""
	echo ""
	if [[ ${STUDY_TYPE} == "CTMM" ]]; then
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "Plotting fastQTL results for an eQTL analysis using CTMM's monocytes whole-genome expression data."
		echo ""
		### Creating a job that will aid in plotting the data.
		### FOR DEBUGGING
		### ${QTLTOOLKIT}/QTLPlotter.sh ${STUDY_TYPE} ${SAMPLE_TYPE} ${REGIONS} ${SUMMARY} ${STUDYNAME} ${CLUMPDIR} ${CLUMP}
		echo "${QTLTOOLKIT}/QTLPlotter.sh ${STUDY_TYPE} ${SAMPLE_TYPE} ${REGIONS} ${SUMMARY} ${STUDYNAME} ${CLUMPDIR} ${CLUMP}"> ${SUMMARY}/${STUDYNAME}_QTLPlot_excl_${EXCLUSION_TYPE}.sh
		qsub -S /bin/bash -N QTLPlot_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLSum_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/${STUDYNAME}_QTLPlot_excl_${EXCLUSION_TYPE}.errors -o ${SUMMARY}/${STUDYNAME}_QTLPlot_excl_${EXCLUSION_TYPE}.log -l h_rt=04:00:00 -l h_vmem=16G -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_QTLPlot_excl_${EXCLUSION_TYPE}.sh
	
	elif [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "Many CpGs that map to one or multiple genes, and some CpGs might not map to any gene in particular. Thus"
		echo "plotting mQTL results is not yet implemented pending further consideration of the above."
		echo ""
	else
		echo "                        *** ERROR *** "
		echo "Something is rotten in the City of Gotham; most likely a typo. "
		echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
		echo "                *** END OF ERROR MESSAGE *** "
		exit 1
	fi
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Creating SNP info file for easy reading."
	echo ""

### END of if-else statement for the number of command-line arguments passed ###
fi
script_copyright_message

	### EXCLUSION LISTS NOTES
	### Please note that it is okay to have more (or different) samples in the *genotype* data 
	### as compared to the *phenotype* data. However, it is *NOT* okay to have more 
	### (or different) samples in the *phenotype* data as compared to the *genotype* data!!!
	### In other words: remove from the BED files - *BEFORE* while making them!!! - the
	### samples that do *NOT* have genotype data!!!
	### FOR DEBUGGING USEFULL:
	###EXCLUSION_NONAEMS450K1="${GENETICDATA}/exclude_nonAEMS450K1.list"
	###EXCLUSION_NONAEMS450K2="${GENETICDATA}/exclude_nonAEMS450K2.list"


	### EXCLUSION LISTS for fastQTL
	###
	### CTMM & AEGS
	### For CTMM & AEGS the exclusion lists have exactly the same identifiers.

	### EXCLUSION LISTS for SNPTEST
	###
	### CTMM
	### - exclusion_nonCTMM.list
	### - exclusion_nonCTMM_FEMALES.list
	### - exclusion_nonCTMM_MALES.list
	### - exclusion_nonCTMM_SMOKER.list
	### - exclusion_nonCTMM_nonSMOKER.list
	### - exclusion_nonCTMM_T2D.list
	### - exclusion_nonCTMM_nonT2D.list
	###
	### AEGS
	### - exclusion_Females.list
	### - exclusion_Males.list
	### - exclusion_nonAEGS.list
	### - exclusion_nonCEA_AEGS.list
	### - exclusion_nonCEA.list
	### - exclusion_nonCEA_Females.list
	### - exclusion_nonCEA_Males.list
	### - exclusion_nonCEA_SMOKER.list
	### - exclusion_nonCEA_nonSMOKER.list
	### - exclusion_nonCEA_T2D.list
	### - exclusion_nonCEA_nonT2D.list
	### -- AEGS SPECIFIC --
	### - exclusion_nonCEA_CKD.list
	### - exclusion_nonCEA_nonCKD.list
	### - exclusion_nonCEA_post2007.list
	### - exclusion_nonCEA_pre2007.list
