#!/bin/bash
#
# You can use the variables below (indicated by "#$") to set some things for the 
# submission system.
# -S /bin/bash # the type of BASH you'd like to use
# -N QTLChecker_v1 # the name of this script
# -hold_jid some_other_basic_bash_script # the current script (basic_bash_script) will hold until some_other_basic_bash_script has finished
# -o /hpc/dhl_ec/svanderlaan/projects/test_mqtl/QTLChecker_v1.log # the log file of this job
# -e /hpc/dhl_ec/svanderlaan/projects/test_mqtl/QTLChecker_v1.errors # the error file of this job
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
	echoerror " * Argument #1  the study name -- set in QTLAnalyzer.sh (please refer to there)."
	echoerror " * Argument #2  exclusion type."
	echoerror " * Argument #3  the root directory, e.g. /hpc/dhl_ec/svanderlaan/projects/test_qtl."
	echoerror " * Argument #4  where the results are saved -- set in QTLAnalyzer.sh (please refer to there)."
	echoerror " * Argument #4  where the summary is saved -- set in QTLAnalyzer.sh (please refer to there)."
	echoerror " * Argument #6  project name, e.g. 'CAD'."
	echoerror " * Argument #7  file containing the regions of interest."
	echoerror " * Argument #8  QTL type [CIS/TRANS]."
	echoerror ""
	echoerror " An example command would be: "
	echoerror "./QTLChecker.sh [arg1] [arg2] [arg3] [arg4] [arg5] [arg6] [arg7]"
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
echobold "+ * Written by  : Sander W. van der Laan                                                                +"
echobold "+ * E-mail      : s.w.vanderlaan-2@umcutrecht.nl                                                        +"
echobold "+ * Last update : 2018-02-26                                                                            +"
echobold "+ * Version     : 1.1.3                                                                                 +"
echobold "+                                                                                                       +"
echobold "+ * Description : This script will set some directories, execute something in a for-loop, and will then +"
echobold "+                 submit this in a job.                                                                 +"
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
 	
### Set the study name
STUDYNAME=${STUDYNAME} # What is the study name to be used in files -- refer to QTLAnalyzer.sh for information
EXCLUSION_TYPE=${EXCLUSION_TYPE} # The exclusion type -- refer to QTLAnalyzer.sh for information

### PROJECT SPECIFIC 
ROOTDIR=${ROOTDIR} # the root directory, e.g. /hpc/dhl_ec/svanderlaan/projects/test_qtl
RESULTS=${2} # The directory in which the fastQTL results are saved -- refer to QTLAnalyzer.sh for information
SUMMARY=${3} # The directory in which the fastQTL results are saved -- refer to QTLAnalyzer.sh for information
PROJECTNAME=${PROJECTNAME} # What is the projectname? E.g. 'CAD' -- refer to QTLAnalyzer.sh for information
REGIONS=${REGIONS_FILE} # The file containing the regions of interest -- refer to QTLAnalyzer.sh for information
QTL_TYPE=${QTL_TYPE} # QTL type, cis or trans
 
### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 1 ]]; then 
	echo "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "You must supply at least [1] argument when summarizing QTL results!"

