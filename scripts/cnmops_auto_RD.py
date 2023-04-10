import pandas as pd
from optparse import OptionParser

parser = OptionParser()
parser.add_option("--mode", help="")
parser.add_option("--gender_file", help="")
parser.add_option("--chr_mat",help="")
parser.add_option("--output",help="")
(options, args) = parser.parse_args()

def extract_mt(gender_mat,chr_mat,mode):
    sample_mode=gender_mat[(gender_mat.gender== int(mode))]['sampleID'].to_list()
    sample_mode.insert(0,"End")
    sample_mode.insert(0,"Start")
    sample_mode.insert(0,"#Chr")
    chr_mat_mode = chr_mat[sample_mode]
    print(chr_mat_mode)
    return chr_mat_mode

def main():
    colnames=["familyID","sampleID","gender"]
    gender_mat= pd.read_csv(options.gender_file,delim_whitespace=True,names=colnames,index_col=False)
    chr_mat = pd.read_csv(options.chr_mat,header=0,delimiter="\t")
    chr_mat_mode = extract_mt(gender_mat,chr_mat,options.mode)
    chr_mat_mode.to_csv(options.output,header=True,sep='\t',index=False)

if __name__ == '__main__':
    main()