import gzip
import collections
import time

if not hasattr(time, 'monotonic'):
    time.monotonic = time.time

from pyliftover import LiftOver

GWASRow = collections.namedtuple('GWA', 'ref oth f b se p')
INV = { 'A': 'T', 'T': 'A', 'C': 'G', 'G': 'C', }
ACT_NOP, ACT_SKIP, ACT_FLIP, ACT_REM = 1, 2, 3, 4
GWAS = '/home/llandsmeer/Data/CTMM/cardiogram_gwas_results.txt.gz'
STATS = '/home/llandsmeer/Data/CTMM/ctmm_1kGp3GoNL5_RAW_rsync.stats.gz'

liftover = LiftOver('hg18', 'hg19')

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

def read_gwas(filename):
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
            bp = int(bp)
            conv = liftover.convert_coordinate(ch, bp)
            if conv:
                ch19, bp19, s19, _ = conv[0]
                if ch19.startswith('chr'): ch19 = ch19[3:]
                yield (ch19, bp19), GWASRow(parts[ref], parts[oth], float(parts[freq]),
                                            float(parts[b]), parts[se], parts[p])
            else:
                pass
                # print('conversion failed')
        if lineno % 10000 == 0:
            reporter.update(lineno, 2420300)


def update_read_stats(gwas, stats_filename):
    reporter = ReporterLine('reading genetic data')
    # print('SNP A1 A2 freq b se p n')
    # begin = time.time()
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
        row_pos = parts[ch].lstrip('0'), int(parts[pos])
        gwas_row = gwas.get(row_pos)
        if not gwas_row is None:
            parts = line.split()
            act = select_action(parts[a], parts[b],
                                parts[ma], parts[mi],
                                float(parts[maf]),
                                gwas_row.ref, gwas_row.oth,
                                gwas_row.f)
            freq, beta = gwas_row.f, gwas_row.b
            if act is ACT_FLIP:
                freq = 1-freq
                beta = -beta
            elif act is ACT_REM:
                del gwas[row_pos]
                continue
            elif act is ACT_SKIP:
                continue
            del gwas[row_pos]
            # print(parts[rsid], parts[b], parts[a], freq, beta, gwas_row.se, gwas_row.p, 'NA')
        # if lineno % 100 == 0 and if time.time() - begin > 10: break
        if lineno % 10000 == 0:
            reporter.update(lineno, 88930413)

gwas = {}
for idx, (pos, row) in enumerate(read_gwas(GWAS)):
    gwas[pos] = row
    if idx > 10000:
        break
update_read_stats(gwas, STATS)

# print('leftover', len(gwas))
# for k, v in gwas.items():
    # print(k)
    # print(v)

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
