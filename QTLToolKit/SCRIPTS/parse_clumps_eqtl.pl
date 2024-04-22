#!/usr/bin/perl
####################################################################################################
#
# Editor: 			Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl
#					University Medical Center Utrecht
# Original author:	Paul de Bakker, pdebakker@rics.bwh.harvard.edu
#         			Division of Genetics, Brigham and Women's Hospital
#         			Program in Medical and Population Genetics, Broad Institute of MIT and Harvard
#       
# Last update: 2016-06-29
#
#
####################################################################################################
#
# Required input:
#
#
####################################################################################################

use strict;
use Getopt::Long;

my $index;
my $clumpFile;

GetOptions(
	   "file=s"       => \$clumpFile,
	   "snp=s"         => \$index,
           );

if ( $clumpFile eq "" || $index eq "" ) { 
  print STDERR "Usage: %> parse_clumps_eqtl.pl --file clump_file --snp index_snp\n";
  exit;
}

my $toggle = 0;

################################################################################
################################################################################
###
### read in clumps
###
################################################################################
################################################################################
# NOTE: ANNOT = BETA,SE,EAF
#CHR    F             SNP         BP          P    TOTAL   NSIG    S05    S01   S001  S0001
#   9    1       rs2891168   22098619   2.29e-98      167      0      0      0      0    167 
#
#                                  KB      RSQ  ALLELES    F            P        ANNOT
#  (INDEX)       rs2891168          0    1.000        G    1     2.29e-98 A, G, -.193401, .0091877, .511332
#
#                rs2518723       -103    0.224    GC/AT    1     1.18e-23 C, T, .09531, .0095071, .528334
#               rs61271866       -102    0.222    GT/AA    1     2.43e-25 T, A, .112191, .0107857, .734317
#                rs3218020       -101    0.399    GA/AG    1     6.92e-40 G, A, -.126496, .0095701, .632861
#
#FIELDS				0				1		2		3		4		5	  6	 7		8		9		10		
print "SNP KB RSQR P EFFECT_ALLELE OTHER_ALLELE BETA SE EAF\n"; 

open (CLUMP, $clumpFile) or die "cannot open $clumpFile\n";
while(my $c = <CLUMP>){
  chomp $c;
  $c =~ s/^\s+//;
  $c =~ s/,//g;
  my @fields = split /\s+/, $c;

  if ( $fields[0] eq "(INDEX)" && $index eq $fields[1] ) { 
    shift @fields;
#    print join " ", @fields;   
    print "$fields[0] $fields[1] $fields[2] $fields[5] $fields[6] $fields[7] $fields[8] $fields[9] $fields[10]\n";
    $toggle = 1; 
    my $void = <CLUMP>; 
    next;
  }

  if ( $toggle == 1 ) { 
    if ( $#fields > 2 ) { 
      print "$fields[0] $fields[1] $fields[2] $fields[5] $fields[6] $fields[7] $fields[8] $fields[9] $fields[10]\n";
    } else { $toggle = 0; }
  } 
}
close(CLUMP);