else
	
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


	### CHECKING DATA AND ANALYSIS
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "Checking whether analyses of loci were properly finished."
	rm -v ${SUMMARY}/regions_for_qtl.failedQTLs.temp.txt ${ROOTDIR}/analysis.check.txt
	rm -v ${SUMMARY}/regions_for_qtl.failedQTLs.txt
	rm -v ${SUMMARY}/regions_for_qtl.failedNom.temp.txt
	rm -v ${SUMMARY}/regions_for_qtl.failedNom.txt
	rm -v ${SUMMARY}/regions_for_qtl.failedPerm.temp.txt
	rm -v ${SUMMARY}/regions_for_qtl.failedPerm.txt
	touch ${SUMMARY}/regions_for_qtl.failedQTLs.temp.txt # 'touching' a file for the complete rerun
	touch ${SUMMARY}/regions_for_qtl.failedNom.temp.txt # 'touching' a file for the nominal rerun
	touch ${SUMMARY}/regions_for_qtl.failedPerm.temp.txt # 'touching' a file for the permutation rerun
	touch ${SUMMARY}/analysis.check.txt # a file containing some information regarding the check on the analysis
	
	echo ""
	while IFS='' read -r REGIONOFINTEREST || [[ -n "$REGIONOFINTEREST" ]]; do
		###	1		2		3	4	5		6		7			8		9
		###Variant	Locus	Chr	BP	StartRange	EndRange	WindowSize	Type	Phenotype
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
	
		echo ""
		echo ""
		
		echo "========================================================================================================="
		echo "Checking whether analyses for ${VARIANT} locus on ${CHR} between ${START} and ${END} went well..."
		echo "========================================================================================================="
		REGIONALDIR=${RESULTS}/${VARIANT}_${PROJECTNAME} # setting regional directory
		
		echo "Working in directory: ${REGIONALDIR}/[...]"
		
		echo "Checking variant ${VARIANT} locus on ${CHR}:${START}-${END}." >> ${SUMMARY}/analysis.check.txt
		
		echo ""
		echo "* Checking data extraction..."
		if [[ -n $(grep "Thank you for using qctool." ${REGIONALDIR}/${STUDYNAME}_genex_${VARIANT}_excl_${EXCLUSION_TYPE}.errors) ]]; then
			echo "Extraction of data successfully completed for ${VARIANT}."
			echo "* data extraction: success" >> ${SUMMARY}/analysis.check.txt
			rm -v ${REGIONALDIR}/${STUDYNAME}_genex_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			mv -v ${REGIONALDIR}/${STUDYNAME}_genex_${VARIANT}_excl_${EXCLUSION_TYPE}.errors ${REGIONALDIR}/${STUDYNAME}_genex_${VARIANT}_excl_${EXCLUSION_TYPE}.log
			gzip -v ${REGIONALDIR}/${STUDYNAME}_genex_${VARIANT}_excl_${EXCLUSION_TYPE}.log			
		else
			echo "*** ERROR *** Extraction of data failed for ${VARIANT}."
			echo "* data extraction: failed" >> ${SUMMARY}/analysis.check.txt
		    #rm -rv ${REGIONALDIR}
		    echo "${VARIANT} ${LOCUS} ${CHR} ${BP} ${START} ${END} ${WINDOWSIZE} ${TYPE} ${PHENOTYPE}" >> ${SUMMARY}/regions_for_qtl.failedQTLs.temp.txt
		fi
		
		echo ""
		echo "* Checking data quality control..."
		if [[ -n $(grep "Thank you for using qctool." ${REGIONALDIR}/${STUDYNAME}_genqc_${VARIANT}_excl_${EXCLUSION_TYPE}.errors) ]]; then
			echo "Quality control of extracted data successfully completed for ${VARIANT}."
			echo "* data quality control: success" >> ${SUMMARY}/analysis.check.txt
			rm -v ${REGIONALDIR}/${STUDYNAME}_genqc_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			mv -v ${REGIONALDIR}/${STUDYNAME}_genqc_${VARIANT}_excl_${EXCLUSION_TYPE}.errors ${REGIONALDIR}/${STUDYNAME}_genqc_${VARIANT}_excl_${EXCLUSION_TYPE}.log
			gzip -v ${REGIONALDIR}/${STUDYNAME}_genqc_${VARIANT}_excl_${EXCLUSION_TYPE}.log			
		else
			echo "*** ERROR *** Quality control of extracted data failed for ${VARIANT}."
		    echo "* data quality control: failed" >> ${SUMMARY}/analysis.check.txt
		    #rm -rv ${REGIONALDIR}
		    echo "${VARIANT} ${LOCUS} ${CHR} ${BP} ${START} ${END} ${WINDOWSIZE} ${TYPE} ${PHENOTYPE}" >> ${SUMMARY}/regions_for_qtl.failedQTLs.temp.txt
		fi
		
		echo ""
		echo "* Checking general statistics..."
		if [[ -n $(grep "finito" ${REGIONALDIR}/${STUDYNAME}_genstats_${VARIANT}_excl_${EXCLUSION_TYPE}.log) ]]; then
			echo "Calculating general statistics successfully completed for ${VARIANT}."
			echo "* calculate summary statistics: success" >> ${SUMMARY}/analysis.check.txt
			rm -v ${REGIONALDIR}/${STUDYNAME}_genstats_${VARIANT}_excl_${EXCLUSION_TYPE}.errors
			gzip -v ${REGIONALDIR}/${STUDYNAME}_genstats_${VARIANT}_excl_${EXCLUSION_TYPE}.log
		else
			echo "*** ERROR *** Calculating general statistics failed for ${VARIANT}."
			echo "* calculate summary statistics: failed" >> ${SUMMARY}/analysis.check.txt
			#rm -rv ${REGIONALDIR}
			echo "${VARIANT} ${LOCUS} ${CHR} ${BP} ${START} ${END} ${WINDOWSIZE} ${TYPE} ${PHENOTYPE}" >> ${SUMMARY}/regions_for_qtl.failedQTLs.temp.txt
		fi
		
		echo ""
		echo "* Checking conversion to VCF..."
		if [[ -n $(grep "Thank you for using qctool." ${REGIONALDIR}/${STUDYNAME}_gen2vcf_${VARIANT}_excl_${EXCLUSION_TYPE}.errors) ]]; then
			echo "Conversion to VCF successfully completed for ${VARIANT}."
			echo "* vcf conversion: success" >> ${SUMMARY}/analysis.check.txt
			rm -v ${REGIONALDIR}/${STUDYNAME}_gen2vcf_${VARIANT}_excl_${EXCLUSION_TYPE}.log 
			mv -v ${REGIONALDIR}/${STUDYNAME}_gen2vcf_${VARIANT}_excl_${EXCLUSION_TYPE}.errors ${REGIONALDIR}/${STUDYNAME}_gen2vcf_${VARIANT}_excl_${EXCLUSION_TYPE}.log
			gzip -v ${REGIONALDIR}/${STUDYNAME}_gen2vcf_${VARIANT}_excl_${EXCLUSION_TYPE}.log			
		else
			echo "*** ERROR *** Conversion to VCF failed for ${VARIANT}."
			echo "* vcf conversion: failed" >> ${SUMMARY}/analysis.check.txt
		    #rm -rv ${REGIONALDIR}
		    echo "${VARIANT} ${LOCUS} ${CHR} ${BP} ${START} ${END} ${WINDOWSIZE} ${TYPE} ${PHENOTYPE}" >> ${SUMMARY}/regions_for_qtl.failedQTLs.temp.txt
		fi
		
		echo ""
		echo "* Checking gzipping of VCF..." 
		if [[ ! -s ${REGIONALDIR}/${STUDYNAME}_genvcfgz_${VARIANT}_excl_${EXCLUSION_TYPE}.errors ]]; then
			echo "GZipping VCF file was successfully completed for ${VARIANT}."
			echo "* gzipping vcf: success" >> ${SUMMARY}/analysis.check.txt
			rm -v ${REGIONALDIR}/${STUDYNAME}_vcfgz_${VARIANT}_excl_${EXCLUSION_TYPE}.errors
			gzip -v ${REGIONALDIR}/${STUDYNAME}_vcfgz_${VARIANT}_excl_${EXCLUSION_TYPE}.log
		else
			echo "*** ERROR *** GZipping VCF file failed for ${VARIANT}."
			echo "* gzipping vcf: failed" >> ${SUMMARY}/analysis.check.txt
			#rm -rv ${REGIONALDIR}
			echo "${VARIANT} ${LOCUS} ${CHR} ${BP} ${START} ${END} ${WINDOWSIZE} ${TYPE} ${PHENOTYPE}" >> ${SUMMARY}/regions_for_qtl.failedQTLs.temp.txt
		fi

		echo ""
		echo "* Checking nominal fastQTL analysis..."
		if [[ -n $(grep "Running time" ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log) ]]; then
			echo "Nominal fastQTL analysis successfully completed for ${VARIANT}."
			echo "* nominal analysis: success" >> ${SUMMARY}/analysis.check.txt
			rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.errors 
			rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.output
			rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.sh
			gzip -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log			
		else
			echo "*** ERROR *** Nominal QTLTools analysis failed for ${VARIANT}."
			echo "* nominal analysis: failed" >> ${SUMMARY}/analysis.check.txt
			echo "* error message: " >> ${SUMMARY}/analysis.check.txt
			cat ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log | grep "ERROR" >> ${SUMMARY}/analysis.check.txt
		    #rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.*
		    #rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.*
		    echo "${VARIANT} ${LOCUS} ${CHR} ${BP} ${START} ${END} ${WINDOWSIZE} ${TYPE} ${PHENOTYPE}" >> ${SUMMARY}/regions_for_qtl.failedNom.temp.txt
		fi
		
		echo ""
		echo "* Checking permutation QTLTools analysis..."
		if [[ -n $(grep "Running time" ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log) ]]; then
			echo "Permutation QTLTools analysis successfully completed for ${VARIANT}."
			echo "* permutation analysis: success" >> ${SUMMARY}/analysis.check.txt
			rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.errors
			rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.output
			rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
			gzip -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log			
		else
			echo "*** ERROR *** Permutation QTLTools analysis failed for ${VARIANT}."
			echo "* permutation analysis: failed" >> ${SUMMARY}/analysis.check.txt
			echo "* error message: " >> ${SUMMARY}/analysis.check.txt
			cat ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.log | grep "ERROR" >> ${SUMMARY}/analysis.check.txt
		    #rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.*
		    #rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.*
		    echo "${VARIANT} ${LOCUS} ${CHR} ${BP} ${START} ${END} ${WINDOWSIZE} ${TYPE} ${PHENOTYPE}" >> ${SUMMARY}/regions_for_qtl.failedPerm.temp.txt
		fi

		echo "" >> ${SUMMARY}/analysis.check.txt
		
	done < ${REGIONS}

	echo ""
	echo "* Removing duplicates from re-run file."
	perl ${QTLTOOLKIT}/SCRIPTS/removedupes.pl ${SUMMARY}/regions_for_qtl.failedQTLs.temp.txt NORM ${SUMMARY}/regions_for_qtl.failedQTLs.txt
	perl ${QTLTOOLKIT}/SCRIPTS/removedupes.pl ${SUMMARY}/regions_for_qtl.failedNom.temp.txt NORM ${SUMMARY}/regions_for_qtl.failedNom.txt
	perl ${QTLTOOLKIT}/SCRIPTS/removedupes.pl ${SUMMARY}/regions_for_qtl.failedPerm.temp.txt NORM ${SUMMARY}/regions_for_qtl.failedPerm.txt
	
	echo "  - removing temporary files..."
	rm -v ${SUMMARY}/regions_for_qtl.failedQTLs.temp.txt
	rm -v ${SUMMARY}/regions_for_qtl.failedNom.temp.txt
	rm -v ${SUMMARY}/regions_for_qtl.failedPerm.temp.txt

	echo ""
	echo "* Counting totals to be re-run."
	TOTALQTL=$(cat ${SUMMARY}/regions_for_qtl.failedQTLs.txt | wc -l | awk '{printf ("%'\''d\n", $0)}')
	TOTALNOM=$(cat ${SUMMARY}/regions_for_qtl.failedNom.txt | wc -l | awk '{printf ("%'\''d\n", $0)}')
	TOTALPERM=$(cat ${SUMMARY}/regions_for_qtl.failedPerm.txt | wc -l | awk '{printf ("%'\''d\n", $0)}')
	echo "  - failed extractions............: "${TOTALQTL}
	echo "  - failed nominal analyses.......: "${TOTALNOM}
	echo "  - failed permutation analyses...: "${TOTALPERM}
	echo ""	

### END of if-else statement for the number of command-line arguments passed ###
fi

script_copyright_message
