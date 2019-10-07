# this config file is copied into the job directory on job submission
# it is safe to modify it during a pipeline run

# ORIGINALS="/hpc/dhl_ec/data/_ctmm_originals"
# GENETICDATA="${ORIGINALS}/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5"
# PROJECTNAME="cardiogramplusc4d_88loci_4real_complete_with_4pcs"
# SNPTESTDATA="ctmm_1kGp3GoNL5_RAW_chr"
# STUDYNAME=ctmm
# ROOTDIR="/hpc/dhl_ec/svanderlaan/projects/ctmm/ctmm_eqtl"
# PROJECTDIR=${ROOTDIR}/${PROJECTNAME}

CONFIG_SOFTWARE="/hpc/local/CentOS7/dhl_ec/software"
CONFIG_PLINK=${CONFIG_SOFTWARE}/plink_v1.9
CONFIG_SMR=${CONFIG_SOFTWARE}/smr_v0712/smr_Linux
CONFIG_R=${CONFIG_SOFTWARE}/R_v340
CONFIG_R=/hpc/local/CentOS7/dhl_ec/software/R-3.4.0/bin/Rscript

CONFIG_GWAS=./input/bb.cojo
CONFIG_JOBNAME=88-re-job
CONFIG_JOBDIR=$CONFIG_JOBNAME
CONFIG_QTL_TYPE=nom

# What was qtl type? nom or perm
# Genome wide? false or true
# When genome wide, EQTL_ROOT, 
GW=false
# ? is replaced with chromosome number (1,2..X)
GW_QTL='/hpc/dhl_ec/svanderlaan/projects/ctmm/ctmm_eqtl/gw_ctmm/ctmm_1kGp3GoNL5_QC_chr?.nominals.txt.gz'
GW_GEN='/hpc/dhl_ec/data/_ctmm_originals/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5/ctmm_1kGp3GoNL5_RAW_chr?'

# Next 5 variables are used if GW=false
# PLINK bfiles are expected to reside in $GENETIC_ROOT/$GENETIC_PRE${CHR}
GENETIC_ROOT=/hpc/dhl_ec/data/_ctmm_originals/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5
GENETIC_PRE=ctmm_1kGp3GoNL5_RAW_chr
EQTL_ROOT=/hpc/dhl_ec/svanderlaan/projects/ctmm/ctmm_eqtl/cardiogramplusc4d_88loci_4real_complete_with_4pcs/EXCL_DEFAULT_qtl
EQTL_POST=_cardiogramplusc4d_88loci_4real_complete_with_4pcs
REGIONSFILE=input/variants_for_eqtl.164loci.txt
REGIONSFILE=input/variants_for_eqtl.88loci.txt
