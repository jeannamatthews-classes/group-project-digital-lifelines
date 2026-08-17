import Foundation
import CoreBluetooth
import Flutter

class BleScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    // MARK: - Central (scanning + connecting as joiner)
    private var centralManager: CBCentralManager?
    private var channel: FlutterMethodChannel?
    private let serviceUUID = CBUUID(string: "0000DDDD-0000-1000-8000-00805F9B34FB")
    private let questionCharUUID = CBUUID(string: "0000DDDE-0000-1000-8000-00805F9B34FB")
    private let answerCharUUID = CBUUID(string: "0000DDDF-0000-1000-8000-00805F9B34FB")

    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var questionCharacteristics: [String: CBCharacteristic] = [:]
    private var answerCharacteristics: [String: CBCharacteristic] = [:]

    // MARK: - Peripheral (hosting as question-asker)
    private var peripheralManager: CBPeripheralManager?
    private var questionCharacteristic: CBMutableCharacteristic?
    private var answerCharacteristic: CBMutableCharacteristic?
    private var pendingQuestionId: Int = 0
    private var pendingPairCode: Int = 0

    // Devices that have been approved to see the real question/send answers.
    private var acceptedCentralIDs: Set<String> = []
    // Devices we've already asked the user about, so we don't spam repeat prompts.
    private var pendingApprovalIDs: Set<String> = []
    // Devices the user explicitly rejected - silently ignored from then on.
    private var blockedCentralIDs: Set<String> = []

    init(messenger: FlutterBinaryMessenger) {
        super.init()
        channel = FlutterMethodChannel(name: "digital_lifelines/ble_scanner", binaryMessenger: messenger)
        channel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {
            case "startScan":
                self.startScan()
                result(nil)
            case "stopScan":
                self.stopScan()
                result(nil)
            case "startHosting":
                guard let args = call.arguments as? [String: Any],
                      let questionId = args["questionId"] as? Int else {
                    result(FlutterError(code: "bad_args", message: "questionId required", details: nil))
                    return
                }
                let pairCode = args["pairCode"] as? Int ?? 0
                self.startHosting(questionId: questionId, pairCode: pairCode)
                result(nil)
            case "updateHostedQuestion":
                guard let args = call.arguments as? [String: Any],
                      let questionId = args["questionId"] as? Int else {
                    result(FlutterError(code: "bad_args", message: "questionId required", details: nil))
                    return
                }
                self.updateHostedQuestion(questionId: questionId)
                result(nil)
            case "stopHosting":
                self.stopHosting()
                result(nil)
            case "connectAndReadQuestion":
                guard let args = call.arguments as? [String: Any],
                      let deviceId = args["deviceId"] as? String else {
                    result(FlutterError(code: "bad_args", message: "deviceId required", details: nil))
                    return
                }
                self.connectAndReadQuestion(deviceId: deviceId)
                result(nil)
            case "rereadQuestion":
                guard let args = call.arguments as? [String: Any],
                      let deviceId = args["deviceId"] as? String else {
                    result(FlutterError(code: "bad_args", message: "deviceId required", details: nil))
                    return
                }
                self.rereadQuestion(deviceId: deviceId)
                result(nil)
            case "sendAnswer":
                guard let args = call.arguments as? [String: Any],
                      let deviceId = args["deviceId"] as? String,
                      let answer = args["answer"] as? String else {
                    result(FlutterError(code: "bad_args", message: "deviceId and answer required", details: nil))
                    return
                }
                self.sendAnswer(deviceId: deviceId, answer: answer)
                result(nil)
            case "acceptConnection":
                guard let args = call.arguments as? [String: Any],
                      let deviceId = args["deviceId"] as? String else {
                    result(FlutterError(code: "bad_args", message: "deviceId required", details: nil))
                    return
                }
                self.acceptConnection(deviceId: deviceId)
                result(nil)
            case "rejectConnection":
                guard let args = call.arguments as? [String: Any],
                      let deviceId = args["deviceId"] as? String else {
                    result(FlutterError(code: "bad_args", message: "deviceId required", details: nil))
                    return
                }
                self.rejectConnection(deviceId: deviceId)
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    // MARK: - Scanning (joiner side)

    func startScan() {
        print("BleScanner: startScan() called, centralManager state = \(String(describing: centralManager?.state.rawValue))")
        guard centralManager?.state == .poweredOn else {
            print("BleScanner: Bluetooth not powered on yet")
            return
        }
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        print("BleScanner: scanForPeripherals call completed, isScanning = \(String(describing: centralManager?.isScanning))")
    }

    func stopScan() {
        centralManager?.stopScan()
        print("BleScanner: stopped scanning")
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("BleScanner: adapter state changed to \(central.state.rawValue)")
        if central.state == .poweredOn {
            startScan()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Prefer the freshly-broadcast local name over any cached system
        // name iOS may already know for this device (e.g. from Apple's own
        // background Continuity features) - otherwise our custom pair-code
        // name gets silently overridden and matching breaks.
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name ?? ""
        let serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map { $0.uuidString } ?? []

        discoveredPeripherals[peripheral.identifier.uuidString] = peripheral

        print("BleScanner: found device id=\(peripheral.identifier.uuidString) name=\(name) rssi=\(RSSI) services=\(serviceUUIDs)")
        let result: [String: Any] = [
            "id": peripheral.identifier.uuidString,
            "name": name,
            "rssi": RSSI.intValue
        ]
        channel?.invokeMethod("deviceFound", arguments: result)
    }

    // MARK: - Connecting + reading question (joiner side)

    func connectAndReadQuestion(deviceId: String) {
        guard let peripheral = discoveredPeripherals[deviceId] else {
            print("BleScanner: no known peripheral for id \(deviceId)")
            return
        }
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
        print("BleScanner: connecting to \(deviceId)")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("BleScanner: connected to \(peripheral.identifier.uuidString), discovering services")
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("BleScanner: failed to connect to \(peripheral.identifier.uuidString): \(String(describing: error))")
        channel?.invokeMethod("connectionFailed", arguments: ["deviceId": peripheral.identifier.uuidString])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("BleScanner: service discovery error: \(error)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([questionCharUUID, answerCharUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("BleScanner: characteristic discovery error: \(error)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        let deviceId = peripheral.identifier.uuidString
        for characteristic in characteristics {
            if characteristic.uuid == questionCharUUID {
                questionCharacteristics[deviceId] = characteristic
                peripheral.readValue(for: characteristic)
            } else if characteristic.uuid == answerCharUUID {
                answerCharacteristics[deviceId] = characteristic
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("BleScanner: read error: \(error)")
            return
        }
        guard characteristic.uuid == questionCharUUID, let data = characteristic.value, data.count > 0 else { return }
        let questionId = Int(data[0])
        let deviceId = peripheral.identifier.uuidString

        if questionId == 0 {
            // 0 is a reserved sentinel meaning "waiting for host to accept
            // this connection" - not a real question yet.
            print("BleScanner: connection to \(deviceId) still pending approval")
            channel?.invokeMethod("connectionPending", arguments: ["deviceId": deviceId])
            return
        }

        print("BleScanner: read questionId=\(questionId) from \(deviceId)")
        channel?.invokeMethod("questionRead", arguments: ["deviceId": deviceId, "questionId": questionId])
    }

    /// Re-reads the question characteristic on an already-connected device -
    /// used to poll for updates (new question, or approval finally granted)
    /// without needing a fresh connection.
    func rereadQuestion(deviceId: String) {
        guard let peripheral = discoveredPeripherals[deviceId],
              let characteristic = questionCharacteristics[deviceId] else { return }
        peripheral.readValue(for: characteristic)
    }

    // MARK: - Sending an answer (joiner side)

    func sendAnswer(deviceId: String, answer: String) {
        guard let peripheral = discoveredPeripherals[deviceId],
              let characteristic = answerCharacteristics[deviceId] else {
            print("BleScanner: cannot send answer, missing peripheral/characteristic for \(deviceId)")
            return
        }
        let data = answer.data(using: .utf8) ?? Data()
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("BleScanner: wrote answer '\(answer)' to \(deviceId)")
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("BleScanner: write error: \(error)")
            channel?.invokeMethod("answerSendFailed", arguments: ["deviceId": peripheral.identifier.uuidString])
        } else {
            channel?.invokeMethod("answerSent", arguments: ["deviceId": peripheral.identifier.uuidString])
        }
    }

    // MARK: - Hosting (peripheral / question-asker side)

    func startHosting(questionId: Int, pairCode: Int) {
        pendingQuestionId = questionId
        pendingPairCode = pairCode
        guard peripheralManager?.state == .poweredOn else {
            print("BleScanner: peripheralManager not powered on yet, will retry once it is")
            return
        }
        setupAndAdvertise()
    }

    /// Updates the question being hosted without restarting advertising -
    /// lets someone pick a new question without leaving the screen.
    func updateHostedQuestion(questionId: Int) {
        pendingQuestionId = questionId
        print("BleScanner: updated hosted question to \(questionId)")
    }

    private func setupAndAdvertise() {
        let qChar = CBMutableCharacteristic(
            type: questionCharUUID,
            properties: [.read],
            value: nil,
            permissions: [.readable]
        )
        let aChar = CBMutableCharacteristic(
            type: answerCharUUID,
            properties: [.write],
            value: nil,
            permissions: [.writeable]
        )
        questionCharacteristic = qChar
        answerCharacteristic = aChar

        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [qChar, aChar]

        peripheralManager?.removeAllServices()
        peripheralManager?.add(service)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("BleScanner: failed to add service: \(error)")
            return
        }
        print("BleScanner: service added, starting advertising")
        let localName = pendingPairCode > 0 ? "BLS\(pendingPairCode)" : "DL_Host"
        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: localName
        ])
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("BleScanner: peripheralManager state = \(peripheral.state.rawValue)")
        if peripheral.state == .poweredOn && pendingQuestionId != 0 {
            setupAndAdvertise()
        }
    }

    func stopHosting() {
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()
        pendingQuestionId = 0
        pendingPairCode = 0
        acceptedCentralIDs.removeAll()
        pendingApprovalIDs.removeAll()
        blockedCentralIDs.removeAll()
        print("BleScanner: stopped hosting")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == questionCharUUID else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }

        let centralId = request.central.identifier.uuidString

        if blockedCentralIDs.contains(centralId) {
            // Explicitly rejected - always respond with the pending
            // sentinel, never the real question.
            request.value = Data([0])
            peripheral.respond(to: request, withResult: .success)
            return
        }

        if acceptedCentralIDs.contains(centralId) {
            request.value = Data([UInt8(pendingQuestionId & 0xFF)])
            peripheral.respond(to: request, withResult: .success)
            print("BleScanner: responded to accepted device \(centralId) with questionId=\(pendingQuestionId)")
            return
        }

        // First time seeing this device (or still waiting on a decision) -
        // ask the user once, and respond with the pending sentinel until
        // they decide.
        if !pendingApprovalIDs.contains(centralId) {
            pendingApprovalIDs.insert(centralId)
            channel?.invokeMethod("connectionRequest", arguments: ["deviceId": centralId])
            print("BleScanner: new connection request from \(centralId), asking for approval")
        }
        request.value = Data([0])
        peripheral.respond(to: request, withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard request.characteristic.uuid == answerCharUUID, let data = request.value else { continue }
            let centralId = request.central.identifier.uuidString

            // Only forward answers from devices we've actually accepted -
            // ignore writes from anyone else.
            if acceptedCentralIDs.contains(centralId) {
                let answerText = String(data: data, encoding: .utf8) ?? ""
                print("BleScanner: received answer '\(answerText)' from accepted device \(centralId)")
                channel?.invokeMethod("answerReceived", arguments: ["answer": answerText])
            } else {
                print("BleScanner: ignoring answer write from unaccepted device \(centralId)")
            }
        }
        peripheral.respond(to: requests[0], withResult: .success)
    }

    // MARK: - Accept/reject handshake (host side)

    func acceptConnection(deviceId: String) {
        acceptedCentralIDs.insert(deviceId)
        pendingApprovalIDs.remove(deviceId)
        print("BleScanner: accepted connection from \(deviceId)")
    }

    func rejectConnection(deviceId: String) {
        blockedCentralIDs.insert(deviceId)
        pendingApprovalIDs.remove(deviceId)
        print("BleScanner: rejected connection from \(deviceId)")
    }
}
