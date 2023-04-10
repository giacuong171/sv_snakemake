#!/bin/bash
rf_cutoffs=$1
gt_cutoffs=$2
pesr_sepcutoff=$3
depth_sepcutoff=$4

sep=$(awk -F'\t' 'NR==1 {for(i=1;i<=NF;i++) col[$i]=i; next} \
        {if ($col["algtype"]=="PESR" && $col["min_svsize"]==1000 && $col["metric"]=="RD_Median_Separation") \
        print $col["cutoff"]}' $rf_cutoffs) 
        
awk -v var=$sep 'NR==1 {for(i=1;i<=NF;i++) col[$i]=i; print; next} \
    {if ($col["copy_state"]=="1" && $col["cutoffs"]>1-var) \
                $col["cutoffs"]=1-var; \
                else if ($col["copy_state"]=="2" && $col["cutoffs"]<1+var) \
                $col["cutoffs"]=1+var; \
                print }' $gt_cutoffs | tr ' ' '\t' > $pesr_sepcutoff;
        
sep=$(awk -F'\t' 'NR==1 {for(i=1;i<=NF;i++) col[$i]=i; next} \
        {if ($col["algtype"]=="Depth" && $col["metric"]=="RD_Median_Separation") \
        print $col["cutoff"]}' $rf_cutoffs | sort -nr | head -n 1)

awk -v var=$sep 'NR==1 {for(i=1;i<=NF;i++) col[$i]=i; print; next} \
            { if ($col["copy_state"]=="1" && $col["cutoffs"]>1-var) \
                $col["cutoffs"]=1-var; \
                else if ($col["copy_state"]=="2" && $col["cutoffs"]<1+var) \
                $col["cutoffs"]=1+var; \
                print }' $gt_cutoffs | tr ' ' '\t' > $depth_sepcutoff;