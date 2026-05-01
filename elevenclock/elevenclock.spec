# -*- mode: python ; coding: utf-8 -*-

import importlib, os

#package_imports = [['qtmodern', ['resources/frameless.qss', 'resources/style.qss']]]



a = Analysis(['__init__.py'],
             pathex=['Y:\ElevenClock-Store\elevenclock_bin'],
#             binaries=[('*.pyc', '.')],
             datas=[('resources/', 'resources/'), ("lang/", "lang/")],
             hiddenimports=["win32gui"],
             hookspath=[],
             runtime_hooks=[],
             excludes=['eel', 'tkinter', "PyQt5", "PySide2", "pygame", "numpy", "matplotlib", "elevenclock", "zroya"],
             noarchive=False)


pyz = PYZ(a.pure, a.zipped_data)
exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='elevenclock',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    contents_directory='.',
    icon="resources/icon.ico",
    version="../elevenclock-version-info"
)


coll = COLLECT(
    exe,
    a.binaries,
#    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='ElevenClock',
)