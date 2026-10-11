package edu.clarkson.cs550.digital_lifelines

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
	private val logTag = "DigitalLifelinesBLE"
	private val channelName = "digital_lifelines/ble_scanner"
	private val serviceUuid = UUID.fromString("0000DDDD-0000-1000-8000-00805F9B34FB")
	private val questionUuid = UUID.fromString("0000DDDE-0000-1000-8000-00805F9B34FB")
	private val answerUuid = UUID.fromString("0000DDDF-0000-1000-8000-00805F9B34FB")
	private var gattServer: BluetoothGattServer? = null
	private var questionId = 0
	private var methodChannel: MethodChannel? = null
	private var pendingGattStartResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
		methodChannel!!.setMethodCallHandler { call, result ->
				when (call.method) {
					"startAndroidGattHosting" -> {
						questionId = call.argument<Int>("questionId") ?: 0
						startGattServer(result)
					}
					"updateAndroidGattQuestion" -> {
						questionId = call.argument<Int>("questionId") ?: 0
						Log.i(logTag, "Updated hosted questionId=$questionId")
						result.success(null)
					}
					"stopAndroidGattHosting" -> {
						stopGattServer()
						result.success(null)
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun startGattServer(result: MethodChannel.Result) {
		Log.i(logTag, "Starting GATT server for questionId=$questionId service=$serviceUuid")
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
			result.error("unsupported", "BLE GATT hosting requires Android 5.0 or newer", null)
			return
		}
		stopGattServer()
		val manager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
		gattServer = manager.openGattServer(this, gattCallback)
		if (gattServer == null) {
			Log.e(logTag, "openGattServer returned null")
			result.error("gatt_server_unavailable", "Could not open the BLE GATT server", null)
			return
		}
		val service = BluetoothGattService(serviceUuid, BluetoothGattService.SERVICE_TYPE_PRIMARY)
		service.addCharacteristic(
			BluetoothGattCharacteristic(
				questionUuid,
				BluetoothGattCharacteristic.PROPERTY_READ,
				BluetoothGattCharacteristic.PERMISSION_READ,
			),
		)
		service.addCharacteristic(
			BluetoothGattCharacteristic(
				answerUuid,
				BluetoothGattCharacteristic.PROPERTY_WRITE,
				BluetoothGattCharacteristic.PERMISSION_WRITE,
			),
		)
		pendingGattStartResult = result
		val accepted = gattServer?.addService(service) == true
		Log.i(logTag, "addService accepted=$accepted service=$serviceUuid")
		if (!accepted) {
			pendingGattStartResult = null
			stopGattServer()
			result.error("gatt_service_rejected", "Android rejected the BLE GATT service", null)
		}
	}

	private fun stopGattServer() {
		gattServer?.clearServices()
		gattServer?.close()
		gattServer = null
	}

	private val gattCallback = object : BluetoothGattServerCallback() {
		override fun onServiceAdded(status: Int, service: BluetoothGattService) {
			Log.i(logTag, "onServiceAdded status=$status service=${service.uuid}")
			val result = pendingGattStartResult ?: return
			pendingGattStartResult = null
			if (status == BluetoothGatt.GATT_SUCCESS) {
				result.success(null)
			} else {
				stopGattServer()
				result.error("gatt_service_failed", "Android failed to register the BLE GATT service", status)
			}
		}

		override fun onCharacteristicReadRequest(
			device: BluetoothDevice,
			requestId: Int,
			offset: Int,
			characteristic: BluetoothGattCharacteristic,
		) {
			Log.i(logTag, "Read request from ${device.address} characteristic=${characteristic.uuid} offset=$offset")
			if (characteristic.uuid != questionUuid || offset > 0) {
				gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_INVALID_OFFSET, offset, null)
				return
			}
			gattServer?.sendResponse(
				device,
				requestId,
				BluetoothGatt.GATT_SUCCESS,
				0,
				byteArrayOf(questionId.toByte()),
			)
			Log.i(logTag, "Returned questionId=$questionId to ${device.address}")
		}

		override fun onCharacteristicWriteRequest(
			device: BluetoothDevice,
			requestId: Int,
			characteristic: BluetoothGattCharacteristic,
			preparedWrite: Boolean,
			responseNeeded: Boolean,
			offset: Int,
			value: ByteArray,
		) {
			Log.i(logTag, "Write request from ${device.address} characteristic=${characteristic.uuid} offset=$offset")
			if (characteristic.uuid == answerUuid && offset == 0) {
				Log.i(logTag, "Received answer bytes=${value.size} responseNeeded=$responseNeeded")
				methodChannel?.invokeMethod(
					"androidAnswerReceived",
					mapOf("answer" to value.toString(Charsets.UTF_8)),
				)
			}
			if (responseNeeded) {
				gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
			}
		}
	}

	override fun onDestroy() {
		stopGattServer()
		super.onDestroy()
	}
}
