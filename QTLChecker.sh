#!/bin/bash
#
# You can use the variables below (indicated by "#$") to set some things for the 
# submission system.
# -S /bin/bash # the type of BASH you'd like to use
# -N fastQTLChecker_v1 # the name of this script
# -hold_jid some_other_basic_bash_script # the current script (basic_bash_script) will hold until some_other_basic_bash_script has finished
# -o /hpc/dhl_ec/svanderlaan/projects/test_mqtl/fastQTLChecker_v1.log # the log file of this job
# -e /hpc/dhl_ec/svanderlaan/projects/test_mqtl/fastQTLChecker_v1.errors # the error file of this job
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
	echo "Number of arguments found "$#"."
	echo ""
	echo "$1" # additional error message
	echo ""
	echo "========================================================================================================="
	echo "                                              OPTION LIST"
	echo ""
	echo " * Argument #1  the study name -- set in fastQTLAnalyzer.sh (please refer to there)."
	echo " * Argument #2  exclusion type."
	echo " * Argument #3  the root directory, e.g. /hpc/dhl_ec/svanderlaan/projects/test_qtl."
	echo " * Argument #4  where the results are saved -- set in fastQTLAnalyzer.sh (please refer to there)."
	echo " * Argument #4  where the summary is saved -- set in fastQTLAnalyzer.sh (please refer to there)."
	echo " * Argument #6  project name, e.g. 'CAD'."
	echo " * Argument #7  file containing the regions of interest."
	echo " * Argument #8  QTL type [CIS/TRANS]."
	echo ""
	echo " An example command would be: "
	echo "./fastQTLChecker.sh [arg1] [arg2] [arg3] [arg4] [arg5] [arg6] [arg7]"
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	script_copyright_message
  	exit 1
}

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+                                   QUANTITATIVE TRAIT LOCUS SUMMARIZER                                 +"
echo "+                                                                                                       +"
echo "+                                                                                                       +"
echo "+ * Written by  : Sander W. van der Laan                                                                +"
echo "+ * E-mail      : s.w.vanderlaan-2@umcutrecht.nl                                                        +"
echo "+ * Last update : 2016-12-06                                                                            +"
echo "+ * Version     : 1.0.2                                                                                 +"
echo "+                                                                                                       +"
echo "+ * Description : This script will set some directories, execute something in a for-loop, and will then +"
echo "+                 submit this in a job.                                                                 +"
echo "+                                                                                                       +"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Today's date and time: "$(date)
TODAY=$(date +"%Y%m%d")
echo ""

### Set the study name
STUDYNAME=${1} # What is the study name to be used in files -- refer to fastQTLAnalyzer.sh for information
EXCLUSION_TYPE=${2} # The exclusion type -- refer to fastQTLAnalyzer.sh for information

### PROJECT SPECIFIC 
ROOTDIR=${3} # the root directory, e.g. /hpc/dhl_ec/svanderlaan/projects/test_qtl
RESULTS=${4} # The directory in which the fastQTL results are saved -- refer to fastQTLAnalyzer.sh for information
SUMMARY=${5} # The directory in which the fastQTL results are saved -- refer to fastQTLAnalyzer.sh for information
PROJECTNAME=${6} # What is the projectname? E.g. 'CAD' -- refer to fastQTLAnalyzer.sh for information
REGIONS=${7} # The file containing the regions of interest -- refer to fastQTLAnalyzer.sh for information
QTL_TYPE=${8} # QTL type, cis or trans

### START of if-else statement for the number of command-line arguments passed ###
if [[ $# -lt 7 ]]; then 
	echo "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "You must supply at least [7] arguments when summarizing QTL results!"

else
	
	### GENERIC SETTINGS
	SOFTWARE=/hpc/local/CentOS7/dhl_ec/software
	QCTOOL=${SOFTWARE}/qctool_v1.5-linux-x86_64-static/qctool
	SNPTEST252=${SOFTWARE}/snptest_v2.5.2_CentOS6.5_x86_64_static/snptest_v2.5.2
	FASTQTL=${SOFTWARE}/fastqtl_v2.184
	QTL=${SOFTWARE}/QTLTools/QTLtools_1.0_CentOS6.8_x86_64
	QTLTOOLKIT=${SOFTWARE}/QTLToolKit
	FASTQCTLADDON=${SOFTWARE}/fastQTLToolKit
	FASTQTLPARSER=${FASTQCTLADDON}/NominalResultsParser.py
	LZ13=${SOFTWARE}/locuszoom_1.3/bin/locuszoom
	BGZIP=${SOFTWARE}/htslib-1.3/bgzip
	TABIX=${SOFTWARE}/htslib-1.3/tabix
	PLINK=/hpc/local/CentOS7/dhl_ec/software/plink_v1.9


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
			rm -v ${REGIONALDIR}/${STUDYNAME}_genvcfgz_${VARIANT}_excl_${EXCLUSION_TYPE}.errors
			#gzip -v ${REGIONALDIR}/${STUDYNAME}_genvcfgz_${VARIANT}_excl_${EXCLUSION_TYPE}.log
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
			#gzip -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log			
		else
			echo "*** ERROR *** Nominal fastQTL analysis failed for ${VARIANT}."
			echo "* nominal analysis: failed" >> ${SUMMARY}/analysis.check.txt
			echo "* error message: " >> ${SUMMARY}/analysis.check.txt
			cat ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.log | grep "ERROR" >> ${SUMMARY}/analysis.check.txt
		    #rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}.*
		    #rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlnom_${VARIANT}_excl_${EXCLUSION_TYPE}_NOM.*
		    echo "${VARIANT} ${LOCUS} ${CHR} ${BP} ${START} ${END} ${WINDOWSIZE} ${TYPE} ${PHENOTYPE}" >> ${SUMMARY}/regions_for_qtl.failedNom.temp.txt
		fi
		
		echo ""
		echo "* Checking permutation fastQTL analysis..."
		if [[ -n $(grep "Running time" ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log) ]]; then
			echo "Permutation fastQTL analysis successfully completed for ${VARIANT}."
			echo "* permutation analysis: success" >> ${SUMMARY}/analysis.check.txt
			rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.errors
			rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.output
			rm -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}_PERMUTE.sh
			#gzip -v ${REGIONALDIR}/${STUDYNAME}_QC_qtlperm_${VARIANT}_excl_${EXCLUSION_TYPE}.log			
		else
			echo "*** ERROR *** Permutation fastQTL analysis failed for ${VARIANT}."
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
	perl ${SOFTWARE}/removedupesv2 ${SUMMARY}/regions_for_qtl.failedQTLs.temp.txt NORM ${SUMMARY}/regions_for_qtl.failedQTLs.txt
	perl ${SOFTWARE}/removedupesv2 ${SUMMARY}/regions_for_qtl.failedNom.temp.txt NORM ${SUMMARY}/regions_for_qtl.failedNom.txt
	perl ${SOFTWARE}/removedupesv2 ${SUMMARY}/regions_for_qtl.failedPerm.temp.txt NORM ${SUMMARY}/regions_for_qtl.failedPerm.txt
	
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
