#!/usr/bin/python

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#                          SUN GRID ENGINE JOBARRAY BUILDER
#
#
# * Written by         : Lennart P. L. Landsmeer | lennart@landsmeer.email
# * Suggested for by   : Sander W. van der Laan | s.w.vanderlaan-2@umcutrecht.nl
# * Name               : QTLJobArrayBuilder
# * Version            : v1.0.1
#
# * Description        : Before the existence of this script, QTLAnalyzer.sh
#                        created a huge amount of jobs for each genomic region
#                        of interest. Updating QTLAnalyzer.sh itself to use jobarrays
#                        was more time consuming than building this script. It reads
#                        all qsub commands from QTLAnalyzer.sh (and possible other
#                        scripts, it does not make too much assumptions about the jobs)
#                        and folds jobs with the same nane into a single jobarray.
#                        -hold_jid to -hold_jid_ad conversion is applied where
#                        applicable. Region specific output and error log file
#                        locations are respected.
#
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

from __future__ import print_function

import re
import os
import sys
import textwrap
import collections
from UserDict import UserDict

class NS(UserDict):
    def __getattr__(self, k):
        return self[k]


task_id = 'SGE_TASK_ID'
def reconstruct(qsub, cmd):
    r = ['qsub']
    for k, v in qsub.items():
        r.append('-'+k)
        if isinstance(v, str):
            r.append(v)
        r.append('\\\n')
    r.append(cmd)
    return ' '.join(r)

def norm_job_name(jobname):
    # we need to handle job dependencies via bash variables...
    # so lets normalize them...
    # also useful for graphviz output
    return re.sub(r'[^a-zA-Z_0-9]', '_', jobname) 

task_id = 'SLURM_ARRAY_TASK_ID'
def reconstruct(slurm, cmd):
    if slurm['N']:
        slurm['N'] = norm_job_name(slurm['N'])
    if 'S' in slurm:
        assert slurm['S'] == '/bin/bash'
        del slurm['S']
    trans = { 'wd': '--chdir', 'e': '--error', 'o': '--output',
              'M': '--mail-user', 'm': '--mail-type', 'N': '--job-name', 't': '--array', }
    r = ['sbatch']
    if 'm' in slurm:
        if slurm['m']:
            slurm['m'] = 'ALL'
        else:
            del slurm['m']
            del slurm['M']
    for k, v in slurm.items():
        if k in trans:
            k = trans[k]
        elif k == 'l' and v.split('=', 1)[0] == 'h_vmem':
            k = '--mem'
            v = v.split('=', 1)[1]
        elif k == 'hold_jid_ad':
            k = '--dependency'
            v = 'aftercorr:${' + norm_job_name(v) +'}'
        elif k == 'hold_jid':
            k = '--dependency'
            v = 'afterok:${' + norm_job_name(v) +'}'
        else:
            print('ERROR: COULD NOT ARGUMENT FROM SGE TO SLURM:')
            print(k, v)
            exit(1)
            r.append('-'+k)
        if isinstance(v, str):
            r.append(k + '=' + v)
        else:
            r.append(k)
        r.append('\\\n')
    r.append(cmd)
    out = ' '.join(r)
    if slurm['N']:
        # SLURM only supports job dependencies via job_IDs
        # not job names...
        N = slurm['N']
        out = 'echo Submitting {{{0}}}\n{0}=$({1})\necho ${{{0}}}\n{0}=${{{0}##* }}'.format(N, out)
    return out

def depsolve(f, task, cmdfile):
    name = norm_job_name(task['N'])
    print(name + '[shape=box]', file=f)
    for k in ['hold_jid_ad', 'hold_jid']:
        if k in task:
            print(name, '->', norm_job_name(task[k]), file=f)

def main(taskdir):
    print('#!/usr/bin/bash')
    print('set -e')
    print()
    qsubs = []
    for line in open(os.path.join(taskdir, 'qsub')):
        qsub = NS()
        parts = line.split()
        cmdfile = parts.pop()
        while parts:
            key = parts.pop(0).lstrip('-')
            if parts and not parts[0].startswith('-'):
                qsub[key] = parts.pop(0)
            else:
                qsub[key] = True
        qsub['cmd'] = cmdfile
        qsubs.append(qsub)

    order = []
    by_name = collections.defaultdict(list)

    fdeps = open(os.path.join(taskdir, 'qsub-deps.dot'), 'w')
    print('digraph jobdeps {', file=fdeps)

    for qsub in qsubs:
        if qsub.N not in order:
            order.append(qsub.N)
        by_name[qsub.N].append(qsub)

    arrayjobs = set()

    for name in order:
        if name.startswith('GENEX'):
            hold = name
        tasks = by_name[name]
        if name.startswith('GENQC') and 'hold_jid' not in tasks[0]:
            for _task in tasks:
                _task['hold_jid'] = hold
        if len(tasks) == 1:
            cmd = tasks[0].pop('cmd')
            # rewrite to prepend /usr/bin/bash to keep SLURM happy...
            with open(cmd, 'r') as f:
                cmd_content = f.read()
            with open(cmd, 'w') as f:
                print('#!/usr/bin/bash\n' + cmd_content, file=f)
            print('# JOB', name)
            print(reconstruct(tasks[0], cmd))
            depsolve(fdeps, tasks[0], cmd)
        else:
            qsub_file = os.path.join(taskdir, name + '.jobfile')
            arrayjobs.add((name, len(tasks)))
            with open(qsub_file, 'w') as f:
                print('#!/usr/bin/bash', file=f)
                for idx, task in enumerate(tasks, 1):
                    cmd = task.pop('cmd')
                    print('[ "${' + task_id + '}" -eq', idx, '] &&',
                            '(cd ' + task.pop('wd') + ';',
                            task.S, cmd,
                            '1>' + task.pop('o'),
                            '2>' + task.pop('e') + ';',
                            'exit $?'
                            ') || true', file=f)
            print('#', 'ARRAYJOB', name)
            task = dict(task)
            if (task.get('hold_jid'), len(tasks)) in arrayjobs:
                task['hold_jid_ad'] = task.pop('hold_jid')
            task['t'] = '1-' + str(len(tasks))
            task['o'] = os.path.join(taskdir, name + '.stdout')
            task['e'] = os.path.join(taskdir, name + '.stderr')
            print(reconstruct(task, qsub_file))
            depsolve(fdeps, task, cmd)
        try:
            with open(cmd) as g:
                for line in textwrap.wrap(g.read(), 100):
                    print('#', line)
        except IOError:
            print('\n# could not write debug info for')
            for line in textwrap.wrap(cmd, 100):
                print('#', line)
        print()
        print()

    print('}', file=fdeps)

taskdir = '/tmp/' if len(sys.argv) == 1 else sys.argv[1]

try:
    main(taskdir)
except IOError:
    raise
    pass
