#!/usr/bin/env python
#
#
# POSITION CONVERSION
# 1     -> 01
# chr3  -> 03
# CHRx  -> 0X
# ChrM  -> MT
# BP positions are converted between builds
#
# SNP CONVERSION
#     - reports when frequencies are not close
#
#   ### decision table ###
#
#   # columns
#   gen | gwas| freq    | action
#   e o | e o | gen gwas|
#
#   # non ambivalent
#   A G | A G |  _   _  | nothing + FREQ need to be ballpark same range +/- 0.15
#   A G | T C |  _   _  | CHANGE ALLELES (T>A and C>G) + FREQ need to be ballpark same range +/- 0.15
#   A G | G A |  _   _  | FREQ need to be ballpark same range +/- 0.15, flip freq, flip beta
#   A G | C T |  _   _  | FREQ need to be ballpark same range +/- 0.15, CHANGE ALLELES (C>G, T>A), flip freq, flip beta
#
#   # ambivalent alleles (A/T and G/C)
#   ## freqs close and low/high
#   G C | G C | 0.1 0.1 | nothing + FREQ need to be ballpark same range +/- 0.15
#   G C | C G | 0.1 0.1 | CHANGE ALLELES (C>G and G>C) + FREQ need to be ballpark same range +/- 0.15
#
#   ## freqs inverted and low/high
#   G C | G C | 0.1 0.9 | CHANGE ALLELES (C>G and G>C), flip freq, flip beta
#   G C | C G | 0.1 0.9 | flip freq, flip beta
#
#   ## freqs close and mid
#   G C | C G | 0.5 0.6 | throw away
#   G C | G C | 0.5 0.6 | throw away

from __future__ import print_function

import os
import sys
import argparse
import collections
import gzip
import time
import datetime

try:
    import numpy as np
except ImportError:
    np = None


try:
    from pyliftover import LiftOver
except ImportError:
    def LiftOver(*a):
        print('error: genome build conversion relies on pyliftover')
        print('run pip install pyliftover')
        exit(1)


if not hasattr(time, 'monotonic'):
    time.monotonic = time.time
if not hasattr(os.path, 'commonpath'):
    os.path.commonpath = os.path.commonprefix


# case insensitive
GWAS_H_CHR_AND_BP_COMB_OPTIONS = ['chr_pos_(b36)']
GWAS_H_CHR_OPTIONS =             ['chr', 'chromosome', 'CHR', 'Chr']
GWAS_H_BP_OPTIONS =              ['bp_hg19', 'bp', 'pos', 'position', 'BP', 'POS', 'Pos']
GWAS_H_REF_OPTIONS =             ['reference_allele', 'effect_allele', 'riskallele', 'CODEDALLELE', 'EA']
GWAS_H_OTH_OPTIONS =             ['other_allele', 'noneffect_allele', 'nonriskallele', 'OTHERALLELE', 'NEA']
GWAS_H_FREQ_OPTIONS =            ['ref_allele_frequency', 'effect_allele_freq', 'eaf', 'raf', 'CAF', 'EAF']
GWAS_H_BETA_OPTIONS =            ['log_odds', 'logOR', 'beta', 'effect', 'BETA_FIXED', 'BETA', 'Beta']
GWAS_H_SE_OPTIONS =              ['log_odds_se', 'se_gc', 'se', 'stderr', 'SE_FIXED', 'SE']
GWAS_H_PVALUE_OPTIONS =          ['pvalue', 'p-value_gc', 'p-value', 'pval', 'p', 'P_FIXED', 'P', 'Pvalue']
GWAS_H_NTOTAL_OPTIONS =          ['n_samples', 'TotalSampleSize', 'n_eff', 'N_EFF', 'N', 'neff', 'Neff']
GWAS_H_NCONTROL_OPTIONS =        ['N_control']
GWAS_H_NCASE_OPTIONS =           ['N_case']
GWAS_HG18_HINTS =                ['hg18', 'b36']
GWAS_HG19_HINTS =                ['hg19']


