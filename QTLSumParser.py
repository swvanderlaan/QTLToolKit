#!/usr/bin/python

print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
print "                              QTLTools Summary Parser"
print ""
print ""
print "* Written by         : Jacco Schaap | jacco_schaap@hotmail.com"
print "* Suggested for by   : Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl"
print "* Last update        : 2018-02-21"
print "* Name               : QTLSumParser"
print "* Version            : v1.0.0"
print ""
# print "* Description        : In case of a CTMM eQTL analysis this script will collect all "
# print "                       analysed genes and list their associated ProbeIDs as well as the"
# print "                       number of variants analysed."
# print "                       In case of a AEMS mQTL analysis this script will collect all "
# print "                       analysed CpGs and their associated genes, as well as the "
# print "                       the number of variants analysed."
# print "                       In both cases it will produce a LocusZoom (v1.2+) input file"
# print "                       which contains the variant associated (MarkerName) and the "
# print "                       p-value (P-value)."
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
	# nom
	# with gzip.open("qtl_summary/ctmm_QC_qtlnom_clumped_summary.txt.gz", 'r') as file, open('ctmm_nom_qtl_tophits.txt', 'w') as outfile:  # debugging
	# perm
	# with gzip.open("qtl_summary/ctmm_QC_qtlperm_clumped_summary.txt.gz", 'r') as file, open('ctmm_perm_qtl_tophits.txt',
	#                                                                                         'w') as outfile, open(
	#         'q.list', 'w') as qfile:  # debugging
	try:
		with gzip.open(summary_file, 'r') as file, open(summary_direct + '/ctmm_qtl_perm_tophits.csv', 'w') as outfile:
			outfile.write(
				'lead_SNP' + ',' + 'e_SNP' + ',' + 'pos_tag_snp' + ',' + 'e_Gene' +  'probe' + ',' + 'nom_p_value' + ',' + 'perm_p_value' + ',' + 'approx_perm_p_value' + ',' + 'rsquared' + ',' + 'FDR' + '\n')
			for regel in file.readlines():
				line = regel.split(',')
				all_snps.append(line[0])
				# print line[23]
				try:
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
								SNP + ',' + line[2] + ',' + line[5] + ',' + line[15] + ',' + line[1] + ',' + str(
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
		verschil = list(set(all_snps) - set(permuted_snps))
		print 'Verschil tussen lijsten: ' + str(verschil)
		return permuted_snps
	except IOError:
		print "Probably TRANS analysis with broken QTLTool version, no permuted result available"

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

				# 0 Locus, 1 ProbeID, 2 VARIANT, 3 Chr, 4 BP, 5 OtherAlleleA, 6 CodedAlleleA, 7 MAF, 8 MAC, 9 CAF, 10 HWE,
				# 11 Info, 12 Imputation, 13 N, 14 GeneName, 15 EntrezID, 16 Distance_VARIANT_GENE, 17 Chr, 18 GeneTxStart, 19 GeneTxEnd, 20 Beta,
				# 21 SE, 22 Nominal_P, 23 Bonferroni, 24 BenjHoch, 25 Q
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
					nom_pval = float(line[23])
					pos_tag_snp = line[5]
					rsq = line[3]
					chr = line[4]
					probe = line[1]
					fdr = line[26]
					
				if qtl_type == 'TRANS':
					snp = line[0]
					var = line[2]
					nom_pval = float(line[22])
					pos_tag_snp = line[4]
					rsq = '0'
					chr = line[3]
					probe = line[1]
					fdr = line[25]    		
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
							nom_pval_1 = float(line[23])
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
							+ ',' + str(line[3]) + ',' + str(  # commend for nom
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