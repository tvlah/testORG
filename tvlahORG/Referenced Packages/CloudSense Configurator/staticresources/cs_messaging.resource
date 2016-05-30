if (typeof(console) === 'undefined') console = {log: function(){}};

CSMSG = new function() {
	var accessKey;
	var callbacks = {};
	var msgIdGenerator;
	var configuratorWindow;
	var initialized = false;

	var MESSAGING_ACCESS_KEY = 'sid_Client';

	var CONFIGURATION_FIELDS = {
		'index': 'index',
		'status': 'status',
		'product': 'product',
		'attrname': 'attrname',
		'recurrence': 'recurrence',
		'configname': 'configname',
		'contractterm': 'contractterm',
		'productfamily': 'productfamily',
		'billingfrequency': 'billingfrequency',
		'contracttermperiod': 'contracttermperiod'
	};
	this.CFG = CONFIGURATION_FIELDS;

	var COMMANDS = {
		'getAttribute': 'getAttribute',
		'setAttribute': 'setAttribute',
		'getConfigurationField': 'getConfigurationField',
		'setConfigurationField': 'setConfigurationField',
		'getAttributeFieldValue': 'getAttributeFieldValue',
		'setAttributeFieldValue': 'setAttributeFieldValue'
	};

	this.init = function() {

		if (initialized) {
			return;
		}

		if (window.addEventListener) {
			// W3C standard
			addEventListener("message", processApiMessage, false);
		} else {
			// IE specific
			attachEvent("onmessage", processApiMessage);
		}

		// setup security key
		accessKey = getCookie(MESSAGING_ACCESS_KEY);

		// instantiate postback key generator
		msgIdGenerator = new MessageIdGenerator();

		// IE9 is missing native atob and btoa implementation, skip base 64 encoding for IE9 and less
		if( jQuery.browser.msie && parseInt(jQuery.browser.version, 10) <= 9 ) {
			window.atob = function(str) { return str; };
			window.btoa = function(str) { return str; };
		}

		initialized = true;
	}

	function processApiMessage(event) {
		var response;
		try {
			response = jQuery.parseJSON(decodeMessage(event.data));
		} catch (e) {
			/* This exception may happen when message is received in messageApi listener
			 * and message is not intended to be used with messageApi but some other listener.
			 * When this happens we leave silently and leave other listener to try to process
			 * the message.
			 */
			return;
		}

		var callbacksForRequest = getCallback(response.messageId);

		if (response.errorMsg) {
			try {
				callbacksForRequest.error(response.errorMsg);
			} catch (e) {
				console.log('Exception on execution of messaging API "error" callback.\nPlease check function implementation:\n\n' + callbacksForRequest.error.toSource() + '\n\nError details: \n' + e);
			}
		} else {
			try {
				callbacksForRequest.success(response.value);
			} catch (e) {
				console.log('Exception on execution of messaging API "success" callback.\nPlease check function implementation:\n\n' + callbacksForRequest.success.toSource() + '\n\nError details: \n' + e);
			}
		}
		removeCallback(response.messageId);
	}

	this.getAttribute = function(attrRefId, successCallback, errorCallback) {
		var messageId = registerCallbacks(successCallback, errorCallback);
		var message = JSON.stringify({
			"command": COMMANDS.getAttribute,
			"attrRefId": attrRefId,
			"messageId": messageId
		});
		configuratorWindow.postMessage(encodeMessage(message), '*');
	}

	this.getAttributeFieldValue = function(attrRefId, fieldName, successCallback, errorCallback) {
		var messageId = registerCallbacks(successCallback, errorCallback);
		var message = JSON.stringify({
			"command": COMMANDS.getAttributeFieldValue,
			"attrRefId": attrRefId,
			"fieldName": fieldName,
			"messageId": messageId
		});
		configuratorWindow.postMessage(encodeMessage(message), '*');
	}

	this.getConfigurationField = function(cfgRefId, fieldName, successCallback, errorCallback) {
		if (CONFIGURATION_FIELDS[fieldName] === undefined) {
			throw 'Configuration fieldName "' + fieldName + '" does not exist.';
		}
		var messageId = registerCallbacks(successCallback, errorCallback);
		var message = JSON.stringify({
			"command": COMMANDS.getConfigurationField,
			"cfgRefId": cfgRefId,
			"fieldName": fieldName,
			"messageId": messageId
		});
		configuratorWindow.postMessage(encodeMessage(message), '*');
	}

	this.setAttribute = function(attrRefId, value, successCallback, errorCallback) {
		var messageId = registerCallbacks(successCallback, errorCallback);
		var message = JSON.stringify({
			"command": COMMANDS.setAttribute,
			"attrRefId": attrRefId,
			"value": value,
			"accessKey": accessKey,
			"messageId": messageId
		});
		configuratorWindow.postMessage(encodeMessage(message), '*');
	}

	this.setAttributeFieldValue = function(attrRefId, fieldName, value, successCallback, errorCallback) {
		var messageId = registerCallbacks(successCallback, errorCallback);
		var message = JSON.stringify({
			"command": COMMANDS.setAttributeFieldValue,
			"attrRefId": attrRefId,
			"fieldName": fieldName,
			"value": value,
			"accessKey": accessKey,
			"messageId": messageId
		});
		configuratorWindow.postMessage(encodeMessage(message), '*');
	}

	this.setConfigurationField = function(cfgRefId, fieldName, value, successCallback, errorCallback) {
		if (CONFIGURATION_FIELDS[fieldName] === undefined) {
			throw 'Configuration fieldName "' + fieldName + '" does not exist.';
		}
		var messageId = registerCallbacks(successCallback, errorCallback);
		var message = JSON.stringify({
			"command": COMMANDS.setConfigurationField,
			"cfgRefId": cfgRefId,
			"fieldName": fieldName,
			"value": value,
			"accessKey": accessKey,
			"messageId": messageId
		});
		configuratorWindow.postMessage(encodeMessage(message), '*');
	}

	this.customCommand = function(cmdName, params, successCallback, errorCallback) {
		var messageId = registerCallbacks(successCallback, errorCallback);
		var message = JSON.stringify({
			"command": cmdName,
			"params": params,
			"accessKey": accessKey,
			"messageId": messageId
		});
		configuratorWindow.postMessage(encodeMessage(message), '*');
	}

	function MessageIdGenerator() {
		var postbackMessageId = 0;

		this.generate = function() {
			return postbackMessageId++;
		}
	}

	function registerCallbacks(successCallback, errorCallback) {
		var messageId = msgIdGenerator.generate();
		callbacks[messageId] = {
			success: successCallback || function() {},
			error: errorCallback || function(errorMsg) { console.log('ERROR received : ' + errorMsg); }
		}
		return messageId;
	}

	function getCallback(messageId) {
		return callbacks[messageId];
	}

	function removeCallback(messageId) {
		delete callbacks[messageId];
	}

	this.setConfiguratorWindow = function(winOrigin) {
		configuratorWindow = winOrigin;
	}

	function getCookie(cname) {
		var name = cname + '=';
		var ca = document.cookie.split(';');
		for(var i = 0; i < ca.length; i++) {
			var c = ca[i].trim();
			if (c.indexOf(name) == 0) {
				return c.substring(name.length, c.length);
			}
		}
		return '';
	}

	/**
	 * Encode and decode message functions. Except 64 base encoding additional
	 * escape and encode is applied to bypass problems that native btoa and atob
	 * functions have with non Latin1 character set.
	 *
	 * @param msg String message to be encoded or decoded
	 */
	function encodeMessage(msg) {
		return btoa(unescape(encodeURIComponent(msg)));
	}

	function decodeMessage(msg) {
		return decodeURIComponent(escape(atob(msg)));
	}

	this.help = function() {
		var help = [];
		help.push("Available methods:");
		help.push("");
		help.push("CSMSG.getAttribute(attrRefId, successCallback, errorCallback)");
		help.push("CSMSG.getAttributeFieldValue(attrRefId, fieldName, successCallback, errorCallback)");
		help.push("CSMSG.getConfigurationField(cfgRefId, fieldName, successCallback, errorCallback)");
		help.push("");
		help.push("CSMSG.setAttribute(attrRefId, value, successCallback, errorCallback)");
		help.push("CSMSG.setAttributeFieldValue(attrRefId, fieldName, value, successCallback, errorCallback)");
		help.push("CSMSG.setConfigurationField(cfgRefId, fieldName, value, successCallback, errorCallback)");
		help.push("");
		help.push("CSMSG.customCommand(cmdName, params, successCallback, errorCallback)");
		help.push("CSMSG.help()");
		help.push("");
		help.push("*successCallback and errorCallback params are optional.");
		help.push("*For your convenience CSMSG.CFG contains list of available ConfigurationFields to be used as parameter - to avoid any eventual typo errors.");
		console.log(help.join("\n"));
	}
}();
CSMSG.init();
