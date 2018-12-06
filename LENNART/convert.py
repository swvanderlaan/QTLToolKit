'''
gen eff/oth | gwas eff/oth | eff freq gen/gwas | act

# non ambivalent
A G | A G |  _   _  | nothing
A G | T C |  _   _  | nothing
A G | G A |  _   _  | flip freq, flip beta
A G | C T |  _   _  | flip freq, flip beta

# ambivalent alleles
## freqs close and low/high
G C | G C | 0.1 0.1 | nothing
G C | C G | 0.1 0.1 | nothing

## freqs inverted and low/high
G C | G C | 0.1 0.9 | flip freq, flip beta
G C | C G | 0.1 0.9 | flip freq, flip beta

## freqs close and mid
G C | C G | 0.5 0.6 | throw away
G C | G C | 0.5 0.6 | throw away
'''

from __future__ import print_function

import os
import argparse
import collections
import gzip
import time

from pyliftover import LiftOver

GWAS = '/home/llandsmeer/Data/CTMM/cardiogram_gwas_results.txt.gz'
STATS = '/home/llandsmeer/Data/CTMM/ctmm_1kGp3GoNL5_RAW_rsync.stats.gz'

parser = argparse.ArgumentParser()
parser.add_argument('-o', '--out', dest='outfile', metavar='cojo',
        type=os.path.abspath, help='Output .cojo file')
parser.add_argument('-r', '--report', dest='report', metavar='txt',
        type=os.path.abspath, help='Report here')
parser.add_argument('-g', '--gen', dest='gen', metavar='file.stats.gz', default=STATS,
        type=os.path.abspath, help='Genetic data', required=False) # TODO
parser.add_argument('--gwas', dest='gwas', metavar='file.txt.gz.', default=GWAS,
        type=os.path.abspath, help='illuminaHumanv4 sqlite database path', required=False) # TODO

# Optimizations, with speeds measured on my laptop
#  680.2klines/s first version
#  802.7klines/s line.split(None, maxsplit)
#                in the hot path, only split until enough fields have
#                been read to read chr and bp
#  871.8klines/s int(bp) -> bp
#                storing basepair position as a string in the gwas dict
#                prevents a call to int(bp) in reading the genetic data
#  914.4klines/s gwas.get -> gwas[pos]
#                first checking if a item is in a dictionary and then
#                retrieving it is faster here than the combined operation
#  969.4klines/s chr 1 -> 01
#                in the gwas dictionary, chrs are stored in the .stats.gz
#                format with leading 0 to prevent a call to str.lstrip
# 1635.6klines/s max IO bound, no useful calculations

if not hasattr(time, 'monotonic'):
    time.monotonic = time.time
if not hasattr(os.path, 'commonpath'):
    os.path.commonpath = os.path.commonprefix

GWASRow = collections.namedtuple('GWA', 'ref oth f b se p lineno')
INV = { 'A': 'T', 'T': 'A', 'C': 'G', 'G': 'C', }
ACT_NOP, ACT_SKIP, ACT_FLIP, ACT_REM = 1, 2, 3, 4

liftover = LiftOver('hg18', 'hg19')

class ReporterLine:
    def __init__(self, line=''):
        self.line = line
        self.last_time = time.monotonic()
        self.last_lineno = 0
        print()
    def update(self, lineno, end):
        now = time.monotonic()
        dt = now - self.last_time
        dlineno = lineno - self.last_lineno
        print('\033[1A\033[K', end='')
        print(self.line, lineno, str(round(lineno/end*100, 1))+'%', str(round(dlineno/dt/1000, 1))+'klines/s')

def inv(dna):
    if len(dna) == 1:
        return INV[dna]
    return ''.join(INV[bp] for bp in dna)

def select_action(gen_a, gen_b,
         gen_maj, gen_min,
         gen_maf,
         gwas_ref, gwas_oth,
         gwas_ref_freq):
    # b is the effect allele
    gen_b_freq = gen_maf if gen_b == gen_min else 1 - gen_maf
    freq_close = abs(gen_b_freq - gwas_ref_freq) < 0.45
    freq_mid = abs(gen_b_freq - 0.5) < 0.10
    ambivalent = gen_a == inv(gen_b)
    if not ambivalent:
        if gen_b == gwas_ref and gen_a == gwas_oth:
            return ACT_NOP
        elif gen_b == gwas_oth and gen_a == gwas_ref:
            return ACT_FLIP
        elif gen_b == inv(gwas_ref) and gen_a == inv(gwas_oth):
            return ACT_NOP
        elif gen_b == inv(gwas_oth) and gen_a == inv(gwas_ref):
            return ACT_FLIP
        else:
            return ACT_SKIP
    else:
        if gen_b == gwas_ref and gen_a == gwas_oth:
            equal = True
        elif gen_a == gwas_ref and gen_b == gwas_oth:
            equal = False
        else:
            return ACT_SKIP
        if freq_mid:
            return ACT_REM
        if freq_close:
            return ACT_NOP
        else:
            return ACT_FLIP