def build_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--out', dest='outfile', metavar='cojo',
            type=os.path.abspath, help='Output .cojo file.')
    parser.add_argument('-r', '--report', dest='report', metavar='txt',
            type=os.path.abspath, help='Report discarded variantss here.')
    parser.add_argument('-g', '--gen', dest='gen', metavar='file.stats.gz',
            type=os.path.abspath, help='Genetic reference data. Could be an in-house GWAS or a reference dataset (e.g. 1000G phase1, phase3, etc.) in PLINK binary format (i.e. bed/bim/fam).')
    parser.add_argument('--gwas', dest='gwas', metavar='file.txt.gz.',
            type=os.path.abspath, help='GWAS summary statistics location.', required=True)
    parser.add_argument('--header-only', dest='header_only', action='store_true',
            help='Exit after reading GWAS header. ' +
                 'Useful for testing whether a file is readable by this program.')
    filter_parser = parser.add_argument_group('filter snps')
    filter_parser.add_argument('--fmid', dest='fmid', metavar='MID',
            help='Ambivalent variants are ambiguous when effect frequency ' +
                 'is between 0.5-MID and 0.5+MID. ' +
                 'Set to 0 to prevent discarding. Default is 0.05.',
            default='0.05', type=float)
    filter_parser.add_argument('--fclose', dest='fclose', metavar='CLOSE',
            help='Fequencies are considered close when their difference is less than CLOSE. ' +
                 'Default is 0.1',
            default='0.1', type=float)
    filter_parser.add_argument('--ignore-indels', action='store_true',
            help='Should insertions and deletions be ignored? Only SNPs are retained.')
    gwas_header = parser.add_argument_group('gwas header')
    gwas_header.add_argument('--gwas:effect', metavar='COLUMN', help='Effect/Risk/Coded/Minor allele column name.')
    gwas_header.add_argument('--gwas:other', metavar='COLUMN', help='Non-effect/Other/Major allele column name.')
    gwas_header.add_argument('--gwas:freq', metavar='COLUMN', help='Effect/Risk/Coded/Minor allele frequency column name.')
    gwas_header.add_argument('--gwas:beta', metavar='COLUMN', help='Log-odds column name [beta/effect], relative to effect/risk/coded/minor allele.')
    gwas_header.add_argument('--gwas:se', metavar='COLUMN', help='Log-odds standard error column name.')
    gwas_header.add_argument('--gwas:p', metavar='COLUMN', help='P-value column name.')
    gwas_header.add_argument('--gwas:chr-bp', metavar='COLUMN', help='Position column name when encoded as chr:pos.')
    gwas_header.add_argument('--gwas:chr', metavar='COLUMN', help='Chromosome column name.')
    gwas_header.add_argument('--gwas:bp',metavar='COLUMN', help='Chromosomal position column name.')
    gwas_header.add_argument('--gwas:build',metavar='BUILDID', help='hg18, hg19, etc.')
    gwas_header.add_argument('--gwas:n',metavar='COLUMN(S)',
            help='Column name(s) of the sample counts. Separated by commas. If multiple colums ' +
                 'are specified, their sum is stored.')
    gwas_default = parser.add_argument_group('gwas default values')
    gwas_default.add_argument('--gwas:default:p', metavar='VALUE')
    gwas_default.add_argument('--gwas:default:beta', metavar='VALUE')
    gwas_default.add_argument('--gwas:default:se', metavar='VALUE')
    gwas_default.add_argument('--gwas:default:chr', metavar='VALUE')
    gwas_default.add_argument('--gwas:default:n',metavar='VALUE')
    gen_header = parser.add_argument_group('genetic data header')
    gen_header.add_argument('--gen:ident', metavar='COLUMN', help='Column name of variant identifier (e.g. rsid).')
    gen_header.add_argument('--gen:chr', metavar='COLUMN', help='Column name of chromosome.')
    gen_header.add_argument('--gen:bp', metavar='COLUMN', help='Column name of bp position.')
    gen_header.add_argument('--gen:effect', metavar='COLUMN', help='Column name of effect allele.')
    gen_header.add_argument('--gen:other', metavar='COLUMN', help='Column name of non-effect allele.')
    gen_header.add_argument('--gen:eaf', metavar='COLUMN', help='Column name of effect allele frequency.')
    gen_header.add_argument('--gen:oaf', metavar='COLUMN', help='Column name of non-effect allele frequency.')
    gen_header.add_argument('--gen:maf', metavar='COLUMN', help='Column name of minor allele frequency.')
    gen_header.add_argument('--gen:minor', metavar='COLUMN', help='Column name of minor allele. When used in combination with maf, ' +
            'it is used to find the effect allele frequency.')
    gen_header.add_argument('--gen:build', metavar='COLUMN', help='Genetic reference data build. Defaults to hg19', default='hg19')
    return parser


