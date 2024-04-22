from sys import argv
import gzip
import os

file = argv[1]
snp_dir = argv[2]
region_file = argv[3]
chr = argv[4]
snps = []

with open(region_file, 'r') as r_file:
    for line in r_file.readlines():
        line = line.strip('\n')
        line = line.split('\t')
        SNP = line[0]
        if line[2] == chr:
            snps.append(SNP)
    print snps
    count = 0
    with gzip.open(file, 'r') as hit_file:
        for regel in hit_file.readlines():
            line = regel.split(' ')
            if line[3] in snps:
                with gzip.open(snp_dir + '/' + line[3] + '.hits.txt.gz', 'a') as outfile:
                    print regel
                    outfile.write(regel)
os.remove(file)