def read_gwas(filename, report=None):
    yes = no = 0
    reporter = ReporterLine('reading gwas data')
    for lineno, line in enumerate(gzip.open(filename, 'rt'), 1):
        if lineno == 1:
            header = line.split()
            pos = header.index('chr_pos_(b36)')
            ref = header.index('reference_allele')
            oth = header.index('other_allele')
            freq = header.index('ref_allele_frequency')
            b = header.index('log_odds')
            se = header.index('log_odds_se')
            p = header.index('pvalue')
        else:
            parts = line.split()
            ch, bp = parts[pos].split(':', 1)
            conv = liftover.convert_coordinate(ch, int(bp))
            if conv:
                ch19, bp19, s19, _ = conv[0]
                if ch19.startswith('chr'): ch19 = ch19[3:]
                ch19 = ch19.zfill(2)
                yield (ch19, str(bp19)), GWASRow(parts[ref], parts[oth], float(parts[freq]),
                                            float(parts[b]), parts[se], parts[p], lineno)
                yes += 1
            else:
                no += 1
                if report:
                    print('gwas hg18->hg19 conversion failed', file=report)
                    print('   ', lineno, *parts, sep='\t', file=report)
                    print(file=report)
        if lineno % 10000 == 0:
            reporter.update(lineno, 2420300)
    print('successfully hg18->hg19 converted', yes, 'rows')
    print('conversion failed for', no, 'rows')

def update_read_stats(gwas, stats_filename, output=None, report=None):
    reporter = ReporterLine('reading genetic data')
    if output:
        print('SNP A1 A2 freq b se p n', file=output)
    counts = collections.defaultdict(int)
    for lineno, line in enumerate(gzip.open(stats_filename, 'rt'), 1):
        if not gwas:
            break
        if lineno == 1:
            header = line.split()
            rsid = header.index('RSID')
            ch = header.index('Chr')
            pos = header.index('BP')
            a = header.index('A_allele')
            b = header.index('B_allele')
            mi = header.index('MinorAllele')
            ma = header.index('MajorAllele')
            maf = header.index('MAF')
            minsplit = max(ch, pos) + 1
            continue
        parts = line.split(None, minsplit)
        row_pos = parts[ch], parts[pos]
        if row_pos in gwas:
            gwas_row = gwas[row_pos]
            parts = line.split()
            act = select_action(parts[a], parts[b],
                                parts[ma], parts[mi],
                                float(parts[maf]),
                                gwas_row.ref, gwas_row.oth,
                                gwas_row.f)
            freq, beta = gwas_row.f, gwas_row.b
            if act is ACT_FLIP:
                counts['flip'] += 1
                freq = 1-freq
                beta = -beta
            elif act is ACT_REM:
                counts['remove'] += 1
                del gwas[row_pos]
                if report:
                    print('removing gwas row due insufficient information on ambivalent allele', file=report)
                    print(line, file=report, end='')
                    print(gwas_row, file=report)
                    print(file=report)
                continue
            elif act is ACT_SKIP:
                counts['skip'] += 1
                if report:
                    print('skipping gwas row due to non matching alleles', file=report)
                    print(line, file=report, end='')
                    print(gwas_row, file=report)
                    print(file=report)
                continue
            else:
                counts['ok'] += 1
            del gwas[row_pos]
            if output:
                print(parts[rsid], parts[b], parts[a], freq, beta, gwas_row.se, gwas_row.p, 'NA', file=output)
        if lineno % 10000 == 0:
            reporter.update(lineno, 88930413)
    print('gwas allele conversions:')
    for k, v in counts.items():
        print(' ', k, v)
        if report:
            print(' ', k, v, file=report)
    print('leftover gwas row count', len(gwas))
    if report:
        print(file=report)
        print('LEFTOVER GWAS ROWS', file=report)
        for (ch, pos), row in gwas.items():
            print(ch, pos, row, file=report)

def main(args):
    paths = [args.gen, args.gwas]
    output = report = None
    if args.outfile:
        output = open(args.outfile, 'w')
        paths.append(args.report)
    if args.report:
        report = open(args.report, 'w')
        paths.append(args.report)
    root = os.path.commonpath(paths)
    print('root', root)
    print('genetic data', os.path.relpath(args.gen, root))
    print('gwas', os.path.relpath(args.gwas, root))
    if args.outfile:
        print('output', os.path.relpath(args.outfile, root))
    else:
        print('WARNING not writing results (-o)')
    if args.report:
        print('output', os.path.relpath(args.report, root))
    else:
        print('WARNING not writing report (-r)')
    gwas = {}
    for idx, (pos, row) in enumerate(read_gwas(args.gwas, report=report)):
        gwas[pos] = row
    update_read_stats(gwas, args.gen, output=output, report=report)
    if args.outfile:
        output.close()
    if args.report:
        report.close()

if __name__ == '__main__':
    args = parser.parse_args()
    main(args)