GWASRow = collections.namedtuple('GWASRow', 'ref oth f b se p lineno ch bp n')
INV = { 'A': 'T', 'T': 'A', 'C': 'G', 'G': 'C' }
ACT_NOP, ACT_SKIP, ACT_FLIP, ACT_REM, ACT_REPORT_FREQ, ACT_INDEL_SKIP = 1, 2, 3, 4, 5, 6


def conv_chr_letter(ch, full=False):
    if full:
        ch = ch.upper()
        if ch.startswith('CHR'):
            ch = ch[3:]
        ch = ch.zfill(2)
    # else: asumme ch = ch.upper() and not chr_
    if ch == '23': return 'X'
    elif ch == '24': return 'Y'
    elif ch == '25': return 'XY'
    elif ch == '26': return 'MT'
    elif ch == 'M': return 'MT'
    elif ch == '0M': return 'MT'
    return ch


class ReporterLine:
    def __init__(self, line=''):
        self.line = line
        self.last_time = time.monotonic()
        self.last_lineno = 0
        self.last_tell = 0
        self.size = None
        print()

    def update(self, lineno, fileno, message=''):
        now = time.monotonic()
        dt = now - self.last_time
        if not sys.stdout.isatty() and dt < 5:
            return
        tell = os.lseek(fileno, 0, os.SEEK_CUR)
        if self.size is None:
            self.size = os.fstat(fileno).st_size
        dlineno = lineno - self.last_lineno
        dtell = tell - self.last_tell
        part = 100. * tell / self.size
        kline_per_s = dlineno/dt/1000
        tell_per_s = dtell/dt/1000000
        if sys.stdout.isatty():
            print('\033[1A\033[K', end='')
        print(self.line, '{0} {1:.1f}kline/s {2:.1f}% {3:.1f}M/s {message}'.format(
                lineno, kline_per_s, part, tell_per_s, message=message))
        self.last_time, self.last_lineno, self.last_tell = now, lineno, tell


def inv(dna):
    if len(dna) == 1:
        return INV[dna]
    return ''.join(INV[bp] for bp in dna)


