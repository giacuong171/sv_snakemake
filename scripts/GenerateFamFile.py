import glob 
import pandas as pd
from optparse import OptionParser

parser = OptionParser()
parser.add_option("--bam_dir", help="Path to bam files")
parser.add_option("--output_name",help="Name of the output file")
(options, args) = parser.parse_args()

def GenerateFamFile(bam_dir):
    bam_files=glob.glob(bam_dir + "/*.bam")
    bam_names=[x.split('/')[-1].split('.')[0] for x in bam_files]
    sample_names=[]
    for sample in bam_names:
        if (len(sample) > 14):
            sample_names.append(sample[:13])
        else :
            sample_names.append(sample)
    gender=[]
    for sample in bam_names:
        if (sample.split("_")[2] == "00"):
            gender.append(2)
        elif (sample.split("_")[2] == "01") :
            gender.append(1)
    p = [0]*len(gender)
    df = pd.DataFrame({
        "FID": sample_names,
        "IID": sample_names,
        "PID": sample_names,
        "MID": sample_names,
        "Sex": gender,
        "P": p
    })
    return df

def main():
    input_df=GenerateFamFile(options.bam_dir)
    input_df.to_csv(options.output_name,sep='\t',index=False,header=False)

if __name__ == '__main__':
    main()

