import Foundation
import CoreBluetooth
import Flutter

class BleScanner: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    private var channel: FlutterMethodChannel?
    private let targetServiceUUID = CBUUID(string: "0000DDDD-0000-1000-8000-00805F9B34FB")

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
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

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
        let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
        var questionId: Int? = nil
        if let data = serviceData?[targetServiceUUID], data.count > 0 {
            questionId = Int(data[0])
        }

        print("BleScanner: found device id=\(peripheral.identifier.uuidString) name=\(name) rssi=\(RSSI) services=\(serviceUUIDs) questionId=\(String(describing: questionId))")

        let result: [String: Any] = [
            "id": peripheral.identifier.uuidString,
            "name": name,
            "rssi": RSSI.intValue,
            "questionId": questionId as Any
        ]
        channel?.invokeMethod("deviceFound", arguments: result)
    }
}