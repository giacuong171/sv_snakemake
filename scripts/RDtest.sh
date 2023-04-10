#!/bin/bash

vcf_file=$1
source=$2
chr_list=$3
op_dir=$4
ref_dict=$5
coveragefile=$6
prefix=$7
fam_file=$8
include_list=$9

mkdir $op_dir/$source

tabix -f -p vcf $vcf_file

for chr in $chr_list
do
    tabix -h $vcf_file $chr \
    svtk vcf2bed --no-header stdin stdout > $op_dir/$source/all.$chr.$source.bed
done

for fbed in  $op_dir/$source/*
do
    set +o pipefail
    start=$(( $(cut -f2 $fbed | sort -k1,1n | head -n1) ))
    end=$(( $(cut -f3 $fbed | sort -k1,1n | tail -n1) ))
    chrom=$(cut -f1 $fbed | head -n1)
    
    gatk PrintSVEvidence \
        --sequence-dictionary $ref_dict \
        --evidence-file $coveragefile \
        -L "${chrom}:${start}-${end}" \
        -O local.RD.txt.gz
    tabix -p bed local.RD.txt.gz

    Rscript src/RdTest/RdTest.R \
      -b $fbed \
      -n $prefix \
      -c local.RD.txt.gz \
      -m $medianfile \
      -f $fam_file \
      -w $include_list 
    echo $fbed >> tmp.list
done

echo 'chr	Start	End	CNVID	SampleIDs	Type	Median_Power	P	2ndMaxP	Model	Median_Rank	Median_Separation' > $prefix.$source.stats

while read split; do 
    sed 1d $split;
done <- tmp.list >> $prefix.$source.stats


