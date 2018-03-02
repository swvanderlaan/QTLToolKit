#!/usr/bin/python

print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
print "                              QTLTools Summary Parser"
print ""
print ""
print "* Written by         : Jacco Schaap | jacco_schaap@hotmail.com"
print "* Suggested for by   : Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl"
print "* Last update        : 2018-03-01"
print "* Name               : QTLSumParser"
print "* Version            : v1.0.2"
print ""
print "* Description        : This script parses QTL summary results to obtain lists of"
print "                       variants in LD with lead-variants."
print ""
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

from sys import argv
import gzip

clump = argv[1] # Y for clumped results, N for normal results
summary_file = argv[2] # Permuted summary file that needs to be parsed 
nom_summary_file = argv[3] # Nominal summary file that needs to be parsed
summary_direct = argv[4] # Directory to put results in
qtl_type = argv[5] # CIS or TRANS

def main():
	#search()
	second()


def search():
	data = []
	snp_list = []
	permuted_snps = []
	all_snps = []
	try:
		with gzip.open(summary_file, 'r') as file, open(summary_direct + '/ctmm_qtl_perm_tophits.csv', 'w') as outfile:
			outfile.write(
				'lead_SNP' + ',' + 'e_SNP' + ',' + 'pos_tag_snp' + ',' + 'e_Gene' +  'probe' + ',' + 'nom_p_value' + ',' + 'perm_p_value' + ',' + 'approx_perm_p_value' + ',' + 'rsquared' + ',' + 'FDR' + '\n')
			for regel in file.readlines():
				line = regel.split(',')
				all_snps.append(line[0])
				# print line[23]
				try:
					# PERMUTED RESULTS
					# 0 Locus, 1 ProbeID, 2 VARIANT, 3 RSquare, 4 Chr, 5 BP, 6 OtherAlleleA, 7 CodedAlleleA,
					# 8 MAF, 9 MAC, 10 CAF, 11 HWE, 12 Info, 14 Imputation, 15 N, 16 GeneName, 17 EntrezID,
					# 18 Distance_VARIANT_GENE, 19 Chr, 20 GeneTxStart, 21 GeneTxEnd, 22 Beta, 23 SE,
					# 24 Nominal_P, 25 Perm_P, 26 ApproxPerm_P, 27 Bonferroni, 28 BenjHoch, 29 Q
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
						if item['approx_pval'] < lowest_pval:
							lowest_pval = item['approx_pval']
							nom_pval = item['nom_pval']
							perm_pval = item['perm_pval']
							approx_pval = item['approx_pval']
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
				print '\nLead variant: [ ' + SNP + ' ].'
				print '\nTop tagging variant: [ ' + top_variant + ' ]. Note that this could be the same as the lead variant.'
				print '\nThe lowest reported p-value: [ ' + str(lowest_pval) + ' ].'
				print '\nThe r-square between lead variant [' + SNP + '] and the top tagging variant [' + top_variant + '] is: [' + str(RSQ) + '].'
				with gzip.open(summary_file, 'r') as file:
					for regel in file.readlines():
						line = regel.split(',')
						if line[0] == SNP and line[2] == top_variant and line[1] == probe or (
								line[0] == SNP and line[2] == SNP) and float(line[23]) <= 0.05:
							permuted_snps.append(line[0])
							RSQ = ''
							inf_list = line[2] + '\t' + line[1] + '\t' + chr + '\t' + pos + '\n' # line2 is top SNP
							interesting_snps.append(inf_list)
							if line[0] == line[2]:
								RSQ = 1
							else:
								RSQ = line[3]
	
							interesting_genes.append(line[15])
							outfile.write(
								SNP + ',' + line[2] + ',' + line[5] + ',' + line[15] + ',' + line[1] + ',' + str(
									float(line[23]))
								+ ',' + str(  # command for nom
									float(line[24])) + ',' + str(  # command for nom
									float(line[25]))  # command for nom
								+ ',' + str(RSQ) + ',' + line[28])
					with open(summary_direct + '/interesting_variants_permuted.list', 'w') as ivfile, open(summary_direct + '/interesting_genes_permuted.list', 'w') as igfile:
	
					for isnp in interesting_snps:
						# print isnp
						ivfile.write(isnp)
					for gen in set(interesting_genes):
						igfile.write(gen + '\n')
		verschil = list(set(all_snps) - set(permuted_snps))
		print 'Difference between lists: ' + str(verschil)
		return permuted_snps
	except IOError:
		print "Probably TRANS analysis with broken QTLTool version, no permuted result available."

