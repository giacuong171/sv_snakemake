#!/bin/bash
set -euo pipefail

bam=$1
ref=$2
sample_id=$3
threads=$4
include_list=$5
pri_contig_list=$6
wham_vcf=$7

reference_index_file="$2.fai"

echo "whamg $(./whamg 2>&1 >/dev/null | grep Version)"
GOOD_INTERVALS=$(awk '{print $1 ":" $2 "-" $3 "\n"}' $include_list)
VCFS=""
chr_list=$(sed ':a;N;$!ba;s/\n/,/g' $pri_contig_list)
for GOOD_INTERVAL in $GOOD_INTERVALS; do
    echo "Analyzing $GOOD_INTERVAL"
    NEW_VCF="./tmp/$sample_id.$GOOD_INTERVAL.wham.vcf.gz"
    whamg \
        -c $chr_list \
        -x $threads \
        -a $ref \
        -f $bam \
        -r "$GOOD_INTERVAL" \
        | bgzip -c > "$NEW_VCF"
    tabix -f "$NEW_VCF"
    if [ -z "$VCFS" ]; then
        VCFS="$NEW_VCF"
    else 
        VCFS="$VCFS $NEW_VCF"
    fi
done

# We need to update both the VCF sample ID and the TAGS INFO field in the WHAM output VCFs.
# WHAM uses both to store the sample identifier, and by default uses the SM identifier from the BAM file.
# We need to update both to reflect the potentially-renamed sample identifier used by the pipeline (sample_id) --
# svtk standardize_vcf uses the TAGS field to identify the sample for WHAM VCFs.

VCF_FILE_FIXED_HEADER=$wham_vcf
VCF_FILE_BAD_TAGS="./tmp/$sample_id.wham_bad_header_bad_tags.vcf.gz"
VCF_FILE_BAD_HEADER="./tmp/$sample_id.wham_bad_header.vcf.gz"

# concatenate resulting vcfs into final vcf
echo "Concatenating results"
bcftools concat -a -O z -o "$VCF_FILE_BAD_TAGS" $VCFS
tabix -p vcf "$VCF_FILE_BAD_TAGS"
query_str="%CHROM\t%POS\t%REF\t%ALT\t"$sample_id"\n"
# write out a an annotation table with the new sample ID for each variant record.
bcftools query -f $query_str $VCF_FILE_BAD_TAGS | bgzip -c > ./tmp/$sample_id.tags_annotation_file.tsv.gz
tabix -f -s1 -b2 -e2 ./tmp/$sample_id.tags_annotation_file.tsv.gz

bcftools annotate -a ./tmp/$sample_id.tags_annotation_file.tsv.gz -c CHROM,POS,REF,ALT,INFO/TAGS  $VCF_FILE_BAD_TAGS | bgzip -c > $VCF_FILE_BAD_HEADER
tabix -p vcf "$VCF_FILE_BAD_HEADER"


echo "Getting existing header"
# get the existing header
OLD_HEADER=$(bcftools view -h "$VCF_FILE_BAD_HEADER" | grep -v '##contig=')
# create new header lines with the contig lengths
echo "Making grep pattern to extract contigs from reference index"
CONTIGS_PATTERN="^$(cat $pri_contig_list | paste -sd "," - | sed "s/,/\\\t|^/g")\t"
echo "Adding contigs with length to vcf header"        
CONTIGS_HEADER=$(grep "$CONTIGS_PATTERN" -P "$reference_index_file" | awk '{print "##contig=<ID=" $1 ",length=" $2 ">"}')
# Create a new header with
#   -all but last line of old header, followed by newline
#   -contig header lines, followed by newline
#   -last line of old header
# Replace old header with new header
echo "Replacing header"
echo "$OLD_HEADER" | grep -v "^#CHROM" > ./tmp/$sample_id.new_header.txt
echo "$CONTIGS_HEADER" >> ./tmp/new_header.txt
echo "$OLD_HEADER" | grep "^#CHROM" >> ./tmp/$sample_id.new_header.txt
bcftools reheader \
    -h ./tmp/$sample_id.new_header.txt \
    -s <(echo $sample_id) \
    "$VCF_FILE_BAD_HEADER" \
    > "$VCF_FILE_FIXED_HEADER"

echo "Indexing vcf"
tabix -f "$VCF_FILE_FIXED_HEADER"
echo "finished RunWhamg"

rm $VCFS ./tmp/$sample_id.tags_annotation_file.tsv.gz \
    $VCF_FILE_BAD_HEADER \
    ./tmp/$sample_id.new_header.txt \
    