def select_action(args,
         gen_eff, gen_oth,
         gen_eaf,
         gwas_ref, gwas_oth,
         gwas_ref_freq):
    freq_close = abs(gen_eaf - gwas_ref_freq) < args.fclose
    freq_inv_close = abs((1-gen_eaf) - gwas_ref_freq) < args.fclose
    freq_mid = abs(gen_eaf - 0.5) < args.fmid
    ambivalent = gen_eff == inv(gen_oth)
    if gen_eff in 'IDR' or gen_oth in 'IDR':
        if len(gwas_ref) < len(gwas_oth):
            gwas_ref, gwas_oth = 'DI'
        elif len(gwas_ref) > len(gwas_oth):
            gwas_ref, gwas_oth = 'ID'
        elif gwas_ref not in 'IDR' or gwas_oth not in 'IDR':
            return ACT_INDEL_SKIP
    indel = gwas_ref in 'IDR' or gwas_oth in 'IDR'
    if args.ignore_indels and (indel or len(gwas_ref) != 1 or len(gwas_oth) != 1):
        return ACT_INDEL_SKIP
    if indel:
        if gwas_ref not in 'IDR' or gwas_oth not in 'IDR':
            return ACT_INDEL_SKIP
        elif gwas_ref == 'I' or gwas_oth == 'D':
            if (gen_eff == 'I' or gen_oth == 'D') or len(gen_eff) > len(gen_oth):
                return ACT_NOP
            elif (gen_eff == 'D' or gen_oth == 'I') or len(gen_eff) < len(gen_oth):
                return ACT_FLIP
        elif gwas_ref == 'D' or gwas_oth == 'I':
            if (gen_eff == 'I' or gen_oth == 'D') or len(gen_eff) > len(gen_oth):
                return ACT_FLIP
            elif (gen_eff == 'D' or gen_oth == 'I') or len(gen_eff) < len(gen_oth):
                return ACT_NOP
        return ACT_INDEL_SKIP
    elif not ambivalent:
        if gen_eff == gwas_ref and gen_oth == gwas_oth:
            act = ACT_NOP
        elif gen_eff == gwas_oth and gen_oth == gwas_ref:
            act = ACT_FLIP
        elif gen_eff == inv(gwas_ref) and gen_oth == inv(gwas_oth):
            act = ACT_NOP
        elif gen_eff == inv(gwas_oth) and gen_oth == inv(gwas_ref):
            act = ACT_FLIP
        else:
            return ACT_SKIP
        if act is ACT_NOP and not freq_close:
            return ACT_REPORT_FREQ
        if act is ACT_FLIP and not freq_inv_close:
            return ACT_REPORT_FREQ
        return act
    else:
        if gen_eff == gwas_ref and gen_oth == gwas_oth:
            pass # equal = True, if wanted equal could be used for statistics
        elif gen_oth == gwas_ref and gen_eff == gwas_oth:
            pass # equal = False
        else:
            return ACT_SKIP
        if freq_mid:
            return ACT_REM
        if freq_close:
            return ACT_NOP
        elif freq_inv_close:
            return ACT_FLIP
        else:
            return ACT_REPORT_FREQ


def log_error(report, name, gwas, gen=()):
    parts = list(gwas)
    if gen:
        parts.extend(gen)
    print(name, *parts, file=report, sep='\t')


def fopen(filename):
    if filename.endswith('.gz'):
        return gzip.open(filename, 'rt')
    else:
        return open(filename)


