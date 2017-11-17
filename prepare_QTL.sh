#!/bin/bash
#
# You can use the variables below (indicated by "#$") to set some things for the 
# submission system.
#$ -S /bin/bash # the type of BASH you'd like to use
#$ -N prepare_QTL_v1_1_0 # the name of this script
# -hold_jid some_other_basic_bash_script # the current script (basic_bash_script) will hold until some_other_basic_bash_script has finished
#$ -o /hpc/dhl_ec/svanderlaan/projects/prepare_QTL_v1_1_0.log # the log file of this job
#$ -e /hpc/dhl_ec/svanderlaan/projects/prepare_QTL_v1_1_0.errors # the error file of this job
#$ -l h_rt=04:00:00 # h_rt=[max time, e.g. 02:02:01] - this is the time you think the script will take
#$ -l h_vmem=16G #  h_vmem=[max. mem, e.g. 45G] - this is the amount of memory you think your script will use
# -l tmpspace=64G # this is the amount of temporary space you think your script will use
#$ -M s.w.vanderlaan-2@umcutrecht.nl # you can send yourself emails when the job is done; "-M" and "-m" go hand in hand
#$ -m ea # you can choose: b=begin of job; e=end of job; a=abort of job; s=suspended job; n=no mail is send
#$ -cwd # set the job start to the current directory - so all the things in this script are relative to the current directory!!!
#
# Another useful tip: you can set a job to run after another has finished. Name the job 
# with "-N SOMENAME" and hold the other job with -hold_jid SOMENAME". 
# Further instructions: https://wiki.bioinformatics.umcutrecht.nl/bin/view/HPC/HowToS#Run_a_job_after_your_other_jobs
#
# It is good practice to properly name and annotate your script for future reference for
# yourself and others. Trust me, you'll forget why and how you made this!!!

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "                             PREPARE DATA FOR QTL ANALYSES"
echo ""
echo ""
echo "* Written by  : Sander W. van der Laan"
echo "* E-mail      : s.w.vanderlaan-2@umcutrecht.nl"
echo "* Last update : 2017-11-17"
echo "* Version     : v1.1.0"
echo ""
echo "* Description : This script will prepare biobank data "
echo "                for use with fastQTL/QTLTool."
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Today's: "$(date)
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "The following directories are set."
SOFTWARE=/hpc/local/CentOS7/dhl_ec/software
QCTOOL=$SOFTWARE/qctool_v1.5
SNPTEST25=$SOFTWARE/snptest_v2.5.2 

AEGSORIGINALS=/hpc/dhl_ec/data/_ae_originals
AAAGSORIGINALS=/hpc/dhl_ec/data/_aaa_originals
CTMMGSORIGINALS=/hpc/dhl_ec/data/_ctmm_originals

AEGSIMPUTEDDATA=${AEGSORIGINALS}/AEGS_COMBINED_IMPUTE2_1000Gp3_GoNL5
AAAGSIMPUTEDDATA=${ORIGINALS}/AAAGS_IMPUTE2_1000Gp3_GoNL5
CTMMGSIMPUTEDDATA=${ORIGINALS}/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5

PHENOTYPESAEMS450K1=${AEGSORIGINALS}/AEMethylS_IlluminaMethylation450K/AEM_mQTL_INPUT_DATA
PHENOTYPESAEMS450K2=${AEGSORIGINALS}/AEMS450K2

MYDIR=/hpc/dhl_ec/svanderlaan
ROOTDIR=${MYDIR}/projects

### SETTINGS QSUB
QSUBTIME="08:00:00"
QSUBMEM="16G"
QSUBMAIL="s.w.vanderlaan-2@umcutrecht.nl"
QSUBMAILSETTINGS="ea"

