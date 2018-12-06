#!/usr/bin/bash
set -xeu

source config.sh

mkdir -p ${CONFIG_JOBDIR}/besd
cp config.sh $CONFIG_JOBDIR/config.sh

cat $REGIONSFILE | awk \
    -v genetic="$GENETIC_ROOT" \
    -v pre="$GENETIC_PRE" \
    -v eqtl="$EQTL_ROOT" \
    -v jobdir="$CONFIG_JOBDIR" \
    -v post="$EQTL_POST" \
    '{
        chr = $3;
        variant = $1;
        gen = genetic "/" pre chr;
        eqtl_file = eqtl "/" variant post "/ctmm_QC_qtlperm_" variant "_excl_EXCL_DEFAULT.txt.gz";
        besd_output = jobdir "/besd/" variant
        print variant, gen, eqtl_file, besd_output
    }' > ${CONFIG_JOBDIR}/make-besd.param

NLINES=$(wc -l job/make-besd.param | awk '$0=$1')
J=-$CONFIG_JOBNAME

qsub                          -N make-besd$J   -t 1-$NLINES -cwd job-files/make-besd.job    $CONFIG_JOBDIR/config.sh
qsub -hold_jid_ad make-besd$J -N run-smr$J     -t 1-$NLINES -cwd job-files/run-smr.job      $CONFIG_JOBDIR/config.sh
qsub -hold_jid    make-besd$J -N combine-besd$J             -cwd job-files/combine-besd.job $CONFIG_JOBDIR/config.sh
qsub -hold_jid    run-smr$J   -N combine-smr$J              -cwd job-files/combine-smr.job  $CONFIG_JOBDIR/config.sh

echo ' === OUTPUT FILES === '
echo ${CONFIG_JOBDIR}/smr.out
echo ${CONFIG_JOBDIR}/besd/dense
echo ' === OUTPUT FILES === '

qstat
