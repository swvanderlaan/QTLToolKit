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
The only script the user should use is the `QTLAnalyzer.sh` script in conjunction with a configuration file `qtl.conf`. 

By typing...

```
bash QTLAnalyzer.sh $(pwd)/qtl.conf
```

...the user will control what analysis will be done. Simply typing `bash QTLAnalyzer.sh` will produce an extensive error-message explaining what arguments are expected. Note: it is absolutely pivotal to use `$(pwd)` to indicate the whole path to the configuration file, because this is used by the script(s) for the creation of directories _etc_. 

In addition, there are multiple scripts that work in union or solo. Below a description of each.

**Script** 					| **Description**                                         | **Location**    | **Usage**
----------------------------|---------------------------------------------------------|-----------------|------------------------
*prepare_QTL.sh*            | You can use this scripts to prepare the input-data.     | Root            | Standalone
                            | This script will:                                       |                 | 
                            | - create, and index the 'phenotype' bed-file, _i.e._    |                 | 
                            |   the expression or methylation data.                   |                 | 
                            | - convert VCF files from bgen-files.                    |                 | 
*QTLAnalyzer.sh*            | Analysis script. This is the 'master' script that       | Root            | Main script
                            | controls the whole analysis in conjunction with the     |                 |  
                            | configuration file.                                     |                 | 
*qtl.config*                | The configuration file in which you can add/edit paths  |                 | Configuration
*NominalResultsParser.py*   | Parses the nominal QTL analysis results for downstream  |                 | QTLToolKit
                            | workflow.                                               |                 | 
*QTL_QC.R*                  | Quality control of QTL analysis results.                |                 | QTLToolKit
*QTLChecker.sh*             | Checks and wraps up the QTL analysis results.           | Root            | QTLToolKit
*QTLClumpanator.py*         | Clumps results to focus only on a particular list of    | Root            | QTLToolKit 
                            | variants/loci.                                          |                 |  
*QTLPlotter.sh*             | Creates relevant plots of analysis results, including   | Root            | QTLToolKit
                            | LocusZoom plots after eQTL analysis results. Note:      |                 |
                            | regional association plots are (so far) not possible    |                 |
                            | for mQTL analyses, as there are many CpGs in a typical  |                 |
                            | analysis. This would require a bit more integrated      |                 |
                            | plotting to show the regional effects on proximal CpGs. |                 |
*QTLSummarizer.sh*           | Summarises the QTL-analysis results into a folder, and  | Root            | QTLToolKit
                            | zipped files. Including a small, incomplete analysis    |                 |
                            | report (see [TO DO](#to-do) list below).                |                 |
*QTLSumEditor.py*            | Adds linkage disequilibrium r^2 when `CLUMP="Y"` into   | Root            | QTLToolKit
                            | the summarised results.                                 |                 |
*QTLSumParser.py*           | Parses some of the summarised results when `CLUMP="Y"`. | Root            | QTLToolKit
*parse_clumps_eqtl.pl*      | Script to parse clumps of QTL results.                  | Root/SCRIPTS    | Legacy
*parse_input.py*            |      | Root/SCRIPTS    | QTLToolKit
*BED_Annotation_Creator.R*  | Create appropriate annotation file for QTL analyses.    | Root/SCRIPTS    | Standalone
*BED_Creator_DNAmArrays.R*  | Create the required BED files from DNAmArray data.      | Root/SCRIPTS    | Standalone 
*SE_Creator.R*              | Create a SummarizedExperiment object in R of the        | Root/SCRIPTS    | Standalone
                            | expression, methylation or other 'omics'-data.          |                 |
*parseTable.pl*             | Utility script to parse a table.                        | Root/SCRIPTS    | QTLToolKit/Standalone
*removedupes.pl*            | Remove duplicate lines from a text-table.               | Root/SCRIPTS    | QTLToolKit/Standalone
*runFDR_cis.R*              | Correct for false-discovery rate (FDR), used for        | Root/SCRIPTS    | QTLToolKit
                            | functional density, and Regulatory Trait Cconcordance   |                 |
                            | (RTC), and functional enrichment analysis.              |                 |
*QTLTransHitParser.py*      | Parser of trans-QTL-analysis results.                   | Root            | QTLToolKit (_BETA_)
*runFDR_ftrans.R*           | Correct for FDR, used after trans-QTL-analysis.         | Root/SCRIPTS    | QTLToolKit (_BETA_)
*runFDR_atrans.R*           | Extract and FDR-correct adjusted and permuted trans-    | Root/SCRIPTS    | QTLToolKit (_BETA_)
                            | QTL-analysis results.                                   |                 |
*plotTrans.R*               | Plot trans-QTL analysis results.                        | Root/SCRIPTS    | QTLToolKit (_BETA_)
----------------------------|---------------------------------------------------------|-----------------|------------------------


--------------

#### COMMON WORKFLOW 

\*A schematic will be put here\*.


--------------

#### TO DO
There are definitely improvements needed. Below of things I'd like to add or edit in the (near) future. Priorities are indicated according to MoSCoW (must have, should have, could have, would have)

- [X] - **M** - simplify the configuration using a config-file, similar to [GWASToolKit](http://swvanderlaan.github.io/GWASToolKit/)
- [ ] - **C** - add proper `--help` flag
- [ ] - **C** - clean up codes further, especially with respect to the various error-flags
- [ ] - **C** - add in checks of the environment, similar to `slideToolkit` scripts
- [ ] - **M** - add in some code to produce a simple report
- [ ] - **M** - edit `QTL_QC.R` script
    - [ ] - **S** - to check the delimiter automatically of the annotation file
    - [ ] - **S** - add in the `data.table()` to read and write tables using `fread` or `fwrite`
    - [X] - **M** - the eQTL-part (nom/perm for cis) to match with the new 'strand' column (as the column numbers have changed by the addition of the 'strand' column in the output)
    - [ ] - **M** - double check the trans-QTL-part to match with the new 'strand' column (as the column numbers have changed by the addition of the 'strand' column in the output)
    - [ ] - **M** - double check the mQTL-part to match with the new 'strand' column (as the column numbers have changed by the addition of the 'strand' column in the output)
- [ ] - **C** - add an annotation creation script
- [ ] - **M** - add a routine (somewhere) to remove CpGs (probes) containing SNPs or that map to multiple locations. Refer to: [Zhou W. *et al*. Nucleic Acids Res. 2016](https://www.ncbi.nlm.nih.gov/pubmed/27924034).
- [ ] - **M** - add in script to create BED-files. 

--------------

#### The MIT License (MIT)
##### Copyright (c) 2014-2018 Sander W. van der Laan | s.w.vanderlaan [at] gmail [dot] com.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:   

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Reference: http://opensource.org.
