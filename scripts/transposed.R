
x <- read.table(snakemake@input[['medCov_bed']],check.names=FALSE) 
xtransposed <- t(x[,c(1,2)])
write.table(xtransposed,file=snakemake@output[['transposed_bed']],sep="\t",row.names=F,col.names=F,quote=F)