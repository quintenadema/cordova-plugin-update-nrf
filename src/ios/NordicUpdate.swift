import iOSDFULibrary

@objc(NordicUpdate) class NordicUpdate : CDVPlugin, CBCentralManagerDelegate, DFUServiceDelegate, DFUProgressDelegate  {

	var dfuCallbackId: String?
	var manager = CBCentralManager()
	var dfuController: DFUServiceController?

	@objc(pluginInitialize)
	override func pluginInitialize() {
		super.pluginInitialize()
		manager = CBCentralManager(delegate: self, queue: nil)
	}

	@objc(updateFirmware:)
	func updateFirmware(command: CDVInvokedUrlCommand) {
		commandDelegate.run {
			self.dfuCallbackId = command.callbackId


			var pluginResult = CDVPluginResult(
				status: CDVCommandStatus_ERROR
			)

			let deviceId = command.arguments[0] as? String ?? ""
			let fileURL = command.arguments[1] as? String ?? ""

			if deviceId.count < 1 {

				self.commandDelegate!.send(
					CDVPluginResult(
						status: CDVCommandStatus_ERROR,
						messageAs: [
							"status": "dfuAborted",
							"message": "Device ID is required"
						]
					),
					callbackId: self.dfuCallbackId

				)
				return
			}

			if (fileURL.count < 1) {

				self.commandDelegate!.send(
					CDVPluginResult(
						status: CDVCommandStatus_ERROR,
						messageAs: [
							"status": "dfuAborted",
							"message": "File URL is required"
						]
					),
					callbackId: self.dfuCallbackId

				)
				return
			}

			if (deviceId.count > 0 && fileURL.count > 0) {
				let sourceURL = self.getURI(url: fileURL)


				pluginResult = self.startUpgrade(deviceId: deviceId, url: sourceURL)
			}


			self.commandDelegate!.send(
				pluginResult,
				callbackId: command.callbackId
			)
		}
	}

	func startUpgrade(deviceId: String, url: URL) -> CDVPluginResult {
		let selectedFirmware = DFUFirmware(urlToZipFile: url)

		if (!(selectedFirmware?.valid ?? true) || selectedFirmware == nil) {
			return CDVPluginResult(
				status: CDVCommandStatus_ERROR,
				messageAs: ["status": "dfuAborted",
							"message": "Invalid firmware"]
			)
		}

		let deviceUUID = UUID.init(uuidString: deviceId) ?? nil

		if (deviceUUID == nil) {
			return CDVPluginResult(
				status: CDVCommandStatus_ERROR,
				messageAs: [
					"status": "dfuAborted",
					"message": "Address " + deviceId + " is not a valid UUID"
				]
			)
		}

		let peripherals = manager.retrievePeripherals(withIdentifiers: [deviceUUID!])
		if (peripherals.count < 1) {
			return CDVPluginResult(
				status: CDVCommandStatus_ERROR,
				messageAs: [
					"status": "dfuAborted",
					"message": "Device with address " + deviceId + " not found"
				]
			)
		}

		let deviceP = peripherals[0];

		let initiator = DFUServiceInitiator(queue: nil).with(firmware: selectedFirmware!)

		initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
		initiator.packetReceiptNotificationParameter = 10
		initiator.forceDfu = false
		initiator.delegate = self
		initiator.progressDelegate = self

		dfuController = initiator.start(target: deviceP)!

		let pluginResult = CDVPluginResult(
			status: CDVCommandStatus_OK,
			messageAs: deviceId + ":" + url.absoluteString
		)

		pluginResult?.setKeepCallbackAs(true)

		return pluginResult!
	}

	func dfuStateDidChange(to state: DFUState) {
		var stateStr: String = "unknown";
		switch(state) {
		case DFUState.connecting:
			stateStr = "deviceConnecting"
			break;
		case DFUState.starting: stateStr = "dfuProcessStarting"; break;
		case DFUState.enablingDfuMode: stateStr = "enablingDfuMode"; break;
		case DFUState.uploading: stateStr = "firmwareUploading"; break;
		case DFUState.validating: stateStr = "firmwareValidating"; break;
		case DFUState.disconnecting: stateStr = "deviceDisconnecting"; break;
		case DFUState.completed: stateStr = "dfuCompleted"; break;
		case DFUState.aborted: stateStr = "dfuAborted"; break;
		}

		let pluginResult = CDVPluginResult(
			status: CDVCommandStatus_OK,
			messageAs: ["status": stateStr]
		)
		pluginResult?.setKeepCallbackAs(true)
		self.commandDelegate.send(pluginResult, callbackId: dfuCallbackId)

		if (state == DFUState.aborted || state == DFUState.completed) {
			self.clearHandlers()
		}
	}

	func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
		let pluginResult = CDVPluginResult(
			status: CDVCommandStatus_ERROR,
			messageAs: [
				"message": message,
				"status": "dfuAborted"
			]
		)

		self.commandDelegate.send(pluginResult, callbackId: dfuCallbackId)
		self.clearHandlers()
	}

	func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
		let message = [
			"status": "progressChanged",
			"progress": [
				"percent": progress,
				"speed": currentSpeedBytesPerSecond,
				"avgSpeed": avgSpeedBytesPerSecond,
				"currentPart": part,
				"partsTotal": totalParts,
			]
		] as [String : Any]

		let pluginResult = CDVPluginResult(
			status: CDVCommandStatus_OK,
			messageAs: message
		)
		pluginResult?.setKeepCallbackAs(true)
		self.commandDelegate.send(pluginResult, callbackId: dfuCallbackId)
	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {

	}

	func clearHandlers() {
		self.dfuCallbackId = nil
		self.dfuController = nil

		self.pluginInitialize()
	}

	func getURI(url: String) -> URL  {
		var filePath: String = ""
		var resourceURL: NSURL = NSURL.init(string: url)!
		if (url.hasPrefix("cdvfile://")) {
			let filePlugin: CDVFile = commandDelegate.getCommandInstance("File") as! CDVFile
			let url = CDVFilesystemURL.fileSystemURL(with: url)
			filePath = filePlugin.filesystemPath(for: url)
			if (filePath != "") {
				resourceURL = NSURL.init(string: filePath)!
			}
		}

		return resourceURL as URL

	}
}
