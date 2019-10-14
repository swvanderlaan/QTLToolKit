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


import os
import sys
import textwrap
import collections
from UserDict import UserDict

class NS(UserDict):
    def __getattr__(self, k):
        return self[k]

def main(taskdir):
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

    for qsub in qsubs:
        if qsub.N not in order:
            order.append(qsub.N)
        by_name[qsub.N].append(qsub)

    def reconstruct(qsub):
        r = []
        for k, v in qsub.items():
            r.append('-'+k)
            if isinstance(v, str):
                r.append(v)
            r.append('\\\n')
        return ' '.join(r)

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
            print('# JOB', name)
            print('qsub', reconstruct(tasks[0]), cmd)
        else:
            qsub_file = os.path.join(taskdir, name + '.jobfile')
            arrayjobs.add((name, len(tasks)))
            with open(qsub_file, 'w') as f:
                for idx, task in enumerate(tasks, 1):
                    cmd = task.pop('cmd')
                    print('[ "${SGE_TASK_ID}" -eq', idx, '] &&',
                            '(cd ' + task.pop('wd') + ';',
                            task.S, cmd,
                            '1>' + task.pop('o'),
                            '2>' + task.pop('e'),
                            ')', file=f)
            print('#', 'ARRAYJOB', name)
            task = dict(task)
            if (task.get('hold_jid'), len(tasks)) in arrayjobs:
                task['hold_jid_ad'] = task.pop('hold_jid')
            task['t'] = '1-' + str(len(tasks))
            task['o'] = os.path.join(taskdir, name + '.stdout')
            task['e'] = os.path.join(taskdir, name + '.stderr')
            print('qsub', reconstruct(task), qsub_file)
        with open(cmd) as g:
            for line in textwrap.wrap(g.read(), 100):
                print('#', line)
        print()
        print()

taskdir = '/tmp/' if len(sys.argv) == 1 else sys.argv[1]

try:
    main(taskdir)
except IOError:
    pass
