#!/bin/bash
#
#$ -S /bin/bash 																			# the type of BASH you'd like to use
#$ -N fastQTLAnalyzer_v2  																	# the name of this script
#$ -hold_jid some_other_basic_bash_script  													# the current script (basic_bash_script) will hold until some_other_basic_bash_script has finished
#$ -o /hpc/dhl_ec/svanderlaan/projects/test_mqtl/fastQTLAnalyzer_v2.log						# the log file of this job
#$ -e /hpc/dhl_ec/svanderlaan/projects/test_mqtl/fastQTLAnalyzer_v2.errors					# the error file of this job
#$ -l h_rt=00:30:00  																		# h_rt=[max time, e.g. 02:02:01] - this is the time you think the script will take
#$ -l h_vmem=4G  																			#  h_vmem=[max. mem, e.g. 45G] - this is the amount of memory you think your script will use
# -l tmpspace=64G  																		# this is the amount of temporary space you think your script will use
#$ -M s.w.vanderlaan-2@umcutrecht.nl  														# you can send yourself emails when the job is done; "-M" and "-m" go hand in hand
#$ -m a  																					# you can choose: b=begin of job; e=end of job; a=abort of job; s=suspended job; n=no mail is send
#$ -cwd  																					# set the job start to the current directory - so all the things in this script are relative to the current directory!!!
#
# You can use the variables above (indicated by "#$") to set some things for the submission system.
# Another useful tip: you can set a job to run after another has finished. Name the job 
# with "-N SOMENAME" and hold the other job with -hold_jid SOMENAME". 
# Further instructions: https://wiki.bioinformatics.umcutrecht.nl/bin/view/HPC/HowToS#Run_a_job_after_your_other_jobs
#
# It is good practice to properly name and annotate your script for future reference for
# yourself and others. Trust me, you'll forget why and how you made this!!!

# CHANGES MADE BY JACCO SCHAAP 
# Removed rootdir path in region and covariate file specification 
# Also for v3 changed dataset to a pruned one
# Besides that the jobnames aren't unique so we can't run multiple fastQTL's at the same time

### REGARDING NOTES ###
### Please note that uncommented notes can be found at the end of this script.
###

### MoSCoW FEATURE LIST ###
###
###

### Creating display functions
### Setting colouring
NONE='\033[00m'
BOLD='\033[1m'
FLASHING='\033[5m'
UNDERLINE='\033[4m'

RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'

function echobold { #'echobold' is the function name
    echo -e "${BOLD}${1}${NONE}" # this is whatever the function needs to execute, note ${1} is the text for echo
}
function echoerrorflash { 
    echo -e "${RED}${BOLD}${FLASHING}${1}${NONE}" 
}
function echoerror { 
    echo -e "${RED}${1}${NONE}"
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
	echoerror " * Argument #1   indicate which study type you want to analyze, so either [AEMS450K1/AEMS450K2/CTMM]:"
	echoerror "                 - AEMS450K1: methylation quantitative trait locus (mQTL) analysis "
	echoerror "                              on plaques or blood in the Athero-Express Methylation "
	echoerror "                              Study 450K prune100 1."
	echoerror "                 - AEMS450K2: mQTL analysis on plaques or blood in the Athero-Express"
	echoerror "                              Methylation Study 450K prune100 2."
	echoerror "                 - CTMM:      expression QTL (eQTL) analysis in monocytes from CTMM."
	echoerror " * Argument #2   the sample type must be [AEMS450K1: PLAQUES/BLOOD], "
	echoerror "                 [AEMS450K2: PLAQUES], or [CTMM: MONOCYTES]."
	echoerror " * Argument #3   the root directory, e.g. /hpc/dhl_ec/svanderlaan/projects/test_qtl."
	echoerror " * Argument #4   where you want stuff to be save inside the rootdir, "
	echoerror "                 e.g. mqtl_aems450k1"
	echoerror " * Argument #5   project name, e.g. 'CAD'."
	echoerror " * Argument #6   text file with on each line the regions of interest, refer to "
	echoerror "                 example file."
	echoerror " * Argument #7   the type of exclusion to apply: "
	echoerror "                 - AEMS/CTMM:     DEFAULT/SMOKER/NONSMOKER/MALES/FEMALES/T2D/NONT2D/NONMONOCYTE "
	echoerror "                 - AEMS-specific: CKD/NONCKD/PRE2007/POST2007/NONAEGS/NONAEGSFEMALES/NONAEGSMALES."
	echoerror " * Argument #8   text file with excluded covariates, refer to example file."
	echoerror " * Argument #9   qsub e-mail address, e.g. s.w.vanderlaan-2@umcutrecht.nl."
	echoerror " * Argument #10  qsub mail settings, e.g. 'beas' - refer to qsub manual."
	echoerror " * Argument #11  configurationfile: fastqtl.config.txt."
	echoerror " * Argument #12  CIS or TRANS? [CIS/TRANS]"
	echoerror " * Argument #13  plot clumped set? [Y/N]"
	echoerror " * Argument #14  Threshold for rsquared, optional"
	echoerror ""
	echoerror " An example command would be: "
	echoerror "./fastQTLAnalyzer.sh [arg1] [arg2] [arg3] [arg4] [arg5] [arg6] [arg7] [arg8] [arg9] [arg10] [arg11] [arg12]"
	echoerror ""
	echoerror "========================================================================================================="
  	# The wrong arguments are passed, so we'll exit the script now!
  	script_copyright_message
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "+                                      QUANTITATIVE TRAIT LOCUS ANALYZER                                +"
echobold "+                                                                                                       +"
echobold "+                                                                                                       +"
echobold "+ * Written by  : Sander W. van der Laan                                                                +"
echobold "+ * E-mail      : s.w.vanderlaan-2@umcutrecht.nl                                                        +"
echobold "+ * Updated by  : Jacco Schaap			                                                              +"
echobold "+ * E-mail      : j.schaap-2@umcutrecht.nl             	                                              +"
echobold "+ * Last update : 2017-08-28                                                                            +"
echobold "+ * Version     : 2.1.0                                                                                 +"
echobold "+                                                                                                       +"
echobold "+ * Description : This script will set some directories, execute something in a for-loop, and will then +"
echobold "+                 submit this in a job.                                                                 +"
echobold "+                                                                                                       +"
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Today's date and time: "$(date)
TODAY=$(date +"%Y%m%d")
echo ""

# set name automatically
CLUMP=${13}
CLUMP_THRESH=${14}

### SET STUDY AND SAMPLE TYPE
### Note: All analyses with AE data are presumed to be constrained to CEA-patients only.
###       You can set the exclusion criteria 'NONAEGS/FEMALES/MALES' if you want to analyse
###       all AE data!
### Set the analysis type.
STUDY_TYPE=${1} # AEMS450K1/AEMS450K2/CTMM

### Set the analysis type.
SAMPLE_TYPE=${2} # AE: PLAQUES/BLOOD; CTMM: MONOCYTES

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 12 ]]; then 
	echoerrorflash "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "You must supply at least [10] arguments when running a mQTL or eQTL analysis using Athero-Express 
