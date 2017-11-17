from sys import argv
import gzip

clump = argv[1] # Y for clumped results, N for normal results
summary_file = argv[2] # Permuted summary file that needs to be parsed 
nom_summary_file = argv[3] # Nominal summary file that needs to be parsed 
# print summary_file
summary_direct = argv[4] # Directory to put results in

def main():
    #search()
    second()

def search():
    data = []
    snp_list = []
    permuted_snps = []
    # nom
    # with gzip.open("qtl_summary/ctmm_QC_qtlnom_clumped_summary.txt.gz", 'r') as file, open('ctmm_nom_qtl_tophits.txt', 'w') as outfile:  # debugging
    # perm
    # with gzip.open("qtl_summary/ctmm_QC_qtlperm_clumped_summary.txt.gz", 'r') as file, open('ctmm_perm_qtl_tophits.txt',
    #                                                                                         'w') as outfile, open(
    #         'q.list', 'w') as qfile:  # debugging
    try:
    	with gzip.open(summary_file, 'r') as file, open(summary_direct + '/ctmm_qtl_perm_tophits.csv', 'w') as outfile:
    	    outfile.write(
    	        'lead_SNP' + ',' + 'e_SNP' + ',' + 'pos_tag_snp' + ',' + 'e_Gene - probe' + ',' + 'nom_p_value' + ',' + 'perm_p_value' + ',' + 'approx_perm_p_value' + ',' + 'rsquared' + ',' + 'FDR' + '\n')
    	    for regel in file.readlines():
    	        line = regel.split(',')
    	        # print line[23]
    	        try:
    	            # if float(line[23]) > '0.05': # pval
    	            #     print line
    	            #     continue
    	            # if line[3] == 'NR': # no rsquared > 0.6
    	            #     continue
    	            # if clump == 'Y': # in case clumped results are asked filter the lows out
    	            #     if line[3] < '0.8': # no rsquared > 0.8
    	            #     # print line
    	            #         continue
    	            # with open('/Users/slidetoolkit/Desktop/Jacco/scriptie_data/CADsnps_st_covs_rsquare_0.8/' + line[0] + '.txt', 'a+') as outfile: # write file with info per lead snp
    	            #     outfile.write(regel)
    	            snp = line[0]
    	            var = line[2]
    	            nom_pval = float(line[23])
    	            perm_pval = float(line[24])
    	            approx_pval = float(line[25])
    	            pos_tag_snp = line[5]
    	            rsq = line[3]
    	            chr = line[4]
    	            probe = line[1]
    	            fdr = line[28]
    	            # nominal
    	            # if snp not in snp_list and snp != 'Locus' and snp not in perm_snps:
    	            #     snp_list.append(snp)
    	            # permuted
    	            if snp not in snp_list and snp != 'Locus': #All SNP's in list, skipping header
    	                snp_list.append(snp)
    	            data.append(
    	                {'snp': snp, 'var': var, 'nom_pval': nom_pval, 'perm_pval': perm_pval, 'approx_pval': approx_pval,
    	                 'rsquare': rsq, 'chr': chr, 'pos_tag': pos_tag_snp, 'probe': probe, 'fdr': fdr})
    	        except ValueError:
    	            continue
	
    	    interesting_snps = []  # save tag snps
    	    interesting_genes = []  # save eqtl genes
    	    print 'Parsing data, results so far:'
    	    for SNP in snp_list:  # find all top tag SNPs for the lead SNP's with LD buddies.
    	        # if SNP != 'rs4593108':
    	        #     continue
    	        lowest_pval = 1
    	        top_variant = ''
    	        perm_pval = ''
    	        approx_pval = ''
    	        RSQ = ''
    	        chr = ''
    	        pos = ''
    	        probe = ''
    	        # print top_variant
    	        for item in data:
    	            if item['snp'] == SNP:
    	                # print item
    	                # print lowest_pval
    	                # print item['nom_pval']
    	                # nom
    	                # if item['nom_pval'] < lowest_pval:
    	                if item['approx_pval'] < lowest_pval:
    	                    # print lowest_pval
    	                    # nom
    	                    # lowest_pval = item['nom_pval']
    	                    # perm
    	                    lowest_pval = item['approx_pval']
    	                    nom_pval = item['nom_pval']
    	                    perm_pval = item['perm_pval']
    	                    approx_pval = item['approx_pval']
    	                    # print top_variant
    	                    top_variant = item['var']
    	                    chr = item['chr']
    	                    pos = item['pos_tag']
    	                    probe = item['probe']
    	                    if top_variant == SNP:
    	                        RSQ = 1
    	                    else:
    	                        RSQ = item['rsquare']
    	                else:
    	                    continue
    	        print '\n' + SNP
    	        # inf_list = top_variant + '\t' + chr + '\t' + pos + '\n'
    	        print top_variant
    	        print lowest_pval
    	        print RSQ
    	        # print inf_list
    	        # outfile.write('\n' + SNP + ',' + top_variant + ',' + str(lowest_pval) + ',' + str(RSQ))
    	        # nom
    	        # with gzip.open("qtl_summary/ctmm_QC_qtlnom_clumped_summary.txt.gz", 'r') as file:  # debugging
    	        # perm
    	        # with gzip.open("qtl_summary/ctmm_QC_qtlperm_clumped_summary.txt.gz", 'r') as file:  # debugging
    	        with gzip.open(summary_file, 'r') as file:
    	            for regel in file.readlines():
    	                line = regel.split(',')
    	                if line[0] == SNP and line[2] == top_variant and line[1] == probe or (
    	                        line[0] == SNP and line[2] == SNP) and float(line[23]) <= 0.05:
    	                    permuted_snps.append(line[0])
    	                    RSQ = ''
    	                    # qfile.write(line[28])
    	                    inf_list = line[2] + '\t' + line[1] + '\t' + chr + '\t' + pos + '\n' # line2 is top SNP
    	                    interesting_snps.append(inf_list)
    	                    if line[0] == line[2]:
    	                        RSQ = 1
    	                    else:
    	                        RSQ = line[3]
	
    	                    interesting_genes.append(line[15])
    	                    outfile.write(
    	                        SNP + ',' + line[2] + ',' + line[5] + ',' + line[15] + ' - ' + line[1] + ',' + str(
    	                            float(line[23]))
    	                        + ',' + str(  # commend for nom
    	                            float(line[24])) + ',' + str(  # commend for nom
    	                            float(line[25]))  # commend for nom
    	                        + ',' + str(RSQ) + ',' + line[28])
	
    	        # nom
    	        # with open('r06_nominal_interesting_variants.list', 'w') as igfile, open('r06_nominal_interesting_genes.list', 'w') as ivfile:
    	        # perm
    	        # with open('r06_perm_interesting_variants.list', 'w') as igfile, open('r06_perm_interesting_genes.list',
    	        #                                                                      'w') as ivfile:
    	        with open(summary_direct + '/interesting_variants_permuted.list', 'w') as ivfile, open(summary_direct + '/interesting_genes_permuted.list', 'w') as igfile:
	
    	            for isnp in interesting_snps:
    	                # print isnp
    	                ivfile.write(isnp)
    	            for gen in set(interesting_genes):
    	                igfile.write(gen + '\n')
	
    	return permuted_snps
    except IOError:
    	print "Probably TRANS analysis with broken QTLTool version, no permuted result available"

