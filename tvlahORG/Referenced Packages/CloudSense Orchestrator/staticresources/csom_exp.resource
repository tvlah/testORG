JsonExpImp = new function() {
	var namespace = this.namespace = getNameSpace();
	var callNS = this.callNS = namespace ? namespace + "." : "";
	var urlNS = this.urlNS = namespace ? namespace + "__" : "";

	function getNameSpace() {
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
							return nsCandidate;
						}
					} catch (err) {}
				}
			}
		}

		return "";
	}

	var startProgress = function() {
		jQuery('[value="Export to JSON"]').parent().append('<img class="progress_wheel" src="/img/loading.gif" id="json_progress_wheel"/>');
	}

	var stopProgress = function() {
		jQuery('.progress_wheel').remove();
	}

	var prepareJsonExport = function(jobStatusJson) {
		var jobStatus = jQuery.parseJSON(jobStatusJson);
		if (jobStatus.jobFinished == true) {
			downloadJson(jobStatus.exportedDocId, jobStatus.exportName);
			return;
		}
		sforce.apex.execute(
			callNS + "JsonExportController", "prepareJsonExport",
			{
				"jobStatus": jobStatusJson
			}, {
				onSuccess: function(result) { prepareJsonExport(result[0]); },
				onFailure: downloadJsonFailed
			}
		);
	}

	var downloadJson = function(docId, exportName) {
		var downloadURL = "/apex/" + urlNS + "JsonExportExtend?docId=" + docId + "&name=" + encodeURI(exportName);
		document.location = downloadURL;
		stopProgress();
	}

	var downloadJsonFailed = function(result) {
	    stopProgress();
		console.log(result);
		alert("Failed exporting to JSON: " + (result.faultString ? result.faultString : result));
	}

	this.startJsonExport = function(objectType, objectId, exportName) {
		startProgress();
		var jobStatusJson = JSON.stringify({objectType: objectType, objects: [objectId], exportName: exportName});
		prepareJsonExport(jobStatusJson);
	}

	this.startJsonListExport = function(objectType, exportName) {
		// get ids of selected records
		var selected = [];
		jQuery("[name=ids]:checked").each(function() { selected.push(this.value); });
		if (selected.length == 0) {
			return;
		}

		startProgress();
		var jobStatusJson = JSON.stringify({objectType: objectType, objects: selected, exportName: exportName});
		prepareJsonExport(jobStatusJson);
	}
}
