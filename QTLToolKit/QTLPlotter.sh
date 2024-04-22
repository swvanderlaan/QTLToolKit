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
	echoerror " * Argument #3  directory where clump data can be found."
	echoerror " * Argument #4  whether the data was clumped or not [Y/N]."
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
echobold "+                                      QUANTITATIVE TRAIT LOCUS PLOTTER                                 +"
echobold "+                                                                                                       +"
echobold "+                                                                                                       +"
echobold "+ * Written by  : Sander W. van der Laan; Jacco Schaap                                                  +"
echobold "+ * E-mail      : s.w.vanderlaan-2@umcutrecht.nl; jacco_schaap@hotmail.com                              +"
echobold "+ * Last update : 2018-07-29                                                                            +"
echobold "+ * Version     : 1.3.2                                                                                 +"
echobold "+                                                                                                       +"
echobold "+ * Description : This script will produce regional association plots of QTL results, using             +"
echobold "+                 LocusZoom v1.3.                                                                       +"
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
	QCTOOL=${QCTOOL}
	SNPTEST252=${SNPTEST252}
	QTLTOOLS=${QTLTOOLS}
	LOCUSZOOM=${LOCUSZOOM}
	BGZIP=${BGZIP}
	TABIX=${TABIX}
	PLINK=${PLINK}
	PYTHON=${PYTHON}
	
	STUDYNAME=${STUDYNAME} # What is the study name to be used in files -- refer to 'qtl.config' for information
	PROJECTDIR=${ROOTDIR}/${PROJECTNAME} # What is the project directory?  -- refer to 'qtl.config' for for information
	PROJECTNAME=${PROJECTNAME} # What is the projectname? E.g. 'CAD' -- refer to f'qtl.config' for for information
	SUMMARY=${2} # The summary directory to put all summarized files in -- refer to 'qtl.config' for for information
	
	REGIONS=${REGIONS_FILE} # The file containing the regions of interest -- refer to 'qtl.config' for for information
	
	EXCLUSION_TYPE=${EXCLUSION_TYPE} # The exclusion type -- refer to 'qtl.config' for for information
	
	CLUMPDIR=${3} # Directory with clump information
	
	QTL_TYPE=${QTL_TYPE} # CIS or TRANS
	
	CLUMP=${4} # Clumped or nominal data. Y for Clumped, N for Nominal

### START of if-else statement for the number of command-line arguments passed ###

