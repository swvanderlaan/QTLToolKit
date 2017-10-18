#!/bin/bash
#
# You can use the variables below (indicated by "#$") to set some things for the 
# submission system.
# -S /bin/bash # the type of BASH you'd like to use
# -N fastQTLPlotter_v1 # the name of this script
# -hold_jid some_other_basic_bash_script # the current script (basic_bash_script) will hold until some_other_basic_bash_script has finished
# -o /hpc/dhl_ec/svanderlaan/projects/test_mqtl/fastQTLPlotter_v1.log # the log file of this job
# -e /hpc/dhl_ec/svanderlaan/projects/test_mqtl/fastQTLPlotter_v1.errors # the error file of this job
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
	echo " * Argument #1  indicate which study type you want to analyze, so either:"
	echo "                [AEMS450K1/AEMS450K2/CTMM]:"
	echo "                - AEMS450K1: methylation quantitative trait locus (mQTL) analysis "
	echo "                             on plaques or blood in the Athero-Express Methylation "
	echo "                             Study 450K phase 1."
	echo "                - AEMS450K2: mQTL analysis on plaques or blood in the Athero-Express"
	echo "                             Methylation Study 450K phase 2."
	echo "                - CTMM:      expression QTL (eQTL) analysis in monocytes from CTMM."
	echo " * Argument #2  the sample type must be [AEMS450K1: PLAQUES/BLOOD], "
	echo "                [AEMS450K2: PLAQUES], or [CTMM: MONOCYTES]."
	echo " * Argument #3  file containing the regions of interest."
	echo " * Argument #4  summary directory to put all summarized files in."
	echo " * Argument #5  project name, e.g. 'CAD'."
	echo ""
	echo " An example command would be: "
	echo "./fastQTLSummarizer.sh [arg1] [arg2] [arg3] [arg4] [arg5]"
	echo ""
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  	# The wrong arguments are passed, so we'll exit the script now!
  	script_copyright_message
  	exit 1
}

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+                                      QUANTITATIVE TRAIT LOCUS PLOTTER                                 +"
echo "+                                                                                                       +"
echo "+                                                                                                       +"
echo "+ * Written by  : Sander W. van der Laan                                                                +"
echo "+ * E-mail      : s.w.vanderlaan-2@umcutrecht.nl                                                        +"
echo "+ * Updated by  : Jacco Schaap                                                                          +"
echo "+ * E-mail      : j.schaap-2@umcutrecht.nl                                                              +"
echo "+ * Last update : 2017-17-06                                                                            +"
echo "+ * Version     : 1.0.1                                                                                 +"
echo "+                                                                                                       +"
echo "+ * Description : This script will set some directories, execute something in a for-loop, and will then +"
echo "+                 submit this in a job.                                                                 +"
echo "+                                                                                                       +"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Today's date and time: "$(date)
TODAY=$(date +"%Y%m%d")
echo ""

### SET STUDY AND SAMPLE TYPE
### Note: All analyses with AE data are presumed to be constrained to CEA-patients only.
###       You can set the exclusion criteria 'NONAEGS/FEMALES/MALES' if you want to analyse
###       all AE data!
### Set the analysis type.
STUDY_TYPE=${1} # AEMS450K1/AEMS450K2/CTMM

### Set the analysis type.
SAMPLE_TYPE=${2} # AE: PLAQUES/BLOOD; CTMM: MONOCYTES

REGIONS=${3} # The file containing the regions of interest -- refer to fastQTLAnalyzer.sh for information

SUMMARY=${4} # The summary directory to put all summarized files in -- refer to fastQTLAnalyzer.sh for information

STUDYNAME=${5} # What is the study name to be used in files -- refer to fastQTLAnalyzer.sh for information

CLUMPDIR=${6} # clump directory, same place as qtl; qtl_sum and now the region_list. .clumped en ld buddie files are in this directory

CLUMP=${7} # Clumped or nominal data. Y for Clumped, N for Nominal
### START of if-else statement for the number of command-line arguments passed ###

