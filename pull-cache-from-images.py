#!/usr/bin/env python3

from __future__ import print_function

import subprocess
import sys

import yaml


def get_cache_from_images(config, services=None, visited=None):
    services = services or config['services'].keys()
    visited = visited or set()

    for svc in services:
        if svc in visited:
            continue

        visited.add(svc)

        svc_config = config['services'][svc]
        depends_on = svc_config.get('depends_on', [])
        if depends_on:
            yield from get_cache_from_images(
                config, services=depends_on, visited=visited)

        for cache_from in svc_config.get('build', {}).get('cache_from', []):
            yield cache_from


config = subprocess.check_output(['docker-compose', 'config'])
config = yaml.safe_load(config)
services = sys.argv[1:]

for img in get_cache_from_images(config, services):
    subprocess.check_call(['docker', 'pull', img])
