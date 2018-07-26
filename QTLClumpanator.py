#!/usr/bin/python

print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
print "                              QTLTools Clumpanator"
print ""
print ""
print "* Written by         : Jacco Schaap | jacco_schaap@hotmail.com"
print "* Suggested for by   : Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl"
print "* Last update        : 2018-07-26"
print "* Name               : QTLClumpanator"
print "* Version            : v1.1.1"
print ""
print "* Description        : In case of a QTL analysis this script will collect all "
print "                       variants in LD with index variants based on a specific GWAS"
print "                       dataset (e.g. CARDIoGRAMplusC4D), and according to p-value, "
print "                       r^2, and range thresholds (in kb)."
print ""
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

from subprocess import call
from datetime import datetime
from os.path import isfile, isdir
import gzip
import sys

plink = sys.argv[1] #'/hpc/local/CentOS7/dhl_ec/software/plink_v1.9'

id = sys.argv[2]
chr = sys.argv[3]
nominal_data_file = sys.argv[4]
ld_nominal_data_file = sys.argv[5]
output = sys.argv[6]  # clumps directory in qtl folder
data = sys.argv[7]
clump = sys.argv[8]
metalfile =  sys.argv[15]
exclusion = sys.argv[16] # exclude variants that are duplicated because they are multi-allelic - such as rs114643911.

try:
    clump_tresh = sys.argv[9]

except IndexError:
    print 'No clump threshold given, set to 0.8.'
    clump_tresh = 0.8

try:
    clump_p1 = sys.argv[10]

except IndexError:
    print 'No clump p1 threshold given, set to 5e-8 (GWAS threshold).'
    clump_p1 = 5e-8

try:
    clump_p2 = sys.argv[11]

except IndexError:
    print 'No clump p2 threshold given, set to 0.05.'
    clump_p2 = 0.05

try:
    clump_kb = sys.argv[12]

except IndexError:
    print 'No clump range threshold given, set to 1000kb.'
    clump_kb = 1000

try:
    clump_gwas_snpfield = sys.argv[13]

except IndexError:
    print 'The clump varianID field.'
    clump_gwas_snpfield = "SNP"

try:
    clump_gwas_pval = sys.argv[14]

except IndexError:
    print 'The clump p-value field.'
    clump_gwas_pval = "P"

if not isfile(sys.argv[0]):
    print 'Script not found'


def main():
    print 'Start-time: ' + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + '\n'
#     check_qtlnom()
    read_clumped(id, chr)
    print '\n' + 'End-time: ' + datetime.now().strftime('%Y-%m-%d %H:%M:%S')


def create_clumped_file(chr):
    # creates clumped file with minimum p-value of 0.05
    if clump == 'Y':
        call([plink,
              "--bfile", data,
              "--exclude", exclusion,
              "--clump-verbose",
              "--clump", metalfile,
              "--clump-r2", clump_tresh, "--clump-p1", clump_p1, "--clump-p2", clump_p2, "--clump-kb", clump_kb,
              "--clump-snp-field", clump_gwas_snpfield, "--clump-field", clump_gwas_pval,
              "--memory", "4000",
              "--out", output+"/chr"+chr+"."+id
              ])
    if clump == 'N':
        call([plink,
              "--bfile", data,
              "--exclude", exclusion,
              "--clump-verbose",
              "--clump", metalfile,
              "--clump-r2", "0.8", "--clump-p1", "5e-8", "--clump-p2", "0.05", "--clump-kb", "1000",
              "--clump-snp-field", "SNP", "--clump-field", "P",
              "--memory", "4000",
              "--out", output+"/chr"+chr+"."+id 
              ])


def read_clumped(id, chr):
    # print id
    range = ''
    ldbuddies = []
    if isfile(output + '/highlight_ranges_' + id + '.list'):
        with open(output + '/highlight_ranges_' + id + '.list', 'r') as file:
            for line in file.readlines():
                line = line.split('\t')
                if id in line[0]:
                    open(output + '/highlight_ranges_' + id + '.list', 'w')
    # id = 'rs10953541'
    if not isfile(output + '/chr' + chr + '.' + id + '.clumped'):
        print "\n\t***Chromosome " + chr + " isn't clumped, mr Bourne will do it right away...***\n"
        create_clumped_file(chr)
        print "\nDone clumping chr" + chr + ", fast ain't it???\n"
        if not isfile(output + '/chr' + chr + '.' + id + '.clumped'):
            print 'no LD buddies found, created empty file\n'
            open(output+'/chr'+chr+'.' + id + '.clumped', 'w')
    elif isfile(output + '/chr' + chr + '.' + id + '.clumped'):
        print "\n\t***Chromosome " + chr + " for " + id + " is clumped before, skipping this part.***\n"

    with open(output + '/chr' + chr + '.' + id + '.clumped', 'r') as file, open(output + '/ldbuddies_' + id + '.list',
                                                                     'w') as outfile \
            , open(output + '/rsquared.txt', 'w') as rfile, open(output + '/only_ldbuddies_' + id + '.list', 'w') as ldfile:
        print 'Outputfile: ' + output + '/ldbuddies_' + id + '.list'
        outfile.write(id + '\t' + id + '\t' + '1' + '\n')
        ldfile.write(id + '\n')
        teller = 0
        chr_bp = ''
        for line in file.readlines():
            line = line.strip('\n')
            line = line.split()
            # print line
            try:
                try:
                    if id == line[2]:
                        # print line
                        #     bp = line[3]
                        chr_bp = chr + ':' + line[3]
                except IndexError:
                    pass
                if id == line[1]:
                    # print line
                    teller = 1
                if teller == 1 and 'RANGE:' not in line and '(INDEX)' not in line:
                    # print line
                    ldbuddies.append(line[0])
                    ldfile.write(line[0] + '\n')
                    outfile.writelines(id + '\t' + line[0] + '\t' + line[2] + '\n')
                if "RANGE:" in line and teller == 1:
                    range = line[1]
                    teller = 0
                    # print line
            except IndexError:
                continue
        ldbuddies.append(id)

    try:
        range = range.split(':')[1]
        range = range.split('..')

        # write range file, comma separated
        with open(output + '/highlight_ranges_' + id + '.list', 'a') as rangefile:
            rangefile.writelines(id + ',' + range[0] + ',' + range[1] + '\n')
        print 'High-light range: ' + range[0] + '..' + range[1]
        print 'Number of LD buddies found: ' + str(len(ldbuddies))
        return ldbuddies
    except IndexError:
        print 'No LD buddies found for ' + id + ', created empty files.\n'
        with open(output + '/highlight_ranges_' + id + '.list', 'a') as rangefile:
            rangefile.writelines(id + ',' + '' + ',' + '' + '\n')


def check_qtlnom():
    ldbuddies = read_clumped(id, chr)
    print 'File: ' + nominal_data_file
    with gzip.open(nominal_data_file, 'r') as file, \
            gzip.open(ld_nominal_data_file + '.txt.gz', 'w') as outfile:
        for regel in file.readlines():
            regel = regel.strip('\n')
            line = regel.split(' ')
            #             print line
            for buddie in ldbuddies:
                if buddie == line[1]:
                    # print line
                    outfile.writelines(regel + '\n')


main()
