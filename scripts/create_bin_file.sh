#!/bin/bash
# make the CollectReadCounts output consistent with the old bincov code
# determine what format this is

#$1 Count file
#$2 Bin size output file name
#$3 Bin locs

count_file=$1
binsize_file=$2
bin_locs=$3



firstchar=$(gunzip -c $count_file | head -c 1)
set -o pipefail
if [ $firstchar == '@' ]; then
    shift=1  # GATK CollectReadCounts (to convert from 1-based closed intervals)
else
    shift=0  # bincov sample or matrix
fi

tmp_locs="$(basename $count_file).tmp_locs"
# kill the dictionary | kill the header | adjust to bed format: 0-based half-open intervals
zcat $count_file \
    | sed '/^@/d' \
    | sed '/^CONTIG	START	END	COUNT$/d' \
    | sed '/^#/d' \
    | awk -v x="${shift}" 'BEGIN{OFS="\t"}{$2=$2-x; print $1,$2,$3}' > $tmp_locs

# determine bin size, and drop all bins not exactly equal to this size

#if ~{defined(binsize)}; then
#    # use the provided bin size
#    binsize=~{binsize}
#else
#    # use the most common bin size from the bins
#    binsize=$(
#    sed -n '1,1000p' tmp_locs | awk '{ print $3-$2 }' \
#    | sort | uniq -c | sort -nrk1,1 \
#    | sed -n '1p' | awk '{ print $2 }'
#    )
#fi

# use the most common bin size from the bins
binsize=$(
    sed -n '1,1000p' $tmp_locs | awk '{ print $3-$2 }' \
    | sort | uniq -c | sort -nrk1,1 \
    | sed -n '1p' | awk '{ print $2 }'
)
# store binsize where cromwell can read it
echo $binsize > $binsize_file

# write final bed file with header, and compress it
awk -v FS="\t" -v b=$binsize 'BEGIN{ print "#Chr\tStart\tEnd" } { if ($3-$2==b) print $0 }' $tmp_locs \
    | bgzip -c \
    > $bin_locs


rm $tmp_locs
# if bincov_matrix_samples was passed, convert to tab-separated string
#if ~{defined(bincov_matrix_samples)}; then
#    mv "~{write_tsv([select_first([bincov_matrix_samples, ["dummy"]])])}" "~{bincov_header_file_name}"
#else
#    touch "~{bincov_header_file_name}"
#fi

