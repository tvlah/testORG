JsonExpImp = new function() {
	var namespace = null;
	var callNS = null;
	var urlNS = null;
	var jQueryRef = jQuery.noConflict();

	function getNameSpace() {
	    if (namespace == null) {
			namespace = "";
			var scripts = document.getElementsByTagName("script");
			for (var i = 0; i < scripts.length; ++i) {
				var s = scripts[i];
				if (s.src) {
					var matches = s.src.match(/.*\/(\w*?)(?:__)?csom_exp.*/);
					if (matches) {
						var nsCandidate = matches[1];
						var callNsCandidate = nsCandidate ? nsCandidate + "." : "";
						try {
							var result = sforce.apex.execute(callNsCandidate + "JsonExportController", "confirmNamespace", {});
							if (result) {
								namespace = nsCandidate;
								break;
							}
						} catch (err) {}
					}
				}
			}
		}
		return namespace;
	}

	var getCallNS = this.getCallNS = function() {
		if (callNS == null) {
			callNS = getNameSpace() ? getNameSpace() + "." : "";
		}
		return callNS;
	}

	var getUrlNS = this.getUrlNS = function() {
		if (urlNS == null) {
			urlNS = getNameSpace() ? getNameSpace() + "__" : "";
		}
		return urlNS;
	}

	var startProgress = function() {
		jQueryRef('[value="Export to JSON"]').parent().append('<img class="progress_wheel" src="/img/loading.gif" id="json_progress_wheel"/>');
	}

	var startListProgress = function() {
		jQueryRef('.mainTitle').append('<img class="progress_wheel" src="/img/loading.gif" id="json_progress_wheel"/>');
	}

	var stopProgress = function() {
		jQuery('.progress_wheel').remove();
	}

	var prepareJsonExport = function(processorJson) {
		var jobStatus = getJobStatus(processorJson);
		if (jobStatus.error) {
			stopProgress();
			showError(jobStatus.error, jobStatus.nodeErrorData);
			return;
		}
		if (jobStatus.jobFinished == true) {
			downloadJson(jobStatus.exportedDocId, jobStatus.exportName);
			return;
		}
		sforce.apex.execute(
			getCallNS() + "JsonExportController", "prepareJsonExport",
			{
				"processorJson": processorJson
			}, {
				onSuccess: function(result) { prepareJsonExport(result[0]); },
				onFailure: downloadJsonFailed
			}
		);
	}

	var getJobStatus = function(processorJson) {
		processor = jQuery.parseJSON(processorJson);
		return jQuery.parseJSON(processor.environment.data);
	}

	var createProcessorJson = function(jobStatus) {
		var jobStatusName = getCallNS() + "Exporter.JobStatus";
		var jobStatusJson = JSON.stringify(jobStatus);
		return JSON.stringify( { environment: { typeName: jobStatusName, data: jobStatusJson } } );
	}

	var downloadJson = function(docId, exportName) {
		document.location = "/apex/" + getUrlNS() + "JsonExport?docId=" + docId + "&name=" + encodeURI(exportName);
		stopProgress();
	}

	var downloadJsonFailed = function(result) {
	    stopProgress();
		console.log(result);
		var message = String(result.faultString ? result.faultString : result);
		var innerMsg = message.match(/JsonExportImportException: ([^\n]*)/);
		if (innerMsg) {
			message = innerMsg[1];
		}
		showError("Failed exporting to JSON: " + message);
	}

	this.startJsonExport = function(objectType, objectId, exportName) {
		startProgress();
		var processorJson = createProcessorJson( { objectType: objectType, objects: [objectId], exportName: exportName } );
		prepareJsonExport(processorJson);
	}

	this.startJsonListExport = function(objectType, objectIds, exportName) {
		startListProgress();
		var processorJson = createProcessorJson( { objectType: objectType, objects: objectIds, exportName: exportName } );
		prepareJsonExport(processorJson);
	}

	var showError = function(message, nodeErrorData){
		jQueryRef('<div>').html(message + prepareNodeDataErrorHtml(nodeErrorData)).dialog(
			{
				modal: true,
				width: 500,
				title: 'JSON export error',
				close: function() { jQueryRef(this).dialog('destroy').remove(); }
			}
		);
	}

	var prepareNodeDataErrorHtml = function prepareNodeDataErrorHtml(nodeErrorData) {
		var prepareNodeDescrLink = function prepareNodeDescrLink(node) {
			var retVal = '<a href="/' + node.id + '" target="_blank">';
			if (node.name) {
				retVal += node.name;
			} else {
				retVal += node.typeName + ' (Id = ' + node.id + ')';
			}

			return retVal + '</a>';
		}

		var makeTypeMapDescr = function makeTypeMapDescr(nodes, typeNameExtension) {
			var retVal = '';
			for (var typeName in nodes) {
				var nodeList = nodes[typeName];
				if (nodeList && nodeList.length) {
					var typeDefinition = '<dt><i>' + typeName + (typeNameExtension ? typeNameExtension : '') + '</i></dt>';
					typeDefinition += '<dd style="padding-left: 10px">';

					for (var i = 0; i < nodeList.length; i++) {
						typeDefinition += '<span>' + prepareNodeDescrLink(nodeList[i]) + '</span>';
					}

					retVal += typeDefinition + '</dd>';
				}
			}

			return retVal;
		}

		if (!nodeErrorData || !nodeErrorData.errorNode) {
			return '';
		}

		var html = '<div style="padding-bottom: 5px;"></div><hr><div style="padding-top: 5px;padding-left: 5px">';
		html += '<span>Error in object ' + prepareNodeDescrLink(nodeErrorData.errorNode) + '.</span>';
		html += nodeErrorData.cause ? '<p><br><b>Problem:</b> ' + nodeErrorData.cause + '<br>' : '';
		html += nodeErrorData.hintText ? '<b>Hint:</b> ' + nodeErrorData.hintText + '<br></p>' : '';
		html += '<br><i>Object references:</i><dl style="padding-left: 10px;padding-bottom: 15px;">';
		html += makeTypeMapDescr(nodeErrorData.childNodes, ' children');
		html += makeTypeMapDescr(nodeErrorData.parentNodes, ' parents');
		html += '</dl></b></div>';

		return html;
	}
}

jQuery(document).ready(function () {
	var jQqueryUICssId = '__JQueryUI1.8_id___';
	// Load jQueryUI css
	if (!document.getElementById(jQqueryUICssId)) {
		var jQueryUICss = document.createElement('link');
		jQueryUICss.id = jQqueryUICssId;
		jQueryUICss.setAttribute('rel', 'stylesheet');
		jQueryUICss.setAttribute('type', 'text/css');
		jQueryUICss.setAttribute('href', '/resource/' + JsonExpImp.getUrlNS() + 'jQueryUI_1_8/jquery-ui.css');
		document.getElementsByTagName('head')[0].appendChild(jQueryUICss);
	}
	// Load jQueryUI js
	var jQueryUIJSId = '__JQueryUI1.8.js_id___';
	if (!document.getElementById(jQueryUIJSId)) {
		var jQueryUIJS = document.createElement('script');
		jQueryUIJS.id = jQueryUIJSId;
		jQueryUIJS.setAttribute('type', 'text/javascript');
		jQueryUIJS.setAttribute('src', '/resource/' + JsonExpImp.getUrlNS() + 'jQueryUI_1_8/jquery-ui.min.js');
		document.getElementsByTagName('body')[0].appendChild(jQueryUIJS);
	}
});