if [[ $# -lt 5 ]]; then 
	echo "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "You must supply at least [5] arguments when plotting QTL SUMMARYs!"

else
	
	### GENERIC SETTINGS
	SOFTWARE=/hpc/local/CentOS7/dhl_ec/software
	QCTOOL=${SOFTWARE}/qctool_v1.5-linux-x86_64-static/qctool
	SNPTEST252=${SOFTWARE}/snptest_v2.5.2_CentOS6.5_x86_64_static/snptest_v2.5.2
	FASTQTL=${SOFTWARE}/fastqtl_v2.184
	FASTQCTLADDON=${SOFTWARE}/fastQTLToolKit
	FASTQTLPARSER=${FASTQCTLADDON}/NominalResultsParser.py
	LZ13=${SOFTWARE}/locuszoom_1.3/bin/locuszoom
	BGZIP=${SOFTWARE}/htslib-1.3/bgzip
	TABIX=${SOFTWARE}/htslib-1.3/tabix
	
	MFILE=/hpc/dhl_ec/jschaap/scripts/locuszoom/metal.txt
	PLINK=/hpc/local/CentOS7/dhl_ec/software/plink_v1.9
	

#
# 	###FOR DEBUGGING
# 	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
# 	echo "The following is set:"
# 	echo ""
# 	echo "Software directory                                 ${SOFTWARE}"
# 	echo "Where \"qctool\" resides                             ${QCTOOL}"
# 	echo "Where \"fastQTL\" resides                            ${FASTQTL}"
# 	echo "Where \"bgzip\" resides                              ${BGZIP}"
# 	echo "Where \"tabix\" resides                              ${TABIX}"
# 	echo "Where \"snptest 2.5.2\" resides                      ${SNPTEST252}"
# 	echo ""
# 	echo "Project directory                                  ${SUMMARY}"
# 	echo ""     
# 	echo "We will run this script on                         ${TODAY}"
# 	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#
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
	echo "Parse nominal SUMMARYs to get Hits per Locus and (mapped) Gene, and input files"
	echo "for LocusZoom v1.2+."
	echo "Data type: ${CLUMP}"

	### Jacco 17-6-17, standardize to find both nominal and permuted data instead of only nominal
	### Select the right dataset for python script
	### Nominal set
	NOM_DATA=''
	if [ ${CLUMP} = 'N' ]; then
		# Old
		#DATA=${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt.gz
		# Jacco
		NOM_DATA=${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt.gz
		echo "Nominal Data"
	fi
	### Clumped set
	if [ ${CLUMP} = 'Y' ]; then
	    # Old
		#DATA=${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz
		# Jacco
		NOM_DATA=${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz
		echo "Clumped Data"
	fi
	PERM_DATA=${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt.gz
	#echo "Datafile: ${DATA}"
	### First we will collect all the nominal association SUMMARYs.
	echo ""
	echo "Parsing nominal SUMMARYs..."
	cd ${SUMMARY}
	pwd
	module load python
	
	# Normal set, old
	#echo "python /hpc/dhl_ec/jschaap/fastQTLToolKit/NominalResultsParser.py ${DATA} ${CLUMPDIR} ${CLUMP}"
	#python /hpc/dhl_ec/jschaap/fastQTLToolKit/NominalResultsParser.py ${DATA} ${CLUMPDIR} ${CLUMP}
	echo "python /hpc/dhl_ec/jschaap/fastQTLToolKit/NominalResultsParser.py ${NOM_DATA}"
	python /hpc/dhl_ec/jschaap/fastQTLToolKit/NominalResultsParser.py ${NOM_DATA}
	
	#### Now we will start plotting per locus each gene-probe-pair.
	echo ""
	
	while IFS='' read -r REGIONOFINTEREST || [[ -n "$REGIONOFINTEREST" ]]; do
		### 1		2		3	4	5		6		7			8		9
		### Variant	Locus	Chr	BP	BP-1Mb	BP+1Mb	WindowSize	Type	Phenotype
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
		echo "        INITIALISING LOCUSZOOM PLOTTING FOR ${VARIANT} LOCUS"
		echo "===================================================================="
		echo ""
		
		### Getting only the top part of the variant-gene-probeid list
		cat ${SUMMARY}/_loci/${VARIANT}.txt | tail -n +2 > ${SUMMARY}/_loci/${VARIANT}.LZ.txt
		LOCUSHITS=${SUMMARY}/_loci/${VARIANT}.LZ.txt
		echo "These are the hits we're interested in for ${VARIANT}..."
		echo ""
		cat ${LOCUSHITS}
		
		echo ""
		while IFS='' read -r VARIANTGENEPROBE || [[ -n "$VARIANTGENEPROBE" ]]; do
			### 1		2			3		4			5
			### Locus	GeneName	ProbeID	N_Variants	N_Significant
			LINE=${VARIANTGENEPROBE}
			LOCUSVARIANT=$(echo "${LINE}" | awk '{print $1}')
			GENENAME=$(echo "${LINE}" | awk '{print $2}')
			PROBEID=$(echo "${LINE}" | awk '{print $3}')
			N_VARIANTS=$(echo "${LINE}" | awk '{print $4}')
			N_SIGNIFICANT=$(echo "${LINE}" | awk '{print $5}')
		
			echo "===================================================================="
			echo "Plotting SUMMARYs for the ${LOCUSVARIANT} locus on ${CHR}:${START}-${END}."
			echo "	* Plotting association SUMMARYs for ${GENENAME} and ${PROBEID}."
			echo "	* Total number of variants analysed: 	${N_VARIANTS}."
			echo "	* Total number of significant variants:	${N_SIGNIFICANT}."
			
			echo ""
			### FOR DEBUGGING
			### echo "Checking existence of proper input file..."
			### ls -lh ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz
			### echo ""
			### echo "Head:"
			### head ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz
			### echo ""
			### echo "Tail:"
			### tail ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz
			### echo ""
			### echo "Row count:"
			### cat ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz | wc -l
			
			### Setting up LocusZoom v1.2+ plotting
			### Some general settings
			#LOCUSZOOM_SETTINGS="refsnpTextColor='black' legendColor='black' legendBoxColor='white' legendInnerBoxColor='black' legend='auto' drawMarkerNames=TRUE ldColors=\"#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" showRecomb=TRUE ldCol='r^2' drawMarkerNames=FALSE refsnpTextSize=0.8 geneFontSize=0.6 showRug=FALSE showAnnot=FALSE showRefsnpAnnot=TRUE showGenes=TRUE clean=TRUE bigDiamond=TRUE ymax=12 rfrows=10 refsnpLineWidth=2 condLdColors=\"gray60,#E41A1C,#377EB8,#4DAF4A,#984EA3,#FF7F00,#A65628,#F781BF\" "
			
			#last used LZ settings
			#LOCUSZOOM_SETTINGS="ldColors=\"#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" legendColor=transparent legendBoxColor=transparent ldTitle=rsquare showRecomb=TRUE drawMarkerNames=FALSE refsnpTextSize=1 geneFontSize=0.7 showAnnot=FALSE showRefsnpAnnot=TRUE showRug=FALSE showGenes=TRUE clean=TRUE bigDiamond=TRUE ymax=12 rfrows=10 refsnpLineWidth=2"
			### The proper genome-build
			LDMAP="--pop EUR --build hg19 --source 1000G_March2012"
			### Directory prefix
			PREFIX="${LOCUSVARIANT}_${GENENAME}_${PROBEID}_excl_${EXCLUSION_TYPE}_"
			LOCUSZOOM_SETTINGS="ldColors=\"transparent,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" legendColor=transparent showRecomb=TRUE drawMarkerNames=FALSE refsnpTextSize=1 geneFontSize=0.7 showAnnot=FALSE showRefsnpAnnot=TRUE showRug=FALSE showGenes=TRUE clean=TRUE bigDiamond=TRUE ymax=12 rfrows=10 refsnpLineWidth=2"
			
			# old not needed data, delete later
 			#REFSNP=$(sort -t$'\t' -k2 -n ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz | tail -1 | awk ' { print $3 }')
			#echo $(sort -t$'\t' -k2 -n ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz | tail -1 | awk ' { print $2, $3 }')
			
			# find ranges to highlight with locuszoom
			HISTART=$(grep ${LOCUSVARIANT} ${CLUMPDIR}/highlight_ranges.list |  cut -d ',' -f 2)
			HIEND=$(grep ${LOCUSVARIANT} ${CLUMPDIR}/highlight_ranges.list |  cut -d ',' -f 3)
			
			### Actual plotting
			# if [ ${CLUMP} = 'N' ]; then
# 				${LZ13} --metal ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz --refsnp ${LOCUSVARIANT} --markercol MarkerName --pvalcol P-value --delim tab --chr ${CHR} --start ${START} --end ${END} ${LDMAP} ${LOCUSZOOM_SETTINGS} --prefix=${PREFIX} hiStart=${HISTART} hiEnd=${HIEND} theme=publication title="${LOCUSVARIANT} - ${GENENAME} (${PROBEID})"
# 			fi
# 			if [ ${CLUMP} = 'Y' ]; then
# 				${LZ13} --metal ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz --add-refsnp ${LOCUSVARIANT} --markercol MarkerName --pvalcol P-value --delim tab --chr ${CHR} --start ${START} --end ${END} ${LDMAP} ${LOCUSZOOM_SETTINGS} --prefix=${PREFIX} hiStart=${HISTART} hiEnd=${HIEND} theme=publication title="${LOCUSVARIANT} - ${GENENAME} (${PROBEID})"
# 			fi
			
			## For DEBUGGING old plot, handy for presentation Pasterkamp
			if [ ${LOCUSVARIANT} == 'rs1412444' ]; then
				if [ ${GENENAME} == 'LIPA' ]; then
					${LZ13} --metal ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz --add-refsnp ${LOCUSVARIANT} --markercol MarkerName --pvalcol P-value --delim tab --chr ${CHR} --start ${START} --end ${END} ${LDMAP} ${LOCUSZOOM_SETTINGS} --prefix=${PREFIX} hiStart=${HISTART} hiEnd=${HIEND} theme=publication title="${LOCUSVARIANT} - ${GENENAME} (${PROBEID})"
# 					${LZ13} --metal ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz --markercol MarkerName --pvalcol P-value --delim tab --chr ${CHR} --start ${START} --end ${END} ${LDMAP} ${LOCUSZOOM_SETTINGS} --prefix=${PREFIX} theme=publication title="${LOCUSVARIANT} - ${GENENAME} (${PROBEID})"
				fi
			fi
			#if [ ${GENENAME} == 'PDGFD' ]; then
			# 	LOCUSZOOM_SETTINGS="ldColors=\"transparent,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" legendColor=transparent legendBoxColor=transparent ldTitle=rsquare showRecomb=TRUE drawMarkerNames=FALSE refsnpTextSize=1 geneFontSize=0.7 showAnnot=FALSE showRefsnpAnnot=TRUE showRug=FALSE showGenes=TRUE clean=TRUE bigDiamond=TRUE ymax=6 rfrows=10 refsnpLineWidth=2"
			#	HISTART=103498627
			#	HIEND=103763638
			#	# Single SNP
			#	#${LZ13} --metal ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz --refsnp ${LOCUSVARIANT} --markercol MarkerName --pvalcol P-value --delim tab --chr ${CHR} --start ${START} --end ${END} ${LDMAP} ${LOCUSZOOM_SETTINGS} --prefix=${PREFIX} theme=publication hiStart=${HISTART} hiEnd=${HIEND} title="${LOCUSVARIANT} - ${GENENAME} (${PROBEID})"
			#	#two SNPS
			#	${LZ13} --metal ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz --add-refsnp ${LOCUSVARIANT} --markercol MarkerName --pvalcol P-value --delim tab --chr ${CHR} --start ${START} --end ${END} ${LDMAP} ${LOCUSZOOM_SETTINGS} --prefix=${PREFIX} hiStart=${HISTART} hiEnd=${HIEND} theme=publication title="${LOCUSVARIANT} - ${GENENAME} (${PROBEID})"	
			#fi
			
		done < ${LOCUSHITS}
		
		### rm -v ${SUMMARY}/_loci/${VARIANT}.LZ.txt
		
	done < ${REGIONS}
	
	
### END of if-else statement for the number of command-line arguments passed ###
fi

script_copyright_message