def read_gwas(args, filename, report=None):
    liftover = None
    float_conv_failed = yes = no = 0
    desc = {}
    default_p, default_std = args['gwas:default:p'], args['gwas:default:se']
    default_n, default_chr = args['gwas:default:n'], args['gwas:default:chr']
    default_beta = args['gwas:default:beta']
    def select(name, options, fail=True):
        option_name = 'gwas:' + name
        if not args[option_name] is None:
            desc[name] = args[option_name]
        if name in desc:
            try:
                return header.index(desc[name])
            except IndexError:
                print('Specified header (--gwas:'+name, args[option_name] + ') not found.')
                exit(1)
        for option in options:
            header_upper = list(map(str.upper, header))
            if option.upper() in header_upper:
                desc[name] = option
                return header_upper.index(option.upper())
        if fail and not args.get('gwas:default:'+name):
            print('Could not find a header in GWAS for', name)
            print('  specify with --' + option_name)
            print('suggestions:')
            for part in header:
                print(' * --' + option_name, part)
            exit(1)
    try:
        with fopen(filename) as f:
            for lineno, line in enumerate(f, 1):
                if lineno == 1:
                    if not args['gwas:build'] is None:
                        desc['build'] = args['gwas:build']
                    elif any(hint in line for hint in GWAS_HG19_HINTS):
                        desc['build'] = 'hg19'
                    elif any(hint in line for hint in GWAS_HG18_HINTS):
                        desc['build'] = 'hg18'
                    header = line.split()
                    hpos = select('chr_bp', GWAS_H_CHR_AND_BP_COMB_OPTIONS, fail=False)
                    if hpos is None:
                        postype_combined = False
                        hpos_ch = select('chr', GWAS_H_CHR_OPTIONS)
                        hpos_bp = select('bp', GWAS_H_BP_OPTIONS)
                    else:
                        postype_combined = True
                    href = select('effect', GWAS_H_REF_OPTIONS)
                    hoth = select('other', GWAS_H_OTH_OPTIONS)
                    hfreq = select('freq', GWAS_H_FREQ_OPTIONS)
                    hb = select('beta', GWAS_H_BETA_OPTIONS)
                    hse = select('se', GWAS_H_SE_OPTIONS)
                    hp = select('p', GWAS_H_PVALUE_OPTIONS)
                    if not args['gwas:n'] is None:
                        hn = [header.index(col) for col in args['gwas:n'].split(',')]
                        desc['n'] = '+'.join(args['gwas:n'].split(','))
                    elif any(col in header for col in GWAS_H_NTOTAL_OPTIONS):
                        ncol = next(col_ for col_ in GWAS_H_NTOTAL_OPTIONS if col_ in header)
                        desc['n'] = ncol
                        hn = [header.index(ncol)]
                    elif (any(col in header for col in GWAS_H_NCASE_OPTIONS) and
                          any(col in header for col in GWAS_H_NCONTROL_OPTIONS)):
                        ncol_a = next(col_ for col_ in GWAS_H_NCASE_OPTIONS if col_ in header)
                        ncol_b = next(col_ for col_ in GWAS_H_NCONTROL_OPTIONS if col_ in header)
                        desc['n'] = ncol_a + '+' + ncol_b
                        hn = [header.index(ncol_a), header.index(ncol_b)]
                    elif not args['gwas:default:n']:
                        print('Could not find a header in GWAS for the number of samples, or the number of cases and controls.')
                        exit(1)
                    else:
                        hn = None
                    if 'build' not in desc:
                        print('Could not determine GWAS genome build; use flag --gwas:build <BUILD>.')
                        exit(1)
                    if desc['build'] != args['gen:build']:
                        liftover = LiftOver(desc['build'], args['gen:build'])
                        print('converting', desc['build'], '->', args['gen:build'])
                    print('= Detected headers =')
                    for k, v in args.items():
                        if k.startswith('gwas:default') and v:
                            desc[k[13:]] = 'DEFAULT ' + v
                    for k, v in desc.items():
                        print(k.ljust(10), v)
                    if args['header_only']:
                        exit(0)
                    print('= Converting =')
                    reporter = ReporterLine('Reading gwas data.')
                    continue
                parts = line.split()
                if postype_combined:
                    ch, bp = parts[hpos].split(':', 1)
                    if default_chr:
                        print('Default chromosome specified but reading chr:bp column.')
                        exit(1)
                else:
                    ch = default_chr or parts[hpos_ch]
                    bp = parts[hpos_bp]
                try:
                    n = default_n or sum(int(float(parts[col])+0.5) for col in hn)
                except ValueError:
                    n = 'NA'
                gwas_freq = parts[hfreq]
                gwas_beta = default_beta or parts[hb]
                try:
                    gwas_freq, gwas_beta = float(gwas_freq), float(gwas_beta)
                except ValueError:
                    row = GWASRow(parts[href].upper(), parts[hoth].upper(),
                            gwas_freq, gwas_beta,
                            default_std or parts[hse],
                            default_p or parts[hp],
                            lineno, ch, bp, n)
                    if report: log_error(report, 'gwas_float_conv_failed', gwas=row)
                    float_conv_failed += 1
                    continue
                row = GWASRow(parts[href].upper(), parts[hoth].upper(),
                        gwas_freq, gwas_beta,
                        default_std or parts[hse],
                        default_p or parts[hp],
                        lineno, ch, bp, n)
                ch = ch.upper()
                if ch.startswith('CHR'):
                    ch = ch[3:]
                ch = ch.lstrip('0')
                ch = conv_chr_letter(ch)
                if liftover:
                    conv = liftover.convert_coordinate('chr'+ch, int(bp))
                    if conv:
                        ch, bp, s19, _ = conv[0]
                        bp = str(bp)
                        if ch.startswith('chr'):
                            ch = ch[3:]
                        yes += 1
                    else:
                        no += 1
                        if report:
                            log_error(report, 'gwas_build_conv_failed', gwas=row)
                        continue
                ch = ch.zfill(2)
                yield (ch, bp), row
                if lineno % 40000 == 0:
                    reporter.update(lineno, f.fileno())
    except KeyboardInterrupt:
        print('Aborted reading gwas data at line', lineno)
    if liftover:
        print('Successfully', desc['build'], '->', args['gen:build'], 'converted', yes, 'rows')
        print('Build conversion failed for', no, 'rows (reported as gwas_build_conv_failed).')
    if float_conv_failed:
        print('Numeric conversion failed for', float_conv_failed, 'rows (reported as gwas_float_conv_failed).')