or CTMM data!"
	
elif [[ (${STUDY_TYPE} = "AEMS450K1" || ${STUDY_TYPE} = "AEMS450K2") && ${SAMPLE_TYPE} = "MONOCYTES" ]]; then 
	echoerrorflash "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "When running a *** mQTL analysis *** using ${STUDY_TYPE}, you must supply 'PLAQUES' or 'BLOOD' 
as SAMPLE_TYPE [arg2]!"
	
elif [[ ${STUDY_TYPE} = "AEMS450K2" && ${SAMPLE_TYPE} = "BLOOD" ]]; then 
	echoerrorflash "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "When running a *** mQTL analysis *** using ${STUDY_TYPE}, you must supply 'PLAQUES' as 
SAMPLE_TYPE [arg2]!"
	
elif [[ ${STUDY_TYPE} = "CTMM" && (${SAMPLE_TYPE} = "PLAQUES" || ${SAMPLE_TYPE} = "BLOOD") ]]; then 
	echoerrorflash "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "When running a *** eQTL analysis *** using ${STUDY_TYPE}, you must supply 'MONOCYTES' as 
SAMPLE_TYPE [arg2]!"
	
else
	
	### GENERIC SETTINGS
	SOFTWARE=/hpc/local/CentOS7/dhl_ec/software
	QCTOOL=${SOFTWARE}/qctool_v1.5-linux-x86_64-static/qctool
	SNPTEST252=${SOFTWARE}/snptest_v2.5.2_CentOS6.5_x86_64_static/snptest_v2.5.2
	FASTQTL=${SOFTWARE}/fastqtl_v2.184
	QTL=${SOFTWARE}/QTLTools/QTLtools_1.0_CentOS6.8_x86_64
	#QTLTOOLKIT=${SOFTWARE}/QTLToolKit
	QTLTOOLKIT=/hpc/dhl_ec/jschaap/QTLToolKit
	FASTQCTLADDON=${SOFTWARE}/fastQTLToolKit
	FASTQTLPARSER=${FASTQCTLADDON}/NominalResultsParser.py
	LZ13=${SOFTWARE}/locuszoom_1.3/bin/locuszoom
	BGZIP=${SOFTWARE}/htslib-1.3/bgzip
	TABIX=${SOFTWARE}/htslib-1.3/tabix
	PLINK=/hpc/local/CentOS7/dhl_ec/software/plink_v1.9

	### PROJECT SPECIFIC 
	ROOTDIR=${3} # the root directory, e.g. /hpc/dhl_ec/svanderlaan/projects/test_qtl; [arg3]
	PROJECTDIR=${4} # where you want stuff to be save inside the rootdir, e.g. mqtl_aems450k1; [arg4]
	if [ ! -d ${ROOTDIR}/${PROJECTDIR} ]; then
				echo "The project directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${ROOTDIR}/${PROJECTDIR}
			else
				echo "The project directory '${PROJECTDIR}' already exists."
			fi
	PROJECT=${ROOTDIR}/${PROJECTDIR}
	
	PROJECTNAME=${5} # e.g. "CAD"
	
	### JACCO - Removed the rootdir at REGIONS and EXCLUSION files, just give the right path to the covariant file please.
	
	### DEFINE REGION(S)
	REGIONS=${6} # regions_for_eqtl.txt OR regions_for_qtl.small.txt; [arg5]
	
	### SET EXCLUSION TYPE & COVARIATES
	EXCLUSION_TYPE=${7} # e.g. "DEFAULT" -- DEFAULT/SMOKER/NONSMOKER/MALES/FEMALES/T2D/NONT2D [CKD/NONCKD/PRE2007/POST2007/NONAEGS/NONAEGSFEMALES/NONAEGSMALES -- these are AE-specific!!!]
	
	EXCLUSION_COV="${8}" # e.g. "excl_cov.txt"
	
	### MAIL SETTINGS -- PLEASE CHANGE TO YOUR SITUATION
	### --- THESE COULD BE ARGUMENTS --- ###
	EMAIL=${9} # e.g. "s.w.vanderlaan-2@umcutrecht.nl"
	MAILTYPE=${10} # e.g. "as"; you can choose: b=begin of job; e=end of job; a=abort of job; s=suspended job; n=no mail is send

	### SOURCE THE CONFIGURATION FILE
	source ${11}
	QTL_TYPE=${12} # CIS or TRANS
	echo "${QTL_TYPE}"
	### QSUB SETTINGS
	### --- THESE COULD BE ARGUMENTS --- ###
	QUEUE_QCTOOL=${QUEUE_QCTOOL_CONFIG}
	VMEM_QCTOOL=${VMEM_QCTOOL_CONFIG}
	QUEUE_NOM=${QUEUE_NOM_CONFIG}
	VMEM_NOM=${VMEM_NOM_CONFIG}
	QUEUE_PERM=${QUEUE_PERM_CONFIG}
	VMEM_PERM=${VMEM_PERM_CONFIG}

	### FASTQTL SETTINGS
	### --- THESE COULD BE ARGUMENTS --- ###
	SEEDNO=${SEEDNO_CONFIG}
	PERMSTART=${PERMSTART_CONFIG}
	PERMEND=${PERMEND_CONFIG}
	
	### QCTOOL SETTINGS
	### --- THESE COULD BE ARGUMENTS --- ###
	MAF=${MAF_CONFIG}
	INFO=${INFO_CONFIG}
	HWE=${HWE_CONFIG}


	### Check parameters for existence 

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

	
	### SETTING STUDY AND SAMPLE TYPE SPECIFIC THINGS
	### --- THESE COULD BE ARGUMENTS --- ###
	if [[ ${STUDY_TYPE} == "AEMS450K1" ]]; then
		### AEMS450K1 SPECIFIC -- DO NOT CHANGE
		ORIGINALS=/hpc/dhl_ec/data/_ae_originals
		GENETICDATA=${ORIGINALS}/AEGS_COMBINED_IMPUTE2_1000Gp3_GoNL5
		AEMS450K1=${ORIGINALS}/AEMethylS_IlluminaMethylation450K
	
		### for file names
		STUDYNAME="aegs"
		STUDYJOBNAME="AEMS450K1"
		SNPTESTDATA="aegs_combo_1kGp3GoNL5_RAW_chr"
		#SNPTESTSAMPLEDATA=""
		SNPTESTOUTPUTDATA="aegs_1kGp3GoNL5"
		if [[ ${SAMPLE_TYPE} == "PLAQUES" ]]; then
			FASTQTLDATA="${AEMS450K1}/AEM_mQTL_INPUT_DATA/aems450k1_QC_443872_plaques.bed.gz"
			FASTQTLINDEX="${AEMS450K1}/AEM_mQTL_INPUT_DATA/aems450k1_QC_443872_plaques.bed.gz.tbi"
		elif [[ ${STUDY_TYPE} == "BLOOD" ]]; then
			FASTQTLDATA="${AEMS450K1}/AEM_mQTL_INPUT_DATA/aems450k1_QC_443872_blood.bed.gz"
			FASTQTLINDEX="${AEMS450K1}/AEM_mQTL_INPUT_DATA/aems450k1_QC_443872_blood.bed.gz.tbi"
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'sample type' please: '${SAMPLE_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
		### COVARIATES FILE
		COVARIATES="${GENETICDATA}/covariates_aegs_combo.all.cov"
	
	elif [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
		### AEMS450K2 SPECIFIC -- DO NOT CHANGE
		ORIGINALS=/hpc/dhl_ec/data/_ae_originals
		GENETICDATA=${ORIGINALS}/AEGS_COMBINED_IMPUTE2_1000Gp3_GoNL5
		AEMS450K2=${ORIGINALS}/AEMS450K2
	
		### for file names
		STUDYNAME="aegs"
		STUDYJOBNAME="AEMS450K2"
		SNPTESTDATA="aegs_combo_1kGp3GoNL5_RAW_chr"
		#SNPTESTSAMPLEDATA=""
		SNPTESTOUTPUTDATA="aegs_1kGp3GoNL5"
		if [[ ${SAMPLE_TYPE} == "PLAQUES" ]]; then
			FASTQTLDATA="${AEMS450K2}/AEM_mQTL_INPUT_DATA/aems450k2_QC_443872_plaques.bed.gz"
			FASTQTLINDEX="${AEMS450K2}/AEM_mQTL_INPUT_DATA/aems450k2_QC_443872_plaques.bed.gz.tbi"
		elif [[ ${STUDY_TYPE} == "BLOOD" ]]; then
			FASTQTLDATA="${AEMS450K2}/AEM_mQTL_INPUT_DATA/aems450k2_QC_443872_blood.bed.gz"
			FASTQTLINDEX="${AEMS450K2}/AEM_mQTL_INPUT_DATA/aems450k2_QC_443872_blood.bed.gz.tbi"
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'sample type' please: '${SAMPLE_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
		### COVARIATES FILE
		COVARIATES="${GENETICDATA}/covariates_aegs_combo.all.cov"
	
	elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
		### CTMM SPECIFIC -- DO NOT CHANGE
		### ORIGINALS=/hpc/dhl_ec/data/_ctmm_originals/pruned
		ORIGINALS=/hpc/dhl_ec/data/_ctmm_originals
		GENETICDATA=${ORIGINALS}/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5
		CTMMEXPRESSIONDATA=${ORIGINALS}/CTMMHumanHT12v4r2_15002873B
	
		### for file names
		STUDYNAME="ctmm"
		STUDYJOBNAME="CTMM"
		SNPTESTDATA="ctmm_1kGp3GoNL5_RAW_chr"
		#SNPTESTSAMPLEDATA=""
		SNPTESTOUTPUTDATA="ctmm_1kGp3GoNL5"
		if [[ ${SAMPLE_TYPE} == "MONOCYTES" ]]; then
			FASTQTLDATA="${CTMMEXPRESSIONDATA}/phenotype_ctmm.all.bed.gz"
			FASTQTLINDEX="${CTMMEXPRESSIONDATA}/phenotype_ctmm.all.bed.gz.tbi"
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'sample type' please: '${SAMPLE_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
		### COVARIATES FILE
		COVARIATES="${GENETICDATA}/covariates_ctmm.all.cov"
	else
		echo "                        *** ERROR *** "
		echo "Something is rotten in the City of Gotham; most likely a typo. "
		echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
		echo "                *** END OF ERROR MESSAGE *** "
		exit 1
	fi


	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "The following is set:"
	echo ""
	echo "Software directory                                 ${SOFTWARE}"
	echo "Where \"qctool\" resides                             ${QCTOOL}"
	echo "Where \"fastQTL\" resides                            ${FASTQTL}"
	echo "Where \"bgzip\" resides                              ${BGZIP}"
	echo "Where \"tabix\" resides                              ${TABIX}"
	echo "Where \"snptest 2.5.2\" resides                      ${SNPTEST252}"
	echo ""

	echo "Original Athero-Express/CTMM data directory        ${ORIGINALS}"
	echo "AEGS/CTMM genetic data directory (1kGp3v5+GoNL5)   ${GENETICDATA}"
	echo ""
	echo "Expression or methylation data directory           ${CTMMEXPRESSIONDATA}${AEMS450K1}${AEMS450K2}"
	echo ""     
	echo "Project directory                                  ${PROJECT}"
	echo ""     
	echo "Additional fastQTL specific settings:"     
	echo ""     
	echo "Seed number                                        ${SEEDNO}"
	echo ""     
	echo "We will run this script on                         ${TODAY}"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	### AEMS - CTMM SPECIFIC
	### CREATES RESULTS AND SUMMARY DIRECTORIES; SETS EXCLUSION-FILES
	### DEFAULT
	if [[ ${EXCLUSION_TYPE} == "DEFAULT" ]]; then
		# Results directory
		if [ ! -d ${PROJECT}/qtl ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl
		# Summary directory
		if [ ! -d ${PROJECT}/qtl_summary ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCTMM.list"

		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
	### MALES ONLY ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "FEMALES" ]]; then
		# Results directory
		if [ ! -d ${PROJECT}/qtl_males ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_males
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_males
		# Summary directory
		if [ ! -d ${PROJECT}/qtl_summary_males ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_males
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_males
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_Females.list"

		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCTMM_FEMALES.list"
			
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
	
	### FEMALES ONLY ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "MALES" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_females ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_females
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_females
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_females ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_females
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_females
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_Males.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCTMM_MALES.list"
			
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi

	### SMOKER ONLY ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "NONSMOKER" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_smoker ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_smoker
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_smoker
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_smoker ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_smoker
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_smoker
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_nonSMOKER.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCTMM_nonSMOKER.list"
			
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
	
	### NONSMOKER ONLY ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "SMOKER" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_nonsmoker ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_nonsmoker
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_nonsmoker
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_nonsmoker ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_nonsmoker
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_nonsmoker
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_SMOKER.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCTMM_SMOKER.list"
			
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
	
	### NON-TYPE 2 DIABETES ONLY ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "T2D" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_nont2d ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_nont2d
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_nont2d
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_nont2d ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_nont2d
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_nont2d
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_T2D.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCTMM_T2D.list"
			
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
	
	### TYPE 2 DIABETES ONLY ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "NONT2D" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_t2d ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_t2d
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_t2d
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_t2d ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_t2d
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_t2d
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_nonT2D.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCTMM_nonT2D.list"
			
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi

	##### THIS PART IS ATHERO-EXPRESS SPECIFIC ONLY #####

	### NON-CKD ONLY ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "CKD" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_nonckd ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_nonckd
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_nonckd
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_nonckd ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_nonckd
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_nonckd
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_CKD.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			echo "The exclusion criterium '${EXCLUSION_TYPE}' does *not* exist for CTMM."
			exit 1
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi

	### CKD DIABETES ONLY ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "NONCKD" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_ckd ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_ckd
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_ckd
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_ckd ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_ckd
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_ckd
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_nonCKD.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			echo "The exclusion criterium '${EXCLUSION_TYPE}' does *not* exist for CTMM."
			exit 1
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi

	### POST 2007 ONLY ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "PRE2007" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_post2007 ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_post2007
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_post2007
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_post2007 ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_post2007
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_post2007
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_pre2007.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			echo "The exclusion criterium '${EXCLUSION_TYPE}' does *not* exist for CTMM."
			exit 1
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi

	### PRE 2007 ONLY ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "POST2007" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_pre2007 ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_pre2007
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_pre2007
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_pre2007 ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_pre2007
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_pre2007
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_post2007.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			echo "The exclusion criterium '${EXCLUSION_TYPE}' does *not* exist for CTMM."
			exit 1
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi

	### ALL AEGS ANALYSIS
	elif [[ ${EXCLUSION_TYPE} == "NONAEGS" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_allaegs ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_allaegs
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_allaegs
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_allaegs ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_allaegs
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_allaegs
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonAEGS.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			echo "The exclusion criterium '${EXCLUSION_TYPE}' does *not* exist for CTMM."
			exit 1
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
	
	### ALL AEGS ANALYSIS -- MALES ONLY
	elif [[ ${EXCLUSION_TYPE} == "NONAEGSFEMALES" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_allaegs_males ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_allaegs_males
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_allaegs_males
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_allaegs_males ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_allaegs_males
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_allaegs_males
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonFemales.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			echo "The exclusion criterium '${EXCLUSION_TYPE}' does *not* exist for CTMM."
			exit 1
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
	
	### ALL AEGS ANALYSIS -- FEMALES ONLY
	elif [[ ${EXCLUSION_TYPE} == "NONAEGSMALES" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_allaegs_females ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_allaegs_females
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_allaegs_females
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_allaegs_females ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_allaegs_females
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_allaegs_females
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonMales.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			echo "The exclusion criterium '${EXCLUSION_TYPE}' does *not* exist for CTMM."
			exit 1
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi

	
	elif [[ ${EXCLUSION_TYPE} == "NONMONOCYTE" ]]; then		
		# Results directory
		if [ ! -d ${PROJECT}/qtl_nonmonocyte ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${PROJECT}/qtl_nonmonocyte
			else
				echo "The regional directory already exists."
			fi
		RESULTS=${PROJECT}/qtl_nonmonocyte
		# Summary directory	
		if [ ! -d ${PROJECT}/qtl_summary_nonmonocyte ]; then
			echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
			mkdir -v ${PROJECT}/qtl_summary_nonmonocyte
		else
			echo "The regional directory already exists."
		fi
		SUMMARY=${PROJECT}/qtl_summary_nonmonocyte
	
		# Exclusion files
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCEA_nonMONOCYTE.list"
			
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			EXCLUSION_LIST="${GENETICDATA}/exclusion_nonCTMM_nonMONOCYTE.list"
			
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi


	else
		echo "                        *** ERROR *** "
		echo "Something is rotten in the City of Gotham; most likely a typo. "
		echo "Double back, and check you 'exclusion type' please."	
		echo "                *** END OF ERROR MESSAGE *** "
		exit 1
	fi

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
		
		### Extraction relevant regions for QTL analysis using fastQTL
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
		### Running QTLTool
		if [[ ${CHR} -lt 10 ]]; then 
			echo "Processing a variant in region 0${CHR}:${START}-${END}."
			### Running nominal and permutation passes of fastQTL, respectively
			echo "Creating bash-script to submit nominal pass for 'cis-eQTLs'..."
			### FOR DEBUGGING
			###${FASTQTL} --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			echo "${QTL} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-5 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid VCFGZ${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.output -l h_rt=${QUEUE_NOM} -l h_vmem=${VMEM_NOM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			echo "Creating bash-script to submit permutation pass for 'cis-eQTLs'..."
			### FOR DEBUGGING
			###${FASTQTL} --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log
			echo "${QTL} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid VCFGZ${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.output -l h_rt=${QUEUE_PERM} -l h_vmem=${VMEM_PERM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
		elif  [[ ${CHR} -ge 10 ]]; then
			echo "Processing a variant in region ${CHR}:${START}-${END}."
			###Running nominal and permutation passes of fastQTL, respectively
			echo "Creating bash-script to submit nominal pass for 'cis-eQTLs'..."
			### FOR DEBUGGING
			###${FASTQTL} --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			echo "${QTL} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-5 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid VCFGZ${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.output -l h_rt=${QUEUE_NOM} -l h_vmem=${VMEM_NOM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			echo ""
			echo "Creating bash-script to submit permutation pass for 'cis-eQTLs'..."
			### FOR DEBUGGING
			###${FASTQTL} --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			echo "${QTL} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid VCFGZ${STUDYJOBNAME}_${VARIANT}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.output -l h_rt=${QUEUE_PERM} -l h_vmem=${VMEM_PERM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
		else
			echo "*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please."	
			exit 1
		fi
		
		echo ""
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "Extracting LD buddies of ${VARIANT} from nominal txt file and creating new files"
		### VARIANT	CHR	INPUT OUTPUT_CLUMPED.TXT.GZ_FILE	DIRECTORY_FOR_OTHER_RESUTLS		DIRECTORY_WITH_DATA		EXCLUSION_LISTS
		echo "python ${QTLTOOLKIT}/QTLClumpanator.py ${VARIANT} ${CHR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped ${CLUMPDIR} /hpc/dhl_ec/data/_ctmm_originals/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5/ctmm_1kGp3GoNL5_RAW_chr${CHR} /home/dhl_ec/jschaap/datacheck/results/ctmm_1kGp3GoNL5_RAW_chr${CHR}.list ${CLUMP} ${CLUMP_THRESH}"> ${REGIONALDIR}/clump_${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.py
		qsub -S /bin/bash -N CLUMP_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_clump.errors -o ${REGIONALDIR}/${STUDYNAME}_clump.output -l h_rt=00:20:00 -l h_vmem=6G -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/clump_${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.py
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		
		### Running fastQTL for clumped results
		if [[ ${CHR} -lt 10 ]]; then 
			echo "Processing a variant in clumped region of 0${CHR}:${START}-${END}."
			### Running nominal and permutation passes of fastQTL, respectively
			echo "Creating bash-script to submit nominal pass with the clumped dataset for 'cis-eQTLs'..."
			### FOR DEBUGGING
			###${FASTQTL} --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			echo "${QTL} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-5 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_clumped_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid CLUMP_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.output -l h_rt=${QUEUE_NOM} -l h_vmem=${VMEM_NOM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			echo "Creating bash-script to submit permutation pass for 'cis-eQTLs'..."
			### FOR DEBUGGING
			###${FASTQTL} --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log
			echo "${QTL} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region 0${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_clumped_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid CLUMP_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.output -l h_rt=${QUEUE_PERM} -l h_vmem=${VMEM_PERM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
		elif  [[ ${CHR} -ge 10 ]]; then
			echo "Processing a variant in clumped region ${CHR}:${START}-${END}."
			###Running nominal and permutation passes of fastQTL, respectively
			echo "Creating bash-script to submit nominal pass for 'cis-eQTLs'..."
			### FOR DEBUGGING
			###${FASTQTL} --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			echo "${QTL} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --nominal 1e-5 --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_clumped_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid CLUMP_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.output -l h_rt=${QUEUE_NOM} -l h_vmem=${VMEM_NOM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			echo ""
			echo "Creating bash-script to submit permutation pass with the clumped dataset for 'cis-eQTLs'..."
			### FOR DEBUGGING
			###${FASTQTL} --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			echo "${QTL} cis --vcf ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.vcf.gz --bed ${FASTQTLDATA} --region ${CHR}:${START}-${END} --seed ${SEEDNO} --window ${WINDOWSIZE} --permute ${PERMSTART} ${PERMEND} --exclude-samples ${EXCLUSION_LIST} --exclude-covariates ${EXCLUSION_COV} --cov ${COVARIATES} --include-sites ${CLUMPDIR}/only_ldbuddies_${VARIANT}.list --out ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz --log ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped${VARIANT}_excl_${EXCLUSION_TYPE}.log "> ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
			qsub -S /bin/bash -N QTL_${STUDYJOBNAME}_clumped_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid CLUMP_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.errors -o ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.output -l h_rt=${QUEUE_PERM} -l h_vmem=${VMEM_PERM} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
		else
			echo "*** ERROR *** Something is rotten in the City of Gotham; most likely a typo. Double back, please."	
			exit 1
		fi
	
	done < ${REGIONS}
	
	### PUT THE fastQTLChecker.sh here
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Checking QTL results -- reporting all failures and successes."
	echo ""
	### Creating a job that will aid in summarizing the data.
	### FOR DEBUGGING
	###${FASTQCTLADDON}/fastQTLChecker.sh ${STUDYNAME} ${EXCLUSION_TYPE} ${ROOTDIR} ${RESULTS} ${SUMMARY} ${PROJECTNAME} ${REGIONS}
	echo "${QTLTOOLKIT}/QTLChecker.sh ${STUDYNAME} ${EXCLUSION_TYPE} ${ROOTDIR} ${RESULTS} ${SUMMARY} ${PROJECTNAME} ${REGIONS} "> ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.sh
	# OLD: hold for exclusion, need hold for clumping
	#qsub -S /bin/bash -N QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTL_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.errors -o ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.sh
	# NEW: hold for clumping
	qsub -S /bin/bash -N QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTL_${STUDYJOBNAME}_clumped_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.errors -o ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_QTLCheck_excl_${EXCLUSION_TYPE}.sh

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


	### DATA QUALITY CONTROL AND PARSING
	echo ""
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Quality control and parsing of fastQTL results."
	
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
		### Make this part smarter -- everything is the same, except for the annotation file...
		if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
			echo "Creating bash-script to submit 'fastQTL RESULTS QUALITY CONTROL & PARSER v2' on >>> nominal <<< pass results..."
			### FOR DEBUGGING
			###Rscript ${FASTQCTLADDON}/fastQTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t NOM -q MQTL -o ${REGIONALDIR}/ -a ${ORIGINALS}/IlluminaMethylation450K.annotation.txt.gz -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats 
			echo "Rscript ${FASTQCTLADDON}/fastQTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t NOM -q MQTL -o ${REGIONALDIR}/ -a ${ORIGINALS}/IlluminaMethylation450K.annotation.txt.gz -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} "> ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			echo ""
			echo "Creating bash-script to submit 'fastQTL RESULTS QUALITY CONTROL & PARSER v2' on >>> permutation <<< pass results..."
			### FOR DEBUGGING
			###Rscript ${FASTQCTLADDON}/fastQTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t PERM -q MQTL -o ${REGIONALDIR}/ -a ${ORIGINALS}/IlluminaMethylation450K.annotation.txt.gz -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats 
			echo "Rscript ${FASTQCTLADDON}/fastQTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t PERM -q MQTL -o ${REGIONALDIR}/ -a ${ORIGINALS}/IlluminaMethylation450K.annotation.txt.gz -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} "> ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			echo ""
		elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
			echo "Creating bash-script to submit 'fastQTL RESULTS QUALITY CONTROL & PARSER v2' on >>> nominal <<< pass results..."
			### FOR DEBUGGING
			###Rscript ${FASTQCTLADDON}/fastQTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t NOM -q EQTL -o ${REGIONALDIR}/ -a ${CTMMEXPRESSIONDATA}/annotation_ctmm_all.csv -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats 
			
			#old
			echo "Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t NOM -q EQTL -o ${REGIONALDIR}/ -a ${CTMMEXPRESSIONDATA}/annotation_ctmm_all.csv -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} "> ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			
			# right clumped
			echo "Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t NOM -q EQTL -o ${REGIONALDIR}/ -a ${CTMMEXPRESSIONDATA}/annotation_ctmm_all.csv -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} "> ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_clumped${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			
			#jacco
			#echo "Rscript ${FASTQCTLADDON}/fastQTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped.txt.gz -t NOM -q EQTL -o ${REGIONALDIR}/ -a ${CTMMEXPRESSIONDATA}/annotation_ctmm_all.csv -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats  "> ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped.sh
			#qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCnom_${VARIANT}_excl_${EXCLUSION_TYPE}_clumped.sh
			
			
			echo ""
			echo "Creating bash-script to submit 'fastQTL RESULTS QUALITY CONTROL & PARSER v2' on >>> permutation <<< pass results..."
			### FOR DEBUGGING
			###Rscript ${FASTQCTLADDON}/fastQTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t PERM -q EQTL -o ${REGIONALDIR}/ -a ${CTMMEXPRESSIONDATA}/annotation_ctmm_all.csv -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats 
			echo "Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t PERM -q EQTL -o ${REGIONALDIR}/ -a ${CTMMEXPRESSIONDATA}/annotation_ctmm_all.csv -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} "> ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			
			# clumped
			echo "Rscript ${QTLTOOLKIT}/QTL_QC.R -p ${PROJECT} -r ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.txt.gz -t PERM -q EQTL -o ${REGIONALDIR}/ -a ${CTMMEXPRESSIONDATA}/annotation_ctmm_all.csv -j ${REGIONALDIR}/${SNPTESTOUTPUTDATA}_QC_${VARIANT}_excl_${EXCLUSION_TYPE}.stats -z ${QTL_TYPE} "> ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			qsub -S /bin/bash -N QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLCheck_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.errors -o ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${REGIONALDIR} ${REGIONALDIR}/${STUDYNAME}_QTLQCperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.sh
			
			
			echo ""
		
		
		else
			echo "                        *** ERROR *** "
			echo "Something is rotten in the City of Gotham; most likely a typo. "
			echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
			echo "                *** END OF ERROR MESSAGE *** "
			exit 1
		fi
		
	done < ${REGIONS}
 
	
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Summarizing fastQTL results."
	echo ""
	### Creating a job that will aid in summarizing the data.
	### FOR DEBUGGING
	###${FASTQCTLADDON}/fastQTLSummarizer.sh ${STUDY_TYPE} ${SAMPLE_TYPE} ${STUDYNAME} ${PROJECT} ${PROJECTNAME} ${SUMMARY} ${RESULTS} ${REGIONS} ${EXCLUSION_TYPE} #
	### updated for clumping, last parameter is for Summarizer script
	echo "${QTLTOOLKIT}/QTLSummarizer.sh ${STUDY_TYPE} ${SAMPLE_TYPE} ${STUDYNAME} ${PROJECT} ${PROJECTNAME} ${SUMMARY} ${RESULTS} ${REGIONS} ${EXCLUSION_TYPE} ${CLUMPDIR} ${QTL_TYPE} "> ${SUMMARY}/${STUDYNAME}_QTLSum_excl_${EXCLUSION_TYPE}.sh
	qsub -S /bin/bash -N QTLSum_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLQC_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/${STUDYNAME}_QTLSum_excl_${EXCLUSION_TYPE}.errors -o ${SUMMARY}/${STUDYNAME}_QTLSum_excl_${EXCLUSION_TYPE}.log -l h_rt=${QUEUE_QCTOOL} -l h_vmem=${VMEM_QCTOOL} -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_QTLSum_excl_${EXCLUSION_TYPE}.sh
	
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Creating SNP info file for easy reading."
	echo ""
    if [[ ${CLUMP} == "Y" ]]; then
        echo "python ${QTLTOOLKIT}/QTLSumParser.py Y ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt.gz ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz ${SUMMARY}"> ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.sh
        qsub -S /bin/bash -N QTLParser_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLSum_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.errors -o ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.log -l h_rt=00:15:00 -l h_vmem=12G -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.sh
	else
	    echo "python ${QTLTOOLKIT}/QTLSumParser.py N ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt.gz ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt.gz ${SUMMARY}"> ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.sh
        qsub -S /bin/bash -N QTLParser_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLSum_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.errors -o ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.log -l h_rt=00:15:00 -l h_vmem=12G -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_QTLParser_excl_${EXCLUSION_TYPE}.sh
	fi

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	#echo "Auto_run for variant_analysis."
	#echo ""
	#echo "/hpc/dhl_ec/jschaap/GWASToolKit/run_analysis_auto_variant.sh ${SUMMARY}/ctmm_qtl_tophits.txt"> ${SUMMARY}/${STUDYNAME}_GWAS_var_analysis_excl_${EXCLUSION_TYPE}.sh
	#qsub -S /bin/bash -N GWAS_var_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -hold_jid QTLParser_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME} -e ${SUMMARY}/GWAS_var_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME}.errors -o ${SUMMARY}/GWAS_var_${STUDYJOBNAME}_excl_${EXCLUSION_TYPE}_${PROJECTNAME}.log -l h_rt=00:15:00 -l h_vmem=4G -M ${EMAIL} -m ${MAILTYPE} -wd ${SUMMARY} ${SUMMARY}/${STUDYNAME}_GWAS_var_analysis_excl_${EXCLUSION_TYPE}.sh


	echo ""
	echo ""
	if [[ ${STUDY_TYPE} == "CTMM" ]]; then
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "Plotting fastQTL results for an eQTL analysis using CTMM's monocytes whole-genome expression data."
		echo ""
		### Creating a job that will aid in plotting the data.
		### FOR DEBUGGING
		###${FASTQCTLADDON}/fastQTLPlotter.sh ${STUDY_TYPE} ${SAMPLE_TYPE} ${REGIONS} ${SUMMARY} ${STUDYNAME}
		# Jacco: extra parameter for the directory with clumped data (same level as qtl/qtl_summary dirs). Also extra parameter to tell script wich data must be plotted
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
