#!/usr/bin/env python3
"""Start the actual Linux GUI under Xvfb; not a physical audio/performance test."""
from pathlib import Path
import os
import subprocess
import sys
import tempfile
import time

prefix, evidence = (Path(arg).resolve() for arg in sys.argv[1:])
log = evidence / 'gui-smoke.log'
with tempfile.TemporaryDirectory() as directory:
    profile = Path(directory) / 'profile'
    runtime = Path(directory) / 'runtime'
    runtime.mkdir(mode=0o700)
    env = {**os.environ, 'NAUTICMIXXX_PROFILE': str(profile),
           'XDG_RUNTIME_DIR': str(runtime), 'LIBGL_ALWAYS_SOFTWARE': '1'}
    with log.open('w') as output:
        gl = subprocess.run(['glxinfo', '-B'], stdout=output, stderr=output, env=env)
        if gl.returncode:
            raise RuntimeError('Xvfb Mesa OpenGL context unavailable')
        app = subprocess.Popen([str(prefix / 'bin/nauticmixxx')], stdout=output, stderr=output, env=env)
        try:
            ready = False
            for _ in range(45):
                time.sleep(1)
                if app.poll() is not None:
                    raise RuntimeError(f'GUI exited early: {app.returncode}; see {log}')
                output.flush()
                traces = log.read_text(errors='replace')
                internal = profile / 'mixxx.log'
                if internal.is_file():
                    traces += internal.read_text(errors='replace')
                if 'LegacySkinParser loading skin:' in traces and 'XDJ_RX3_Mixxx' in traces:
                    ready = True
                    # Give skin parsing and initial widget rendering time to finish.
                    time.sleep(10)
                    break
            if not ready or app.poll() is not None:
                raise RuntimeError(f'RX3 GUI did not stay running; see {log}')
        finally:
            app.terminate()
            try:
                app.wait(timeout=15)
            except subprocess.TimeoutExpired:
                app.kill()
                app.wait()
    internal = profile / 'mixxx.log'
    if internal.is_file():
        with log.open('a') as output:
            output.write('\n--- Application trace ---\n' + internal.read_text(errors='replace'))
    traces = log.read_text(errors='replace')
    for error in ('LegacySkinParser::parseSkin - failed', 'default skin cannot be loaded',
                  'LegacySkinParser::openSkin - setContent failed', 'Could not open template file:',
                  'Failed to create OpenGL context'):
        if error in traces:
            raise RuntimeError(f'GUI error: {error}; see {log}')
    settings = (profile / 'mixxx.cfg').read_text()
    if 'Locale en_US' not in settings or 'ResizableSkin XDJ_RX3_Mixxx' not in settings:
        raise RuntimeError('GUI did not retain the English RX3 profile')
print('RX3 GUI started and parsed under virtual X11/Mesa; physical GPU/audio remain untested.')
