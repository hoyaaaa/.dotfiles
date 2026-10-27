#!/usr/bin/env python3
from pathlib import Path
import plistlib,subprocess
# A primary-profile shim prevents Orion's last-active-profile setting from stealing personal links.
primary=Path.home()/'Applications/Orion/Orion Profiles/Defaults/Orion - 개인.app'
launcher=primary/'Contents/MacOS/Orion';launcher.parent.mkdir(parents=True,exist_ok=True)
launcher.write_text('#!/bin/bash\nexec /usr/bin/arch -arm64 "/Applications/Orion.app/Contents/MacOS/Orion" -P Defaults\n');launcher.chmod(0o755)
(primary/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier':'com.kagi.kagimacOS.Defaults','CFBundleName':'Orion - 개인','CFBundleExecutable':'Orion','CFBundlePackageType':'APPL','CFBundleVersion':'1','LSArchitecturePriority':['arm64','x86_64'],'CFBundleURLTypes':[{'CFBundleURLSchemes':['http','https'],'CFBundleTypeRole':'Viewer'}]}))
subprocess.run(['codesign','--force','--sign','-',str(primary)],check=True)
subprocess.run(['/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister','-f',str(primary)],check=True)
root=Path(__file__).resolve().parent;app=Path.home()/'Applications/Orion Link Chooser.app';exe=app/'Contents/MacOS/OrionLinkChooser';exe.parent.mkdir(parents=True,exist_ok=True)
subprocess.run(['swiftc',str(root/'main.swift'),'-o',str(exe),'-framework','AppKit'],check=True)
info={'CFBundleIdentifier':'local.hoya.orion-link-chooser','CFBundleName':'Orion Link Chooser','CFBundleDisplayName':'Orion 링크 선택','CFBundleExecutable':'OrionLinkChooser','CFBundlePackageType':'APPL','CFBundleVersion':'1','CFBundleShortVersionString':'1.0','LSUIElement':True,'NSHighResolutionCapable':True,'CFBundleURLTypes':[{'CFBundleURLName':'Web links','CFBundleURLSchemes':['http','https'],'CFBundleTypeRole':'Viewer'}],'CFBundleDocumentTypes':[{'CFBundleTypeName':'HTML document','CFBundleTypeRole':'Viewer','LSItemContentTypes':['public.html','public.xhtml'],'LSHandlerRank':'Alternate'}]}
(app/'Contents/Info.plist').write_bytes(plistlib.dumps(info));subprocess.run(['codesign','--force','--sign','-',str(app)],check=True);subprocess.run([str(exe),'--self-test'],check=True)
subprocess.run(['/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister','-f',str(app)],check=True)
print('Installed:',app)
