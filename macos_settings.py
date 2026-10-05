#!/usr/bin/env python3
"""Copy a small, reviewed set of macOS preferences, never whole domains."""
import argparse
import datetime
import json
import pathlib
import plistlib
import subprocess
import sys

KEYS = {
    'NSGlobalDomain': {
        'com.apple.swipescrolldirection': 'bool',
        'com.apple.mouse.scaling': 'float', 'com.apple.trackpad.scaling': 'float',
        'AppleShowScrollBars': 'string', 'AppleInterfaceStyle': 'string',
        'KeyRepeat': 'int', 'InitialKeyRepeat': 'int',
        'ApplePressAndHoldEnabled': 'bool',
        'NSAutomaticSpellingCorrectionEnabled': 'bool',
        'NSAutomaticCapitalizationEnabled': 'bool',
        'NSAutomaticPeriodSubstitutionEnabled': 'bool',
        'AppleShowAllExtensions': 'bool',
    },
    'com.apple.dock': {
        'autohide': 'bool', 'tilesize': 'int', 'magnification': 'bool',
        'largesize': 'int', 'orientation': 'string', 'minimize-to-application': 'bool',
        'show-recents': 'bool',
    },
    'com.apple.finder': {
        'AppleShowAllFiles': 'bool', 'ShowPathbar': 'bool', 'ShowStatusBar': 'bool',
        'FXPreferredViewStyle': 'string', 'FXDefaultSearchScope': 'string',
        'ShowExternalHardDrivesOnDesktop': 'bool', 'ShowHardDrivesOnDesktop': 'bool',
        'ShowRemovableMediaOnDesktop': 'bool',
    },
    'com.apple.AppleMultitouchTrackpad': {
        'Clicking': 'bool', 'Dragging': 'bool', 'DragLock': 'bool',
        'TrackpadRightClick': 'bool', 'TrackpadThreeFingerDrag': 'bool',
        'TrackpadPinch': 'bool', 'TrackpadRotate': 'bool',
    },
    'com.apple.driver.AppleBluetoothMultitouch.mouse': {
        'MouseButtonMode': 'string', 'MouseHorizontalScroll': 'bool',
        'MouseVerticalScroll': 'bool', 'MouseMomentumScroll': 'bool',
    },
    'com.apple.screencapture': {'type': 'string', 'disable-shadow': 'bool'},
}
DEFAULT_FILE = pathlib.Path(__file__).resolve().parent / 'files/macos/settings.json'


def capture(source_preferences=None):
    entries = []
    for domain, keys in KEYS.items():
        if source_preferences is not None:
            name = '.GlobalPreferences' if domain == 'NSGlobalDomain' else domain
            path = source_preferences / (name + '.plist')
            values = plistlib.loads(path.read_bytes()) if path.exists() else {}
        else:
            result = subprocess.run(['defaults', 'export', domain, '-'], capture_output=True)
            values = plistlib.loads(result.stdout) if result.returncode == 0 else {}
        for key, kind in keys.items():
            value = values.get(key)
            if value is not None:
                if kind == 'bool': value = bool(value)
                elif kind == 'int': value = int(value)
                elif kind == 'float': value = float(value)
                else: value = str(value)
            entries.append(dict(domain=domain, key=key, type=kind, value=value))
    return dict(format=1, captured_at=datetime.datetime.now().astimezone().isoformat(),
                source='offline preference files' if source_preferences else 'current Mac',
                settings=entries)


def validate(data):
    if data.get('format') != 1: raise ValueError('Unsupported format')
    seen = set()
    for item in data['settings']:
        domain, key, kind, value = (item[x] for x in ('domain', 'key', 'type', 'value'))
        if KEYS.get(domain, {}).get(key) != kind or (domain, key) in seen:
            raise ValueError(f'Unknown or duplicate setting: {domain}/{key}')
        seen.add((domain, key))
        expected = {'bool': bool, 'int': int, 'float': (int, float), 'string': str}[kind]
        if value is not None and (not isinstance(value, expected) or
                                  (kind in ('int', 'float') and isinstance(value, bool))):
            raise ValueError(f'Invalid value: {domain}/{key}')
    return data


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    # Avoid overwriting an earlier snapshot or backup accidentally.
    with path.open('x') as stream:
        json.dump(data, stream, ensure_ascii=False, indent=2)
        stream.write('\n')


def commands(data, restore=False):
    for item in data['settings']:
        domain, key, kind, value = (item[x] for x in ('domain', 'key', 'type', 'value'))
        if value is None:
            if restore: yield ['defaults', 'delete', domain, key]
            continue
        text = str(value).lower() if kind == 'bool' else str(value)
        yield ['defaults', 'write', domain, key, '-' + kind, text]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['export', 'apply', 'restore'])
    parser.add_argument('--file', type=pathlib.Path, default=DEFAULT_FILE)
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--source-preferences', type=pathlib.Path, help='Offline Library/Preferences directory for export')
    args = parser.parse_args()
    if sys.platform != 'darwin': parser.error('macOS only')
    if args.source_preferences and args.action != 'export': parser.error('--source-preferences is only for export')
    if args.source_preferences and not args.source_preferences.is_dir(): parser.error('Source directory does not exist')
    if args.action == 'export':
        if args.dry_run: parser.error('export does not support --dry-run')
        save(args.file, capture(args.source_preferences))
        print(f'Exported: {args.file}')
        return
    data = validate(json.loads(args.file.read_text()))
    restore = args.action == 'restore'
    if args.dry_run:
        import shlex
        for command in commands(data, restore): print(shlex.join(command))
        return
    backup = pathlib.Path.home() / 'Library/Application Support/fish_config/macos-backups' / (
        datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f') + '.json')
    # Capture only the keys about to change, so restore does not affect other preferences.
    targets = {(c[2], c[3]) for c in commands(data, restore)}
    previous = capture()
    previous['settings'] = [i for i in previous['settings'] if (i['domain'], i['key']) in targets]
    save(backup, previous)
    print(f'Backup: {backup}', flush=True)
    for command in commands(data, restore):
        if command[1] == 'delete':
            exists = subprocess.run(['defaults', 'read', command[2], command[3]], capture_output=True)
            if exists.returncode != 0: continue
        subprocess.run(command, check=True)
    print('Done. Log out and log in again, then verify in System Settings.')


if __name__ == '__main__':
    main()
