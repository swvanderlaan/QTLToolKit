#!/bin/bash
#
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
	echoerror " * Argument #2  summary directory to put all summarized files in."
	echoerror " * Argument #3  directory in which the QTL results are saved."
	echoerror " * Argument #4  QTL type [CIS/TRANS]."
	echoerror ""
	echoerror " An example command would be: "
	echoerror ""
	echoerror "./QTLSummarizer.sh [arg1] [arg2] [arg3] [arg4]"
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
echobold "+ * Last update : 2018-08-21                                                                            +"
echobold "+ * Version     : 1.1.4                                                                                 +"
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
	
	CLUMPDIR=${RESULTS}/clumps # Directory with clump information
	
	QTL_TYPE=${4} # CIS or TRANS


### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 4 ]]; then 
	echo "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "You must supply at least [4] arguments when summarizing QTL results!"

else

#	###FOR DEBUGGING
#	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#	echo "The following is set:"
#	echo ""
#	echo "Software directory                                 ${SOFTWARE}"
#	echo "Where \"qctool\" resides                             ${QCTOOL}"
#	echo "Where \"QTLTools\" resides                           ${FASTQTL}"
#	echo "Where \"bgzip\" resides                              ${BGZIP}"
#	echo "Where \"tabix\" resides                              ${TABIX}"
#	echo "Where \"snptest 2.5.2\" resides                      ${SNPTEST252}"
#	echo ""
#	echo "Project directory                                  ${PROJECTDIR}"
#	echo "Results directory                                  ${RESULTS}"
#	echo "Summary directory                                  ${SUMMARY}"
#	echo "Clump directory                                    ${CLUMPDIR}"
#	echo "Regions of interest file                           ${REGIONS}"
#	echo "Exclusion type                                     ${EXCLUSION_TYPE}"
#	echo "QTL-type                                           ${QTL_TYPE}"
#	echo ""     
#	echo "We will run this script on                         ${TODAY}"
#	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

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
		rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt.gz
		rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz
		rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt.gz
		rm -v ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt.gz
	fi
	
	if [[ ${ANALYSIS_TYPE} == "MQTL" ]]; then
		echo "Making appropriate summary file for results from a mQTL analysis in the '${STUDY_TYPE}'..."
		if [[ ${CLUMP} == "N" ]]; then
			echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,Distance_VARIANT_CpG,Strand,Chr_CpG,BP_CpG,ProbeType,GeneName,AccessionID_UCSC,GeneGroup_UCSC,CpG_Island_Relation_UCSC,Phantom,DMR,Enhancer,HMM_Island,RegulatoryFeatureName,RegulatoryFeatureGroup,DHS,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
			echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,Distance_VARIANT_CpG,Strand,Chr_CpG,BP_CpG,ProbeType,GeneName,AccessionID_UCSC,GeneGroup_UCSC,CpG_Island_Relation_UCSC,Phantom,DMR,Enhancer,HMM_Island,RegulatoryFeatureName,RegulatoryFeatureGroup,DHS,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt
		
		else
			echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,Distance_VARIANT_CpG,Strand,Chr_CpG,BP_CpG,ProbeType,GeneName,AccessionID_UCSC,GeneGroup_UCSC,CpG_Island_Relation_UCSC,Phantom,DMR,Enhancer,HMM_Island,RegulatoryFeatureName,RegulatoryFeatureGroup,DHS,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt	
			echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,Distance_VARIANT_CpG,Strand,Chr_CpG,BP_CpG,ProbeType,GeneName,AccessionID_UCSC,GeneGroup_UCSC,CpG_Island_Relation_UCSC,Phantom,DMR,Enhancer,HMM_Island,RegulatoryFeatureName,RegulatoryFeatureGroup,DHS,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt
		fi
		
		echo ""
	elif [[ ${ANALYSIS_TYPE} == "EQTL" ]]; then
		echo "Making appropriate summary file for results from an eQTL analysis in the '${STUDY_TYPE}'..."
		if [[ ${CLUMP} == "N" ]]; then
			echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Strand,Chr_Gene,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
			echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Strand,Chr_Gene,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt
			
		else
			echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Strand,Chr_Gene,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
			echo "Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Strand,Chr_Gene,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q" > ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt
		fi
		
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
		cp -fv ${REGIONALDIR}/*.nominal.all.txt ${SUMMARY}/
		cp -fv ${REGIONALDIR}/*.pdf ${SUMMARY}/
		if [[ ${QTL_TYPE} == "CIS" ]]; then
			cp -fv ${REGIONALDIR}/*.perm.Q0_05.txt ${SUMMARY}/
		fi
		
		echo ""
		echo "Adding all results for the ${VARIANT} locus to the summary file..."
		
		echo ""
		echo "Nominal results..."
		### 17-6-17, trying if we need the clump parameter, so performing summarizing on all data, clumped and not clumped.
		
		if [[ ${QTL_TYPE} == "CIS" ]]; then
			echo ""
			echo "Nominal results..."
			cat ${SUMMARY}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.nominal.all.txt | tail -n +2 | awk -v LOCUS_VARIANT=$VARIANT '{ print LOCUS_VARIANT, $0 }' OFS=","  >> ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
			gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.nominal.all.txt
	
			if [[ ${CLUMP} == "Y" ]]; then
				cat ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.nominal.all.txt | tail -n +2 | awk -v LOCUS_VARIANT=$VARIANT '{ print LOCUS_VARIANT, $0 }' OFS=","  >> ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.nominal.all.txt

			else
				echo ""
				echoerrornooption "We only performed a permutation QTL-analysis on non-clumped data - no QC on clumped data needed."

			fi
			
			echo ""
			echo "Permutation results..."
			cat ${SUMMARY}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.perm.Q0_05.txt | tail -n +2 | awk -v LOCUS_VARIANT=$VARIANT '{ print LOCUS_VARIANT, $0 }' OFS=","  >> ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt
			gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.perm.Q0_05.txt
		
			if [[ ${CLUMP} == "Y" ]]; then
				cat ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.perm.Q0_05.txt | tail -n +2 | awk -v LOCUS_VARIANT=$VARIANT '{ print LOCUS_VARIANT, $0 }' OFS=","  >> ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt
				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_${VARIANT}_excl_${EXCLUSION_TYPE}.perm.Q_05.txt

			else
				echo ""
				echoerrornooption "We only performed a permutation QTL-analysis on non-clumped data - no QC on clumped data needed."

			fi
		
		elif [[ ${QTL_TYPE} == "TRANS" ]]; then
			cat ${SUMMARY}/${VARIANT}.hits_nominal.all.txt | tail -n +2 | awk -v LOCUS_VARIANT=$VARIANT '{ print LOCUS_VARIANT, $0 }' OFS=","  >> ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
			gzip -fv ${SUMMARY}/${VARIANT}_nominal.all.txt
		fi
		
	done < ${REGIONS}

	### Jacco made changes on 17-6-17, always gzip all the files. Only make differences when plotting!
	### GZIPPING FINAL SUMMARY RESULTS
	echo ""
	echo "Compressing the final summary results..."
	
 	if [[ ${QTL_TYPE} == "CIS" ]]; then
 	
 		if [[ ${CLUMP} == "Y" ]]; then
 			if [[ ${ANALYSIS_TYPE} == "MQTL" ]]; then
 				echo "* Clumped ${QTL_TYPE}-${ANALYSIS_TYPE} results."
 				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
 				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt
 				
 				echo "* And re-ordering based on p-value."
 				zcat ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz | (head -n 1 && tail -n +3  | sort -t , -k 32) > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.reorder.txt
 				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.reorder.txt
 			else
 				echo "* Clumped ${QTL_TYPE}-QTL results."
 				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
 				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt
 				
 				echo "* And re-ordering based on p-value."
 				zcat ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz | (head -n 1 && tail -n +3  | sort -t , -k 24) > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
 				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt
 			fi	
 		else
 			if [[ ${ANALYSIS_TYPE} == "MQTL" ]]; then
 				echo "* Non-clumped ${QTL_TYPE}-${ANALYSIS_TYPE} results."
 				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt
 				
 				echo "* And re-ordering based on p-value."
 				cat ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt | (head -n 1 && tail -n +3  | sort -t , -k 32) > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.reorder.txt
 				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.reorder.txt
 			else 
 				echo "* Non-clumped ${QTL_TYPE}-QTL results."
 				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt
 				
 				echo "* And re-ordering based on p-value."
 				cat ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt | (head -n 1 && tail -n +3  | sort -t , -k 24) > ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
 				gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt
 			fi
 		fi
 		
 	elif [[ ${QTL_TYPE} == "TRANS" ]]; then
 		gzip -fv ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt

 
 	fi
	

### END of if-else statement for the number of command-line arguments passed ###
fi

script_copyright_message
