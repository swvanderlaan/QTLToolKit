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

last_report = None
last_p = 0
def report(current, total):
    global last_report, last_p
    now = time.time()
    if last_report is None:
        last_report = now
        return
    p = int(current * 100. / total + 0.5)
    if now - last_report > 1 and p - last_p > 1:
        last_report = now
        last_p = p
        print(str(p)+'%', end=' ')
        sys.stdout.flush()

def main(args):
    if not args.quiet:
        print(cit)
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
                report(src.fileobj.tell(), filesize)
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

parser = argparse.ArgumentParser(description='Find SNPs in HumanHTv12 probes')
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

if __name__ == '__main__':
    args = parser.parse_args()
    main(args)
