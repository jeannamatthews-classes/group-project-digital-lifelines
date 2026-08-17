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

    // Keep discovered/connected peripherals alive - CoreBluetooth drops them if not retained.
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var questionCharacteristics: [String: CBCharacteristic] = [:]
    private var answerCharacteristics: [String: CBCharacteristic] = [:]

    // MARK: - Peripheral (hosting as question-asker)
    private var peripheralManager: CBPeripheralManager?
    private var questionCharacteristic: CBMutableCharacteristic?
    private var answerCharacteristic: CBMutableCharacteristic?
    private var pendingQuestionId: Int = 0

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
                self.startHosting(questionId: questionId)
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
            case "sendAnswer":
                guard let args = call.arguments as? [String: Any],
                      let deviceId = args["deviceId"] as? String,
                      let answer = args["answer"] as? String else {
                    result(FlutterError(code: "bad_args", message: "deviceId and answer required", details: nil))
                    return
                }
                self.sendAnswer(deviceId: deviceId, answer: answer)
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
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
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
        print("BleScanner: read questionId=\(questionId) from \(deviceId)")
        channel?.invokeMethod("questionRead", arguments: ["deviceId": deviceId, "questionId": questionId])
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

    func startHosting(questionId: Int) {
        pendingQuestionId = questionId
        guard peripheralManager?.state == .poweredOn else {
            print("BleScanner: peripheralManager not powered on yet, will retry once it is")
            return
        }
        setupAndAdvertise()
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
        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "DL_Host"
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
        print("BleScanner: stopped hosting")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == questionCharUUID else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }
        request.value = Data([UInt8(pendingQuestionId & 0xFF)])
        peripheral.respond(to: request, withResult: .success)
        print("BleScanner: responded to question read with questionId=\(pendingQuestionId)")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard request.characteristic.uuid == answerCharUUID, let data = request.value else { continue }
            let answerText = String(data: data, encoding: .utf8) ?? ""
            print("BleScanner: received answer '\(answerText)'")
            channel?.invokeMethod("answerReceived", arguments: ["answer": answerText])
        }
        peripheral.respond(to: requests[0], withResult: .success)
    }
}
