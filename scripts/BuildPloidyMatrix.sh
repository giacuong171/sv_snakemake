bincov_matrix=$1
batch_ploidy_matrix=$2

zcat $bincov_matrix \
    | awk ' \
    function printRow() \
        {printf "%s\t%d\t%d",chr,start,stop; \
        for(i=4;i<=nf;++i) {printf "\t%d",vals[i]; vals[i]=0}; \
        print ""} \
    BEGIN {binSize=1000000} \
    NR==1 {print substr($0,2)} \
    NR==2 {chr=$1; start=$2; stop=start+binSize; nf=NF; for(i=4;i<=nf;++i) {vals[i]=$i}} \
    NR>2  {if($1!=chr){printRow(); chr=$1; start=$2; stop=start+binSize} \
            else if($2>=stop) {printRow(); while($2>=stop) {start=stop; stop=start+binSize}} \
            for(i=4;i<=nf;++i) {vals[i]+=$i}} \
    END   {if(nf!=0)printRow()}' \
    | bgzip > $batch_ploidy_matrix