def update_read_stats(args, gwas, stats_filename, output=None, report=None):
    reporter = ReporterLine('genetic:')
    if output:
        print('SNP A1 A2 freq b se p n', file=output)
    counts = collections.defaultdict(int)
    freq_comp = np.zeros((40000, 2)) if np else None
    converted = discarded = 0
    stopped = False
    def select(name, options, can_fail=False):
        option_name = 'gen:' + name
        option_val = getattr(args, option_name)
        if not option_val is None:
            try:
                return header.index(option_val)
            except IndexError:
                print('Specified header (--gen:'+name, option_val + ') not found.')
                exit(1)
        upper = [col.upper() for col in header]
        matches = [option.upper() for option in options if option.upper() in upper]
        if len(matches) == 1:
            return upper.index(matches[0])
        if not can_fail:
            print('Could not find a header in genetic data for', name)
            print('  specify with --' + option_name)
            print('suggestions:')
            for part in header:
                print(' * --' + option_name, part)
            exit(1)
    try:
        with fopen(stats_filename) as f:
            for lineno, line in enumerate(f, 1):
                if lineno == 1:
                    header = line.split()
                    hrsid = select('ident', ['rsid', 'snp', 'variantid'])
                    hch = select('chr', ['chr', 'chromosome'])
                    hbp = select('bp', ['bp', 'position', 'pos'])
                    heff = select('effect', [])
                    hoth = select('other', [])
                    heaf = select('eaf', [], can_fail=True)
                    hoaf = select('oaf', [], can_fail=True)
                    hmaf = select('maf', [], can_fail=True)
                    hminor = select('minor', [], can_fail=True)
                    if heaf is None and hoaf is None and hmaf is None and hminor is None:
                        print('Could not find a header in genetic data for eaf, oaf or maf+minor')
                        print('  specify with --gen:eaf, --gen:oaf, or --gen:maf and --gen:minor.')
                        print('Suggestions:')
                        for part in header:
                            print(' * --gen:eaf', part)
                        exit(1)
                    elif sum([heaf is not None, hoaf is not None, hmaf is not None]) != 1:
                        print('Only one of --gen:eaf, --gen:maf and --gen:oaf can be specified.')
                        exit(1)
                    if hmaf is None != hminor is None:
                        print('Arguments --gen:hmaf and --gen:minor can only be used together')
                        print('to find effect allele frequency.')
                        exit(1)
                    minsplit = max(hch, hbp) + 1
                    yield # really hacky, but allow for parsing header before processing
                          # to give user information if parsing is possible
                    continue
                if not gwas:
                    break
                parts = line.split(None, minsplit)
                ch = conv_chr_letter(parts[hch], full=True)
                row_pos = ch, parts[hbp]
                if row_pos in gwas:
                    gwas_row = gwas[row_pos]
                    parts = line.split()
                    if hmaf is not None:
                        minor = parts[hminor]
                        if minor == parts[heff]:
                            eaf = float(parts[hmaf])
                        else:
                            eaf = 1 - float(parts[hmaf])
                    elif heaf is not None:
                        eaf = float(parts[heaf])
                    else:
                        eaf = 1 - float(parts[hoaf])
                    act = select_action(
                            args, parts[heff], parts[hoth], eaf,
                            gwas_row.ref, gwas_row.oth,
                            gwas_row.f)
                    freq, beta = gwas_row.f, gwas_row.b
                    if act is ACT_FLIP:
                        counts['flip'] += 1
                        freq = 1-freq
                        beta = -beta
                    elif act is ACT_REM:
                        counts['report:ambiguous_ambivalent'] += 1
                        del gwas[row_pos]
                        if report: log_error(report, 'ambiguous_ambivalent', gwas=gwas_row, gen=parts)
                        discarded += 1
                        continue
                    elif act is ACT_SKIP:
                        counts['report:allele_mismatch'] += 1
                        if report: log_error(report, 'allele_mismatch', gwas=gwas_row, gen=parts)
                        discarded += 1
                        continue
                    elif act is ACT_INDEL_SKIP:
                        counts['report:indel_ignored'] += 1
                        if report: log_error(report, 'indel_ignored', gwas=gwas_row, gen=parts)
                        discarded += 1
                        continue
                    elif act is ACT_REPORT_FREQ:
                        counts['report:frequency_mismatch'] += 1
                        if report: log_error(report, 'frequency_mismatch', gwas=gwas_row, gen=parts)
                        discarded += 1
                        continue
                    else:
                        counts['ok'] += 1
                    del gwas[row_pos]
                    converted += 1
                    if np:
                        freq_comp[converted % freq_comp.shape[0]] = freq, eaf
                    if output:
                        print(parts[hrsid], parts[heff], parts[hoth], freq, beta,
                              gwas_row.se, gwas_row.p, gwas_row.n, file=output)
                if lineno % 100000 == 0:
                    message = '#{0}+{1}'.format(converted,discarded)
                    if np and converted > freq_comp.shape[0]:
                        ss_tot = ((freq_comp[:,1]-freq_comp[:,1].mean())**2).sum()
                        ss_res = ((freq_comp[:,1]-freq_comp[:,0])**2).sum()
                        r2 = 1 - ss_res/ss_tot
                        message += ' freq-r2={0:.4f}'.format(r2)
                    reporter.update(lineno, f.fileno(), message)
    except KeyboardInterrupt:
        print('Aborted reading genetic data at line', lineno)
        stopped = True
    print('gwas allele conversions:')
    for k, v in counts.items():
        print(' ', '{:6}'.format(v), k)
    print('leftover gwas row count', len(gwas))
    if report:
        if stopped and len(gwas) > 1000:
            print('Not writing leftover rows due to early stop.')
        else:
            for gwas_row in gwas.values():
                log_error(report, 'leftover', gwas=gwas_row)
    yield


