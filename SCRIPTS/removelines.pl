#!usr/bin/perl 
#
# Remove lines from a (gzipped) file based on a list in another file.
#
# Description: 	removes lines from a (gzipped) file based on a list provided in another
#               file. 
#
# Written by:	Sander W. van der Laan; UMC Utrecht, Utrecht, the Netherlands; 
#               s.w.vanderlaan-2@umcutrecht.nl.
# Version:		1.0
# Update date: 	2016-01-28
#
# Usage:		removedupes.pl [INPUT] [GZIP/NORM] [OUTPUT]
#
# Starting removal
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "+                              REMOVE LINES BASED ON OTHER FILE                          +\n";
print "+                                           V1.0                                         +\n";
print "+                                        28-08-2018                                      +\n";
print "+                             Written by: Sander W. van der Laan                         +\n";
print "+                                                                                        +\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "\n";
print "Hello. I am starting the removal of duplicate lines.\n";
my $time = localtime; # scalar, i.e. non-numeric, context
print "The current date and time is: $time.\n";
print "\n";

#use strict;
#use warnings;

# Three arguments are required: 
# - the input file (IN)
# - whether the input file is zipped (GZIP/NORM)
# - the other file to compare to
# - the output file (OUT)
my $origfile = $ARGV[0]; # first argument
my $compfile = $ARGV[1]; # second argument
my $outfile = $ARGV[2]; # third argument
my $zipped = $ARGV[3]; # second argument
my %hTMP;

# IF/ELSE STATEMENTS
if ($zipped eq "GZIP1") {
	open (IN1, "gunzip -c $origfile |") or die "* ERROR: Couldn't open input file: $!";
	open (IN2, $compfile) or die "* ERROR: Couldn't open input file: $!";

} elsif ($zipped eq "GZIP2") {
	open (IN1, $origfile) or die "* ERROR: Couldn't open input file: $!";
	open (IN2, "gunzip -c $compfile |") or die "* ERROR: Couldn't open input file: $!";

} elsif ($zipped eq "GZIPB") {
	open (IN1, "gunzip -c $origfile |") or die "* ERROR: Couldn't open input file: $!";
	open (IN2, "gunzip -c $compfile |") or die "* ERROR: Couldn't open input file: $!";

} elsif ($zipped eq "NORM") {
	open (IN1, $origfile) or die "* ERROR: Couldn't open input file: $!";
	open (IN2, $compfile) or die "* ERROR: Couldn't open input file: $!";

} else {
    print "* ERROR: Please, indicate the type of input file: gzipped [GZIP] or uncompressed [NORM]!\n";
    print "         (Arguments are case-sensitive.)\n";

}

open (OUT, ">$outfile") or die "* ERROR: Couldn't open output file: $!"; 

while (<IN1>) {
        chomp;
    	push (@array_one, $_);
	}

while (<IN2>) {
        chomp;
        push (@array_two, $_);
        }

my @C = grep { my $x = $_; not grep { $x =~ /\Q$_/i } @array_two } @array_one;

foreach $C (@C) {
print OUT "$C\n";
}

close IN1;
close IN2;
close OUT;

print "Wow. That was a lot of work. I'm glad it's done. Let's have beer, buddy!\n";
my $newtime = localtime; # scalar context
print "The current date and time is: $newtime.\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "\n";
print "\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "+ The MIT License (MIT)                                                                  +\n";
print "+ Copyright (c) 2018 Sander W. van der Laan                                              +\n";
print "+                                                                                        +\n";
print "+ Permission is hereby granted, free of charge, to any person obtaining a copy of this   +\n";
print "+ software and associated documentation files (the \"Software\"), to deal in the           +\n";
print "+ Software without restriction, including without limitation the rights to use, copy,    +\n";
print "+ modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,    +\n";
print "+ and to permit persons to whom the Software is furnished to do so, subject to the       +\n";
print "+ following conditions:                                                                  +\n";
print "+                                                                                        +\n";
print "+ The above copyright notice and this permission notice shall be included in all copies  +\n";
print "+ or substantial portions of the Software.                                               +\n";
print "+                                                                                        +\n";
print "+ THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,    +\n";
print "+ INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A          +\n";
print "+ PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT     +\n";
print "+ HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF   +\n";
print "+ CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE   +\n";
print "+ OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                          +\n";
print "+                                                                                        +\n";
print "+ Reference: http://opensource.org.                                                      +\n";
print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";



