
def readset(fn):
    with open(fn) as fh:
        return [x for x in map(str.strip, fh.readlines()) if x]

METRICS = ['wip', 'ip']
SRRs = readset("sets/96s-present-00.txt")
Xs = ['3e9']
Ks = ['20']
Ns = ['1']


rule all:
    input:
        expand("data/kwip/{run}-k{k}x{x}N{N}-{metric}.dist", k=Ks, x=Xs, N=Ns,
               run=SRRs, metric=METRICS),
        expand("data/kwip/{run}-k{k}x{x}N{N}-entvec.dist", k=Ks, x=Xs, N=Ns,
               run=SRRs),


rule hash:
    input:
        "sra/{run}.sra"
    output:
        "data/hashes/{run}-k{k}x{x}N{N}.ct.gz"
    log:
        "data/log/hashes/{run}-k{k}x{x}N{N}.log"
    params:
        x=lambda w: w.x,
        N=lambda w: w.N,
        k=lambda w: w.k,
    shell:
        "fastq-dump "
        "    --split-spot "
        "    --skip-technical "
        "    --stdout "
        "    --readids "
        "    --defline-seq '@$sn/$ri' "
        "    --defline-qual '+' "
        "    {input} "
        "    2> {log} "
        "| sickle pe "
        "    -c /dev/stdin "
        "    -q 28 "
        "    -l 40 "
        "    -t sanger "
        "    -M /dev/stdout "
        "    >> {log} 2>&1 "
        "| load-into-counting.py"
        " -N {params.N}"
        " -x {params.x}"
        " -k {params.k}"
        " -b"
        " -s tsv"
        " {output}"
        " -"
        " >{log} 2>&1"


rule kwip:
    input:
        "data/hashes/{run}-k{k}x{x}N{N}.ct.gz"
    output:
        d="data/kwip/{run}-k{k}x{x}N{N}-{metric}.dist",
        k="data/kwip/{run}-k{k}x{x}N{N}-{metric}.kern"
    params:
        metric= lambda w: '-U' if w.metric == 'ip' else ''
    log:
        "data/log/kwip/{run}-k{k}x{x}N{N}-{metric}.log"
    threads:
        24
    shell:
        "kwip"
        " {params.metric}"
        " -d {output.d}"
        " -k {output.k}"
        " -t {threads}"
        " {input}"
        " >{log} 2>&1"


rule kwip_stats:
    input:
        "data/hashes/{run}-k{k}x{x}N{N}.ct.gz"
    output:
        "data/kwip/{run}-k{k}x{x}N{N}.stat",
    log:
        "data/log/kwip/{run}-k{k}x{x}N{N}-entvec.log"
    threads:
        24
    shell:
        "kwip-entvec"
        " -o {output}"
        " -t {threads}"
        " {input}"
        " >{log} 2>&1"