def gwas_header_auto(gwas_filename):
    with fopen(filename, 'rt') as f:
        for lineno, line in enumerate(f, 1):
            parts = line.split()
            if lineno == 1:
                header = parts
                cols = [[] for _col in range(len(headers))]
                continue
            for col_idx, part in enumerate(parts):
                cols[col_idx].append(part)
            if lineno > 100:
                break
    def test_chr(col):
        return (all(x.lower().startswith('chr') and ':' not in x for x in col)
            or  all(x.lower() in 'x y xy m mt' or x.isdigit() and 0 < int(x) <= 24))
    def test_pos(col):
        return (all(x.count(':') == 1 and x.split(':')[1].isdigit() for x in col))
    def test_bp(col):
        return (all(x.isdigit() and int(x) > 0 for x in col)
            and max(int(x) for x in col) > 100000)
    def find(f):
        mask = list(map(f, cols))
        if sum(mask) == 1:
            return mask.index(True)


def main(args):
    paths = [args.gwas]
    output = report = None
    if args.gen:
        paths.append(args.gen)
    if args.outfile:
        output = open(args.outfile, 'w')
        paths.append(args.outfile)
    if args.report:
        report = open(args.report, 'w')
        paths.append(args.report)
    if args.gen is None and not args.header_only:
        parser.error('Either argument -g/--gen or --header-only is required.')
    if not args.header_only:
        root = os.path.commonpath(paths)
        print('root', root)
        if args.gen:
            print(' / genetic data:', os.path.relpath(args.gen, root))
        print(' / gwas:        ', os.path.relpath(args.gwas, root))
        if args.outfile:
            print(' / output:      ', os.path.relpath(args.outfile, root))
        else:
            print('*WARNING* not writing result file (-o) *WARNING*')
        if args.report:
            print(' / report:      ', os.path.relpath(args.report, root))
            with fopen(args.gen) as f:
                gen_header = f.readline().split()
            log_error(report, 'type', GWASRow._fields, gen_header)
        else:
            print('*WARNING* not writing report file (-r) *WARNING*')
    gwas = {}
    if not args.header_only:
        updater = update_read_stats(args, gwas, args.gen, output=output, report=report)
        next(updater) # coroutine like, first parse header
    for idx, (pos, row) in enumerate(read_gwas(vars(args), args.gwas, report=report)):
        gwas[pos] = row
    next(updater) # the perform rest of function body (sorry for the hack)
    if args.outfile:
        output.close()
    if args.report:
        report.close()


