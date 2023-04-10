#!/bin/bash


EMPTY_OUTPUT_ERROR="No CNV regions in result object"

ip_extract=$1
ip_bincov=$2
exclude=$3
r=$4
type_r=$5
chr=$6
op_dir=$7
output=$8
set +e
bash src/WGD/bin/cnMOPS_workflow.sh -S $exclude -x $exclude -r $r -o $op_dir -M $ip_extract $ip_bincov 2>&1 | tee ./tmp/cnmops.$chr.$type_r.out
RC=$?
set -e
if [ ! $RC -eq 0 ]; then
    if grep -q "$EMPTY_OUTPUT_ERROR" ./tmp/cnmops.$chr.$type_r.out; then
        touch $output
    else
        echo "cnMOPS_workflow.sh returned a non-zero code that was not due to an empty call file."
        exit $RC
    fi
fi