echo "Original AEGS data directory________________  ${AEGSORIGINALS}"
echo "Original AAAGS data directory_______________  ${AAAGSORIGINALS}"
echo "Original CTMMGS data directory______________  ${CTMMGSORIGINALS}"
echo "Imputed AEGS data directory_________________  ${AEGSIMPUTEDDATA}"
echo "Imputed AAAGS data directory________________  ${AAAGSIMPUTEDDATA}"
echo "Imputed CTMMGS data directory_______________  ${CTMMGSIMPUTEDDATA}"
echo "Phenotype data directory AEMS450K1___  ${PHENOTYPESAEMS450K1}"
echo "Phenotype data directory AEMS450K2___  ${PHENOTYPESAEMS450K2}"
echo "SNPTEST directory____________________  ${SNPTEST25}"
echo "Software directory___________________  ${SOFTWARE}"
echo "Where \"qctool\" resides_____________  ${QCTOOL}"
echo ""

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Convert the phenotype files and index these..."
# echo "* AEMS450K1..."
# echo "  >>> copying data <<<"
# echo ""
# cp -v ${ROOTDIR}/mQTL/aems450k1_QC_443872_plaques.bed ${PHENOTYPESAEMS450K1}/
# cp -v ${ROOTDIR}/mQTL/aems450k1_QC_443872_blood.bed ${PHENOTYPESAEMS450K1}/
# echo ""
# echo "  >>> plaque data <<<"
# echo ""
# ${SOFTWARE}/bgzip_v1.3 ${PHENOTYPESAEMS450K1}/aems450k1_QC_443872_plaques.bed && ${SOFTWARE}/tabix_v1.3 -p bed ${PHENOTYPESAEMS450K1}/aems450k1_QC_443872_plaques.bed.gz
# echo "  --- heads ---"
# zcat ${PHENOTYPESAEMS450K1}/aems450k1_QC_443872_plaques.bed.gz | head
# echo "  --- tails ---"
# zcat ${PHENOTYPESAEMS450K1}/aems450k1_QC_443872_plaques.bed.gz | tail
# echo ""
# echo "  >>> blood data <<<"
# ${SOFTWARE}/bgzip_v1.3 ${PHENOTYPESAEMS450K1}/aems450k1_QC_443872_blood.bed && ${SOFTWARE}/tabix_v1.3 -p bed ${PHENOTYPESAEMS450K1}/aems450k1_QC_443872_blood.bed.gz
# echo "  --- heads ---"
# zcat ${PHENOTYPESAEMS450K1}/aems450k1_QC_443872_blood.bed.gz | tail
# echo "  --- tails ---"
# zcat ${PHENOTYPESAEMS450K1}/aems450k1_QC_443872_blood.bed.gz | tail
# echo ""
# echo "* AEMS450K2..."
# echo "  >>> plaque data <<<"
# ${SOFTWARE}/bgzip_v1.3 ${PHENOTYPESAEMS450K2}/aems450k2_QC_443872_plaques.bed && ${SOFTWARE}/tabix_v1.3 -p bed ${PHENOTYPESAEMS450K2}/aems450k2_QC_443872_plaques.bed.gz
# echo "  --- heads ---"
# zcat ${PHENOTYPESAEMS450K2}/aems450k2_QC_443872_plaques.bed.gz | head
# echo "  --- tails ---"
# zcat ${PHENOTYPESAEMS450K2}/aems450k2_QC_443872_plaques.bed.gz | tail
# echo ""
# echo "  >>> blood data <<<"
# ${SOFTWARE}/bgzip_v1.3 ${PHENOTYPESAEMS450K2}/aems450k2_QC_443872_blood.bed && ${SOFTWARE}/tabix_v1.3 -p bed ${PHENOTYPESAEMS450K2}/aems450k2_QC_443872_blood.bed.gz
# echo "  --- heads ---"
# zcat ${PHENOTYPESAEMS450K2}/aems450k2_QC_443872_blood.bed.gz | tail
# echo "  --- tails ---"
# zcat ${PHENOTYPESAEMS450K2}/aems450k2_QC_443872_blood.bed.gz | tail
# echo ""
# echo ""
echo "Converting to VCF...."
# echo "* AEGS..."
# for CHR in $(seq 1 22) X; do 
# 	echo "* submitting conversion job for chromosome ${CHR}..."
# 	echo "${QCTOOL} -g ${AEGSIMPUTEDDATA}/aegs_combo_1kGp3GoNL5_RAW_chr${CHR}.bgen -s ${AEGSIMPUTEDDATA}/aegs_combo_1kGp3GoNL5_RAW_chr${CHR}.sample -og ${AEGSIMPUTEDDATA}/aegs_combo_1kGp3GoNL5_RAW_chr${CHR}.vcf" > ${AEGSIMPUTEDDATA}/prep.QTL.makeVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR}.sh
# 	qsub -S /bin/bash -N prep.QTL.makeVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR} -e ${AEGSIMPUTEDDATA}/prep.QTL.makeVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR}.errors -o ${AEGSIMPUTEDDATA}/prep.QTL.makeVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR}.log -l h_rt=${QSUBTIME} -l h_vmem=${QSUBMEM} -M ${QSUBMAIL} -m ${QSUBMAILSETTINGS} -cwd ${AEGSIMPUTEDDATA}/prep.QTL.makeVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR}.sh
# 	echo ""
# done
echo "* AAAGS..."
for CHR in $(seq 1 22) X; do 
	echo "* submitting conversion job for chromosome ${CHR}..."
	echo "${QCTOOL} -g ${AAAGSIMPUTEDDATA}/aaags_1kGp3GoNL5_RAW_chr${CHR}.bgen -s ${AAAGSIMPUTEDDATA}/aaags_1kGp3GoNL5_RAW_chr${CHR}.sample -og ${AAAGSIMPUTEDDATA}/aaags_1kGp3GoNL5_RAW_chr${CHR}.vcf" > ${AAAGSIMPUTEDDATA}/prep.QTL.makeVCF.aaags_1kGp3GoNL5_RAW.chr${CHR}.sh
	qsub -S /bin/bash -N prep.QTL.makeVCF.aaags_1kGp3GoNL5_RAW.chr${CHR} -e ${AAAGSIMPUTEDDATA}/prep.QTL.makeVCF.aaags_1kGp3GoNL5_RAW.chr${CHR}.errors -o ${AAAGSIMPUTEDDATA}/prep.QTL.makeVCF.aaags_1kGp3GoNL5_RAW.chr${CHR}.log -l h_rt=${QSUBTIME} -l h_vmem=${QSUBMEM} -M ${QSUBMAIL} -m ${QSUBMAILSETTINGS} -cwd ${AAAGSIMPUTEDDATA}/prep.QTL.makeVCF.aaags_1kGp3GoNL5_RAW.chr${CHR}.sh
	echo ""
