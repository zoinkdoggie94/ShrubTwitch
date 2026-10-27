#!/usr/bin/env python3
"""Inject a custom sideload dylib into an IPA without publishing the original app."""
from __future__ import annotations

import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

import lief


def run(*args: str, cwd: Path | None = None) -> None:
    subprocess.run(args, cwd=cwd, check=True)


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit('Usage: inject_ipa.py source.ipa ShrubTwitch.dylib output_dir')
    source, dylib, output = (Path(x).resolve() for x in sys.argv[1:])
    if not source.is_file() or not zipfile.is_zipfile(source):
        raise SystemExit('Missing or invalid source IPA')
    if not dylib.is_file():
        raise SystemExit('Missing compiled dylib')

    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='shrubtwitch-') as folder:
        work = Path(folder)
        # ditto preserves the app bundle structure, resources, and symlinks.
        run('ditto', '-xk', str(source), str(work))
        apps = sorted((work / 'Payload').glob('*.app'))
        if len(apps) != 1:
            raise SystemExit('Expected exactly one Payload/*.app in source IPA')
        app = apps[0]
        with (app / 'Info.plist').open('rb') as file:
            info = plistlib.load(file)
        executable = info.get('CFBundleExecutable')
        if not isinstance(executable, str) or not executable:
            raise SystemExit('Missing CFBundleExecutable in app Info.plist')
        binary = app / executable
        if not binary.is_file():
            raise SystemExit(f'Main Twitch executable not found: {executable}')

        # Do not replace Twitch's Assets.car: doing so could break native image assets.
        info['CFBundleDisplayName'] = 'ShrubTwitch'
        with (app / 'Info.plist').open('wb') as stream:
            plistlib.dump(info, stream, fmt=plistlib.FMT_BINARY)
        target = app / 'ShrubTwitch.dylib'
        shutil.copy2(dylib, target)
        icon = Path('.').resolve() / 'Assets/shrubtwitch-icon.png'
        if icon.is_file():
            shutil.copy2(icon, app / 'ShrubTwitch-Logo.png')
        reference = '@executable_path/ShrubTwitch.dylib'
        fat = lief.MachO.parse(str(binary))
        if fat is None:
            raise SystemExit('LIEF cannot parse the IPA main executable')
        for macho in fat:
            libraries = [str(command.name) for command in macho.commands
                         if hasattr(command, 'name')]
            if reference in libraries:
                print('Already contains ShrubTwitch injection: skipping duplicate')
                continue
            macho.add_library(reference)
        fat.write(str(binary))
        result = subprocess.check_output(['otool', '-L', str(binary)], text=True)
        if reference not in result:
            raise SystemExit('Injection verification failed: dylib not linked')

        # Ad-hoc signatures are not installation provisioning profiles.
        run('ldid', '-S', str(target))
        run('ldid', '-S', str(binary))

        version = str(info.get('CFBundleShortVersionString', 'unknown'))
        version = re.sub(r'[^A-Za-z0-9._-]', '_', version)[:32]
        name = f'ShrubTwitch-1.2.0-Twitch-{version}-unsigned.ipa'
        output_file = output / name
        # A fast Deflate level avoids multi-minute max-compression CPU costs.
        run('zip', '-q', '-r', '-y', '-1', '-X', str(output_file), '.', cwd=work)
        with zipfile.ZipFile(output_file) as archive:
            entry = f'Payload/{app.name}/ShrubTwitch.dylib'
            if entry not in archive.namelist():
                raise SystemExit('Final archive verification failed: missing dylib')
            if archive.read(entry)[:4] not in (b'\xcf\xfa\xed\xfe', b'\xca\xfe\xba\xbe', b'\xfe\xed\xfa\xcf'):
                raise SystemExit('Final archive verification failed: invalid dylib signature')
        print(f'Created {output_file.name}: {output_file.stat().st_size // 1048576} MiB')


if __name__ == '__main__':
    main()