if [[ $# -lt 4 ]]; then 
	echo "                                     *** Oh no! Computer says no! ***"
	echo ""
	script_arguments_error "You must supply at least [4] arguments when plotting QTL SUMMARYs!"

else
	
	###FOR DEBUGGING
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "The following is set:"
	echo ""
	echo "Software directory                                 ${SOFTWARE}"
	echo "Where \"qctool\" resides                             ${QCTOOL}"
	echo "Where \"QTLTools\" resides.                          ${QTLTOOLS}"
	echo "Where \"bgzip\" resides                              ${BGZIP}"
	echo "Where \"tabix\" resides                              ${TABIX}"
	echo "Where \"snptest \" resides                           ${SNPTEST252}"
	echo "Where \"LocusZoom 1.3\" resides                      ${LOCUSZOOM}"
	echo "Where \"PLINK\" resides                              ${PLINK}"
	echo "Where \"Python\" resides                             ${PYTHON}"
	echo ""
	echo "Project directory                                  ${PROJECTDIR}"
	echo "Summary directory                                  ${SUMMARY}"
	echo "Clump directory                                    ${CLUMPDIR}"
	echo "Regions of interest file                           ${REGIONS}"
	echo "Exclusion type                                     ${EXCLUSION_TYPE}"
	echo "QTL-type                                           ${QTL_TYPE}"
	echo "Did we apply clumping?                             ${CLUMP}"
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
	echo "Parse nominal SUMMARYs to get Hits per Locus and (mapped) Gene, and input files for LocusZoom v1.2+."
	echo ""

	### Jacco 17-6-17, standardize to find both nominal and permuted data instead of only nominal
	### Select the right dataset for python script
	### Nominal set
	NOM_DATA=''
	if [ ${CLUMP} = 'N' ]; then
		NOM_DATA=${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt.gz
		echo "We are not using clumped nominal data."
	fi
	### Clumped set
	if [ ${CLUMP} = 'Y' ]; then
		NOM_DATA=${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz
		echo "We are using clumped nominal data."
	fi

	### First we will collect all the nominal association SUMMARYs.
	echo ""
	echo "Parsing nominal SUMMARYs..."
	cd ${SUMMARY}
	echo ""
	
	# Normal set, old
	### FOR DEBUG
	### echo "${PYTHON} ${QTLTOOLKIT}/NominalResultsParser.py ${NOM_DATA}"
	${PYTHON} ${QTLTOOLKIT}/NominalResultsParser.py ${NOM_DATA}
	
	#### Now we will start plotting per locus each gene-probe-pair.
	echo ""
	
	# When not clumping
	if [ ${CLUMP} = 'N' ]; then
	
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
		
			echo "============================================================================="
			echo "            INITIALISING LOCUSZOOM PLOTTING FOR ${VARIANT} LOCUS"
			echo "============================================================================="
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
		
				echo "============================================================================="
				echo "Plotting SUMMARYs for the ${LOCUSVARIANT} locus on ${CHR}:${START}-${END}."
				echo "	* Plotting association SUMMARYs for ${GENENAME} and ${PROBEID}."
				echo "	* Total number of variants analysed: 	[ ${N_VARIANTS} ]."
				echo "	* Total number of significant variants:	[ ${N_SIGNIFICANT} ]."
			
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
				### LOCUSZOOM_SETTINGS="refsnpTextColor='black' legendColor='black' legendBoxColor='white' legendInnerBoxColor='black' legend='auto' drawMarkerNames=TRUE ldColors=\"#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" showRecomb=TRUE ldCol='r^2' drawMarkerNames=FALSE refsnpTextSize=0.8 geneFontSize=0.6 showRug=FALSE showAnnot=FALSE showRefsnpAnnot=TRUE showGenes=TRUE clean=TRUE bigDiamond=TRUE ymax=12 rfrows=10 refsnpLineWidth=2 condLdColors=\"gray60,#E41A1C,#377EB8,#4DAF4A,#984EA3,#FF7F00,#A65628,#F781BF\" "
			
				### Setting up LocusZoom v1.3+ plotting
				### Some general settings
				LOCUSZOOM_SETTINGS=${LOCUSZOOM_SETTINGS}
				# LOCUSZOOM_SETTINGS="ldColors=\"#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" showRecomb=TRUE drawMarkerNames=FALSE showRug=FALSE showAnnot=TRUE showRefsnpAnnot=TRUE showGenes=TRUE clean=TRUE bigDiamond=TRUE rfrows=10 refsnpLineWidth=2 refsnpTextSize=1.0 axisSize=1.25 axisTextSize=1.25 geneFontSize=1.25"
				echo "*** DEBUGGING ***"
 				echo $LOCUSZOOM_SETTINGS
 				
				### The proper genome-build
				LDMAP="--pop ${LDPOP} --build ${LDBUILD} --source ${LDSOURCE}"
 				echo "*** DEBUGGING ***"
 				echo $LDMAP
 				
				### Directory prefix
				PREFIX="${LOCUSVARIANT}_${GENENAME}_${PROBEID}_excl_${EXCLUSION_TYPE}"
			
				# find ranges to highlight with locuszoom
				HISTART=$(grep ${LOCUSVARIANT} ${CLUMPDIR}/highlight_ranges_${LOCUSVARIANT}.list |  cut -d ',' -f 2)
				HIEND=$(grep ${LOCUSVARIANT} ${CLUMPDIR}/highlight_ranges_${LOCUSVARIANT}.list |  cut -d ',' -f 3)
			
				### Actual plotting
				${LOCUSZOOM} --metal ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz --refsnp ${LOCUSVARIANT} --markercol ${LZMARKERNAME} --pvalcol ${LZPVALUE} --delim ${LZDELIMITER} --chr ${CHR} --start ${START} --end ${END} ${LDMAP} ${LOCUSZOOM_SETTINGS} --prefix=${PREFIX} hiStart=${HISTART} hiEnd=${HIEND} theme=${LZTHEME} title="${LOCUSVARIANT} - ${GENENAME} (${PROBEID})"
			
			done < ${LOCUSHITS}

		### Should we gzip this shizzle?
		gzip -fv ${SUMMARY}/_loci/${VARIANT}.LZ.txt
		
		done < ${REGIONS}

	fi
		
	# When clumping
	if [ ${CLUMP} = 'Y' ]; then
		PERMUTEDHITS=${SUMMARY}/${STUDYNAME}_qtl_perm_tophits.csv
		### head of perm_tophits.csv
		### 1 lead_SNP, 2 e_SNP, 3 chr_tag_snp, 4 pos_tag_snp, 5 e_Gene, 6 probe,
		### 7 nom_p_value, 8 perm_p_value, 9 approx_perm_p_value, 10 rsquared, 11 FDR
		### rs9970807,rs56170783,1,57016131,C8B,ILMN_1731293,0.00304069,0.004995,0.00191528,0.977,0.01340696
		### rs7528419,rs7528419,1,109817192,PSRC1,ILMN_2315964,3.6016e-17,0.000999001,1.48056e-20,1,1.1252256e-18
		### rs7528419,rs7528419,1,109817192,PSRC1,ILMN_1671843,6.73537e-14,0.000999001,6.65731e-17,1,2.5297778e-15
		
		cat ${PERMUTEDHITS} | awk -F "," '{ print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11 }' | tail -n +2 > ${SUMMARY}/${STUDYNAME}_qtl_perm_tophits.parsed.txt
		PERMUTEDHITSPARSED=${SUMMARY}/${STUDYNAME}_qtl_perm_tophits.parsed.txt
		
		echo ""
		while IFS='' read -r VARIANTGENEPROBE || [[ -n "$VARIANTGENEPROBE" ]]; do
			### 1		2			3		4			5
			### Locus	GeneName	ProbeID	N_Variants	N_Significant
			LINE=${VARIANTGENEPROBE}
			LOCUSVARIANT=$(echo "${LINE}" | awk '{print $1}')
			TAGVARIANT=$(echo "${LINE}" | awk '{print $1}')
			GENENAME=$(echo "${LINE}" | awk '{print $5}')
			PROBEID=$(echo "${LINE}" | awk '{print $6}')
			PERMPVALUE=$(echo "${LINE}" | awk '{print $9}')
			RSQUARED=$(echo "${LINE}" | awk '{print $10}')
			FDR=$(echo "${LINE}" | awk '{print $11}')

			VARIANT=$(cat ${REGIONS} | awk ' $1 == "'$LOCUSVARIANT'" ' | awk ' { print $1 } ')
			CHR=$(cat ${REGIONS} | awk ' $1 == "'$LOCUSVARIANT'" ' | awk ' { print $3 } ')
			BP=$(cat ${REGIONS} | awk ' $1 == "'$LOCUSVARIANT'" ' | awk ' { print $4 } ')
			START=$(cat ${REGIONS} | awk ' $1 == "'$LOCUSVARIANT'" ' | awk ' { print $5 } ')
			END=$(cat ${REGIONS} | awk ' $1 == "'$LOCUSVARIANT'" ' | awk ' { print $6 } ')
			
			echo "============================================================================="
			echo "   INITIALISING LOCUSZOOM PLOTTING FOR ${VARIANT} LOCUS -- AFTER CLUMPING"
			echo "============================================================================="
			echo "Plotting SUMMARYs for the ${LOCUSVARIANT} locus on ${CHR}:${START}-${END}."
			echo "	* Plotting association SUMMARYs for ${GENENAME} and ${PROBEID}."
			echo "	* The ${TAGVARIANT} tags ${LOCUSVARIANT} with r^2 = ${RSQUARED}, and permuted p-value = ${PERMPVALUE} (FDR: ${FDR})."
			echo "    Note: the tagging variant can be the same as the index-variant!"
		
			echo ""
			### Setting up LocusZoom v1.2+ plotting
			### Some general settings
			### LOCUSZOOM_SETTINGS="refsnpTextColor='black' legendColor='black' legendBoxColor='white' legendInnerBoxColor='black' legend='auto' drawMarkerNames=TRUE ldColors=\"#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" showRecomb=TRUE ldCol='r^2' drawMarkerNames=FALSE refsnpTextSize=0.8 geneFontSize=0.6 showRug=FALSE showAnnot=FALSE showRefsnpAnnot=TRUE showGenes=TRUE clean=TRUE bigDiamond=TRUE ymax=12 rfrows=10 refsnpLineWidth=2 condLdColors=\"gray60,#E41A1C,#377EB8,#4DAF4A,#984EA3,#FF7F00,#A65628,#F781BF\" "
		
			### Setting up LocusZoom v1.3+ plotting
			### Some general settings
			LOCUSZOOM_SETTINGS=${LOCUSZOOM_SETTINGS}
			# LOCUSZOOM_SETTINGS="ldColors=\"#595A5C,#4C81BF,#1396D8,#C5D220,#F59D10,red,#9A3480\" showRecomb=TRUE drawMarkerNames=FALSE showRug=FALSE showAnnot=TRUE showRefsnpAnnot=TRUE showGenes=TRUE clean=TRUE bigDiamond=TRUE rfrows=10 refsnpLineWidth=2 refsnpTextSize=1.0 axisSize=1.25 axisTextSize=1.25 geneFontSize=1.25"
			echo "*** DEBUGGING ***"
 			echo $LOCUSZOOM_SETTINGS
 			
			### The proper genome-build
			LDMAP="--pop ${LDPOP} --build ${LDBUILD} --source ${LDSOURCE}"
 			echo "*** DEBUGGING ***"
 			echo $LDMAP
		
			### Directory prefix
			PREFIX="${LOCUSVARIANT}_${GENENAME}_${PROBEID}_excl_${EXCLUSION_TYPE}"
		
			# find ranges to highlight with locuszoom
			HISTART=$(grep ${LOCUSVARIANT} ${CLUMPDIR}/highlight_ranges_${LOCUSVARIANT}.list |  cut -d ',' -f 2)
			HIEND=$(grep ${LOCUSVARIANT} ${CLUMPDIR}/highlight_ranges_${LOCUSVARIANT}.list |  cut -d ',' -f 3)
		
			### Actual plotting
			${LOCUSZOOM} --metal ${SUMMARY}/_probes/${LOCUSVARIANT}_${GENENAME}_${PROBEID}.lz --add-refsnp ${TAGVARIANT} --markercol ${LZMARKERNAME} --pvalcol ${LZPVALUE} --delim ${LZDELIMITER} --chr ${CHR} --start ${START} --end ${END} ${LDMAP} ${LOCUSZOOM_SETTINGS} --prefix=${PREFIX} hiStart=${HISTART} hiEnd=${HIEND} theme=${LZTHEME} title="${LOCUSVARIANT} tagged by ${TAGVARIANT} - ${GENENAME} (${PROBEID})"
			
		done < ${PERMUTEDHITSPARSED}
		
		### Should we gzip this shizzle?
		gzip -fv ${SUMMARY}/_loci/${VARIANT}.LZ.txt
	
	fi 
	
	
### END of if-else statement for the number of command-line arguments passed ###
fi

script_copyright_message


