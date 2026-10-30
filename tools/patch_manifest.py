#!/usr/bin/env python3
"""Προσθέτει στο AndroidManifest.xml τα intent-filters ώστε το Nivens να
εμφανίζεται στο «Άνοιγμα με…» για .java .py .css .dart .html .txt .md .js .php
.pdf .doc .docx. Τρέξ' το από τη ρίζα του project:  python3 tools/patch_manifest.py
Είναι ασφαλές να τρέξει πολλές φορές (δεν διπλογράφει)."""
import re, sys, pathlib

path = pathlib.Path('android/app/src/main/AndroidManifest.xml')
if not path.exists():
    sys.exit('Δεν βρέθηκε το android/app/src/main/AndroidManifest.xml — τρέξε το από τη ρίζα του project.')
xml = path.read_text(encoding='utf-8')
MARK = 'NIVENS_OPEN_WITH'
if MARK in xml:
    sys.exit('Ήδη εφαρμοσμένο.')

mimes = [
    'text/plain', 'text/markdown', 'text/html', 'text/css',
    'text/x-python', 'text/x-python-script', 'text/x-java-source', 'text/x-java',
    'text/javascript', 'application/javascript', 'text/x-dart',
    'text/x-php', 'application/x-php', 'application/x-httpd-php',
    'application/pdf', 'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/octet-stream',
]
exts = ['txt', 'md', 'html', 'htm', 'css', 'py', 'java', 'dart', 'js', 'php',
        'pdf', 'doc', 'docx']

block = f'\n            <!-- {MARK} (αρχή) -->\n'
# 1) Βάσει MIME type (content:// και file://)
block += '''            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="content"/>
                <data android:scheme="file"/>
''' + ''.join(f'                <data android:mimeType="{m}"/>\n' for m in mimes) + '''            </intent-filter>
'''
# 2) Βάσει κατάληξης στο path (για file managers που δίνουν λάθος MIME)
for scheme in ('file', 'content'):
    block += f'''            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="{scheme}"/>
                <data android:host="*"/>
                <data android:mimeType="*/*"/>
''' + ''.join(
        f'                <data android:pathPattern=".*\\\\.{e}"/>\n' for e in exts) + '''            </intent-filter>
'''
block += f'            <!-- {MARK} (τέλος) -->\n        '

# Εισαγωγή μέσα στο activity που έχει MAIN/LAUNCHER
m = re.search(r'<activity\b(?:(?!</activity>).)*android\.intent\.action\.MAIN(?:(?!</activity>).)*?(</activity>)',
              xml, re.S)
if not m:
    sys.exit('Δεν βρέθηκε το κύριο <activity> στο manifest.')
xml = xml[:m.start(1)] + block + xml[m.start(1):]
path.with_suffix('.xml.bak').write_text(path.read_text(encoding='utf-8'), encoding='utf-8')
path.write_text(xml, encoding='utf-8')
print('OK — προστέθηκαν τα intent-filters (backup: AndroidManifest.xml.bak).')