def second():
	data = []
	snp_list = []
	permuted_snps = search()
	nominale_resultaten = []
	print permuted_snps
	print 'Number of permuted hits: ' + str(len(permuted_snps))
	print nom_summary_file
	with gzip.open(nom_summary_file, 'r') as file, open(summary_direct + '/ctmm_qtl_nom_tophits.csv', 'w') as outfile:
		outfile.write(
			'lead_SNP' + ',' + 'e_SNP' + ',' + 'pos_tag_snp' + ',' + 'e_Gene' + 'probe' + ',' + 'nom_p_value' + ',' + 'rsquared' + ',' + 'FDR' + '\n')
		for regel in file.readlines():
			line = regel.split(',')
			if line[0] not in nominale_resultaten:
				nominale_resultaten.append(line[0])
			try:
				if line[0] in permuted_snps:
					continue
			except TypeError:
				pass
			# print line[23]
			try:
				# PERMUTED RESULTS
				# 0 Locus, 1 ProbeID, 2 VARIANT, 3 RSquare, 4 Chr, 5 BP, 6 OtherAlleleA, 7 CodedAlleleA,
				# 8 MAF, 9 MAC, 10 CAF, 11 HWE, 12 Info, 14 Imputation, 15 N, 16 GeneName, 17 EntrezID,
				# 18 Distance_VARIANT_GENE, 19 Chr, 20 GeneTxStart, 21 GeneTxEnd, 22 Beta, 23 SE,
				# 24 Nominal_P, 25 Perm_P, 26 ApproxPerm_P, 27 Bonferroni, 28 BenjHoch, 29 Q
				snp = ''
				var = ''
				nom_pval = ''
				rsq = ''
				chr = ''
				pos_tag_snp = ''
				probe = ''
				fdr = ''
				if qtl_type == 'CIS':
					snp = line[0]
					var = line[2]
					nom_pval = float(line[24])
					pos_tag_snp = line[5]
					rsq = line[3]
					chr = line[4]
					probe = line[1]
					fdr = line[28] # we use this in the meantime, as the qvalue() package (FDR) doesn't work'
					
				if qtl_type == 'TRANS':
					snp = line[0]
					var = line[2]
					nom_pval = float(line[24])
					pos_tag_snp = line[4]
					rsq = '0'
					chr = line[3]
					probe = line[1]
					fdr = line[28] # we use this in the meantime, as the qvalue() package (FDR) doesn't work'
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
			lowest_pval_1 = 1
			top_variant_1 = ''
			RSQ_1 = ''
			chr_1 = ''
			pos_1 = ''
			probe_1 = ''
			# print top_variant
			for item in data:
				if item['snp'] == SNP:
					if item['nom_pval'] < lowest_pval_1:
						lowest_pval_1 = item['nom_pval']
						nom_pval = item['nom_pval']
						# print top_variant
						top_variant_1 = item['var']
						chr_1 = item['chr']
						pos_1 = item['pos_tag']
						probe_1 = item['probe']
						if top_variant_1 == SNP:
							RSQ_1 = 1
						else:
							RSQ_1 = item['rsquare']
					else:
						continue
			print '\n' + SNP
			print top_variant_1
			print lowest_pval_1
			print RSQ_1
			with gzip.open(nom_summary_file, 'r') as file:
				for regel in file.readlines():
					line = regel.split(',')
					nom_pval_1 = ''
					try:
						if qtl_type == 'CIS':
							nom_pval_1 = float(line[24])
						if qtl_type == 'TRANS':
							nom_pval_1 = float(line[22])
					except ValueError:
						continue
					if line[0] == SNP and line[2] == top_variant_1 and line[1] == probe_1 or (line[0] == SNP and line[2] == SNP) and nom_pval_1 <= 0.05:
						print nom_pval_1
						RSQ = ''
						# qfile.write(line[28])
						inf_list = var + '\t' + line[1] + '\t' + chr_1 + '\t' + pos_1 + '\n' # line2 is top SNP
						interesting_snps.append(inf_list)
						if line[0] == line[2]:
							RSQ_1 = 1
						else:
							RSQ_1 = line[3]

						interesting_genes.append(line[15])
						outfile.write(
							SNP + ',' + line[2] + ',' + line[5] + ',' + line[14] + ',' + line[1] + ',' + str(
								float(line[22]))
							+ ',' + str(line[3]) + ',' + str(  # command for nom
								float(line[25])) + '\n')

			with open(summary_direct + '/interesting_variants_nominal.list', 'w') as ivfile, open(summary_direct + '/interesting_genes_nominal.list', 'w') as igfile:

				for isnp in interesting_snps:
					# print isnp
					ivfile.write(isnp)
				for gen in set(interesting_genes):
					igfile.write(gen + '\n')
	verschil = list(set(permuted_snps) - set(nominale_resultaten))
	print verschil
main()