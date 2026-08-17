path = 'ios/Runner/BleScanner.swift'
with open(path, 'r') as f:
    content = f.read()

original = content

old_case = """            case "sendAnswer":"""
new_case = """            case "rereadQuestion":
                guard let args = call.arguments as? [String: Any],
                      let deviceId = args["deviceId"] as? String else {
                    result(FlutterError(code: "bad_args", message: "deviceId required", details: nil))
                    return
                }
                self.rereadQuestion(deviceId: deviceId)
                result(nil)
            case "sendAnswer":"""
if old_case not in content:
    print("ERROR: sendAnswer case not found")
elif "rereadQuestion\":" in content:
    print("Already present")
else:
    content = content.replace(old_case, new_case, 1)
    print("Added missing rereadQuestion method channel case")

if content == original:
    print("NOTHING CHANGED")
else:
    with open(path, 'w') as f:
        f.write(content)
    print("File saved.")
