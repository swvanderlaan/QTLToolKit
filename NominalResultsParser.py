#!/usr/bin/python

print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
print "                         fastQTL NOMINAL RESULTS PARSER"
print ""
print ""
print "* Written by         : Tim Bezemer"
print "* Updated by         : Jacco Schaap"

print "* E-mail             : t.bezemer-2@umcutrecht.nl"
print "* Suggested for by   : Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl"
print "* Last update        : 2016-10-28"
print "* Name               : NominalResultsParser"
print "* Version            : v1.2.1"
print ""
print "* Description        : In case of a CTMM eQTL analysis this script will collect all "
print "                       analysed genes and list their associated ProbeIDs as well as the"
print "                       number of variants analysed."
print "                       In case of a AEMS mQTL analysis this script will collect all "
print "                       analysed CpGs and their associated genes, as well as the "
print "                       the number of variants analysed."
print "                       In both cases it will produce a LocusZoom (v1.2+) input file"
print "                       which contains the variant associated (MarkerName) and the "
print "                       p-value (P-value)."
print ""
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

import gzip
import pandas as pd
from sys import argv, exit
from os import mkdir
from os.path import isdir, isfile
from subprocess import call

fn_nom = argv[1] # Nominal data. Ether clumped or normal
#fn_perm = argv[2] # Permuted data. Ether clumped or normal
#fn2 = argv[3] # Directory were clumped data can be found
#clump = argv[4] # Yes for plotting clumped set, N for plotting normal set


def main():
    parser()
    #if clump == 'Y':
    #    read_summary()


### created by Tim Bezemer
def parser():
    if len(argv) < 1 or not isfile(argv[1]):
        print "Invalid filename was supplied."
        print "Usage: " + argv[0] + " [filename]"
        print "Please make sure the data file contains the following columns:"
        print "Locus\tGeneName\tProbeID\tVARIANT\tNominal_P\t"

        exit()

    ###data = pd.read_csv(fn, '\t')
    data = pd.read_csv(fn_nom)

    print "Checking for/creating directories loci/ and probes/ ..."
    if not isdir("_loci"): mkdir("_loci")
    if not isdir("_probes"): mkdir("_probes")

    # One file per locus (VariantID as name), containing all gene names and associated probes. Count Gene-Probe pairs.
	
    loci_ids = set(data['Locus'])

    loci = {}

    for l in loci_ids:

        print "Generating mapping for locus " + l

        loci[l] = dict()

        with open("_loci/" + l + ".txt", "w") as locus_mapping:

            print >> locus_mapping, "Locus\tGeneName\tProbeID\tN_Variants\tN_Sign_Variants"

            GeneNames = list(set(data[data['Locus'] == l]['GeneName']))
            print GeneNames
            for g in GeneNames:
				#print g
                loci[l][g] = []

                print "\t* gene " + g
                ###print "\t* gene " + str(g)

                ProbeIDs = list(set(data[(data['Locus'] == l) & (data['GeneName'] == g)]['ProbeID']))

                for p in ProbeIDs:
                    loci[l][g].append(p)

                    print "\t\t- collecting variants for probe " + p

                    variants = data[(data['Locus'] == l) & (data['GeneName'] == g) & (data['ProbeID'] == p)][
                        ['VARIANT', 'Nominal_P', 'Chr', 'BP']]

                    variants_p_below_threshold = data[
                        (data['Locus'] == l) & (data['GeneName'] == g) & (data['ProbeID'] == p) & (
                        data['Nominal_P'] < 0.05)][['VARIANT', 'Nominal_P', 'Chr', 'BP']]

                    variants.rename(columns={"VARIANT": "MarkerName", "Nominal_P": "P-value"}, inplace=True)
                    variants["MarkerName"] = variants.apply(lambda x: str(x['Chr']) + ":" + str(x['BP']), axis=1)

                    variants.rename(columns={"Chr": "RSID"}, inplace=True)

                    variants["RSID"] = data[(data['Locus'] == l) & (data['GeneName'] == g) & (data['ProbeID'] == p)][
                        'VARIANT']
                    # variants["RSID"] = variants.apply(lambda x: str(x['VARIANT']), axis=1)

                    variants = variants.drop('BP', axis=1)

                    # print "***DEBUG*** show variant on next line (second time)"
                    # print variants

                    n_of_variants = len(variants)
                    n_of_variants_below_threshold = len(variants_p_below_threshold)

                    # Output locus, gene, probeID, the variant count, and the N of significant hits per gene to the mapping file
                    print >> locus_mapping, "\t".join([l, g, p, str(n_of_variants), str(n_of_variants_below_threshold)])

                    # Construct the file containing variants for LocusZoom
                    with open("_probes/" + "_".join([l, g, p]) + ".lz", "w") as probe_file:
                        variants.to_csv(probe_file, sep='\t', index=False)

    print "Pfieuw. That was a lot! Let's have a beer."


### created by Jacco Schaap, 19-5-'17
#def read_summary():
#    print 'Started with updating nominal summary file'
#    with gzip.open(fn_nom, 'r') as file, gzip.open(fn_nom + '_temp.txt.gz', 'w') as out:
#        out.write('Locus,ProbeID,VARIANT,RSquare,Chr,BP,OtherAlleleA,CodedAlleleA,MAF,MAC,CAF,HWE,Info,Imputation,N,GeneName,EntrezID,Distance_VARIANT_GENE,Chr,GeneTxStart,GeneTxEnd,Beta,SE,Nominal_P,Bonferroni,BenjHoch,Q\n')
#        for regel in file.readlines():
#            regel = regel.strip('\n')
#            line = regel.split(',')
#            locus = line[0]
#            variant = line[2]
#            if line[0] == 'Locus':
#                continue
#            with open(fn2 + '/ldbuddies_' + locus + '.list', 'r') as ldfile:
##             	print 'Opened ldbuddie file, split on tab: ' + fn2 + '/ldbuddies_' + locus + '.list'
#                for snp in ldfile.readlines():
#                    snp = snp.strip('\n')
#                    # print snp
#                    snp = snp.split('\t')
#                    try:
#                        if snp[1] == variant:
#                        # print regel + ',' + snp[2]
#                            newline = ','.join(line[0:3]) + ',' + snp[2] + ',' + ','.join(line[4:26])
#                            out.write(newline + '\n')
#                    except IndexError:
#                        print snp
#                        continue
#
#    call(["mv", fn_nom + '_temp.txt.gz', fn_nom])




main()
