QTLToolKit
============
[![DOI](https://zenodo.org/badge/101641410.svg)](https://zenodo.org/badge/latestdoi/101641410)

**QTLToolKit** is a pipeline written in the BASH, Perl and Python languages to run *cis-* or *trans-* [quantitative trait loci analyses](https://www.nature.com/scitable/topicpage/quantitative-trait-locus-qtl-analysis-53904) using [QTLtools](https://qtltools.github.io/qtltools/) efficiently. It will aid in selecting the region, get descriptive statistics on the variants used, parse results, create diagnostic plots where necessary, create [LocusZoom style](https://genome.sph.umich.edu/wiki/LocusZoom_Standalone) plots when needed, and concatenate everything in tables. 

All scripts are annotated for debugging purposes - and future reference. The scripts will work within the context of a certain Linux environment (in this case a CentOS7 system on a SUN Grid Engine background). As such we have tested **QTLToolKit** on CentOS6.6, CentOS7, and OS X El Capitan (version 10.11.[x]). 


--------------

#### Installing the scripts locally

You can use the scripts locally to run analyses on a Unix-based system, like Mac OS X (Mountain Lion+). We need to make an appropriate directory to download 'gits' to, and install this 'git'.

##### Step 1: make a directory, and go there.

```
mkdir -p ~/git/ && cd ~/git
```

##### Step 2: clone this git, unless it already exists.

```
if [ -d ~/git/QTLToolKit/.git ]; then \
		cd ~/git/QTLToolKit && git pull; \
	else \
		cd ~/git/ && git clone https://github.com/swvanderlaan/QTLToolKit.git; \
	fi
```

--------------

#### USAGE 
The only script the user should use is the `[cis/trans]QTLAnalyzer.sh` script in conjunction with a configuration file `qtl.conf`. 

By typing...

```
bash [cis/trans]QTLAnalyzer.sh $(pwd)/qtl.conf
```

...the user will control what analysis will be done. Simply typing `bash [cis/trans]QTLAnalyzer.sh` will produce an extensive error-message explaining what arguments are expected. Note: it is absolutely pivotal to use `$(pwd)` to indicate the whole path to the configuration file, because this is used by the script(s) for the creation of directories _etc._ 

In addition, there are multiple scripts that work in union or solo. Below a description of each.

- *prepare_QTL.sh*
You can use this scripts to prepare the input-data. This script will 
    - create, and index the 'phenotype' bed-file, _i.e._ the expression or methylation data.
    - convert VCF files from bgen-files.
    

\*Further instructions will follow\*.


--------------

#### COMMON WORKFLOW 

\*A schematic will be put here\*.


--------------

#### TO DO
There are definitely improvements needed. Below of things I'd like to add or edit in the (near) future.

- simplify the configuration using a config-file, similar to [GWASToolKit](http://swvanderlaan.github.io/GWASToolKit/)
- add proper `--help` flag
- clean up codes further, especially with respect to the various error-flags
- add in checks of the environment, similar to `slideToolkit` scripts
- add in some code to produce a simple report
- edit `QTL_QC.R` script
    - to check the delimiter automatically of the annotation file
    - add in the `data.table()` to read and write tables using `fread` or `fwrite`
- add an annotation creation script

--------------

#### The MIT License (MIT)
##### Copyright (c) 2014-2018 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:   

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Reference: http://opensource.org.
