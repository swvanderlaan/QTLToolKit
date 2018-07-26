#!/bin/bash

# create three ENCODE-based files for functional enrichment analysis
# these were downloaded from: 
# first we 'touch' some files and than we add information to those files
cd /hpc/dhl_ec/svanderlaan/projects/encode/H3K27ac
touch H3K27ac.encode.txt
for i in $(ls *.bed); do 
	tissue=${i%.bed}; 
	echo "* processing tissue [ $tissue ] in file [ $i ]..."; 
	cat $i | awk '{ gsub("chr", "", $1) ; print } '  | awk '{ if($1 < 10) { print "0"$1,$2,$3,$4 } else if($1 =="X") { print "0"$1,$2,$3,$4 } else if($1 == "Y") { print "0"$1,$2,$3,$4 } else {print $1,$2,$3,$4 } }' >> H3K27ac.encode.bed ; 
done

cd /hpc/dhl_ec/svanderlaan/projects/encode/H3K4me1
touch H3K4me1.encode.txt
for i in $(ls *.bed); do 
	tissue=${i%.bed}; 
	echo "* processing tissue [ $tissue ] in file [ $i ]..."; 
	cat $i | awk '{ gsub("chr", "", $1) ; print } '  | awk '{ if($1 < 10) { print "0"$1,$2,$3,$4 } else if($1 =="X") { print "0"$1,$2,$3,$4 } else if($1 == "Y") { print "0"$1,$2,$3,$4 } else {print $1,$2,$3,$4 } }' >> H3K4me1.encode.bed ; 
done

cd /hpc/dhl_ec/svanderlaan/projects/encode/H3K4me3
touch H3K4me3.encode.txt
for i in $(ls *.bed); do 
	tissue=${i%.bed}; 
	echo "* processing tissue [ $tissue ] in file [ $i ]..."; 
	cat $i | awk '{ gsub("chr", "", $1) ; print } '  | awk '{ if($1 < 10) { print "0"$1,$2,$3,$4 } else if($1 =="X") { print "0"$1,$2,$3,$4 } else if($1 == "Y") { print "0"$1,$2,$3,$4 } else {print $1,$2,$3,$4 } }' >> H3K4me3.encode.bed ; 
done

cat /hpc/dhl_ec/svanderlaan/projects/encode/H3K27ac/H3K27ac.encode.alltissues.bed | grep "Monocytes" > /hpc/dhl_ec/svanderlaan/projects/encode/H3K27ac/H3K27ac.encode.monocytescd14pos.bed
cat /hpc/dhl_ec/svanderlaan/projects/encode/H3K4me1/H3K4me1.encode.alltissues.bed | grep "Monocytes" > /hpc/dhl_ec/svanderlaan/projects/encode/H3K4me1/H3K4me1.encode.monocytescd14pos.bed
cat /hpc/dhl_ec/svanderlaan/projects/encode/H3K4me3/H3K4me3.encode.alltissues.bed | grep "Monocytes" > /hpc/dhl_ec/svanderlaan/projects/encode/H3K4me3/H3K4me3.encode.monocytescd14pos.bed