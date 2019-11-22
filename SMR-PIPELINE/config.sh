# SMR PIPELINE CONFIGURATION FILE
#
# Edit this file in the repository, and then start the pipeline by
# running ./run-pipeline.sh in the same directory with various flags.
# or pass ./run-pipeline.sh -c <other-config.sh> after copying this
# file.
# 
# By default, ./run-pipeline.sh tries to cause as little damage as
# possible. ./run-pipeline.sh --no-dry-run is needed to actually
# submit the jobs. By default only a list of qsub commands to be
# executed is shown. It is recommended that after some changes to
# this file, the configuration is first tested by passing the
# `-l <n>` flag to limit the amount of array jobs scheduled.
# Its not needed to edit the regions file for this.

# This config file is copied into the job directory on job submission
# it is safe to modify directly after starting the pipeline to
# kick of a second pipeline run. Use of relative paths is also safe,
# as the jobs either execute in the current working directory, or
# turn relative paths into absolute paths prior to changing directories.

# Location of various binaries. The run-pipeline script
# performs some version testing but this can be disabled
# with a flag.
CONFIG_SOFTWARE="/hpc/local/CentOS7/dhl_ec/software"
CONFIG_PLINK=${CONFIG_SOFTWARE}/plink_v1.9
CONFIG_SMR=${CONFIG_SOFTWARE}/smr_v0712/smr_Linux
CONFIG_R=${CONFIG_SOFTWARE}/R-3.4.0/bin/Rscript

# It is recommended to keep the next 3 variables as is.
# It defined the location of the illumina humanv4 probe
# database, used for annotation of probes with gene names.
# Annotation will be skipped # if empty or nonexistant.
# The other two are used by SMR to generate plots.
CONFIG_PROBEDB=data-files/illuminaHumanv4.sqlite
CONFIG_SMR_GENE_LIST=data-files/glist-hg19
CONFIG_SMR_PLOT=data-files/plot_SMR.r

# The GWAS, in SMR COJO format. Use the script gwas2cojo.py
# to convert an arbitrary GWAS file to the COJO format,
# to make sure the effect/other alleles and beta value are in line with
# the genetic data and to remove ambigiuous ambivalent alleles
CONFIG_GWAS=/hpc/dhl_ec/llandsmeer/_ctmm/input/ukbb.cojo
CONFIG_JOBNAME=redo-164-nom-job
CONFIG_JOBDIR=/hpc/dhl_ec/llandsmeer/_ctmm/$CONFIG_JOBNAME

# Which QTL data to read from the QTLToolKit output?
# 'nom' for nominally tested, or 'perm' for permutation tested
CONFIG_QTL_TYPE=nom

# Location of the genetic data. The PLINK bfiles are expected to
# reside in $GENETIC_ROOT/$GENETIC_PRE${CHR}
GENETIC_ROOT=/hpc/dhl_ec/data/_ctmm_originals/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5
GENETIC_PRE=ctmm_1kGp3GoNL5_RAW_chr

# Next, this analysis can be performed in 'genome wide' mode
# or in region based mode. For genome wide, the full chromosomes
# are used as regions, for region based mode the regions listed
# in the REGIONSFILE are used
# Genome wide? false or true
GW=false

# For genome wide mode (GW=true), the QTL data location is specified in
# GW_QTL and GW_GEN. In the paths, the ? mark is replaced
# by chromosome numbers (1,2..X)
GW_QTL='/hpc/dhl_ec/svanderlaan/projects/ctmm/ctmm_eqtl/gw_ctmm/ctmm_1kGp3GoNL5_QC_chr?.nominals.txt.gz'
GW_GEN='/hpc/dhl_ec/data/_ctmm_originals/CTMMAxiomTX_IMPUTE2_1000Gp3_GoNL5/ctmm_1kGp3GoNL5_RAW_chr?'

# For region-based analysis (GW=false), the QTL location is specified
# with EQTL_ROOT and EQTL_POST. The QTL data will then be found at the
# following path for each region. This follows exactly the output of
# QTLToolKit.
# Path: ${EQTL_ROOT}/${REGION}${EQTL_POST}/ctmm_QC_qtl${CONFIG_QTL_TYPE}_${REGION}_excl_EXCL_DEFAULT.txt.gz
EQTL_ROOT=/hpc/dhl_ec/llandsmeer/_ctmm/eqtl/cardiogramplusc4d_164loci_4real_complete_with_4pcs/EXCL_DEFAULT_qtl
EQTL_POST=_cardiogramplusc4d_164loci_4real_complete_with_4pcs
# EQTL_ROOT=/hpc/dhl_ec/svanderlaan/projects/ctmm/ctmm_eqtl/cardiogramplusc4d_88loci_4real_complete_with_4pcs/EXCL_DEFAULT_qtl
# EQTL_POST=_cardiogramplusc4d_88loci_4real_complete_with_4pcs

# For region-based analysis, REGIONSFILE determines, the position
# of the regions file. It is the exact same file as used by QTLToolKit
REGIONSFILE=/hpc/dhl_ec/llandsmeer/_ctmm/input/variants_for_eqtl.164loci.txt
