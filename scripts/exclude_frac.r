library(optparse)
option_list <- list(
  make_option(c("-I","--INPUT_file"), type="character", default=NULL,
              help="INPUT file",
              metavar="character"),
  make_option(c("-O","--OUTPUT_file"), type="character",default=NULL,
              help="OUTPUT_file",
              metavar="character"),
  make_option(c("-f","--fraction_max"),type="double",default=0.5,
              help="acceptable fraction")
)

args <- parse_args(OptionParser(option_list=option_list))


INFILE <- args$INPUT_file
OUTFILE <- args$OUTPUT_file
frac_max <- args$fraction_max
filter_frac <- function(dat){
  mark <- apply(dat[11],1,function(val){
    return(val<frac_max)
  })
  return(dat[which(mark==TRUE),])
}
dat <- read.table(INFILE,header=F)
dat$V11 <- as.double(dat$V11)

filter_dat <- filter_frac(dat)

write.table(filter_dat,OUTFILE,col.names = F,row.names = F, sep="\t",quote=F)
