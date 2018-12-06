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

CONFIG_GWAS=./input/realgwas.cojo
CONFIG_JOBNAME=job4
CONFIG_JOBDIR=$CONFIG_JOBNAME

GENETIC_ROOT=/hpc/dhl_ec/data/_ctmm_originals/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5
GENETIC_PRE=ctmm_1kGp3GoNL5_RAW_chr
EQTL_ROOT=/hpc/dhl_ec/svanderlaan/projects/ctmm/ctmm_eqtl/cardiogramplusc4d_88loci_4real_complete_with_4pcs/EXCL_DEFAULT_qtl
EQTL_POST=_cardiogramplusc4d_88loci_4real_complete_with_4pcs
REGIONSFILE=input/variants_for_eqtl.88loci.txt
