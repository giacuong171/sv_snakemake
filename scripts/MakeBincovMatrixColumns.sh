set -Eeu

count_file=$1
bin_locs=$2
bin_size="$(cat $3)"
bincov_file_name=$4
sample=$5


firstchar=$(gunzip -c $count_file | head -c 1)
set -o pipefail
if [ $firstchar == '@' ]; then
    shift=1
else
    shift=0
fi

TMP_BED="$(basename $count_file).tmp.bed"
printf "#Chr\tStart\tEnd\t%s\n" $sample > $TMP_BED
zcat $count_file \
    | sed '/^@/d' \
    | sed '/^CONTIG	START	END	COUNT$/d' \
    | sed '/^#/d' \
    | awk -v x=$shift -v b=$bin_size \
    'BEGIN{OFS="\t"}{$2=$2-x; if ($3-$2==b) print $0}' \
    >> "$TMP_BED"

if ! cut -f1-3 "$TMP_BED" | cmp <(bgzip -cd $bin_locs); then
    echo "$count_file has different intervals than $bin_locs"
    exit 1
fi
cut -f4- "$TMP_BED" >> $bincov_file_name

rm $TMP_BED