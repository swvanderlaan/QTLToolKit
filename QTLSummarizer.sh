#!/bin/bash
#
# You can use the variables below (indicated by "#$") to set some things for the 
# submission system.
# -S /bin/bash # the type of BASH you'd like to use
# -N fastQTLSummarizer_v1 # the name of this script
# -hold_jid some_other_basic_bash_script # the current script (basic_bash_script) will hold until some_other_basic_bash_script has finished
# -o /hpc/dhl_ec/svanderlaan/projects/test_mqtl/fastQTLSummarizer_v1.log # the log file of this job
# -e /hpc/dhl_ec/svanderlaan/projects/test_mqtl/fastQTLSummarizer_v1.errors # the error file of this job
# -l h_rt=04:00:00 # h_rt=[max time, hh:mm:ss, e.g. 02:02:01] - this is the time you think the script will take
# -l h_vmem=8G #  h_vmem=[max. mem, e.g. 45G] - this is the amount of memory you think your script will use
# -l tmpspace=32G # this is the amount of temporary space you think your script will use
# -M s.w.vanderlaan-2@umcutrecht.nl # you can send yourself emails when the job is done; "-M" and "-m" go hand in hand
# -m ea # you can choose: b=begin of job; e=end of job; a=abort of job; s=suspended job; n=no mail is send
# -cwd # set the job start to the current directory - so all the things in this script are relative to the current directory!!!
#
# Another useful tip: you can set a job to run after another has finished. Name the job 
# with "-N SOMENAME" and hold the other job with -hold_jid SOMENAME". 
# Further instructions: https://wiki.bioinformatics.umcutrecht.nl/bin/view/HPC/HowToS#Run_a_job_after_your_other_jobs
#
# It is good practice to properly name and annotate your script for future reference for
# yourself and others. Trust me, you'll forget why and how you made this!!!

### REGARDING NOTES ###
### Please note that uncommented notes can be found at the end of this script.
###

### MoSCoW FEATURE LIST ###
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
	echoerror " * Argument #1  configurationfile: qtl.config."
	echo " * Argument #2  summary directory to put all summarized files in."
	echo " * Argument #3  directory in which the QTL results are saved."
	echo " * Argument #4  Directory where clump data can be found."
	echo " * Argument #5  QTL type [CIS/TRANS]."
	echoerror ""
	echoerror " An example command would be: "
	echoerror ""
	echoerror "./QTLSummarizer.sh [arg1] [arg2] [arg3] [arg4] [arg5]"
	echoerror ""
	echoerror "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	script_copyright_message
  	exit 1
}

echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echobold "+                                   QUANTITATIVE TRAIT LOCUS SUMMARIZER                                 +"
echobold "+                                                                                                       +"
echobold "+                                                                                                       +"
echobold "+ * Written by  : Sander W. van der Laan; Jacco Schaap                                                  +"
echobold "+ * E-mail      : s.w.vanderlaan-2@umcutrecht.nl; jacco_schaap@hotmail.com                              +"
echobold "+ * Last update : 2018-02-25                                                                            +"
echobold "+ * Version     : 1.0.4                                                                                 +"
echobold "+                                                                                                       +"
echobold "+ * Description : This script will conveniently summarize the QTL analysis and put the files in a       +"
echobold "+                 summary directory.                                                                    +"
echobold "+                                                                                                       +"
echobold "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Today's date and time: "$(date)
TODAY=$(date +"%Y%m%d")
echo ""

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
	NOMINAL_P=${NOMINAL_P}
	
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
	
	STUDYNAME=${STUDYNAME} # What is the study name to be used in files -- refer to 'qtl.config' for information
	PROJECTDIR=${ROOTDIR}/${PROJECTNAME} # What is the project directory?  -- refer to 'qtl.config' for for information
	PROJECTNAME=${PROJECTNAME} # What is the projectname? E.g. 'CAD' -- refer to f'qtl.config' for for information
	SUMMARY=${2} # The summary directory to put all summarized files in -- refer to 'qtl.config' for for information
	RESULTS=${3} # The directory in which the QTL results are saved -- refer to 'qtl.config' for for information
	
	REGIONS=${REGIONS_FILE} # The file containing the regions of interest -- refer to 'qtl.config' for for information
	
	EXCLUSION_TYPE=${EXCLUSION_TYPE} # The exclusion type -- refer to 'qtl.config' for for information
	
	CLUMPDIR=${4} # Directory with clump information
	
	QTL_TYPE=${5} # CIS or TRANS


### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 5 ]]; then 
	echo "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "You must supply at least [5] arguments when summarizing QTL results!"

else
	

	###FOR DEBUGGING
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
	echo "Project directory                                  ${PROJECTDIR}"
	echo "Results directory                                  ${RESULTS}"
	echo "Summary directory                                  ${SUMMARY}"
	echo "Clump directory                                    ${CLUMPDIR}"
	echo "Regions of interest file                           ${REGIONS}"
	echo "Exclusion type                                     ${EXCLUSION_TYPE}"
	echo "QTL-type                                           ${QTL_TYPE}"
	echo ""     
	echo "We will run this script on                         ${TODAY}"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"


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

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Summarising all relevant files into one file."
	
	### CREATES SUMMARY FILES
	if [ ! -f ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt ]; then
		echo "The summary file doesn't exist; Mr. Bourne will make it for you."
	elif [ ! -f ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt ]; then
		echo "The summary file doesn't exist; Mr. Bourne will make it for you."
	else
		echo "The sumary file already exists; Mr. Bourne will re-create it for you."
		rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
		rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
		rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt
		rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt
	fi
	
	if [[ ${STUDY_TYPE} == "AEMS450K1" ]] || [[ ${STUDY_TYPE} == "AEMS450K2" ]]; then
		echo "Making appropriate summary file for results from a mQTL analysis in the '${STUDY_TYPE}'..."
		echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,Distance_VARIANT_CpG,Chr_CpG,BP_CpG,ProbeType,GeneName,AccessionID_UCSC,GeneGroup_UCSC,CpG_Island_Relation_UCSC,Phantom,DMR,Enhancer,HMM_Island,RegulatoryFeatureName,RegulatoryFeatureGroup,DHS,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
		echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,Distance_VARIANT_CpG,Chr_CpG,BP_CpG,ProbeType,GeneName,AccessionID_UCSC,GeneGroup_UCSC,CpG_Island_Relation_UCSC,Phantom,DMR,Enhancer,HMM_Island,RegulatoryFeatureName,RegulatoryFeatureGroup,DHS,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
		echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,Distance_VARIANT_CpG,Chr_CpG,BP_CpG,ProbeType,GeneName,AccessionID_UCSC,GeneGroup_UCSC,CpG_Island_Relation_UCSC,Phantom,DMR,Enhancer,HMM_Island,RegulatoryFeatureName,RegulatoryFeatureGroup,DHS,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt
		echo ""
	elif [[ ${STUDY_TYPE} == "CTMM" ]]; then
		echo "Making appropriate summary file for results from an eQTL analysis in the '${STUDY_TYPE}'..."
		echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Chr,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
		echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Chr,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
		echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Chr,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt
		echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Chr,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt
		echo ""
	else
		echo "                        *** ERROR *** "
		echo "Something is rotten in the City of Gotham; most likely a typo. "
		echo "Double back, and check you 'study type' please: '${STUDY_TYPE}' does *not* exist."	
		echo "                *** END OF ERROR MESSAGE *** "
		exit 1
	fi
	
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
		
		if [[ ${QTL_TYPE} == "CIS" ]]; then
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
			echo ${REGIONALDIR}
			echo ${RESULTS}/${CHR}_${PROJECTNAME}
			
		elif [[ ${QTL_TYPE} == "TRANS" ]]; then
			echo "===================================================================="
			echo "Processing ${VARIANT} locus on ${CHR} between ${START} and ${END}..."
			### Make directories for script if they do not exist yet (!!!PREREQUISITE!!!)
			if [ ! -d ${RESULTS}/${CHR}_${PROJECTNAME} ]; then
				echo "The regional directory doesn't exist; Mr. Bourne will make it for you."
				mkdir -v ${RESULTS}/${CHR}_${PROJECTNAME}
			else
				echo "The regional directory already exists."
			fi
			REGIONALDIR=${RESULTS}/${CHR}_${PROJECTNAME}
			echo ${REGIONALDIR}
			echo ${RESULTS}/${CHR}_${PROJECTNAME}
		fi
		echo ""
		echo "Copying results to the Summary Directory..."	
		# Also copies the clumped file, so this is fine
		cp -v ${REGIONALDIR}/*_nominal.all.txt ${SUMMARY}/
		cp -v ${REGIONALDIR}/*.pdf ${SUMMARY}/
		if [[ ${QTL_TYPE} == "CIS" ]]; then
			cp -v ${REGIONALDIR}/*_perm.P0_05.txt ${SUMMARY}/
		fi
		
		echo ""
		echo "Adding all results for the ${VARIANT} locus to the summary file..."
		
		echo ""
		echo "Nominal results..."
		### 17-6-17, trying if we need the clump parameter, so performing summarizing on all data, clumped en not clumped.
		
		if [[ ${QTL_TYPE} == "CIS" ]]; then
			echo ""
			echo "Nominal results..."
			cat ${SUMMARY}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_nominal.all.txt | tail -n +2 | awk -v LOCUS_VARIANT=$VARIANT '{ print LOCUS_VARIANT, $0 }' OFS=","  >> ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
			gzip -v ${SUMMARY}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_nominal.all.txt
		
			cat ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_nominal.all.txt | tail -n +2 | awk -v LOCUS_VARIANT=$VARIANT '{ print LOCUS_VARIANT, $0 }' OFS=","  >> ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
			gzip -v ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_nominal.all.txt

			echo ""
			echo "Permutation results..."
			cat ${SUMMARY}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_perm.P0_05.txt | tail -n +2 | awk -v LOCUS_VARIANT=$VARIANT '{ print LOCUS_VARIANT, $0 }' OFS=","  >> ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt
			gzip -v ${SUMMARY}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_perm.P0_05.txt
		
			cat ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_perm.P0_05.txt | tail -n +2 | awk -v LOCUS_VARIANT=$VARIANT '{ print LOCUS_VARIANT, $0 }' OFS=","  >> ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt
			gzip -v ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}_perm.P0_05.txt
		
		elif [[ ${QTL_TYPE} == "TRANS" ]]; then
			cat ${SUMMARY}/${VARIANT}.hits_nominal.all.txt | tail -n +2 | awk -v LOCUS_VARIANT=$VARIANT '{ print LOCUS_VARIANT, $0 }' OFS=","  >> ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
			gzip -v ${SUMMARY}/${VARIANT}_nominal.all.txt
		fi
		
	done < ${REGIONS}

	### Jacco made changes on 17-6-17, always gzip all the files. Only make differences when plotting!
	### GZIPPING FINAL SUMMARY RESULTS
	echo ""
	echo "Compressing the final summary results..."
	
	if [[ ${QTL_TYPE} == "TRANS" ]]; then
		gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
		#rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
		#rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt
		#rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt # why is this removed???

	elif [[ ${QTL_TYPE} == "CIS" ]]; then
		gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
		gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
		gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt
		gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt
		# Add rsquare value to the summary files, created a python script that does the job (17-6-17)
# 		pwd
# # 		module load python
# 		echo "${PYTHON} ${QTLTOOLKIT}/QTLSumEditor.py ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt.gz ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt.gz ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt.gz ${CLUMPDIR}"
# 		${PYTHON} ${QTLTOOLKIT}/QTLSumEditor.py ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt.gz ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt.gz ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt.gz ${CLUMPDIR} 
	fi
	
	zcat ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt.gz | (head -n 1 && tail -n +3  | sort -t , -k 23) > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
	gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
### END of if-else statement for the number of command-line arguments passed ###
fi

script_copyright_message
