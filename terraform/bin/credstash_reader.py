#!/usr/bin/env python
import sys, subprocess, json, base64, random

from pprint import pprint

d = json.loads(sys.stdin.read())

try:
    secret = subprocess.check_output(
        [
            'credstash',
            '-t',
            d['table'],
            '-r',
            d['region'],
            'get',
            d['key'],
        ],
        stderr             = subprocess.STDOUT,
        universal_newlines = True,
    )
except subprocess.CalledProcessError as exc:
    print >> sys.stderr, exc.output
    sys.exit(1)

if 'b64decode' in d:
    if d['b64decode']:
        secret = base64.b64decode(secret)

print json.dumps({
    'secret': secret.rstrip(),
})
