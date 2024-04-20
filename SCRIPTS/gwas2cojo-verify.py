#!/usr/bin/env python3

import sys
import traceback
import collections
import argparse

GWAS = collections.namedtuple('GWAS', 'ref oth freq beta')
Genetic = collections.namedtuple('Genetic', 'ref oth freq')
Result = collections.namedtuple('Result', 'ref oth freq beta act')

acts = 'NOP SKIP FLIP REM REPORT_FREQ INDEL_SKIP'.split()
tr = {'A':'T', 'T':'A', 'C':'G', 'G':'C'}

def equal_alleles(a, b): return a.ref == b.ref and a.ref == b.ref
def switched_alleles(a, b): return gen.ref == gwas.oth and gen.oth == gwas.ref
def translated_equal_alleles(a, b): return a.ref == tr[b.ref] and a.oth == tr[b.oth]
def translated_switched_alleles(a, b): return a.ref == tr[b.oth] and a.oth == tr[b.ref]

def close(a, b):
    return abs(a-b) < 0.1

def verify(gen, gwas, res):
    assert res.act in ('NOP', 'FLIP')
    assert equal_alleles(gen, res)
    if res.act == 'NOP':
        assert equal_alleles(gen, gwas) or translated_equal_alleles(gen, gwas)
        assert close(gen.freq, gwas.freq)
        assert gwas.beta == res.beta
    if res.act == 'FLIP':
        assert switched_alleles(gen, gwas) or translated_switched_alleles(gen, gwas)
        assert close(gen.freq, 1 - gwas.freq)
        assert gwas.beta == -res.beta

def verify_file(report_filename):
    error_count = 0
    with open(report_filename) as f:
        for lineno, line in enumerate(f):
            if not line.startswith('ok'):
                continue
            p = line.split()
            gwas = GWAS(p[2], p[3], float(p[4]), float(p[5]))
            gen = Genetic(p[7], p[8], float(p[9]))
            act = acts[int(p[15])-1]
            res = Result(p[11], p[12], float(p[13]), float(p[14]), act)
            if len(gen.ref) != len(gen.oth) != 1:
                continue
            try:
                verify(gen, gwas, res)
            except AssertionError as ex:
                if error_count == 0:
                    print('Genetic  GWAS     Result   Act')
                _, _, tb = sys.exc_info()
                tb_info = traceback.extract_tb(tb)
                filename, line, func, text = tb_info[-1]
                print(f'{gen.ref}{gen.oth} {gen.freq:.01f}   ' +
                      f'{gwas.ref}{gwas.oth} {gwas.freq:.01f}   ' +
                      f'{res.ref}{res.oth} {res.freq:.01f}   ' +
                      f'{res.act}   ', text[7:])
                error_count += 1
    print('verification errors:', error_count)

def prolog():
    print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
    print('                                    QTLTools CONVERT GWAS FOR SMR')
    print('')
    print('')
    print('* Written by         : Lennart Landsmeer | l.p.l.landsmeer@umcutrecht.nl')
    print('* Suggested for by   : Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl')
    print('* Last update        : 2019-11-21')
    print('* Name               : gwas2cojo-verify')
    print('* Version            : v1.0.0')
    print('')
    print('* Description        : When gwas2cojo was written, it was not checked for errors (just visual inspection)')
    print('                       This script takes the report file or a gwas2cojo with the -rr/--report-ok option')
    print('                       and verifies that the beta and frequency transforms are sane.')
    print('                       In general, it should NOT return any errors.')
    print('')
    print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')

def epilog():
    print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++')
    print('+ The MIT License (MIT)                                                                                 +')
    print('+ Copyright (c) 1979-2024 Lennart P.L. Landsmeer & Sander W. van der Laan                               +')
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

def main():
    prolog()
    parser = argparse.ArgumentParser()
    parser.add_argument('report', metavar='FILE',
                    help='The gwas2cojo.py report file to check')
    args = parser.parse_args()
    verify_file(args.report)
    epilog()

if __name__ == '__main__':
    main()
