var exec = require('cordova/exec');

var updateNrf = {};
updateNrf['dfu'] = function(deviceIdentifier, fileURL, resultCallback, errorCallback) {
	exec(resultCallback, errorCallback, "NordicUpdate", "updateFirmware", [deviceIdentifier, fileURL]);
}

module.exports = updateNrf;