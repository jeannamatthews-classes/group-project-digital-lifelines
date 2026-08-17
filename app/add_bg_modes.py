path = 'ios/Runner/Info.plist'
with open(path, 'r') as f:
    content = f.read()

original = content

old_tail = """</dict>
</plist>"""
new_tail = """    <key>UIBackgroundModes</key>
    <array>
        <string>bluetooth-central</string>
        <string>bluetooth-peripheral</string>
    </array>
</dict>
</plist>"""

if old_tail not in content:
    print("ERROR: closing dict/plist tags not found")
else:
    content = content.replace(old_tail, new_tail)
    print("Added UIBackgroundModes")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
