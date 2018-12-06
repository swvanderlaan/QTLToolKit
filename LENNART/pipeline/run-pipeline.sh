#!/usr/bin/bash
set -eu

source config.sh

setup () {
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
    NLINES=$(wc -l $REGIONSFILE | awk '$0=$1')
    J=-$CONFIG_JOBNAME
}

DRY=true
if [ $# -gt 0 ]; then
    if [ "$1" == "--no-dry-run" ]; then
        DRY=false
    fi
fi

sub () {
    if $DRY; then
        echo qsub "$@"
    else
        qsub $(echo "$@" | sed 's/%//g')
    fi
}

[ -d "$CONFIG_JOBDIR" ] && echo "WARNING job directory $CONFIG_JOBDIR already exists"

setup

main () {
    sub %            %            -N make-besd$J    -t 1-$NLINES -cwd job-files/make-besd.job    $CONFIG_JOBDIR/config.sh
    sub -hold_jid_ad make-besd$J  -N run-smr$J      -t 1-$NLINES -cwd job-files/run-smr.job      $CONFIG_JOBDIR/config.sh
    sub -hold_jid    make-besd$J  -N combine-besd$J %  %         -cwd job-files/combine-besd.job $CONFIG_JOBDIR/config.sh
    sub -hold_jid    run-smr$J    -N combine-smr$J  %  %         -cwd job-files/combine-smr.job  $CONFIG_JOBDIR/config.sh
}

if $DRY; then
    echo 'this is dry run, no actual jobs are submitted, use --no-dry-run to qsub'
    echo ' === QSUB ARGUMENTS ==='
    main | column -t
else
    setup
    main
fi

echo ' === OUTPUT FILES ==='
echo ${CONFIG_JOBDIR}/smr.out
echo ${CONFIG_JOBDIR}/besd/dense

echo ' === QSTAT ==='

qstat
