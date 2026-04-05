#!/usr/bin/env python3
"""Generate a JSON manifest of PDFs in the given output directory.

Usage: scripts/generate_manifest.py OUTDIR
"""
import sys
import os
import json
import glob
import time


def main():
    if len(sys.argv) < 2:
        print("Usage: generate_manifest.py OUTDIR", file=sys.stderr)
        return 2
    outdir = sys.argv[1]
    manifest = os.path.join(outdir, 'manifest.json')
    entries = []
    for pdf in sorted(glob.glob(os.path.join(outdir, '*.pdf'))):
        base = os.path.basename(pdf)
        sha_file = pdf + '.sha256'
        sha = None
        if os.path.exists(sha_file):
            with open(sha_file, 'r', encoding='utf-8') as fh:
                sha = fh.read().split()[0]
        sig_file = pdf + '.sig'
        sig = os.path.basename(sig_file) if os.path.exists(sig_file) else None
        st = os.stat(pdf)
        mtime = time.strftime('%Y-%m-%dT%H:%M:%S%z', time.localtime(st.st_mtime))
        entries.append({
            'file': base,
            'path': os.path.relpath(pdf),
            'sha256': sha,
            'sha256_file': os.path.basename(sha_file) if os.path.exists(sha_file) else None,
            'sig_file': sig,
            'size': st.st_size,
            'mtime': mtime,
        })
    os.makedirs(os.path.dirname(manifest), exist_ok=True)
    with open(manifest, 'w', encoding='utf-8') as f:
        json.dump(entries, f, indent=2, ensure_ascii=False)
    print('Wrote', manifest)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
