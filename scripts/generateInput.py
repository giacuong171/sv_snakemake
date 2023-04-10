import pandas as pd
import glob
from optparse import OptionParser

parser = OptionParser()
parser.add_option("--bam_dir",type="string", help="Path to bam files")
parser.add_option("--vcf_dir",type="string", help="Path to vcf files")
parser.add_option("--output_name",type="string", help="Name of the output file")
(options, args) = parser.parse_args()

def GatheringInputFiles(bam_dir,vcf_dir):
    bam_files=glob.glob(bam_dir + "/*.bam")
    bam_names=[x.split('/')[-1].split('.')[0] for x in bam_files]
    sample_names=[]
    for sample in bam_names:
        if (len(sample) > 14):
            sample_names.append(sample[:13])
        else :
            sample_names.append(sample)
    if (vcf_dir):
        vcf_files=[]
        for sample in sample_names:
            vcf_files.append(glob.glob(vcf_dir + "/" + sample + "*.*.vcf.gz")[0])
        df = pd.DataFrame({
        "sample": sample_names,
        "bam_files": bam_files,
        "vcf_files": vcf_files
        })
    else:
        df = pd.DataFrame({
        "sample": sample_names,
        "bam_files": bam_files
        })
    
    return df

def main():
    input_df=GatheringInputFiles(options.bam_dir,options.vcf_dir)
    input_df.to_csv(options.output_name,sep='\t',index=False)

if __name__ == '__main__':
    main()

