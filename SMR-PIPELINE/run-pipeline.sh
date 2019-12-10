#!/usr/bin/env bash
set -eu

DRY=true
SIMPLE_TEST=false
NLINES=all
EXISTS_OK=false
COMBINE_BESD=false
HELP=false
CONFIG=config.sh
IGNORE_VERSIONS=false

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -n|--no-dry-run)
            DRY=false
            shift
            ;;
        --ignore-versions)
            IGNORE_VERSIONS=true
            shift
            ;;
        -l|--limit)
            NLINES="$2"
            shift
            shift
            ;;
        -y|--exists-ok)
            EXISTS_OK=true
            shift
            ;;
        --combine-besd)
            COMBINE_BESD=true
            shift
            ;;
        -h|--help)
            HELP=true
            shift
            ;;
        -c|--config)
            CONFIG="$2"
            shift
            shift
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

usage () {
    echo "usage: $0 [OPTIONS]

OPTIONS:
 -n --no-dry-run        submit jobs
 -l --limit <NLINES>    limit regions/chrs to first NLINES (to test configuration)
 -y --exists-ok         do not fail if job directory exists
 --combine-besd         enable the combine-besd job
 -h --help              show this help
 -c --config <SCRIPT>   use this configuration script
 --ignore-versions      do not fail on version mismatch
"
}

if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
    echo "Unknown arguments: ${POSITIONAL[@]}"
    usage
    exit 1
fi

if $HELP; then
    usage
    exit 0
fi

source $CONFIG

setup () {
    mkdir -p ${CONFIG_JOBDIR}/besd ${CONFIG_JOBDIR}/plot
    mkdir -p ${CONFIG_JOBDIR}/logs ${CONFIG_JOBDIR}/smr
    cp $CONFIG $CONFIG_JOBDIR/config.sh
    if $GW; then
        for chr in $(seq 1 22) X;
        do
            GW_QTL_CHR=${GW_QTL/'?'/$chr}
            GW_GEN_CHR=${GW_GEN/'?'/$chr}
            if ! [ -f $GW_QTL_CHR ];then
                echo "not found: $GW_QTL_CHR"
                exit 1
            fi
            if ! [ -f ${GW_GEN_CHR}.fam ]; then
                echo "not found: $GW_GEN_CHR"
                exit 1
            fi
            echo GW_$chr $GW_GEN_CHR $GW_QTL_CHR ${CONFIG_JOBDIR}/besd/$chr
        done > ${CONFIG_JOBDIR}/make-besd.param
    else
        cat $REGIONSFILE | awk \
            -v genetic="$GENETIC_ROOT" \
            -v pre="$GENETIC_PRE" \
            -v eqtl="$EQTL_ROOT" \
            -v jobdir="$CONFIG_JOBDIR" \
            -v qtltype="$CONFIG_QTL_TYPE" \
            -v post="$EQTL_POST" \
            '{
                chr = $3;
                variant = $1;
                gen = genetic "/" pre chr;
                if (qtltype == "nom") {
                    eqtl_file = eqtl "/" variant post "/ctmm_QC_qtlnom_" variant "_excl_EXCL_DEFAULT.txt.gz";
                } else {
                    eqtl_file = eqtl "/" variant post "/ctmm_QC_qtlperm_" variant "_excl_EXCL_DEFAULT.txt.gz";
                }
                besd_output = jobdir "/besd/" variant
                print variant, gen, eqtl_file, besd_output
            }' > ${CONFIG_JOBDIR}/make-besd.param
    fi
}

if [ "$NLINES" = "all" ]; then
    if $GW; then
        NLINES=23
    else
        NLINES=$(wc -l $REGIONSFILE | awk '$0=$1')
    fi
fi

J=-$CONFIG_JOBNAME
LOGNAME_BASE="${CONFIG_JOBDIR}/logs"/'$JOB_NAME.$TASK_ID'

if [ $# -gt 0 ]; then
    if [ "$1" == "--no-dry-run" ]; then
        DRY=false
    fi
fi

version_check () {
    if grep --version | grep -q GNU; then
        SMR_MAJ=$($CONFIG_SMR | grep -oP 'version \K[0-9]')
        SMR_MIN=$($CONFIG_SMR | grep -oP 'version [0-9]+\.\K[0-9]+')
        if [ "$SMR_MAJ" -eq 0 -a "$SMR_MIN" -lt 712 ]; then
            echo "VERSION ERROR: SMR version 7.12 is required for QTLtools import"
            $IGNORE_VERSIONS || exit 1
        fi
        PYTHON_MAJ=$(python --version 2>&1 | grep -oP 'Python \K[0-9]')
        if [ "$PYTHON_MAJ" -ne 2 ]; then
            echo "The python command should refer to python version 2"
            $IGNORE_VERSIONS || exit 1
        fi
    else
        echo "Version check depends on GNU grep -P extension"
        echo "Pass --ignore-versions to skip"
        $IGNORE_VERSIONS || exit 1
    fi
}

sub () {
    if $DRY; then
        echo qsub "$@"
    else
        qsub -e $LOGNAME_BASE".err" -o $LOGNAME_BASE".out" $(echo "$@" | sed 's/%/ /g')
    fi
}

if [ -d "$CONFIG_JOBDIR" ]; then
    echo "WARNING job directory $CONFIG_JOBDIR already exists"
    if ! $EXISTS_OK; then
        echo "Pass -y/--exists-ok to ignore"
        $DRY || exit 1
    fi
fi


main () {
    extra_opts_gw=""
    if $GW; then
        extra_opts_gw="-pe%threaded%6"
    fi
    sub %            %             -N make-besd$J      -t 1-$NLINES -cwd % \
        job-files/make-besd.job                   $CONFIG_JOBDIR/config.sh
    sub -hold_jid_ad make-besd$J   -N run-smr$J        -t 1-$NLINES -cwd $extra_opts_gw \
        job-files/run-smr.job      $CONFIG_JOBDIR/config.sh
    $COMBINE_BESD && \
    sub -hold_jid    make-besd$J   -N combine-besd$J   %  %         -cwd % \
        job-files/combine-besd.job                $CONFIG_JOBDIR/config.sh
    sub -hold_jid    run-smr$J     -N combine-smr$J    %  %         -cwd % \
        job-files/combine-smr.job                 $CONFIG_JOBDIR/config.sh
    sub -hold_jid    combine-smr$J -N make-make-plot$J %  %         -cwd % \
        job-files/make-job-for-plot.job           $CONFIG_JOBDIR/config.sh
}

if $DRY; then
    echo 'WARNING this is dry run, no actual jobs are submitted'
    echo 'use -n/--no-dry-run to qsub or see help -h/--help'
    echo ' === QSUB ARGUMENTS ==='
    main | column -t | sed 's/%/ /g'
    version_check
else
    version_check
    setup
    main
fi

echo ' === OUTPUT FILES ==='
                 echo ${CONFIG_JOBDIR}/smr.out
$COMBINE_BESD && echo ${CONFIG_JOBDIR}/besd/dense
                 echo ${CONFIG_JOBDIR}/pdf/'{VARIANT}.{GENE}.{PROBE}.pdf'
                 echo ${CONFIG_JOBDIR}/plot/
                 echo ${LOGNAME_BASE}.out
                 echo ${LOGNAME_BASE}.err

echo ' === QSTAT ==='

qstat
