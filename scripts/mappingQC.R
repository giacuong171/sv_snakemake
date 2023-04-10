normalizeContigsPerSample <- function(mat, exclude=c("chrX", "chrY"), ploidy=2){
  #Convert vals to numeric
  mat[, -c(1:3)] <- apply(mat[, -c(1:3)], 2, as.numeric)
  
  #Iterate over all samples and scale each sample by median and center/scale to expected ploidy
  mat[, -c(1:3)] <- sapply(4:ncol(mat), function(i){
    #Compute median of values excluding current value & any other specified
    sampVals <- as.vector(mat[which(!(mat[, 1] %in% exclude)), i])
    excl.median <- median(sampVals[which(sampVals>0)], na.rm=T)
    
    #Normalize values by excl.median
    newVals <- mat[, i]/excl.median
    
    #Scale to expected ploidy
    newVals <- ploidy*newVals
    
    #Return cleaned values
    return(newVals)
  })
  
  #Return normalized matrix
  return(mat)
}

filterZeroBins <- function(mat, exclude=c("X", "Y"), minSamp=0.8, minCov=0.2){
  #Convert vals to numeric
  mat[, -c(1:3)] <- apply(mat[, -c(1:3)], 2, as.numeric)
  
  #Find bins where >minSamp% of samples have coverage>minCov
  #Dev note, Jan 2020: default for minSamp boosted from 0.05 to 0.8, 
  # and minCov boosted from 0.05 to 0.2, to account for switch 
  # from binCov to GATK collectReadCounts
  nZeros <- apply(mat[, -c(1:3)], 1, function(vals){
    return(length(which(vals<=minCov)))
  })
  fracZeros <- nZeros/(ncol(mat)-3)
  keep.bins <- which(fracZeros<=minSamp | mat[, 1] %in% exclude)
  
  #Return subsetted matrix
  return(mat[keep.bins, ])
}

require(ggplot2)

sample <- snakemake@wildcards[['sample']]
op_file <- snakemake@output[['out']]
mat <- read.table(snakemake@input[['bin_mat']],header=T)

mat[,-1] <- t(apply(mat[,-1], 1,as.numeric))

mat <- normalizeContigsPerSample(mat)
mat <- filterZeroBins(mat)
y.step=2
font.size=12
axis.size=0.5
y.title=paste(sample,"_Read_Depth")
x.title="Chromosome"
graph.title=paste("Mapping QC of ",sample)
y.max <- floor(max(mat[sample]))
mat$Chr <- factor(mat$Chr, levels = unique(mat$Chr))
g <- ggplot(mat) +
  geom_point(aes(Start, unlist(mat[sample],use.names=FALSE), colour = as.factor(Chr)), size = 1)
g <- g + facet_grid(.~Chr,scale = "free_x",space = "free_x",switch = "x")
g <- g + ggtitle(graph.title) + xlab(x.title) + ylab(y.title)

png(op_file, height=1250, width=2500)
plot(g)
dev.off()