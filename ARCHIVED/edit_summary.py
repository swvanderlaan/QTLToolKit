#!/usr/bin/python

### created by Jacco Schaap, 17-6-'17
from sys import argv
import gzip
from subprocess import call

nominal = argv[1] # Data. Ether clumped or normal
nominal_clump = argv[2]
permuted = argv[3] # Directory were clumped data can be found
permuted_clump = argv[4] # Yes for plotting clumped set, N for plotting normal set
CLUMPDIR = argv[5] # Directory were clumped data can be found


"""
so for now the code only works on nominal clumped data. Let's fix it for normal and permuted data. We wanna see the rsquared between all variant!

Input is summarized data file, (nominal, nominal_clumped, permuted, ?permuted_nominal)
It now works only on nominal data cause this is the input data of the plotter script.

What I need to do:
read also the permuted summary, specify in plotter script

Header nominal file = 'Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Chr,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q
Header permuted file = 'Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Chr,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q'
"""

def read_summary():
    print 'Started with updating summary file'
    for i in range(1,3):
        print str(i)
        print 'Data from summary file: ' + str(argv[i] + '\n')
        with gzip.open(argv[i], 'r') as file, gzip.open(argv[i] + '_temp.txt.gz', 'w') as out:
            out.write('Locus,ProbeID,VARIANT,RSquare,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Chr,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q\n')
            for regel in file.readlines():
                snp_found = 0
                regel = regel.strip('\n')
                line = regel.split(',')
                locus = line[0]
                variant = line[2]
                if line[0] == 'Locus':
                    continue
                with open(CLUMPDIR + '/ldbuddies_' + locus + '.list', 'r') as ldfile:
    #             	print 'Opened ldbuddie file, split on tab: ' + CLUMPDIR + '/ldbuddies_' + locus + '.list'
                    for snp in ldfile.readlines():
                        snp = snp.strip('\n')
                        # print snp
                        snp = snp.split('\t')
                        try:
                            if snp[1] == variant:
                            # print regel + ',' + snp[2]
                                newline = ','.join(line[0:3]) + ',' + snp[2] + ',' + ','.join(line[3:26])
                                out.write(newline + '\n')
                                snp_found += 1
                        except IndexError:
                            print snp
                            continue
                if snp_found == 0:
                            # print snp + " not found with current rsquared threshold, added as NR"
                            newline = ','.join(line[0:3]) + ',' + 'NR' + ',' + ','.join(line[3:26])
                            out.write(newline + '\n')
        ### Overwrite original summary file with temporary updated one
        call(["mv", argv[i] + '_temp.txt.gz', argv[i]])

    for i in range(3,5):
        print str(i)
        print 'Data from summary file: ' + str(argv[i] + '\n')
        with gzip.open(argv[i], 'r') as file, gzip.open(argv[i] + '_temp.txt.gz', 'w') as out:
            out.write('Locus,ProbeID,VARIANT,RSquare,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Chr,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q\n')
            for regel in file.readlines():
                snp_found = 0
                regel = regel.strip('\n')
                line = regel.split(',')
                locus = line[0]
                variant = line[2]
                if line[0] == 'Locus':
                    continue
                with open(CLUMPDIR + '/ldbuddies_' + locus + '.list', 'r') as ldfile:
                # print 'Opened ldbuddie file, split on tab: ' + CLUMPDIR + '/ldbuddies_' + locus + '.list'
                    for snp in ldfile.readlines():
                        snp = snp.strip('\n')
                        # print snp
                        snp = snp.split('\t')
                        try:
                            if snp[1] == variant:
                            # print regel + ',' + snp[2]
                                newline = ','.join(line[0:3]) + ',' + snp[2] + ',' + ','.join(line[3:28])
                                out.write(newline + '\n')
                                snp_found += 1
                        except IndexError:
                            print snp
                            continue
                if snp_found == 0:
                    # print snp + " not found with current rsquared threshold, added as NR"
                    newline = ','.join(line[0:3]) + ',' + 'NR' + ',' + ','.join(line[3:28])
                    out.write(newline + '\n')
        ### Overwrite original summary file with temporary updated one
    	call(["mv", argv[i] + '_temp.txt.gz', argv[i]])

read_summary()