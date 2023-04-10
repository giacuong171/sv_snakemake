#!/bin/bash
cnmops_file=$1
op_dir=$2
exclude=$3
sample_list=$4
batch=$5
rtype=$6
chrom_file=$7
allo_file=$8
minsize=$9

grep -v "#" $cnmops_file > ./tmp/cnmops.${rtype}.gff1
echo "./tmp/cnmops.${rtype}.gff1"> ./tmp/GFF.${rtype}.list
bash ./src/WGD/bin/cleancnMOPS.sh -z -o ${op_dir}  -S $exclude $sample_list ./tmp/GFF.${rtype}.list

zcat ${op_dir}/*/*.cnMOPS.DEL.bed.gz > ${op_dir}/DELS.${rtype}.bed
awk -v batch=${batch}_DEL_ 'BEGIN {OFS="\t"} {print $1,$2,$3,batch,$4,"cnmops"}' ${op_dir}/DELS.${rtype}.bed | cat -n | awk 'BEGIN {OFS="\t"} {print $2,$3,$4,$5$1,$6,"DEL",$7}' | sort -k1,1V -k2,2n > ${op_dir}/${batch}.DEL.${rtype}.bed

cat <(echo -e "#chr\tstart\tend\tname\tsample\tsvtype\tsources") ${op_dir}/${batch}.DEL.${rtype}.bed  > ${op_dir}/${batch}.DEL.${rtype}.bed1

zcat ${op_dir}/*/*.cnMOPS.DUP.bed.gz > ${op_dir}/DUPS.${rtype}.bed
awk -v batch=${batch}_DUP_ 'BEGIN {OFS="\t"} {print $1,$2,$3,batch,$4,"cnmops"}' ${op_dir}/DUPS.${rtype}.bed | cat -n | awk 'BEGIN {OFS="\t"} {print $2,$3,$4,$5$1,$6,"DUP",$7}' | sort -k1,1V -k2,2n > ${op_dir}/${batch}.DUP.${rtype}.bed

cat <(echo -e "#chr\tstart\tend\tname\tsample\tsvtype\tsources") ${op_dir}/${batch}.DUP.${rtype}.bed  > ${op_dir}/${batch}.DUP.${rtype}.bed1

if [ ${rtype} == "large" ];then
    mv ${op_dir}/${batch}.DUP.${rtype}.bed1 ${op_dir}/${batch}.DUP.${rtype}.prestitch.bed
    mv ${op_dir}/${batch}.DEL.${rtype}.bed1 ${op_dir}/${batch}.DEL.${rtype}.prestitch.bed
    
    cat ${chrom_file} ${allo_file} > ./tmp/contig.${rtype}.fai
    svtk rdtest2vcf --contigs ./tmp/contig.${rtype}.fai ${op_dir}/${batch}.DUP.${rtype}.prestitch.bed $sample_list ${op_dir}/dup.${rtype}.vcf.gz
    svtk rdtest2vcf --contigs ./tmp/contig.${rtype}.fai ${op_dir}/${batch}.DEL.${rtype}.prestitch.bed $sample_list ${op_dir}/del.${rtype}.vcf.gz

    tabix -p vcf ${op_dir}/dup.${rtype}.vcf.gz
    tabix -p vcf ${op_dir}/del.${rtype}.vcf.gz

    bash ./src/sv-pipeline/04_variant_resolution/scripts/stitch_fragmented_CNVs.sh -d ${op_dir}/dup.${rtype}.vcf.gz ${op_dir}/dup1.${rtype}.vcf.gz
    bash ./src/sv-pipeline/04_variant_resolution/scripts/stitch_fragmented_CNVs.sh -d ${op_dir}/del.${rtype}.vcf.gz ${op_dir}/del1.${rtype}.vcf.gz

    tabix -p vcf ${op_dir}/dup1.${rtype}.vcf.gz
    tabix -p vcf ${op_dir}/del1.${rtype}.vcf.gz

    svtk vcf2bed ${op_dir}/dup1.${rtype}.vcf.gz ${op_dir}/dup1.${rtype}.bed
    cat <(awk -v OFS="\t" -v minsize=$minsize '{if($3-$2>minsize)print $1,$2,$3,$4,$6,$5,"cnmops_large"}' ${op_dir}/dup1.${rtype}.bed) >${op_dir}/${batch}.DUP.${rtype}.bed
    svtk vcf2bed ${op_dir}/del1.${rtype}.vcf.gz ${op_dir}/del1.${rtype}.bed
    cat <(awk -v OFS="\t" -v minsize=$min_size '{if($3-$2>minsize)print $1,$2,$3,$4,$6,$5,"cnmops_large"}' ${op_dir}/del1.${rtype}.bed) >${op_dir}/${batch}.DEL.${rtype}.bed
fi