done
# echo "* CTMMGS..."
# for CHR in $(seq 1 22) X; do 
# 	echo "* submitting conversion job for chromosome ${CHR}..."
# 	echo "${QCTOOL} -g ${CTMMGSIMPUTEDDATA}/ctmm_1kGp3GoNL5_RAW_chr${CHR}.bgen -s ${CTMMGSIMPUTEDDATA}/ctmm_1kGp3GoNL5_RAW_chr${CHR}.sample -og ${CTMMGSIMPUTEDDATA}/ctmm_1kGp3GoNL5_RAW_chr${CHR}.vcf" > ${CTMMGSIMPUTEDDATA}/prep.QTL.makeVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR}.sh
# 	qsub -S /bin/bash -N prep.QTL.makeVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR} -e ${CTMMGSIMPUTEDDATA}/prep.QTL.makeVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR}.errors -o ${CTMMGSIMPUTEDDATA}/prep.QTL.makeVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR}.log -l h_rt=${QSUBTIME} -l h_vmem=${QSUBMEM} -M ${QSUBMAIL} -m ${QSUBMAILSETTINGS} -cwd ${CTMMGSIMPUTEDDATA}/prep.QTL.makeVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR}.sh
# 	echo ""
# done
echo ""
echo "Indexing VCF..."
# echo "* AEGS..."
# for CHR in $(seq 1 22) X; do 
# 	echo "* submitting indexing job for chromosome ${CHR}..."
# 	echo "${SOFTWARE}/bgzip_v1.3 ${AEGSIMPUTEDDATA}/aegs_combo_1kGp3GoNL5_RAW_chr${CHR}.vcf && ${SOFTWARE}/tabix_v1.3 -p vcf ${AEGSIMPUTEDDATA}/aegs_combo_1kGp3GoNL5_RAW_chr${CHR}.vcf.gz" > ${AEGSIMPUTEDDATA}/prep.QTL.indexVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR}.sh
# 	qsub -S /bin/bash -N prep.QTL.indexVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR} -hold_jid prep.QTL.makeVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR} -e ${AEGSIMPUTEDDATA}/prep.QTL.indexVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR}.errors -o ${AEGSIMPUTEDDATA}/prep.QTL.indexVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR}.log -l h_rt=${QSUBTIME} -l h_vmem=${QSUBMEM} -M ${QSUBMAIL} -m ${QSUBMAILSETTINGS} -cwd ${AEGSIMPUTEDDATA}/prep.QTL.indexVCF.aegs_combo_1kGp3GoNL5_RAW.chr${CHR}.sh
# 	echo ""
# done
echo "* AAAGS..."
for CHR in $(seq 1 22) X; do 
	echo "* submitting indexing job for chromosome ${CHR}..."
	echo "${SOFTWARE}/bgzip_v1.3 ${AAAGSIMPUTEDDATA}/aaags_1kGp3GoNL5_RAW_chr${CHR}.vcf && ${SOFTWARE}/tabix_v1.3 -p vcf ${AAAGSIMPUTEDDATA}/aaags_1kGp3GoNL5_RAW_chr${CHR}.vcf.gz" > ${AAAGSIMPUTEDDATA}/prep.QTL.indexVCF.aaags_1kGp3GoNL5_RAW.chr${CHR}.sh
	qsub -S /bin/bash -N prep.QTL.indexVCF.aaags_1kGp3GoNL5_RAW.chr${CHR} -hold_jid prep.QTL.makeVCF.aaags_1kGp3GoNL5_RAW.chr${CHR} -e ${AAAGSIMPUTEDDATA}/prep.QTL.indexVCF.aaags_1kGp3GoNL5_RAW.chr${CHR}.errors -o ${AAAGSIMPUTEDDATA}/prep.QTL.indexVCF.aaags_1kGp3GoNL5_RAW.chr${CHR}.log -l h_rt=${QSUBTIME} -l h_vmem=${QSUBMEM} -M ${QSUBMAIL} -m ${QSUBMAILSETTINGS} -cwd ${AAAGSIMPUTEDDATA}/prep.QTL.indexVCF.aaags_1kGp3GoNL5_RAW.chr${CHR}.sh
	echo ""
