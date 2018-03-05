#!/usr/bin/python

print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
print "                         QTLTools NOMINAL RESULTS PARSER"
print ""
print ""
print "* Written by         : Tim Bezemer | t.bezemer-2@umcutrecht.nl"
print "* Updated by         : Jacco Schaap | jacco_schaap@hotmail.com"
print "* Suggested for by   : Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl"
print "* Last update        : 2018-03-02"
print "* Name               : NominalResultsParser"
print "* Version            : v1.2.5"
print ""
print "* Description        : In case of an eQTL analysis this script will collect all "
print "                       analysed genes and list their associated ProbeIDs as well as the"
print "                       number of variants analysed."
print "                       In case of a mQTL analysis this script will collect all "
print "                       analysed CpGs and their associated genes, as well as the "
print "                       the number of variants analysed."
print "                       In both cases it will produce a LocusZoom (v1.3+) input file"
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
import numpy as np

fn_nom = argv[1] # Nominal data. Either clumped or normal
#fn_perm = argv[2] # Permuted data. Either clumped or normal
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
				### print g
                loci[l][g] = []

                print "\t* gene " + (g if g != np.nan else "NA")
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

                    print "***DEBUG*** show variant on next line (second time)"
                    print variants

                    n_of_variants = len(variants)
                    n_of_variants_below_threshold = len(variants_p_below_threshold)

                    # Output locus, gene, probeID, the variant count, and the N of significant hits per gene to the mapping file
                    print >> locus_mapping, "\t".join([l, g, p, str(n_of_variants), str(n_of_variants_below_threshold)])

                    # Construct the file containing variants for LocusZoom
                    with open("_probes/" + "_".join([l, g, p]) + ".lz", "w") as probe_file:
                        variants.to_csv(probe_file, sep='\t', index=False)

    print "Pfieuw. That was a lot! Let's have a beer."
main()
