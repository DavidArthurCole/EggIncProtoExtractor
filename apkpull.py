#!/usr/bin/env python3
"""
Smart APK puller with hash-based caching.
Only pulls APKs that differ from local input_apks/ copies.
Writes input_apks/.pull_status:
  Line 1: CHANGED or UNCHANGED
  Line 2: path to arm APK (if found)
"""
import sys
import os
import subprocess
import hashlib

INPUT_DIR = 'input_apks'
STATUS_FILE = os.path.join(INPUT_DIR, '.pull_status')


def md5_local(path):
    h = hashlib.md5()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            h.update(chunk)
    return h.hexdigest()


def md5_remote(remote_path):
    r = subprocess.run(['adb', 'shell', f'md5sum "{remote_path}"'],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None
    parts = r.stdout.strip().split()
    return parts[0] if parts else None


def adb_pull(remote_path, local_dir):
    r = subprocess.run(['adb', 'pull', remote_path, local_dir],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stderr.strip(), file=sys.stderr)
    return r.returncode == 0


def get_apk_paths():
    r = subprocess.run(['adb', 'shell', 'pm', 'path', 'com.auxbrain.egginc'],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(f"adb error: {r.stderr.strip()}", file=sys.stderr)
        sys.exit(1)
    paths = []
    for line in r.stdout.splitlines():
        line = line.strip()
        if line.startswith('package:'):
            paths.append(line[len('package:'):].strip())
    return paths


def main():
    os.makedirs(INPUT_DIR, exist_ok=True)

    remote_paths = get_apk_paths()
    if not remote_paths:
        print("Error: no APKs found for com.auxbrain.egginc", file=sys.stderr)
        sys.exit(1)

    any_changed = False

    for remote_path in remote_paths:
        filename = os.path.basename(remote_path)
        local_path = os.path.join(INPUT_DIR, filename)

        if os.path.exists(local_path):
            remote_hash = md5_remote(remote_path)
            local_hash = md5_local(local_path)
            if remote_hash == local_hash:
                print(f"  CACHED:  {filename}")
                continue
            print(f"  CHANGED: {filename} (pulling...)")
        else:
            print(f"  NEW:     {filename} (pulling...)")

        if not adb_pull(remote_path, INPUT_DIR):
            print(f"Error: failed to pull {remote_path}", file=sys.stderr)
            sys.exit(1)
        any_changed = True

    arm_apk = next(
        (os.path.join(INPUT_DIR, f) for f in os.listdir(INPUT_DIR)
         if f.endswith('.apk') and 'arm' in f),
        None
    )

    with open(STATUS_FILE, 'w') as f:
        f.write('CHANGED\n' if any_changed else 'UNCHANGED\n')
        if arm_apk:
            f.write(arm_apk + '\n')

    if not arm_apk:
        print("Error: no arm APK found in input_apks/", file=sys.stderr)
        sys.exit(1)

    print(f"  ARM APK: {arm_apk}")


if __name__ == '__main__':
    main()