def second():
    data = []
    snp_list = []
    permuted_snps = search()
    print permuted_snps
    with gzip.open(nom_summary_file, 'r') as file, open(summary_direct + '/ctmm_qtl_nom_tophits.csv', 'w') as outfile:
        outfile.write(
            'lead_SNP' + ',' + 'e_SNP' + ',' + 'pos_tag_snp' + ',' + 'e_Gene - probe' + ',' + 'nom_p_value' + ',' + 'rsquared' + ',' + 'FDR' + '\n')
        for regel in file.readlines():
            line = regel.split(',')
            if line[0] in permuted_snps:
                continue
            # print line[23]
            try:
                # if float(line[23]) > '0.05': # pval
                #     print line
                #     continue
                # if line[3] == 'NR': # no rsquared > 0.6
                #     continue
                # if clump == 'Y': # in case clumped results are asked filter the lows out
                #     if line[3] < '0.8': # no rsquared > 0.8
                #     # print line
                #         continue
                # with open('/Users/slidetoolkit/Desktop/Jacco/scriptie_data/CADsnps_st_covs_rsquare_0.8/' + line[0] + '.txt', 'a+') as outfile: # write file with info per lead snp
                #     outfile.write(regel)
                snp = line[0]
                var = line[2]
                nom_pval = float(line[23])
                #perm_pval = float(line[24])
                #approx_pval = float(line[25])
                pos_tag_snp = line[5]
                rsq = line[3]
                chr = line[4]
                probe = line[1]
                fdr = line[26]
                # nominal
                # if snp not in snp_list and snp != 'Locus' and snp not in perm_snps:
                #     snp_list.append(snp)
                # permuted
                if snp not in snp_list and snp != 'Locus': #All SNP's in list, skipping header
                    snp_list.append(snp)
                data.append(
                    {'snp': snp, 'var': var, 'nom_pval': nom_pval,
                     'rsquare': rsq, 'chr': chr, 'pos_tag': pos_tag_snp, 'probe': probe, 'fdr': fdr})
            except ValueError:
                continue

        interesting_snps = []  # save tag snps
        interesting_genes = []  # save eqtl genes
        print 'Parsing data, results so far:'
        for SNP in snp_list:  # find all top tag SNPs for the lead SNP's with LD buddies.
            # if SNP != 'rs4593108':
            #     continue
            lowest_pval = 1
            top_variant = ''
            RSQ = ''
            chr = ''
            pos = ''
            probe = ''
            # print top_variant
            for item in data:
                if item['snp'] == SNP:
                    # print item
                    # print lowest_pval
                    # print item['nom_pval']
                    # nom
                    # if item['nom_pval'] < lowest_pval:
                    if item['nom_pval'] < lowest_pval:
                        # print lowest_pval
                        # nom
                        # lowest_pval = item['nom_pval']
                        # perm
                        lowest_pval = item['nom_pval']
                        nom_pval = item['nom_pval']
                        # print top_variant
                        top_variant = item['var']
                        chr = item['chr']
                        pos = item['pos_tag']
                        probe = item['probe']
                        if top_variant == SNP:
                            RSQ = 1
                        else:
                            RSQ = item['rsquare']
                    else:
                        continue
            print '\n' + SNP
            # inf_list = top_variant + '\t' + chr + '\t' + pos + '\n'
            print top_variant
            print lowest_pval
            print RSQ
            # print inf_list
            # outfile.write('\n' + SNP + ',' + top_variant + ',' + str(lowest_pval) + ',' + str(RSQ))
            # nom
            # with gzip.open("qtl_summary/ctmm_QC_qtlnom_clumped_summary.txt.gz", 'r') as file:  # debugging
            # perm
            # with gzip.open("qtl_summary/ctmm_QC_qtlperm_clumped_summary.txt.gz", 'r') as file:  # debugging
            with gzip.open(nom_summary_file, 'r') as file:
                for regel in file.readlines():
                    line = regel.split(',')
                    if line[0] == SNP and line[2] == top_variant and line[1] == probe or (
                            line[0] == SNP and line[2] == SNP) and float(line[23]) <= 0.05:
                        RSQ = ''
                        # qfile.write(line[28])
                        inf_list = line[2] + '\t' + line[1] + '\t' + chr + '\t' + pos + '\n' # line2 is top SNP
                        interesting_snps.append(inf_list)
                        if line[0] == line[2]:
                            RSQ = 1
                        else:
                            RSQ = line[3]

                        interesting_genes.append(line[15])
                        outfile.write(
                            SNP + ',' + line[2] + ',' + line[5] + ',' + line[15] + ' - ' + line[1] + ',' + str(
                                float(line[23]))
                            + ',' + str(line[3]) + ',' + str(  # commend for nom
                                float(line[26])) + '\n') 

            # nom
            # with open('r06_nominal_interesting_variants.list', 'w') as igfile, open('r06_nominal_interesting_genes.list', 'w') as ivfile:
            # perm
            # with open('r06_perm_interesting_variants.list', 'w') as igfile, open('r06_perm_interesting_genes.list',
            #                                                                      'w') as ivfile:
            with open(summary_direct + '/interesting_variants_nominal.list', 'w') as ivfile, open(summary_direct + '/interesting_genes_nominal.list', 'w') as igfile:

                for isnp in interesting_snps:
                    # print isnp
                    ivfile.write(isnp)
                for gen in set(interesting_genes):
                    igfile.write(gen + '\n')             
        


main()