done
# echo "* CTMMGS..."
# for CHR in $(seq 1 22) X; do 
# 	echo "* submitting indexing job for chromosome ${CHR}..."
# 	echo "${SOFTWARE}/bgzip_v1.3 ${CTMMGSIMPUTEDDATA}/ctmm_1kGp3GoNL5_RAW_chr${CHR}.vcf && ${SOFTWARE}/tabix_v1.3 -p vcf ${CTMMGSIMPUTEDDATA}/ctmm_1kGp3GoNL5_RAW_chr${CHR}.vcf.gz" > ${CTMMGSIMPUTEDDATA}/prep.QTL.indexVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR}.sh
# 	qsub -S /bin/bash -N prep.QTL.indexVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR} -hold_jid prep.QTL.makeVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR} -e ${CTMMGSIMPUTEDDATA}/prep.QTL.indexVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR}.errors -o ${CTMMGSIMPUTEDDATA}/prep.QTL.indexVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR}.log -l h_rt=${QSUBTIME} -l h_vmem=${QSUBMEM} -M ${QSUBMAIL} -m ${QSUBMAILSETTINGS} -cwd ${CTMMGSIMPUTEDDATA}/prep.QTL.indexVCF.ctmm_1kGp3GoNL5_RAW.chr${CHR}.sh
# 	echo ""
# done
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Wow. I'm all done buddy. What a job! let's have a beer!"
date


