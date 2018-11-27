#!/usr/bin/env python

from __future__ import print_function
import os
import sys
import argparse
import gzip
import sqlite3
import time

DATABASE = 'illuminaHumanv4.sqlite'
dbpath = os.path.join(os.path.dirname(os.path.realpath(__file__)), DATABASE)
cit = '''Dunning M, Lynch A, Eldridge M (2015). illuminaHumanv4.db:
  Illumina HumanHT12v4 annotation data (chip illuminaHumanv4).
  R package version 1.26.0.'''

class Reporter:
    def __init__(self):
        self.last_report = None
        self.last_p = 0

    def report(self, current, total):
        now = time.time()
        if self.last_report is None:
            self.last_report = now
            return
        p = int(current * 100. / total + 0.5)
        if now - self.last_report > 1 and p - last_p > 1:
            self.last_report = now
            self.last_p = p
            print(str(p)+'%', end=' ')
            sys.stdout.flush()

def filter_genetic_data(args):
    if isinstance(args, argparse.ArgumentParser):
        parser = args
        parser.add_argument(dest='genfile', metavar='GENETIC_DATA', help='Genetic data as .stats.gz')
        parser.add_argument('-o', '--out', dest='outfile', metavar='FILE',
                help='Store filtered SNPs here (.stats.gz)')
        parser.add_argument('--discard', dest='discardfile', metavar='FILE',
                help='Store discarded SNPs here (.stats.gz)')
        parser.add_argument('--db', dest='outfile', metavar='SQLITE', default=dbpath,
                help='illuminaHumanv4 sqlite database path')
        parser.add_argument('-q', '--quiet',
                help='Do not report progress', action='store_true')
        parser.add_argument('-T', '--timeout', metavar='T', dest='timeout',
                help='stop after T seconds')
        parser.set_defaults(func=filter_genetic_data)
        return parser
    if not args.quiet:
        print(cit, file=sys.stderr)
    reporter = Reporter()
    conn = sqlite3.connect(dbpath)
    c = conn.cursor()
    c.execute('select OverlappingSNP from ExtraInfo where OverlappingSNP <> ""')
    overlapping_snps = frozenset(row[0].encode('latin1') for row in c.fetchall())
    ndiscarded = 0
    total = 0
    filesize = os.stat(args.genfile).st_size
    begin = time.time()
    with gzip.open(args.genfile, 'rb') as src:
        dst = gzip.open(args.outfile, 'wb') if args.outfile else False
        discard = gzip.open(args.discardfile, 'wb') if args.discardfile else False
        if not dst and not discard and not args.quiet:
            print('warning: no output files specified, only reporting counts')
        for line in src:
            if not args.quiet:
                reporter.report(src.fileobj.tell(), filesize)
            parts = line.split(None, 2)
            rsid = parts[1].split(b':', 1)[0]
            if rsid not in overlapping_snps:
                if dst: dst.write(line)
            else:
                ndiscarded += 1
                if discard: discard.write(line)
            total += 1
            if args.timeout and time.time() - begin > float(args.timeout):
                if not args.quiet:
                    print('timeout reached')
                break
        if args.outfile: dst.close()
        if args.discardfile: discard.close()
    if not args.quiet:
        print('100%\ndone')
    print('read', total, 'lines')
    print('discarded', ndiscarded, 'lines')
    print('fraction discarded', ndiscarded / float(total))

def build_probe_hybdrid_list(args):
    if isinstance(args, argparse.ArgumentParser):
        parser = args
        parser.add_argument('-o', '--out', dest='outfile', metavar='FILE',
                help='where to store output. stdout by default.')
        parser.add_argument('--db', dest='outfile', metavar='SQLITE', default=dbpath,
                help='illuminaHumanv4 sqlite database path')
        parser.add_argument('-q', '--quiet',
                 action='store_true')
        parser.set_defaults(func=build_probe_hybdrid_list)
        return parser
    if not args.quiet:
        print(cit, file=sys.stderr)
    reporter = Reporter()
    conn = sqlite3.connect(dbpath)
    c = conn.cursor()
    outfile = sys.stdout
    if args.outfile: outfile = open(args.outfile, 'w')
    for probeid, locs in c.execute('select IlluminaID, GenomicLocation from ExtraInfo where GenomicLocation <> ""'):
        sep = ' ' if ' ' in locs else ','
        for loc in locs.split(sep):
            ch, begin, end, strand = loc.split(':')
            if ch.startswith('chr'):
                ch = ch[3:]
            print('{0:<2} {1} {2:>10} {3:>10}'.format(ch, probeid, begin, end), file=outfile)
    if args.outfile: outfile.close()

parser = argparse.ArgumentParser()
subparsers = parser.add_subparsers(title='subcommands')
filter_genetic_data(subparsers.add_parser('filter', help='Find SNPs in HumanHTv12 probes'))
build_probe_hybdrid_list(subparsers.add_parser('hybrid', help='Build SMR probe_hybrid.txt'))

if __name__ == '__main__':
    args = parser.parse_args()
    args.func(args)
