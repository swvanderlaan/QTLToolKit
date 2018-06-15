#!/usr/bin/python

print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
print "                              QTLTools Summary Editor"
print ""
print ""
print "* Written by         : Jacco Schaap | jacco_schaap@hotmail.com"
print "* Suggested for by   : Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl"
print "* Last update        : 2018-06-15"
print "* Name               : QTLSumEditor"
print "* Version            : v1.2.2"
print ""
print "* Description        : This script will collect r-square between locus and QTL "
print "                       variant when data is clumped."
print ""
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

### created by Jacco Schaap, 17-6-'17
from sys import argv
import gzip
from subprocess import call

nominal = argv[1] # Nominal data, e.g. ${SUMMARY}/${STUDYNAME}_QC_qtlnom_summary.txt.gz 
nominal_clump = argv[2] # Clumped nominal data, e.g. ${SUMMARY}/${STUDYNAME}_QC_qtlnom_clumped_summary.txt.gz 
permuted = argv[3] # Permuted data, e.g. ${SUMMARY}/${STUDYNAME}_QC_qtlperm_summary.txt.gz
permuted_clump = argv[4] # Clumped permute data, e.g. ${SUMMARY}/${STUDYNAME}_QC_qtlperm_clumped_summary.txt.gz
CLUMPDIR = argv[5] # Directory were clumped data can be found, e.g.  ${CLUMPDIR} 

"""
so for now the code only works on nominal clumped data. Let's fix it for normal and permuted data. 
We wanna see the rsquared between all variants!

Input is summarized data file, (nominal, nominal_clumped, permuted, ?permuted_nominal)
It now works only on nominal data cause this is the input data of the plotter script.

What I need to do:
read also the permuted summary, specify in plotter script

Header nominal file = 'Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Strand,Chr_Gene,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q
Header permuted file = 'Locus,ProbeID,VARIANT,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Strand,Chr_Gene,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q'

"""

def read_summary():
    print '\nStarted with updating (clumped) >> NOMINAL << summary file.\n'
    for i in range(1,3):
#         print str(i)
        print '* Updating data from summary file [ ' + str(argv[i] + ' ].\n')
        with gzip.open(argv[i], 'r') as file, gzip.open(argv[i] + '_temp.txt.gz', 'w') as out:
            out.write('Locus,ProbeID,VARIANT,RSquare,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Strand,Chr_Gene,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q\n')
            for regel in file.readlines():
                snp_found = 0
                regel = regel.strip('\n')
                line = regel.split(',')
                locus = line[0]
#                 print '* DEBUG: updating data for locus: ' + locus + '.\n'
                variant = line[2]
                if line[0] == 'Locus':
                    continue
                with open(CLUMPDIR + '/ldbuddies_' + locus + '.list', 'r') as ldfile:
#                     print '* DEBUG: opened ldbuddie file, split on tab: ' + CLUMPDIR + '/ldbuddies_' + locus + '.list.\n'
                    for snp in ldfile.readlines():
                        snp = snp.strip('\n')
#                         print '* DEBUG: reading this variant:' + snp + '.\n'
                        snp = snp.split('\t')
                        try:
                            if snp[1] == variant:
#                                 print '* DEBUG: extracting data from ' + regel + ' and ' + snp[2] + '.\n'
                                newline = ','.join(line[0:3]) + ',' + snp[2] + ',' + ','.join(line[3:27])
                                out.write(newline + '\n')
                                snp_found += 1
                        except IndexError:
                            print '*** WARNING *** cannot find this variant:' + snp + '.\n'
                            continue
                if snp_found == 0:
#                     print '*** WARNING *** ' + str(snp) + ' not found with current rsquared threshold, writing NR.\n'
                            newline = ','.join(line[0:3]) + ',' + 'NR' + ',' + ','.join(line[3:27])
                            out.write(newline + '\n')
        ### Overwrite original summary file with temporary updated one
        call(["mv", argv[i] + '_temp.txt.gz', argv[i]])

    print '\nStarted with updating (clumped) >> PERMUTATION << summary file.\n'
    for i in range(3,5):
#         print str(i)
        print '* Updating data from summary file [ ' + str(argv[i] + ' ].\n')
        with gzip.open(argv[i], 'r') as file, gzip.open(argv[i] + '_temp.txt.gz', 'w') as out:
            out.write('Locus,ProbeID,VARIANT,RSquare,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Strand,Chr_Gene,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Perm_P,ApproxPerm_P,Bonferroni,BenjHoch,Q\n')
            for regel in file.readlines():
                snp_found = 0
                regel = regel.strip('\n')
                line = regel.split(',')
                locus = line[0]
#                 print '* DEBUG: updating data for locus: ' + locus + '.\n'
                variant = line[2]
                if line[0] == 'Locus':
                    continue
                with open(CLUMPDIR + '/ldbuddies_' + locus + '.list', 'r') as ldfile:
#                     print '* DEBUG: opened ldbuddie file, split on tab: ' + CLUMPDIR + '/ldbuddies_' + locus + '.list.\n'
                    for snp in ldfile.readlines():
                        snp = snp.strip('\n')
#                         print '* DEBUG: reading this variant:' + snp + '.\n'
                        snp = snp.split('\t')
                        try:
                            if snp[1] == variant:
#                                 print '* DEBUG: extracting data from ' + regel + ' and ' + snp[2] + '.\n'
                                newline = ','.join(line[0:3]) + ',' + snp[2] + ',' + ','.join(line[3:29])
                                out.write(newline + '\n')
                                snp_found += 1
                        except IndexError:
                            print '*** WARNING *** cannot find this variant:' + snp + '.\n'
                            continue
                if snp_found == 0:
#                     print '*** WARNING *** ' + str(snp) + ' not found with current rsquared threshold, writing NR.\n'
                    newline = ','.join(line[0:3]) + ',' + 'NR' + ',' + ','.join(line[3:29])
                    out.write(newline + '\n')
        ### Overwrite original summary file with temporary updated one
        call(["mv", argv[i] + '_temp.txt.gz', argv[i]])

read_summary()