def prolog():
    print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
    print('                                   QTLTools CONVERT GWAS FOR SSMR')
    print('')
    print('')
    print('* Written by         : Lennart Landsmeer | l.p.l.landsmeer@umcutrecht.nl')
    print('* Suggested for by   : Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl')
    print('* Last update        : 2018-12-20')
    print('* Name               : gwas2twosmr')
    print('* Version            : v1.0.0')
    print('')
    print('* Description        : To assess pleiotropic effects using Two Sample Mendelian Randomization (2SMR) ')
    print('                       of molecular QTLs on (selected) traits, summary statistics from genome-wide ')
    print('                       association studies (GWAS) are converted to the 2SMR format.')
    print('                       A data frame of the instruments for an exposure is required. Each line has the ')
    print('                       information for one variant for one exposure. The minimum information required for ')
    print('                       MR analysis is the following:')
    print('')
    print('                       - SNP           - rsID from dbSNP.')
    print('                       - beta          - The effect size. If the trait is binary then log(OR) should be used.')
    print('                       - se            - The standard error of the effect size.')
    print('                       - effect_allele - The allele of the SNP which has the effect marked in beta.')
    print('')
    print('                       Other information that is useful for MR can also be provided:')
    print('')
    print('                       - other_allele  - The non-effect allele.')
    print('                       - eaf           - The effect allele frequency.')
    print('                       - Phenotype     - The name of the phenotype for which the SNP has an effect.')
    print('')
    print('                       You can also provide the following extra information:')
    print('')
    print('                       samplesize      - Sample size for estimating the effect size.')
    print('                       ncase           - Number of cases.')
    print('                       ncontrol        - Number of controls.')
    print('                       pval            - The P-value for the SNP’s association with the exposure.')
    print('                       units           - The units in which the effects are presented.')
    print('                       gene            - The gene or other annotation for the the SNP.')
    print('')
    print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
#    print('Start: {}'.format(datetime.datetime.now()))

def epilog():
    print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
    print('+ The MIT License (MIT)                                                                                 +')
    print('+ Copyright (c) 1979-2018 Lennart P.L. Landsmeer & Sander W. van der Laan                               +')
    print('+                                                                                                       +')
    print('+ Permission is hereby granted, free of charge, to any person obtaining a copy of this software and     +')
    print('+ associated documentation files (the \'Software\'), to deal in the Software without restriction,         +')
    print('+ including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, +')
    print('+ and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, +')
    print('+ subject to the following conditions:                                                                  +')
    print('+                                                                                                       +')
    print('+ The above copyright notice and this permission notice shall be included in all copies or substantial  +')
    print('+ portions of the Software.                                                                             +')
    print('+                                                                                                       +')
    print('+ THE SOFTWARE IS PROVIDED \'AS IS\', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT     +')
    print('+ NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                +')
    print('+ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES  +')
    print('+ OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN   +')
    print('+ CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                            +')
    print('+                                                                                                       +')
    print('+ Reference: http://opensource.org.                                                                     +')
    print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
#    print('End: {}'.format(datetime.datetime.now()))

if __name__ == '__main__':
    startime=time.time()
    prolog()
    parser = build_parser()
    args = parser.parse_args()
    try:
        main(args)
    except KeyboardInterrupt:
        print('aborted')
    elapsedtime=(time.time()-startime)/60
    print("Passed time: {}".format(elapsedtime))
    epilog()
