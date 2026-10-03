#!/usr/bin/env python3
"""Check original WAV/JSON oracles, then exercise the native USB decoder path."""
import argparse
import json
from pathlib import Path
import os
import struct
import subprocess
import wave


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--test-binary', required=True, type=Path)
    parser.add_argument('--usb-root', required=True, type=Path)
    parser.add_argument('--truth-dir', required=True, type=Path)
    parser.add_argument('--output-dir', required=True, type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    oracle = []
    for rate in ('44k1', '48k'):
        name = f'grid_test_128bpm_{rate}'
        truth = json.loads((args.truth_dir / f'{name}.json').read_text())
        with wave.open(str(args.truth_dir / f'{name}.wav'), 'rb') as audio:
            assert audio.getframerate() == truth['sample_rate']
            assert audio.getnchannels() == 2 and audio.getsampwidth() == 2
            assert len(truth['beats']) == 64
            errors = []
            for beat in truth['beats']:
                frame = beat['sample']
                audio.setpos(frame - 2)
                window = struct.unpack('<10h', audio.readframes(5))[::2]
                peak = max(range(5), key=lambda i: abs(window[i]))
                errors.append(peak - 2)
            assert all(e == 0 for e in errors), (name, errors)
            oracle.append({'file': f'{name}.wav', 'beats': 64, 'peak_error_frames': errors})
    (args.output_dir / 'wav-oracle.json').write_text(json.dumps(oracle, indent=2) + '\n')
    env = dict(os.environ,
            QT_QPA_PLATFORM='offscreen',
            MIXXX_REKORDBOX_METRONOME_USB=str(args.usb_root.resolve()),
            MIXXX_REKORDBOX_METRONOME_TRUTH=str(args.truth_dir.resolve()),
            MIXXX_REKORDBOX_TIMING_REPORT=str((args.output_dir / 'native-timing.json').resolve()))
    with (args.output_dir / 'native-tests.log').open('w') as log:
        result = subprocess.run([str(args.test_binary.resolve()),
                '--gtest_filter=RekordboxDecoderTimingTest.*:RekordboxWaveformImporterTest.*:RekordboxUsbSessionAudioTest.*',
                f'--gtest_output=xml:{(args.output_dir / "native-tests.xml").resolve()}'],
                env=env, stdout=log, stderr=subprocess.STDOUT)
    if result.returncode:
        raise SystemExit(f'Native timing tests failed; see {args.output_dir / "native-tests.log"}')
    report = json.loads((args.output_dir / 'native-timing.json').read_text())
    assert len({r['file'] for r in report if 'grid_frame' in r}) == 4
    print(f'WAV oracle and native decoder tests passed. Reports: {args.output_dir}')


if __name__ == '__main__':
    main()
