// CS core
jQuery.noConflict();
if (typeof(console) === 'undefined') console = {log: function(){}};

var CS = CS || {};

Array.prototype.remove = function(from, to) {
	var rest = this.slice((to || from) + 1 || this.length);
	this.length = from < 0 ? this.length + from : from;
	// detect ie9 - native objects don't have apply method
	if (this.push.apply) return this.push.apply(this, rest); else return this.push(rest);
};

CS.namespace = function(name) {

	var	parts = (''+name).split('.'),
		parent = CS;

	if (parts[0] === 'CS') parts = parts.slice(1);

	for (var i = 0, l = parts.length; i < l; i++) {

		if (typeof(parent[parts[i]]) === 'undefined') {
			parent[parts[i]] = {};
		}

		parent = parent[parts[i]];
	}

	return parent;
};


function initCore() {
	var $ = this.$ = jQuery.noConflict();
	var ORIGINAL_OPTIONS = 'originalOptions';
	var HIDDEN = 'hidden';
	var READ_ONLY = 'readOnly';
	var RULE_LOCK = 'ruleLock';
	var LOOKUP_DATA = this.LOOKUP_DATA = 'lookupData';
	var PREVIOUS_SELECTED = 'previousSelected';
	var PREVIOUS_VALUE = 'previousValue';
	var REQUIRED_CLASS = 'requiredInput';
	var READONLY_PLACEHOLDER = 'roPlaceholder';
	var FIELD_NAME_SALES_PRICE = this.FIELD_NAME_SALES_PRICE = 'price';
	var FIELD_NAME_LIST_PRICE = this.FIELD_NAME_LIST_PRICE = 'list_price';
	var FIELD_NAME_DISCOUNT_AMOUNT = 'discount_amount';
	var FIELD_NAME_DISCOUNT_TYPE = 'discount_type';
	var DISCOUNT_TYPE_AMOUNT = this.DISCOUNT_TYPE_AMOUNT = 'amount';
	var DISCOUNT_TYPE_PERCENTAGE = this.DISCOUNT_TYPE_PERCENTAGE = 'percentage';
	var EMPTY = this.EMPTY = '';
	var SELECT2_COLUMN_SIZE_CSV = 'data-column-size-csv';
	var INPUT_DELAY_BEFORE_AJAX = this.INPUT_DELAY_BEFORE_AJAX = 250;
	var FLOAT_COMPARISON_LIMIT = 0.00000001;
	var DISPLAY_VALUE_TYPE = 'Display Value';
	var NULL_OPTION_VALUE = this.NULL_OPTION_VALUE = '--None--';

	var FREQUENCIES = {
		'annual': 1,
		'bi-annual': 2,
		'quarterly': 4,
		'monthly': 12,
		'weekly': 52,
		'daily': 365
	};

	var FREQUENCY_NAMES = {
		'1': 'annually',
		'2': 'bi-annually',
		'4': 'quarterly',
		'12': 'monthly',
		'52': 'weekly',
		'365': 'daily'
	};

	var PERIODS = {
		'year': 1,
		'quarter': 4,
		'month': 12,
		'week': 52,
		'day': 365
	};

	var PERIOD_NAMES = {
		'1': 'year',
		'4': 'quarter',
		'12': 'month',
		'52': 'week',
		'365': 'day'
	};

	this.ATTRIBUTE_TYPES = {
		'CALCULATION': 'Calculation',
		'CHECKBOX': 'Checkbox',
		'DATE': 'Date',
		'LOOKUP': 'Lookup',
		'MULTISELECT_LIST': 'MultiSelect List',
		'RELATED_PRODUCT': 'Related Product',
		'SELECT_LIST': 'Select List',
		'TEXT_DISPLAY': 'Text Display',
		'USER_INPUT': 'User Input',
		'RADIO_BUTTON': 'Radio Button',
		'DISPLAY_VALUE': 'Display Value'
	};

	this.DATA_TYPES = {
		'BOOLEAN': 'Boolean',
		'DECIMAL': 'Decimal',
		'DOUBLE': 'Double',
		'INTEGER': 'Integer',
		'STRING': 'String',
		'DATE': 'Date'
	};

	var calculations = [];
	var loggingEnabled = false;
	var loggingTraceEnabled = false;
	var loadingOverlayEnabled = true;
	var progressBarImageUrl = '';
	var infoMessages = {};
	var lookupQueryCache = this.lookupQueryCache = {};
	var executeAfterLookupQueriesQueue = this.executeAfterLookupQueriesQueue = [];
	var lookupQueryQueueTimer = this.lookupQueryQueueTimer = null;
	var cachedLookupValues = this.cachedLookupValues = {};
	var multiSelectLookups = this.multiSelectLookups = {};
	var selectListLookupDataCache = this.selectListLookupDataCache = {};

	/**
	 * Adds callback method to be invoked after query lookup queries are done.
	 * Be sure that you didn't already add callback with same name.
	 * If you want your callback to be invoked with certain arguments, add them as array passing it as third parameter.
	 *  WARNING: callback is then invoked with callback.apply(null, args)
	 *
	 * @param callback Callback function
	 * @param name Callback function name
	 * @param args Arguments to be passed to callback function (it is expected to be an array or typeof Arguments)
	 */
	function executeOnLookupQueriesDone(callback, name, args) {
		if (typeof(callback) != 'function') {
			throw 'Invalid arguments: CS.executeOnLookupQueriesDone(callback, name) callback must be a function';
		}
		if (!name) {
			throw 'Invalid arguments: CS.executeOnLookupQueriesDone(callback, name) name must be specified';
		}
		if (!callback.name) callback.name = name;

		if (_.filter(executeAfterLookupQueriesQueue, function(it){ return it.name == name; }).length > 0) {
			log('Function ' + name + ' already queued');
		} else {
			log('Queuing function after lookup queries');
			executeAfterLookupQueriesQueue.push({
				'invokeCallback' : callback,
				'name' : name,
				'args' : args
			});
		}

		runFunctionsQueuedForLookupQueries();
	}
	this.executeOnLookupQueriesDone = executeOnLookupQueriesDone;

	var pageLoad = true, submissionExecute = false, indicatorTimeout = 1000;
	this.setIndicatorTimeout = function( miliseconds ){
		indicatorTimeout = miliseconds;
	}
	function runFunctionsQueuedForLookupQueries() {
		if (pageLoad || submissionExecute) {
			CS.indicator.start('#indicatorContainer', 0);
		} else{
			CS.indicator.start('#indicatorContainer', indicatorTimeout);
		}
		if (lookupQueriesAreQueued()) {
			log('Waiting for lookup queries to complete...');
			if (lookupQueryQueueTimer != null) {
				lookupQueryQueueTimer = setTimeout(runFunctionsQueuedForLookupQueries, 100);
			}
			return;
		} else {
			log('>>> No lookup queries remain, executing function queue... ');
			lookupQueryQueueTimer = null;
			if (executeAfterLookupQueriesQueue.length === 0) {
				log('Function queue empty');
				CS.indicator.stop();
				pageLoad = false;
				return;
			}
			log('Starting queued function execution...');
			var i = executeAfterLookupQueriesQueue.length;
			while (i-- > 0) {
				try {
					var callbackObj = executeAfterLookupQueriesQueue.shift();
					log('Executing queued function: ' + callbackObj.name);
					if(callbackObj.args && callbackObj.args.length && callbackObj.invokeCallback.apply){
						callbackObj.invokeCallback.apply(null, callbackObj.args);
					} else {
						callbackObj.invokeCallback();
					}
				} catch(e) {
					log(e);
				}
			}
			if (!lookupQueriesAreQueued() && !submissionExecute) {
				CS.indicator.stop();
				pageLoad = false;
			}
		}
	}
	this.runFunctionsQueuedForLookupQueries = runFunctionsQueuedForLookupQueries;

	function lookupQueriesAreQueued() {
		for (var query in CS.lookupQueryCache) {
			if (CS.lookupQueryCache[query].callbacks.length > 0) return true;
		}
		return false;
	}
	this.lookupQueriesAreQueued = lookupQueriesAreQueued;

	// cache for jquery selections
	var jQueryCache = {};
	function jqc(query) {
		// safety net for misuse - if query is not a string (a selector), just call jQuery on it and log the misuse
		if (typeof query !== 'string') {
			var e = new Error('dummy');
			// check added due to Safari issue that caused 'undefined' of e.stack.replace to block configuration of product
			if (e.stack) {
				var stack = e.stack.replace(/^[^\(]+?[\n$]/gm, '')
					.replace(/^\s+at\s+/gm, '')
					.replace(/^Object.<anonymous>\s*\(/gm, '{anonymous}()@')
					.split('\n');
				log('jqc called with non-string selector. Please fix this. Call trace: ' + stack);
			}
			return $(query);
		}
		var res = jQueryCache[query];
		if (!res) {
			res = $(query);
			jQueryCache[query] = res;
		}

		return res;
	};
	this.jqc = jqc;

	function setProgressBarImage(sURL) {
		//#
		//# set the url and preload the image so it's cached on the client.
		//#
		progressBarImageUrl = sURL;
		preLoadImage = new Image();
		preLoadImage.src = sURL;
	}
	this.setProgressBarImage = setProgressBarImage;
	this.getProgressBarImage = function() { return progressBarImageUrl; };

	/**
	 * Enables trace logging. By doing so, whenever something is logged to console via CS.log() method, trace is logged as well.
	 */
	this.enableTraceLogging = function enableTraceLogging() { loggingTraceEnabled = true; };

	/**
	 * Disables trace logging. By doing so, whenever something is logged to console via CS.log() method, trace is not logged.
	 */
	this.disableTraceLogging = function disableTraceLogging() { loggingTraceEnabled = false; };

	this.enableLogging = function() {loggingEnabled = true;};
	this.disableLogging = function() {loggingEnabled = false;};

	this.enableLoadingOverlay = function() {loadingOverlayEnabled = true;};
	this.disableLoadingOverlay = function() {loadingOverlayEnabled = false;};
	this.isLoadingOverlayEnabled = function(){return loadingOverlayEnabled; };

	function toggleLookupClearIcon(ref) {
		var val = ref ? jQuery(CS.getId(ref)).val() : undefined;
		if (val) {
			jQuery(CS.getId(ref + '__del')).show();
		} else {
			jQuery(CS.getId(ref + '__del')).hide();
		}
	}
	this.toggleLookupClearIcon = toggleLookupClearIcon;

	function clearLookup(ref) {
		var data = jQuery(CS.getId(ref)).val('').data(CS.LOOKUP_DATA);
		for (var k in data) {
			data[k] = '';
		}
		window.currentLookupId = ref;
		lookupSelect('', '', data);
		CS.rules.evaluateAllRules(CS.rules.getCurrentRuleExecSequenceId());
	};
	this.clearLookup = clearLookup;

	function selectListLookupQuery(query) {
		var data = {results: []};
		var selectListLookupData = CS.selectListLookupDataCache[currentSelectListLookupConfigId];
		var recordData = selectListLookupData.recordData;
		var orderOfRecords = selectListLookupData.orderOfRecords;
		var orderedData = [];
		for (key in orderOfRecords) {
			orderedData.push(recordData[orderOfRecords[key]]);
		}

		for (key in orderedData) {
			data.results.push({id: orderedData[key].id, text: orderedData[key]});
		}
		query.callback(data);

		if (selectListLookupData && selectListLookupData.warnings && selectListLookupData.warnings instanceof Array) {
			var attributeName = query.element && query.element[0] && query.element[0].name;
			for (var i = 0; i < selectListLookupData.warnings.length; i++) {
				CS.logWarning(
					attributeName,
					':',
					selectListLookupData.warnings[i]
				);
			}
		}
	}
	this.selectListLookupQuery = selectListLookupQuery;

	function formatResult(lookupRecord, currentSelectListLookupAttributeId, currentSelectListLookupConfigId) {
		if (lookupRecord.id === undefined) {
			return;
		}
		var selectListLookupData = CS.selectListLookupDataCache[currentSelectListLookupConfigId];
		var recordData = selectListLookupData.recordData;
		var listColumns = selectListLookupData.listColumns;
		var columnTypes = selectListLookupData.columnTypes;
		var listColumnsWidth = $(CS.getId(currentSelectListLookupAttributeId)).attr(SELECT2_COLUMN_SIZE_CSV).split(',');
		var columnCnt = 0;

		var markup = "<table style='width:100%'><tr>";
		for (key in listColumns) {
			var fieldName = listColumns[key];
			var item = lookupRecord.text[fieldName];
			var columnWidth = listColumnsWidth[columnCnt++];
			var attrDataType = { type: columnTypes[fieldName] };
			item = CS.dataConverter.normalizeValue(item, attrDataType);
			item = CS.dataConverter.localizeValue(item, attrDataType);
			var tdStyle = (columnWidth !== undefined) ? 'style="width:' + columnWidth + 'em;"' : '';
			markup += '<td ' + tdStyle + '>' + item + '</td>';
		}

		markup += '</tr></table>';

		return markup;
	}
	this.formatResult = formatResult;

	function formatSelection(lookupRecord, currentSelectListLookupAttributeId, currentSelectListLookupConfigId) {
		var id = lookupRecord.text.id;
		var name = lookupRecord.text.name;
		var selectListLookupData = CS.selectListLookupDataCache[currentSelectListLookupConfigId];

		if (selectListLookupData === undefined) {
			if (name !== undefined) {
				return name;
			}
			return id;
		}

		var localData = lookupRecord.text;
		var listColumns = selectListLookupData.listColumns;
		var currentLookupId = currentSelectListLookupAttributeId.substr(0, currentSelectListLookupAttributeId.length - 5);

		localData['columnMap'] = listColumns;
		jQuery(CS.getId(currentLookupId + '_Name')).val(name);
		jQuery(CS.getId(currentLookupId)).val(id).data(CS.LOOKUP_DATA, localData);
		CS.rules.evaluateAllRules(CS.rules.getCurrentRuleExecSequenceId());

		if(name !== undefined) {
			return name;
		}
		return id;
	}
	this.formatSelection = formatSelection;

	function getSelectListLookup(controllReferenceId, lookupConfigId, productDefinitionId, attributeValueParams, query) {
		currentSelectListLookupAttributeId = controllReferenceId;

		var dynamicFilterParams = '';
		if (attributeValueParams) {
			nameIdPairs = attributeValueParams.split(',');
			for (i = 0 ; i < nameIdPairs.length ; i++) {
				var oneNameIdPair = nameIdPairs[i].split('|');
				if (dynamicFilterParams != '') dynamicFilterParams += '|';
				dynamicFilterParams += oneNameIdPair[0] + '=' + jQuery(CS.getId(oneNameIdPair[1])).val();
			}
		}

		var namespace = getPackageNamespace();
		namespace['ProductConfiguratorController'].getSelectListLookup(lookupConfigId, query.term, productDefinitionId, CS.urlEncode(dynamicFilterParams), function(result, event) {
			if(event.status) {
				var selectListLookupJSON = result;
				var listColumnsMap = selectListLookupJSON.listColumns;
				var sortedListColumns = {};

				for (var i = 0; i < listColumnsMap.length; i++) {
					for (key in listColumnsMap[i]) {
						sortedListColumns[key] = listColumnsMap[i][key];
					}
				}

				CS.selectListLookupDataCache[lookupConfigId] = {
					listColumns : sortedListColumns,
					searchColumns : selectListLookupJSON.searchColumns,
					recordData : selectListLookupJSON.records,
					columnTypes : selectListLookupJSON.columnTypes,
					orderOfRecords : selectListLookupJSON.orderOfRecords,
					warnings : selectListLookupJSON.warnings
				};

				currentSelectListLookupConfigId = lookupConfigId;
				CS.selectListLookupQuery(query);
			}
		});
	}
	this.getSelectListLookup = getSelectListLookup;

	/**
	* Debounces a function. Returns a function that calls the original fn function only if no invocations have been made
	* within the last quietMillis milliseconds.
	*
	* @param quietMillis number of milliseconds to wait before invoking fn
	* @param fn function to be debounced
	* @param ctx object to be used as this reference within fn
	* @return debounced version of fn
	*/
	function debounce(quietMillis, fn, ctx) {
		ctx = ctx || undefined;
		var timeout;
		return function() {
			var args = arguments;
			window.clearTimeout(timeout);
			timeout = window.setTimeout(function() { fn.apply(ctx, args); }, quietMillis);
		};
	}
	this.debounce = debounce;

	function functionDecorator(f) {
		return function() {
			return f.apply(this, arguments);
		}
	}
	this.functionDecorator = functionDecorator;

	function log() {
		if (loggingEnabled) {
			// if there is trace option available, do log stack trace as well. (helps developers & consultants)
			if (loggingTraceEnabled && console.trace) {
				if(console.trace.apply) {
					console.trace.apply(console, arguments)
				} else {
					for (var i = 0; i < arguments.length; ++i) {
						console.trace(arguments[i]);
					}
				}
			} else if (console.log.apply) {
				console.log.apply(console, arguments);
			} else {
				for (var i = 0; i < arguments.length; ++i) {
					console.log(arguments[i]);
				}
			}
		}
	}
	this.log = log;

	this.LOG_TYPE_INFO = 'info';
	this.LOG_TYPE_ERROR = 'error';
	this.LOG_TYPE_WARN = 'warn';
	this.LOG_ARGUMENTS = 'arguments';
	this.LOG_TYPE = 'type';

	/**
	 * Log method for using other aproaches to console (ex. error or info).
	 * If logging is disabled, nothing will be logged.
	 *
	 * For example:
	 * 	var opts = {};
	 * 	opts[CS.LOG_TYPE] = CS.LOG_TYPE_INFO;//if not set, CS.log() is invoked
	 *  opts[CS.LOG_ARGUMENTS] = args;//array of arguments
	 *
	 *  CS.logToConsole(opts) //it would invoke console.info(opts[CS.LOG_ARGUMENTS]);
	 *
	 * Suported: info (LOG_TYPE_INFO); error (LOG_TYPE_ERROR); warn (LOG_TYPE_WARNING) and default CS.log.
	 *
	 * Ex #2 (simple log):
	 * 	CS.logToConsole('simple log', 'log something else');
	 *  //CS.log method with same arguments is called
	 */
	function logToConsole(opts) {
		if (!loggingEnabled) {
			return;
		}

		var logFunction = null;
		var type = opts[CS.LOG_TYPE];
		if (type) {
			if (CS.LOG_TYPE_INFO === type && console.info) {
				logFunction = console.info;
			} else if (CS.LOG_TYPE_ERROR === type && console.error) {
				logFunction = console.error;
			} else if (CS.LOG_TYPE_WARN === type && console.warn) {
				logFunction = console.warn;
			}
		}

		var args = opts;
		// we have more than 1 argument
		if (arguments.length > 1) {
			args = arguments;
		} else if (opts[CS.LOG_ARGUMENTS] !== undefined) {
			// if its just a single object to log (for example string doesn't have property arguments)
			args = opts[CS.LOG_ARGUMENTS];
		}

		if (logFunction) {
			if (logFunction.apply && (args instanceof Array || args.hasOwnProperty('callee'))) { // callee is property of arguments object
				logFunction.apply(console, args);
			} else {
				logFunction.call(console, args);
			}
		} else if (log.apply && (args instanceof Array || args.hasOwnProperty('callee'))) { // callee is property of arguments object
			// if first argument is array, or it is over opt object we call it only for that argument.
			log.apply(CS, args);
		} else {
			log.call(CS, args);
		}
	}
	this.logToConsole = logToConsole;

	/**
	 * Logs error to console if logging is activated (console.error)
	 */
	function logError() {
		var opts = {};
		opts[CS.LOG_TYPE] = CS.LOG_TYPE_ERROR;
		opts[CS.LOG_ARGUMENTS] = arguments;

		logToConsole(opts);
	}
	this.logError = logError;

	/**
	 * Logs info to console if logging is activated (console.info)
	 */
	function logInfo() {
		var opts = {};
		opts[CS.LOG_TYPE] = CS.LOG_TYPE_INFO;
		opts[CS.LOG_ARGUMENTS] = arguments;

		logToConsole(opts);
	}
	this.logInfo = logInfo;

	/**
	 * Logs warning to console if logging is activated (console.warn)
	 */
	function logWarning() {
		var opts = {};
		opts[CS.LOG_TYPE] = CS.LOG_TYPE_WARN;
		opts[CS.LOG_ARGUMENTS] = arguments;

		logToConsole(opts);
	}
	this.logWarning = logWarning;

	/**
	 * Log an incorrect reference and return empty string so that when a SimpleExpression sees an unresolvable
	 * reference, it can generate descriptive JS code, that will not mess up the attribute's value.
	 *
	 * E.g. This expression
	 * &lt;pre&gt;{attr1} + {rel_prod|0:attr_in_rel}&lt;/pre&gt;
	 * Will generate this code when a related product is attached at the rel_prod attribute:
	 * &lt;pre&gt;(CS.add(CS.getAttributeValue("attr1_0"), CS.getAttributeValue("rel_prod_0_0:attr_in_rel_0")))&lt;/pre&gt;
	 *
	 * However, if no related product is attached yet, this will get generated:
	 * &lt;pre&gt;(CS.add(CS.getAttributeValue("attr1_0"), CS.unresolvedReference("rel_prod|0:attr_in_rel")))&lt;/pre&gt;
	 *
	 * References to not-yet added related products are expected and should be treated as empty strings,
	 * so they can't be treated as absolute errors. Still it is important to provide product designers with
	 * better hints about misspelled attribute names and other kinds of references.
	 */
	function unresolvedReference(refName, message) {
		CS.log("Error evaluating reference (may be due to currently missing related product) >>" + refName + "<<");
		if (typeof message === 'string') {
			CS.logError(message);
		}
		return "";
	}
	this.unresolvedReference = unresolvedReference;

	function dump(o, d) {
		var a = false,
				s = '',
				p = '',
				tab = '  ';
		if (d === undefined) d = 0;
		d += 1;
		if (typeof(o) === 'object') {
			a = toString.call(o) === "[object Array]";
			if (a) s += '[\n';
			else s += 'object {\n';
			for (p in o) {
				s += repeat(tab, d) + p + ': ';
				if (typeof(o[p] === 'object')) s += dump(o[p], d);
				else s += o[p];
			}
			s += repeat(tab, d - 1) + (a ? ']\n' : '}\n');
		}
		else s += o + '\n';
		return s;
	}
	this.dump = dump;

	function repeat(s, n) {
		var i = n,
				s1 = '';
		while (i--) {
			s1 += s;
		}
		return s1;
	}

	var unescapeHtml = (function() {
		// Prevent overhead from creating an HTML element on each call - create it only once
		var textarea = document.createElement('textarea');

		function decodeHtmlEntities(htmlString) {
			if (htmlString && typeof htmlString === 'string') {
				var localString = htmlString.replace(/</g,"&lt;");
				localString = localString.replace(/>/g,"&gt;");
				textarea.innerHTML = localString;
				localString = textarea.textContent;
				textarea.textContent = '';
				return localString;
			} else {
				return htmlString;
			}
		}

		return decodeHtmlEntities;
	})();
	this.unescapeHtml = unescapeHtml;

	function getId(id) {
		return '#' + makeCssIdentifier(id);
	}
	this.getId = getId;

	function makeCssIdentifier(id) {
		return id.replace(/([:\/#;&%,\.\+\*~'"!\?\^\$\[\]\(\)=>\|])/g, '\\$1');
	}

	function getAttributeField(id, fieldName) {
		if (fieldName == null) return null;

		var field = jqc(getId(id + ':_' + fieldName.toLowerCase()));

		if (field.size() === 0) {
			log('Cannot find attribute field: ' + fieldName + ' for attribute: ' + id);
			return null;
		}
		return field;
	}
	this.getAttributeField = getAttributeField;

	this.startsWith = function startsWith(str, head) {
		var headLen = head.length;
		return str.length >= headLen && str.substr(0, headLen) === head;
	};

	this.endsWith = function endsWith(str, tail) {
		var tailLen = tail.length;
		var strLen = str.length;
		return strLen >= tailLen && str.substr(strLen-tailLen, tailLen) === tail;
	};

	// Configurator action implementation
	this.isBlank = function isBlank(str) {
		return typeof str === 'string' && str.trim() === '';
	};

	// Utility function
	this.isBlankOrNull = function(str) {
		return str === null || (''+str).trim() === '';
	};

	this.disableAttribute = function disableAttribute(id) {
		$(getId(id)).parents('.attrWrapper').data(HIDDEN, 'true').data('attributeId', id);
		$(getId(id+':_active')).val('false');
	};

	this.makeAttributeReadOnly = function makeAttributeReadOnly(id) {
		$(getId(id)).data(READ_ONLY, true).parents('.attrWrapper').data(READ_ONLY, 'true').data('attributeId', id);
	};

	this.isAttributeReadOnly = function (id) {
		return ($(getId(id)).parents('.attrWrapper').data(READ_ONLY) === "true") ? true : false;
	}

	function setAttribute(id, value, suppressEvent) {
		if (CS.lockedAttributes.indexOf(id) >= 0) {
			log('Attribute locked in screen flow, no further changes: ' + id);
			return;
		}

		if (value && value.isCallback) {
			value.applyValue = function(data) {
				if (cachedLookupValues[id] == null) cachedLookupValues[id] = $(getId(id)).val();
				var attrDataType = getAttributeDataType(id),
					currentVal = CS.dataConverter.normalizeValue($(getId(id)).val(), attrDataType);
					val = CS.dataConverter.normalizeValue(data[value.fieldName], attrDataType);
				if (val !== 0 && val !== false && !val) val = '';
				if (String(val) != String(currentVal)) {
					// BUG-00894 fix [LHS and RHS] of equality check are transformed to String
					setAttribute(id, val, suppressEvent);
					cachedLookupValues[id] = val;
					log('Dynamic lookup result requires rule evaluation: ' + id + ' - ' + val + ' (' + currentVal + ')');
						CS.rules.evaluateAllRules(value.ruleRunSequenceId);
				}
			};
		} else {
			var field = $(getId(id));
			var oldValue = field.val();
			var attrDataType = getAttributeDataType(id);
			var normalValue = CS.dataConverter.normalizeValue(unescapeHtml(value), attrDataType);

			cachedLookupValues[id] = null;

			field.val(unescapeHtml(normalValue));
			// check if attribute is group of radio buttons
			var radios = getRadioButtons(id);
			if (radios) {
				var enableNullOption = jqc(getId(id + ':_enablenulloption')).val();

				var radioValueFound = false;
				radios.each(function(i) {
					var jqthis = jQuery(this);
					var optionValue = jqthis.val();
					if (optionValue === value) {
						jqthis.attr('checked', 'checked');
						updateOptionPrice(id, optionValue);
						radioValueFound = true;
					} else {
						jqthis.removeAttr('checked');
					}
				});
				// if requested value does not exist, clear attribute value and price
				if (!radioValueFound) {
					value = '';
					setAttributeField(id, FIELD_NAME_SALES_PRICE, '');
				}
			} else if (field.is('select')) {
				// update select's price with the value that the input actually has, not necessarily the one that was requested
				updateOptionPrice(id, value);
				if (typeof(field.chosen) === "function") {
					field.trigger("liszt:updated");
				}
			} else {
				value = CS.dataConverter.normalizeValue(value, attrDataType);
				var attrDisplay = jqc(getId(id + ':_display'));
				if (attrDisplay.length) {
					attrDisplay.val(CS.dataConverter.localizeValue(value, attrDataType));
				}
			}

			var attrType = { type: jqc(getId(id + ':_type')).val() };
			if (attrType.type == DISPLAY_VALUE_TYPE) {
				normalValue = CS.dataConverter.normalizeValue(value, attrType);
				var displayEl = jqc(getId(id)).siblings('.calcValue');
				var localizedValue = CS.dataConverter.localizeValue(normalValue, attrType);
				displayEl.html(localizedValue);
			}

			log('>> Set ' + id + ': ' + value + ' (' + oldValue + ')');
			if (!suppressEvent) {
				fireChange(field);
			}
		}
	}
	this.setAttribute = setAttribute;

	function getAttributeDataType(id) {
		var typeInfo = { type: jqc(getId(id + ':_datatype')).val() };

		if (typeInfo.type == CS.dataConverter.DATA_TYPE_DECIMAL) {
			typeInfo.scale = parseInt(jqc(getId(id + ':_scale'), 10).val()) || 0;
		}

		return typeInfo;
	}

	function getAttributeValue(id, dataType) {
		var field = $(getId(id));
		var val;
		if (dataType === 'Integer') {
			val = parseInt(field.val(), 10);
		}
		if (dataType === 'Double') {
			val = parseFloat(field.val(), 10);
		}
		if (dataType === 'Date') {
			val = CS.dataConverter.parseDate(field.val());
		}
		if (!val && val !== 0) {
			val = unescapeHtml(field.val());
		}

		return val;
	}
	this.getAttributeValue = getAttributeValue;

	function setAttributeField(id, fieldName, value) {
		if (CS.isConfigurationLocked[0] == 'true') {
			log('Configuration locked in screen flow, no further changes on recurrence frequency');
			return;
		}
		if (value && value.isCallback) {
			value.applyValue = function(data) {
				var currentVal = getAttributeFieldValue(id, fieldName);
				var val = data[value.fieldName];
				if (val !== 0 && val !== false && !val) val = '';
				if (val != currentVal) {
					setAttributeField(id, fieldName, val);
				}
			}
		} else {
			var field = getAttributeField(id, fieldName);
			if (!field) return;
			if (fieldName === FIELD_NAME_SALES_PRICE || fieldName === FIELD_NAME_LIST_PRICE) {
				value = CS.dataConverter.roundValue(value, 2);
			}
			if (fieldName === FIELD_NAME_DISCOUNT_TYPE) {
				setAttributeDiscountType(id, value);
			} else {
				field.val(value);
			}
		}
	}
	this.setAttributeField = setAttributeField;

	function setAttributeDiscountType(id, value) {
		var field = getAttributeField(id, FIELD_NAME_DISCOUNT_TYPE);
		if (!field) {
			return;
		}
		if (value !== DISCOUNT_TYPE_AMOUNT && value !== DISCOUNT_TYPE_PERCENTAGE) {
			throw 'Invalid arguments: CS.setAttributeDiscountType(id, value) value must be : '
				+ DISCOUNT_TYPE_AMOUNT + ' or ' + DISCOUNT_TYPE_PERCENTAGE + ' and it is ' + value;
		}
		field.val(value);
		log('Setting attribute "' + id + '" field "' + FIELD_NAME_DISCOUNT_TYPE + '" to : ' + value);
	}
	this.setAttributeDiscountType = setAttributeDiscountType;

	/* Following method is mimicking SalesForce formula field set on
	 * Attribute__c.discount_amount__c and due to that the "code style" is literally
	 * mirroring logic from formula line by line in order to simplify
	 * maintainance if eventual changes on formula happen.
	 */
	function getAttributeDiscount(id) {
		var price = getAttributeFieldValue(id, FIELD_NAME_SALES_PRICE);
		var listPrice = getAttributeFieldValue(id, FIELD_NAME_LIST_PRICE);
		var discountType = getAttributeFieldValue(id, FIELD_NAME_DISCOUNT_TYPE);
		var discountAmount = ''; // (empty string) '' represents null and it is default return value for this method

		if (discountType === '') {
			discountAmount = '';
		} else if (price === '' && listPrice === '') {
			discountAmount = '';
		} else if (price === '' || listPrice === '') {
			discountAmount = 0;
		} else if (price === 0 && listPrice === 0) {
			discountAmount = 0;
		} else if (discountType === DISCOUNT_TYPE_PERCENTAGE && price > 0 && listPrice === 0) {
			discountAmount = '';
		} else if ( discountType === DISCOUNT_TYPE_AMOUNT) {
			discountAmount = listPrice - price;
		} else {
			discountAmount = ( 1 - price / listPrice ) * 100;
		}

		return discountAmount;
	}

	function setCheckbox(id, value, suppressEvent) {
		if (CS.lockedAttributes.indexOf(id) < 0) {
			var field = $(getId(id));
			var cbField = $(getId(id + '__check'));
			if (!field || !cbField) return;
			log('found checkbox fields for : ' + id);
			log('setting value to : ' + value);
			field.val(value);

			if (value.toLowerCase() == 'yes')
				cbField.attr('checked',true);
			else
				cbField.attr('checked',false);

			if (!suppressEvent) fireChange(field);
		} else {
			log('Attribute locked in screen flow, no further changes: ' + id);
		}
	}
	this.setCheckbox = setCheckbox;

	function getAttributeFieldValue(id, fieldName) {
		if (fieldName === FIELD_NAME_DISCOUNT_AMOUNT) {
			return getAttributeDiscount(id);
		}
		var field = getAttributeField(id, fieldName);
		if (!field) return '';

		// Try to normalise the value into ISO Date format
		var val = CS.dataConverter.normalizeValue(field.val(), {type: CS.dataConverter.DATA_TYPE_DATE});
		// If ISO Date normalisation wasn't successful, try parsing the value as a number
		if( val === '' ) val = parseFloat(field.val());

		return (val || val === 0) ? val : field.val();
	}
	this.getAttributeFieldValue = getAttributeFieldValue;

	this.attributeValueChanged = function(attrId) {
		var normalValue = $(getId(attrId)).val(),
			localizedValue = CS.dataConverter.localizeValue(normalValue, getAttributeDataType(attrId));

		var displayElement = $(getId(attrId + ':_display'));
		var currentDisplayValue = displayElement.val();
		if (localizedValue !== currentDisplayValue) {
			displayElement.val(localizedValue);
		}
	}

	this.localizedValueChanged = function(attrId) {
		var dataType = getAttributeDataType(attrId);
		var displayValue = $(getId(attrId + ':_display')).val(),
			normalValue = CS.dataConverter.unlocalizeValue(displayValue, dataType);

		$(getId(attrId)).val(normalValue || displayValue);

		if (normalValue) {
			this.attributeValueChanged(attrId);
		}
	}

	this.getLookupValue = function getLookupValue(id, fieldName, defaultValue) {
		var field = $(getId(id)),
			data = field.data(LOOKUP_DATA);

		if (data == null) {
			CS.log('Lookup for ' + id + ' had no new data, using default value');
			return defaultValue;
		}

		var val = data[fieldName];
		if (val === undefined) {
			data[fieldName] = '';
			val = '';
		}

		CS.log('Lookup for ' + id + ', field ' + fieldName + ': ' + val);

		return (val == null ? null : val);
	};

	this.setLockedAttributes = function setLockedAttributes() {
		var list = CS.lockedAttributes;
			var arrayLength = list.length;
		for (var i = 0; i < arrayLength; i++) {
			CS.makeAttributeReadOnly(list[i]);
		}
		CS.applyAttributeEffects();
	};

	/**
	 * Introduced due problem with remote js calls in Visual Force.
	 * Please remove this method, and its invocations if problem with bulkified remote call is fixed.
	 * (Error occurs when you bulkify remote calls, and one of calls results in error. Then, other calls are not invoked thus no callback for them is ever invoked.)
	 */
	function callAllCallbacksWithError(errorMessage) {
		for (var key in CS.lookupQueryCache) {
			var cached = CS.lookupQueryCache[key];

			if (cached && cached.status === 'requested') {
				// we got our object
				if (cached.callbacks && cached.callbacks.length > 0) {
					while (cached.callbacks.length > 0) {
						callback = cached.callbacks[0];
						try {
							callback.setError(errorMessage);
						} catch(exception){
							log(exception);
						} finally {
							cached.callbacks.shift(); // don't shift before applying so that callback still shows up until processing completed;
						}
					}
				}
				cached.status = 'ready';
			}
		}
	}

	this.getDynamicLookupValue = function getDynamicLookupValue(queryID, fieldName, productDefinitionID, attrAbsoluteReferenceAsId) {
		log('Dynamic lookup: ' + fieldName);
		var configPrefix = '';
		attrAbsoluteReferenceAsId = attrAbsoluteReferenceAsId || '';
		var n = attrAbsoluteReferenceAsId.lastIndexOf(":");
		if (n != -1) {
			configPrefix = attrAbsoluteReferenceAsId.substr(0, n);
		}

		var dynamicFilterMap = {};
		var bConfigAttribute = false;
		var attributeElId;
		jqc(".cfgAttr").each(function(i, attr) {
			bConfigAttribute = false;
			attributeElId = ($(attr).attr('id') == undefined) ? '' : $(attr).attr('id');
			if (configPrefix != '' && attributeElId.lastIndexOf(configPrefix) != -1) {
				if (attributeElId.substring(n).split(":").length < 3) {
					bConfigAttribute = true;
				}
			}
			if (configPrefix == '' && attributeElId.lastIndexOf(':') == -1) {
				bConfigAttribute = true;
			}
			if (bConfigAttribute) {
				var id = getId(attributeElId + ":_name");
				var sel = jqc(id);
				var name = sel.val();
				if (CS.lookupReferencedAttributes[queryID] === undefined) {
					dynamicFilterMap[name] = $(attr).val();
				} else {
					if ($.inArray(name, CS.lookupReferencedAttributes[queryID]) !== -1) {
						dynamicFilterMap[name] = $(attr).val();
					}
				}
			}
		});

		// current run sequence Id
		var tmpCurrentRunSeqId = CS.rules.getCurrentRuleExecSequenceId();

		var queryProxy = {
			isCallback: true,
			fieldName: fieldName.toLowerCase(),
			applyValue: function(value) {
				log('Callback applyValue not defined!');
			},
			setError: function(error) {
				log('Could not update dynamic lookup: ' + error);
			},
			ruleRunSequenceId: tmpCurrentRunSeqId
		};

		var queryIDCacheKey = queryID + configPrefix;

		var cached = CS.lookupQueryCache[queryIDCacheKey];
		if (!cached) {
			cached = CS.lookupQueryCache[queryIDCacheKey] = {callbacks:[]};
		}

		if (cached.params && _.isEqual(cached.params, dynamicFilterMap)) {
			log('Using cached dynamic lookup value for ' + fieldName + ': ', cached.data);
			setTimeout(
					function() {
						queryProxy.ruleRunSequenceId = tmpCurrentRunSeqId;
						queryProxy.applyValue(cached.data, {status: 'cached'});
					},
					100);
		} else {
//			if (!cached.callbacks) cached.callbacks = [];
			CS.lookupQueryCache[queryIDCacheKey].callbacks.push(queryProxy);
			if (cached.status == 'requested') {
				log('Queued callback for: ' + fieldName);
			} else {
				var queryCallback = function(result, event) {
					if (event.status) {
						var data = {},
							callback;
						mapLookupResult(data, result, "");
						log('Received dynamic lookup value for field ' + fieldName, data/*, dump(cached)*/);
						cached.params = dynamicFilterMap;
						cached.data = data;
						while (cached.callbacks.length > 0) {
							callback = cached.callbacks[0];

							try {
								callback.applyValue(data);
							} catch(exception){
								log(exception);
							} finally {
								cached.callbacks.shift(); // don't shift before applying so that callback still shows up until processing completed;
							}
						}
					} else {
						while (cached.callbacks.length > 0) {
							var callback = cached.callbacks[0];

							try {
								callback.setError(event.message);
							} catch(exception) {
								log(exception);
							} finally {
								cached.callbacks.shift(); // don't shift before applying so that callback still shows up until processing completed;
							}
						}
						// VF doesn't call other callbacks if one of bulkified calls results in error
						// remove this call if SF fixes it
						// simple workaround is to invoke 'setError' on all remaining callbacks
						callAllCallbacksWithError(event.message);
					}
					cached.status = 'ready';
					runFunctionsQueuedForLookupQueries();
				};

				log('>> Values have changed:', cached.params, dynamicFilterMap);
				log('>> New remote request for field ' + fieldName);
				var namespace = getPackageNamespace();
				namespace['ProductConfiguratorController'].lookupQuery(
					queryID, dynamicFilterMap, productDefinitionID,
					queryCallback,
					{escape:true}
				);
				cached.status = 'requested';
			}
		}
		return queryProxy;
	};

	function mapLookupResult(data, result, prefix) {
		for (var key in result) {
			var datum = result[key];
			var dataKey = prefix + key.toLowerCase();

			data[dataKey] = datum;

			if (datum != null && typeof datum === 'object') {
				mapLookupResult(data, datum, dataKey + '.');
			}
		}
	}

	function getPackageNamespace() {
		var namespaces = ['cscfga', 'cscfga_t3', 'cscfgc', 'cscfgat4', 'cscfgaap'],
			namespace,
			idx = namespaces.length;

		while(idx--) {
			namespace = window[namespaces[idx]];
			if ( namespace && namespace['ProductConfiguratorController']) return namespace;
		}

		return window;
	}

	this.today = function() {
		return Date.today();
	}

	this.add = function(left, right) {
		var leftDate = left instanceof Date ? left : CS.dataConverter.parseDate(left);
		var rightDate = right instanceof Date ? right : CS.dataConverter.parseDate(right);

		if (leftDate && isInteger(right)) {
			return leftDate.addDays(parseInt(right, 10));
		}

		if (isNumber(left) && isNumber(right)) {
			return parseFloat(left) + parseFloat(right);
		}

		if (leftDate && typeof right === 'string') {
			return CS.dataConverter.localizeValue(left, { type: CS.dataConverter.DATA_TYPE_DATE }) + right;
		} else if (rightDate && typeof left === 'string') {
			return left + CS.dataConverter.localizeValue(right, { type: CS.dataConverter.DATA_TYPE_DATE });
		}

		return left + right;
	}

	this.subtract = function(left, right) {
		// If both operands are null -> return null
		if (CS.isBlankOrNull(left) && CS.isBlankOrNull(right)) {
			return null;
		}

		var result = null;

		var leftDate = left instanceof Date ? left : CS.dataConverter.parseDate(left);
		var rightDate = right instanceof Date ? right : CS.dataConverter.parseDate(right);

		if (leftDate && CS.isBlankOrNull(right) || rightDate && CS.isBlankOrNull(left)) {
			// To keep the existing logic working as before, if one of the operands is null/blank,
			// the function will return null only if the other operand is a Date
			result = null;
		} else if (leftDate && rightDate) {
			// In date subtraction, leftDate is considered future when compared with rightDate
			// This allows the expression "d1 + (d2 - d1)" to evaluate to d2, even if d1 > d2
			var diff = new TimeSpan(leftDate - rightDate),
				dayDiff = diff.days;

			// if leftDate and rightDate are on opposite sides of spring daylight saving time change,
			// the TimeSpan will be one day shorted and 'hours' will be 23. This is not a problem
			// in autumn because the TimeSpan will be 1 hour longer, but the day diff will be correct.
			if (Math.abs(diff.hours) === 23) {
				dayDiff += (diff.hours < 0 ? -1 : 1);
			}
			result = dayDiff;
		} else if (leftDate && isInteger(right)) {
			result = leftDate.addDays(-parseInt(right, 10));
		} else if (isNumber(left) && isNumber(right)) {
			result = parseFloat(left) - parseFloat(right);
		} else {
			result = left - right;
		}
		return result;
	}

	this.concat = function(left, right) {
		var localLeft = '' + left, localRight = '' + right;

		var leftDate = left instanceof Date ? left : CS.dataConverter.parseDate(left);
		if (leftDate !== null) {
			localLeft = CS.dataConverter.localizeValue(leftDate, { type: CS.dataConverter.DATA_TYPE_DATE });
		} else if(typeof left != 'string') {
			if (isDecimal(left)) {
				var leftNumber = CS.dataConverter.normalizeValue(left, { type: CS.dataConverter.DATA_TYPE_DECIMAL, scale: 2 });
				localLeft = '' + CS.dataConverter.localizeValue(leftNumber, { type: CS.dataConverter.DATA_TYPE_DECIMAL, scale: 2 });
			} else if (isInteger(left)) {
				var leftNumber = CS.dataConverter.normalizeValue(left, { type: CS.dataConverter.DATA_TYPE_INTEGER });
				localLeft = '' + CS.dataConverter.localizeValue(left, { type: CS.dataConverter.DATA_TYPE_INTEGER });
			}
		}

		var rightDate = right instanceof Date ? right : CS.dataConverter.parseDate(right);
		if (rightDate !== null) {
			localRight = CS.dataConverter.localizeValue(rightDate, { type: CS.dataConverter.DATA_TYPE_DATE });
		} else if(typeof right != 'string') {
			if (isDecimal(right)) {
				var rightNumber = CS.dataConverter.normalizeValue(right, { type: CS.dataConverter.DATA_TYPE_DECIMAL, scale: 2 });
				localRight = '' + CS.dataConverter.localizeValue(rightNumber, { type: CS.dataConverter.DATA_TYPE_DECIMAL, scale: 2 });
			} else if (isInteger(right)) {
				var rightNumber = CS.dataConverter.normalizeValue(right, { type: CS.dataConverter.DATA_TYPE_INTEGER });
				localRight = '' + CS.dataConverter.localizeValue(rightNumber, { type: CS.dataConverter.DATA_TYPE_INTEGER });
			}
		}

		return localLeft + localRight;
	}

	function canCompareAsNumbers(left, right) {
		var bothAreNumbers = (isNumber(left) && isNumber(right));
		var leftIsEmpty = (left === '' || left === NULL_OPTION_VALUE);
		var rightIsEmpty = (right === '' || right === NULL_OPTION_VALUE);
		return (
			bothAreNumbers ||
			(isNumber(left) && rightIsEmpty) ||
			(leftIsEmpty && isNumber(right))
		);
	}

	this.eq = function(left, right) {
		var leftDate = left instanceof Date ? left : CS.dataConverter.parseDate(left);
		var rightDate = right instanceof Date ? right : CS.dataConverter.parseDate(right);
		if (leftDate && rightDate) {
			return Date.compare(leftDate, rightDate) === 0;
		}

		// numbers are equal if difference is less than comparison treshold
		if (canCompareAsNumbers(left, right) && !leftDate && !rightDate) {
			return Math.abs(parseFloat(left) - parseFloat(right)) < FLOAT_COMPARISON_LIMIT;
		}

		return left == right;
	}

	this.ne = function(left, right) {
		return !(this.eq(left, right));
	}

	this.gt = function(left, right) {
		var leftDate = left instanceof Date ? left : CS.dataConverter.parseDate(left);
		var rightDate = right instanceof Date ? right : CS.dataConverter.parseDate(right);
		if (leftDate && rightDate) {
			return Date.compare(leftDate, rightDate) > 0;
		}

		if (canCompareAsNumbers(left, right) && !leftDate && !rightDate) {
			return parseFloat(left) - parseFloat(right) > FLOAT_COMPARISON_LIMIT;
		}

		return parseFloat(left) > parseFloat(right);
	}

	this.ge = function(left, right) {
		var leftDate = left instanceof Date ? left : CS.dataConverter.parseDate(left);
		var rightDate = right instanceof Date ? right : CS.dataConverter.parseDate(right);
		if (leftDate && rightDate) {
			return Date.compare(leftDate, rightDate) >= 0;
		}

		if (canCompareAsNumbers(left, right) && !leftDate && !rightDate) {
			return parseFloat(left) - parseFloat(right) > -FLOAT_COMPARISON_LIMIT;
		}

		return parseFloat(left) >= parseFloat(right);
	}

	this.lt = function(left, right) {
		var leftDate = left instanceof Date ? left : CS.dataConverter.parseDate(left);
		var rightDate = right instanceof Date ? right : CS.dataConverter.parseDate(right);
		if (leftDate && rightDate) {
			return Date.compare(leftDate, rightDate) < 0;
		}

		if (canCompareAsNumbers(left, right) && !leftDate && !rightDate) {
			return parseFloat(left) - parseFloat(right) < -FLOAT_COMPARISON_LIMIT;
		}

		return parseFloat(left) < parseFloat(right);
	}

	this.le = function(left, right) {
		var leftDate = left instanceof Date ? left : CS.dataConverter.parseDate(left);
		var rightDate = right instanceof Date ? right : CS.dataConverter.parseDate(right);
		if (leftDate && rightDate) {
			return Date.compare(leftDate, rightDate) <= 0;
		}

		if (canCompareAsNumbers(left, right) && !leftDate && !rightDate) {
			return parseFloat(left) - parseFloat(right) < FLOAT_COMPARISON_LIMIT;
		}

		return parseFloat(left) <= parseFloat(right);
	}

	function getFrequencyName(val) {
		return FREQUENCY_NAMES[val] || '';
	}
	this.getFrequencyName = getFrequencyName;

	function getPeriodName(val) {
		return PERIOD_NAMES[val] || '';
	}
	this.getPeriodName = getPeriodName;

	function countRelatedProducts(id) {
		if (id == null) return 0;

		return getAttributeFieldValue(id, 'count');
	}
	this.countRelatedProducts = countRelatedProducts;

	this.updateFromSelect = function updateFromSelect(id) {
		var field = $(getId(id));
		updateOptionPrice(id, field.val());
	};

	function updateOptionPrice(id, val) {
		var price = optionPrices[id][val];
		if (price != null) setAttributeField(id, FIELD_NAME_SALES_PRICE, price);
	}
	this.updateOptionPrice = updateOptionPrice;

	function updateCheckbox(id, checkbox) {
		log('Updating checkbox id ' + id + ': ' + $(checkbox).is(':checked'));
		$(getId(id)).val($(checkbox).is(':checked') ? 'Yes' : 'No');
	}
	this.updateCheckbox = updateCheckbox;

	function setTextDisplay(id, value) {
		if (CS.lockedAttributes.indexOf(id) < 0) {
			if (value && value.isCallback) {
				value.applyValue = function(data) {
					var currentVal = $(getId(id)).val();
					var val = data[value.fieldName];
					if (val !== 0 && val !== false && !val) val = '';
					if (String(val) != String(currentVal)) {
						setTextDisplay(id, val);
					}
				};
			} else {
				var el = $(getId(id));
				if (el.size() < 1) {
					log('Could not find element for ' + id);
					return;
				}
				if (el.get(0).tagName.toUpperCase() == 'INPUT') el.val(value);
				else el.html(value);
				fireChange(el);
			}
		} else {
			log('Attribute locked in screen flow, no further changes: ' + id);
		}
	}
	this.setTextDisplay = setTextDisplay;

	function setCalculation(id, value, suppressEvent) {
		if (value && value.isCallback) {
			value.applyValue = function(data) {
				if (cachedLookupValues[id] == null) cachedLookupValues[id] = $(getId(id)).val();
				//var currentVal = $(getId(id)).val();
				var currentVal = cachedLookupValues[id];
				var val = data[value.fieldName];
				if (val !== 0 && val !== false && !val) val = '';
				if (String(val) != String(currentVal)) {
					setCalculation(id, val, suppressEvent);
					cachedLookupValues[id] = val;
					log('Dynamic lookup value requires rule evaluation: ' + id + ' - ' + val + ' (' + currentVal + ')');
					CS.rules.evaluateAllRules(value.ruleRunSequenceId);
				}
			};
		} else {
			var attrType = getAttributeDataType(id),
				normalValue = CS.dataConverter.normalizeValue(value, attrType),
				displayEl = jqc(getId(id)).siblings('.calcValue'),
				localizedValue = CS.dataConverter.localizeValue(normalValue, attrType);
			setAttribute(id, normalValue, suppressEvent);
			displayEl.html(localizedValue);
		}
	}
	this.setCalculation = setCalculation;

	function setRecurrenceFrequency(id, value) {
		if (CS.isConfigurationLocked[0] == 'false') {
			if (value && value.isCallback) {
				value.applyValue = function(data) {
					var currentVal = $(getId(id)).val();
					var val = data[value.fieldName];
					if (!val) val = '';
					if (val != currentVal) {
						setRecurrenceFrequency(id, val);
					}
				};
			} else {
				var val = null;
				if (value != null) {
					val = parseInt(value, 10);
					if (!val && val !== 0) val = FREQUENCIES[value.toLowerCase()];
				}
				setAttributeField(id, 'recurrence', val);
			}
		} else {
			log('Configuration locked in screen flow, no further changes on recurrence frequency');
		}
	}
	this.setRecurrenceFrequency = setRecurrenceFrequency;

	function setBillingFrequency(id, value) {
		if (CS.isConfigurationLocked[0] == 'false') {
			if (value && value.isCallback) {
				value.applyValue = function(data) {
					var currentVal = $(getId(id)).val();
					var val = data[value.fieldName];
					if (!val) val = '';
					if (val != currentVal) {
						setBillingFrequency(id, val);
					}
				};
			} else {
				var val = null;
				if (value != null) {
					if (isNaN(value)) val = FREQUENCIES[value.toLowerCase()];
					else val = parseInt(value, 10);
				}
				//#
				//# Use this if we want to set a Billing Freq for each product in the config
				//# Currently we set the freqency for the entire config. ('' rather than id)
				//#
				//setAttributeField(id, 'billingFrequency', val);
				setAttributeField('', 'billingFrequency', val);
			}
		} else {
			log('Configuration locked in screen flow, no further changes on billing frequency ');
		}
	}
	this.setBillingFrequency = setBillingFrequency;

	function setContractTerm(id, value) {
		if (value && value.isCallback) {
			value.applyValue = function(data) {
				var currentVal = $(getId(id)).val();
				var val = data[value.fieldName];
				if (!val) val = '';
				if (val != currentVal) {
					setContractTerm(id, val);
				}
			};
		} else {
			var val = null;
			if (value != null) {
				val = parseInt(value, 10);
			}
			setAttributeField(id, 'contractterm', val);
		}
	}
	this.setContractTerm = setContractTerm;

	function setContractTermPeriod(id, value) {
		if (value && value.isCallback) {
			value.applyValue = function(data) {
				var currentVal = $(getId(id)).val();
				var val = data[value.fieldName];
				if (!val) val = '';
				if (val != currentVal) {
					setContractTermPeriod(id, val);
				}
			};
		} else {
			var val = null;
			if (value != null) {
				val = parseInt(value, 10);
				if (!val && val !== 0) val = PERIODS[value.toLowerCase()];
			}
			setAttributeField(id, 'contracttermperiod', val);
		}
	}
	this.setContractTermPeriod = setContractTermPeriod;

	function setProductFamily(id, value) {
		if (value && value.isCallback) {
			value.applyValue = function(data) {
				var currentVal = $(getId(id)).val();
				var val = data[value.fieldName] || '';
				if (val != currentVal) {
					setProductFamily(id, val);
				}
			};
		} else {
			var val = null;
			if (value != null) {
				val = value.substr(0, 40);
			}
			setAttributeField(id, 'productfamily', val);
		}
	}
	this.setProductFamily = setProductFamily;

	function markConfigurationInvalid(id, value) {
		if (value && value.isCallback) {
			value.applyValue = function(data) {
				var currentVal = $(getId(id)).val();
				var val = data[value.fieldName];
				if (!val && val !== false) val = '';
				if (val != currentVal) {
					markConfigurationInvalid(id, val);
				}
			};
		} else {
			var indicator = jqc('#currentScreenValidIndicator');
			var invalidIconSrc = jqc('#screenInvalidIcon').attr('src');
			if (indicator.data(PREVIOUS_VALUE) == null) indicator.data(PREVIOUS_VALUE, indicator.attr('src'));
			indicator.attr('src', invalidIconSrc);
			jqc('#CSValidationMessageBox').css({display: 'block'});
			jqc('#CSValidationMessage').html(value);
			setAttributeField(id, 'status', 'Incomplete');
			setAttributeField(id, 'validationmessage', value);
		}
	}
	this.markConfigurationInvalid = markConfigurationInvalid;

	function markConfigurationValid(id) {
		jqc('#CSValidationMessageBox').css({display: 'none'});
		jqc('#CSValidationMessage').html('');
		setAttributeField(id, 'status', 'Valid');
		setAttributeField(id, 'validationmessage', '');
	}
	this.markConfigurationValid = markConfigurationValid;

	function requireDataRefresh(message) {
		displayInfo(message);
		jqc('span.CSFinishButton').hide();
		jqc('span.CSRefreshButton').show();
	}
	this.requireDataRefresh = requireDataRefresh;

	function displayInfo(value) {
		if (value && value.isCallback) {
			value.applyValue = function(data) {
				var val = data[value.fieldName];
				if (val !== 0 && val !== false && !val) val = '';
				var currentVal = '';
				if (val != currentVal) {
					displayInfo(val);
				}
			};
		} else {
			infoMessages[value] = true;
			jqc('#CSInfoMessageBox').css({display: 'block'});
			var html = '';
			for (var m in infoMessages) html += '<p>' + m + '</p>';
			jqc('#CSInfoMessage').html(html);
		}
	}
	this.displayInfo = displayInfo;

	function clearInfo(message) {
		infoMessages = {};
		jqc('#CSInfoMessageBox').css({display: 'none'});
		jqc('#CSInfoMessage').html('');
	}
	this.clearInfo = clearInfo;

	function updateFromRadio(id, radio) {
		var field = $(getId(id));
		var value = $(radio).val();
		if (value != field.val()) {
			setAttribute(id, value);
			updateOptionPrice(id, value);
		}
	}
	this.updateFromRadio = updateFromRadio;

	function constrainList(id, options) {
		var list = jQuery(getId(id));

		var radios = getRadioButtons(id);
		if (radios) {
			var selected = radios.filter(':checked');

			if (list.data(ORIGINAL_OPTIONS) == null) {
				var radiosContainer = jQuery('.csRadiosContainer.' + makeCssIdentifier(id));
				var radiosHtml = radiosContainer.html();
				list.data(ORIGINAL_OPTIONS, radiosHtml);
			}

			var enabledOptions = {};
			for (var i = 0; i < options.length; ++i) {
				enabledOptions[options[i][1]] = true;
			}

			radios.each(function(i) {
				var jqthis = jQuery(this);
				if (enabledOptions[jqthis.val()] != true) {
					if (jqthis.attr('checked')) {
						jqthis.removeAttr('checked');
						list.val('');
						list.data(PREVIOUS_VALUE, null);
					}
					jqthis.parent().remove();
				}
			});

			list.trigger("liszt:updated");
			fireChange(list);
		} else if (list.size() > 0 && list.get(0).tagName == 'SELECT') {
			var selected = list.children(':selected');

			if (list.data(ORIGINAL_OPTIONS) == null) {
				list.data(ORIGINAL_OPTIONS, list.children('option'));
			}

			var html = '';
			var oneOption = '';
			for (var i = 0; i < options.length; i++) {
				oneOption = '<' + 'opt' + 'ion ' + 'value="' + options[i][1] + '"';
				if (selected.attr('value') == options[i][1]) oneOption = oneOption + ' selected="selected" ';
				oneOption += '>' + options[i][0] + '</option>';

				html +=oneOption;
			}

			list.html(html).trigger("liszt:updated");
			fireChange(list);
		} else {
			var cssClass = '.' + makeCssIdentifier(id);
			list = jqc(cssClass + '.csOptionHolder');

			if (list.size() > 0) {

				jQuery.each(list, function(i, it) {

					it = jQuery(it);
					var thisOption = it.find(cssClass + '.csOption');

					if (thisOption.size() === 0) {
						CS.log('Could not find option: ' + id + ' / ' + cssClass + '.csOption');
						return;
					}

					var available = false;
					for (i = 0; i < options.length; i++) {
						if (options[i][1] == thisOption.val()) {
							available = true;
							break;
						}
					}

					if (!available) {
						if (thisOption.is(':checked')) thisOption.attr('checked', false);
						it.data(HIDDEN, true).hide();
					}
				});
			} else {
				CS.log('Could not find list: ' + id + ' / ' + cssClass + '.csOptionHolder');
				return;
			}
			fireChange(jQuery(getId(id)));
		}
	}
	this.constrainList = constrainList;

	function updateMandatoryFields() {

		var allFields = jqc('.attrLabel label');
		log('Updating ' + allFields.size() + ' fields for mandatory markers...');

		$.each(allFields, function(i, it) {
			var field = $(it);
			var id = field.attr('for');

			if (id != null && id.length > 8 && CS.endsWith(id,'_wrapper')) {
				id = id.substring(0, id.indexOf('_wrapper'));

				var requiredVal = $(getId(id + ':_isrequired')).val();
				var required = requiredVal != null && requiredVal.toLowerCase() == 'true';

				var wrapper = $(getId(id)).parents('.attrWrapper');
				var hidden = (wrapper.data(HIDDEN) === 'true');
				var inner = wrapper.children('div');
				//log('Checking isRequired for id ' + id + ': ' + required);

				if (!hidden && required && !inner.hasClass(REQUIRED_CLASS)) inner.addClass(REQUIRED_CLASS);
				if ((hidden || !required) && inner.hasClass(REQUIRED_CLASS)) inner.removeClass(REQUIRED_CLASS);
			}
		});
	}
	this.updateMandatoryFields = updateMandatoryFields;

	function fireChange(field) {
		if (field.data(RULE_LOCK) !== true) {
			log('Field changed: ' + field.attr('id'));
			field.data(RULE_LOCK, true);
		}
		else log('Field locked, no further changes: ' + field.attr('id'));
	}
	this.fireChange = fireChange;

	function resetAttributes() {
		jqc("input[name$='_status']").val('Valid');
		jqc("input[name$='_validationmessage']").val('');
		jqc('#CSValidationMessageBox').css({display: 'none'});
		var indicator = jqc('#currentScreenValidIndicator');
		var indicatorPrevVal = indicator.data(PREVIOUS_VALUE);
		if (indicatorPrevVal != null) indicator.attr('src', indicatorPrevVal);

		//jQuery('input .csAttr').data(HIDDEN, false);

		jqc('.attrWrapper').data(HIDDEN, 'false').data(READ_ONLY, 'false').prev('.attrLabel').data(HIDDEN, 'false');
		// Reset line items
		// _defislineitem param indicates whether the attribute is by default a line item via its definition
		// so reset the attr's state to this
		// Reset required to attribute definition
		// _defisrequired param contains whether attribute is required by default
		jQuery.each(jqc("input.cfgAttr,select.cfgAttr"), function(i, it) {
			jqc(getId(it.id + ':_islineitem')).val(jqc(getId(it.id + ':_defislineitem')).val());
			jqc(getId(it.id + ':_isrequired')).val(jqc(getId(it.id + ':_defisrequired')).val());
		});

		jQuery.each(jqc('.attrWrapper select'), function(i, it) {
			var select = jQuery(it);
			var originalOptions = select.data(ORIGINAL_OPTIONS);
			if (originalOptions != null) { // intentional cast comparison here - actual result may be null OR undefined
				var selectedItem= select.children(':selected'),
					theValue = selectedItem.attr('value');
				select.empty().append(originalOptions);
				select.val(theValue);
				select.trigger("liszt:updated");
			}
		});

		jQuery.each(jQuery('.csRadiosContainer').siblings('.cfgAttr'), function(i, it) {
			var radioWrapper = jQuery(it),
				id = radioWrapper.attr('id'),
				radios = getRadioButtons(id);
				radiosContainer = jQuery('.csRadiosContainer.' + makeCssIdentifier(id));

			var enableNullOption = jqc(getId(id + ':_enablenulloption')).val();

			if (radioWrapper.data(ORIGINAL_OPTIONS) != null) { // intentional cast comparison here - actual result may be null OR undefined
				var theValue = radioWrapper.attr('value');
				radiosContainer.html(radioWrapper.data(ORIGINAL_OPTIONS));
				jQuery(radiosContainer).find('[value="' + theValue + '"]').attr('checked', 'checked');
				radioWrapper.trigger("liszt:updated");
			}

			if (enableNullOption) {
				radios.each(function(item) {
					var jqthis = jQuery(this);
					var optionValue = jqthis.val();
					var theValue = radioWrapper.attr('value');

					if (enableNullOption === "true" && optionValue === NULL_OPTION_VALUE && theValue === '') {
						jqthis.attr('checked', 'checked');
					}
				});
			}

		});

		jQuery.each(jqc('.csOptionHolder'), function(i, it) {
			var option = jQuery(it);
			if (option.data(HIDDEN) === true) option.show().data(HIDDEN, false);
		});
	}
	this.resetAttributes = resetAttributes;

	function unlockAttributes() {
		jqc('input.cfgAttr').data(RULE_LOCK, false);
	}
	this.unlockAttributes = unlockAttributes;

	function applyAttributeEffects() {
		//#
		//# remove any and all previously created hidden input fields to hold
		//# values from R/O fields
		//#
		jQuery('.' + READONLY_PLACEHOLDER).remove();

		jQuery.each(jqc('.attrWrapper'), function(i, it) {

			var fadeAmt = 0.3;
			var wrapper = jQuery(it);
			var id = wrapper.data('attributeId');

			var attributeType = getAttributeFieldValue(id, 'type');
			var el = { size: function() { return 0; } };
			if (id) {
				if (attributeType == CS.ATTRIBUTE_TYPES.LOOKUP) {
					el = jQuery(getId(id + '_Name'));
				} else if (attributeType == CS.ATTRIBUTE_TYPES.SELECT_LIST) {
					el = jQuery(getId(id));
				} else {
					el = jQuery(getId(id + ':_display'));
				}
			}

			//#
			//# HIDDEN
			//#
			if (wrapper.data(HIDDEN) == 'true') {

				wrapper.css('visibility', 'visible').fadeTo('fast', fadeAmt).prev('.attrLabel').fadeTo('fast', fadeAmt);

				if (el.size() > 0)
				{
					// standard inputs / selects
					if (el.attr("selectedIndex") != null) {
						el.data(PREVIOUS_SELECTED, el.attr('selectedIndex')).attr("selectedIndex",-1);
					} else if (el.val()) {
						el.data(PREVIOUS_VALUE, el.val());
					}

					el.val('').attr('disabled', true);

					// related products and lookup fields
					jQuery(getId(id + '_ctrlButtons')).css({visibility: 'hidden'});
					jQuery(getId(id + '_Name')).attr('readonly', true);
					jQuery(getId(id + ':_islineitem')).val('false');

				}

				// Checkboxes
				if (jQuery(getId(id + '__check')))
					jQuery(getId(id + '__check')).val('').attr('checked',false).attr('disabled',true);

				enableRadioButtons(id, false);
			} else {
				wrapper.css('visibility', 'visible').fadeTo('fast', 1).prev('.attrLabel').fadeTo('fast', 1);
				jQuery(getId(id+':_active')).val('true');

				if (el.size() > 0) {
					var val = el.data(PREVIOUS_VALUE);
					el.data(PREVIOUS_VALUE, null);
					if (val != null) el.val(val);
				}

				try {
					if (id) {
						// inputs and selects
						if (el.size() > 0 && el.attr('disabled'))
						{
							el.removeAttr('disabled').attr('selectedIndex', el.data(PREVIOUS_SELECTED));

							// related products and lookup fields
							jQuery(getId(id + '_ctrlButtons')).css({visibility: 'visible'});
						}
						// checkboxes
						if (jQuery(getId(id + '__check'))) jQuery(getId(id + '__check')).removeAttr('disabled');

						enableRadioButtons(id, true);
					}
				} catch (e) {
					CS.log('ERROR' + e);
				}
			}

			//#
			//# READ ONLY
			//#
			if (wrapper.data(READ_ONLY) == 'true') {

				var encodedVal = el.val();
				if (encodedVal) {
					encodedVal = encodedVal.replace(/\"/g,'&quot;');
				} else {
					encodedVal = '';
				}

				wrapper.append('<input type="hidden" class="' + READONLY_PLACEHOLDER +  '" name="' + id + '" value="' + encodedVal + '"> ');

				// Standard inputs / selects
				if (el.size() > 0)	{
					el.attr('readonly', true);
					el.attr('disabled', true);
					jQuery(getId(id + '_ctrlButtons')).fadeTo('fast', fadeAmt).bind('click.CSReadOnly', function(e) {e.preventDefault();});//css({visibility: 'hidden'});
					jQuery(getId(id + '_Name')).attr('readonly', true);

				}

				// Checkboxes
				if (jQuery(getId(id + '__check')))
					jQuery(getId(id + '__check')).attr('disabled',true);

				// Radio
				makeRadioButtonsReadOnly(id, true);
			} else if (wrapper.data(HIDDEN) != 'true'){
				// standard inputs / selects
				if (el.size() > 0)	{
					el.removeAttr('readonly');
					el.removeAttr('disabled');

					jQuery(getId(id + '_ctrlButtons')).fadeTo('fast', 1).unbind('click.CSReadOnly');//css({visibility: 'visible'});
					jQuery(getId(id + '_Name')).removeAttr('readonly');
				}

				// Checkboxes
				if (jQuery(getId(id + '__check')))
					jQuery(getId(id + '__check')).removeAttr('disabled');

				makeRadioButtonsReadOnly(id, false);
			}
		});

	}
	this.applyAttributeEffects = applyAttributeEffects;

	//#
	//# DEPRECATED: Function to hide and enable R/O fields prior to submit so that
	//# they arrive in the RequestObject
	//#
	function createHiddenInputsForROFields()
	{
		jQuery.each(jqc('.attrWrapper'), function(i, it) {

			var wrapper = jQuery(it);
			var id = wrapper.data('attributeId');
			var el = id ? jQuery(getId(id)) : {size: function(){return 0;}};

			//#
			//# READ ONLY - SO HIDE THEM AND THEN ENBLE THEM
			//#
			if (wrapper.data(READ_ONLY) == 'true')
			{
				log('>>> SUBMIT READ-ONLY - HIDDEN INPUT FIELD FOR: ' + id);
				wrapper.append('<!-- ## RO VAL --> <input type="hidden"  name="' + id + '" value="' + el.val() + '"> ');
			}
		});
	}
	this.createHiddenInputsForROFields = createHiddenInputsForROFields;



	function registerCalculation(func) {
		calculations[calculations.length] = func;
	}
	this.registerCalculation = registerCalculation;

	function updateCalculations() {
		jQuery.each(calculations, function(i, calc) {
			try {
				calc.call(CS);
			} catch (e) {
				CS.log(e);
				CS.log(calc);
			}
		});
	}
	this.updateCalculations = updateCalculations;


	function showProgress(displayText,displayImage) {
		hideProgress();
		if (!loadingOverlayEnabled) return;

		jqc("BODY").append('<div id="processing_overlay"></div>');
		jqc("BODY").append(
			'<div id="processing_container">' +
				//'<div id="processing_title">This is title</div>' +
				'<div id="processing_content">' +
					'<img src="'+displayImage+'" style="width:43px;height:11px;" alt=""/>' +
					'<br/><br/>'+displayText+
				'</div>' +
			'</div>'
		);

		var pos = (jQuery.browser.msie && parseInt(jQuery.browser.version, 10) <= 6 ) ? 'absolute' : 'fixed';

		jqc("#processing_container").css({
			position: pos,
			zIndex: 99999,
			padding: 0,
			margin: 0
		});

		jqc("#processing_container").css({
			minWidth: jqc("#processing_container").outerWidth(),
			maxWidth: jqc("#processing_container").outerWidth()
		});

		var top = ((jQuery(window).height() / 2) - (jqc("#processing_container").outerHeight() / 2)) + (-75);
		var left = ((jQuery(window).width() / 2) - (jqc("#processing_container").outerWidth() / 2)) + 0;
		if( top < 0 ) top = 0;
		if( left < 0 ) left = 0;

		// IE6 fix
		if( jQuery.browser.msie && parseInt(jQuery.browser.version, 10) <= 6 ) top = top + jQuery(window).scrollTop();

		jqc("#processing_container").css({
			top: top + 'px',
			left: left + 'px'
		});
		jqc("#processing_overlay").height( jQuery(document).height() );
	}
	this.showProgress = showProgress;

	function hideProgress() {
		jqc("#processing_container").css('cursor:default');
		jqc("#processing_container").remove();
		jqc("#processing_overlay").remove();
	}
	this.hideProgress = hideProgress;

	function progressOn() {
		CS.indicator.start('#indicatorContainer');
	}
	this.progressOn =  progressOn;

	function executePreSubmissionTasks(js) {
		// this may be a double indirection because evaluateAllRules will call the parameter function
		// using executeOnLookupQueriesDone. However, due to lack of a good test setup to check this,
		// I'm leaving it as-is for now. KT 2012-10-23
		submissionExecute = true;
		CS.rules.evaluateAllRules(function() {
			executeOnLookupQueriesDone(function() {
				CS.log('Starting deferred form submission');
				doPreSubmission(js);
			}, "doPreSubmission");
		}, "doPreSubmissionOuter");
	}
	this.executePreSubmissionTasks = executePreSubmissionTasks;

	function doPreSubmission(js) {
		CS.progressOn();
		if (typeof js === 'function') {
			js();
		} else if (typeof js === 'string') {
			eval(js);
		}
	}

	//#
	//# URL Encode / Decode wrappers.
	//#
	function urlEncode(strValue) {
		return encodeURIComponent(strValue).replace(/\s/g, "+");
	}
	this.urlEncode = urlEncode;

	function urlDecode(strValue) {
		return decodeURIComponent(strValue.replace(/\+/g, " "));
	}
	this.urlDecode = urlDecode;


	function submitForm(formName, values) {
		var f = jqc('#CS_' + formName);
		if (f.size() === 0) {
			console.log('Form CS_' + formName + ' not found');
			return;
		}

		var form = f.get(0);

		if (values) {
			for (var key in values) {
				log('>>>> ' + key);
				if (key == '_action') f.attr('action', values[key]);
				else {
					if (form[key] == null) log('>>>> Expected form field missing: ' + key);
					else form[key].value = values[key];
				}
			}
		}

		f.submit();
	}
	this.submitForm = submitForm;

	function isNumber(ob) {
		return typeof ob == "number" || (typeof ob == "string" && /^(\+|-)?\d+(\.\d*)?$/.test(ob));
	}

	function isInteger(ob) {
		return (typeof ob == "number" && ob % 1 == 0) || (typeof ob == "string" && /^(\+|-)?\d+$/.test(ob));
	}

	function isDecimal(ob) {
		return (typeof ob == "number" && ob % 1 != 0) || (typeof ob == "string" && /^(\+|-)?\d+\.\d*$/.test(ob));
	}

	function initMultiLookup(params) {
		var table = jQuery(getId(params.tableId)),
			tplRow = table.find('tr.dataRow').remove().removeClass('first last'),
			colKeys = [],
			colMaps = {};

		jQuery.each(tplRow.find('span.col'), function(i, it) {
			var j = jQuery(it);
			var idx = parseInt(j.attr('data-col-idx'), 10);
			if (!isNaN(idx)) {
				colKeys[idx] = jQuery(it).text();
			}
		});

		table.css('display', 'table');
		// add column map to each record and convert keys to lower case
		for (var i = params.records.length; i--;) {
			var record = params.records[i];
			colMaps[params.lookupId] = params.columnMap;
			for (var key in record) {
				var val = record[key];
				if (typeof(val) != 'object') {
					delete record[key];
					record[key.toLowerCase()] = val;
				}
			}
		}
		this.multiSelectLookups[params.lookupId] = {
			tableId: getId(params.tableId),
			tplRow: tplRow,
			max: params.max,
			columnKeys: colKeys,
			columnMap: colMaps[params.lookupId],
			records: params.records
		};
	}
	this.initMultiLookup = initMultiLookup;

	function addLookupRecord(lookupId, data) {
		var colMap = data.columnMap,
			lookup = this.multiSelectLookups[lookupId],
			idx;

		if (!lookup) {
			log('Could not add record, lookup not found: ' + lookupId);
			return;
		}

		if (!lookup.columnMap || lookup.columnMap == {}) {
			lookup.columnMap = {};
			for (var key in colMap) {
				lookup.columnMap[key] = colMap[key];
			}
		}
		delete data.columnMap;
		idx = lookup.records.length;
		lookup.records[idx] = data;
		updateMultiSelectLookupValue(currentLookupId);
	}
	this.addLookupRecord = addLookupRecord;

	function removeLookupRecord(lookupId, el) {
		var idx = parseInt(jQuery(el).attr('data-lookup-idx'), 10),
				lookup = this.multiSelectLookups[lookupId];

		if (!lookup || !lookup.records) {
			CS.log('Could not find valid lookup data for ID ' + lookupId, lookup);
			return;
		}

		if (isNaN(idx)) {
			CS.log('Could not parse lookup index (' + jQuery(el).attr('data-lookup-idx') + ')');
			return;
		}

		if (lookup.records.length <= idx) {
			CS.log('Lookup index out of bounds (' + idx + ' / ' + lookup.records.length + ')');
			return;
		}

		lookup.records.remove(idx,idx);
		updateMultiSelectLookupValue(lookupId);
		updateMultiSelectLookupDisplay(lookupId);
	}
	this.removeLookupRecord = removeLookupRecord;

	function updateMultiSelectLookupValue(lookupId) {
		var multiSelectLookup = CS.multiSelectLookups[lookupId],
				attrVal = '',
				sep = '';

		for (var i = 0; i < multiSelectLookup.records.length; i++) {
			var record = multiSelectLookup.records[i];

			if (record) {
				attrVal += sep + record.id;
				sep = ',';
			}
		}
		CS.setAttribute(lookupId, attrVal);
	}
	this.updateMultiSelectLookupValue = updateMultiSelectLookupValue;

	function updateMultiSelectLookupDisplay(lookupId) {
		var multiSelectLookup = CS.multiSelectLookups[lookupId],
				tplRow = multiSelectLookup.tplRow,
				table = jQuery(multiSelectLookup.tableId),
				colNames = [],
				i,k;

		table.find('tr.dataRow').remove();

		if (multiSelectLookup.records.length > 0) {
			for (k = multiSelectLookup.columnKeys.length; k--; ) {
				var colLabel = multiSelectLookup.columnKeys[k];
				colNames[k] = multiSelectLookup.columnMap[colLabel];
			}
		}

		for (i = 0; i < multiSelectLookup.records.length; i++) {
			var newRow = tplRow.clone(),
				record = multiSelectLookup.records[i];

			if (record) {
			for (k = colNames.length; k--; ) {
				var value = record[colNames[k]] || '';
				newRow.find('span[data-col-idx=' + k + ']').text(value);
			}
			newRow.find('span.name').text(record.name);
			newRow.find('a.delAction').attr('data-lookup-idx', i);
			if (i === 0) newRow.addClass('first');
			if (i == multiSelectLookup.records.length - 1) newRow.addClass('last');
			table.append(newRow);
		}
	}
	}
	this.updateMultiSelectLookupDisplay = updateMultiSelectLookupDisplay;

	function updateMultiSelectLookupsDisplay() {
		for (var id in CS.multiSelectLookups) {
			updateMultiSelectLookupDisplay(id);
		}
	}
	this.updateMultiSelectLookupsDisplay = updateMultiSelectLookupsDisplay;

	function getRadioButtons(id) {
		var radios = jQuery("input[name='" + id + "-list" + "']");
		if (radios && radios.length > 0 && radios[0].type === "radio") {
			return radios;
		}

		return false;
	}

	function enableRadioButtons(id, enable) {
		if (!id) {
			return;
		}

		var attr = jQuery(getId(id));
		var radios = getRadioButtons(id);
		if (radios) {
			radios.each(function(i) {
				var jqthis = jQuery(this);
				if (enable) {
					jqthis.removeAttr('disabled');
					if (attr.val() === jqthis.val()) {
						jqthis.attr('checked', 'checked');
					}
				} else {
					jqthis.attr('disabled', 'disabled');
					jqthis.removeAttr('checked');
				}
			});
		}
	}

	function makeRadioButtonsReadOnly(id, readOnly) {
		if (!id) {
			return;
		}

		var attr = jQuery(getId(id));
		var radios = getRadioButtons(id);
		if (radios) {
			radios.each(function(i) {
				var jqthis = jQuery(this);
				if (readOnly) {
					jqthis.attr('disabled', 'disabled');
				} else {
					jqthis.removeAttr('disabled');
				}
			});
		}
	}
}

initCore.call(CS);
CS.getSelectListLookupDebounced = CS.debounce(CS.INPUT_DELAY_BEFORE_AJAX, CS.getSelectListLookup);

//Damjan Jelas 12/04/2013
//Indicator extension
(function(CS) {
	var module = CS.namespace('CS.indicator');
	module = (function(indicator) {
		var finishDisabled = false;
		var $ = CS.$,
		log = CS.log,
		cssClass = 'indicator',
		cssBackgroundClass = 'indicatorBackground',
		startLast,
		stopLast,
		timer,
		start = function(selector, miliseconds) {
			jQuery('span.CSFinishButton a.finish').attr("class", "btnDisabled finish");
			finishDisabled = true;
			if (!CS.isLoadingOverlayEnabled()) {
				return;
			}

			if (selector) {
				var container = $(selector);

				//implicit parameter memory, so we can call 'start' after 'stop' on the same element without selector parameter
				startLast = function() {
					if( container.find('.' + cssClass).length === 0){				//don't create elements if they exist
						container.end();
						container.html('<div class="' + cssClass + '"></div>');
						container.append('<div class="' + cssBackgroundClass + '"></div>');
						container.show();
						log('Starting indicator for: ' + selector);
					}
					clearTimer();
				};
				stopLast = function() {
					stop(selector);
				};
			}
			if (startLast) {
				if (!miliseconds) {
					startLast();
				} else{
					//don't create new delayed function if we already have one
					//user should call 'stop' method before 'start' if he want's to re-initialize delay
					if (!timer) {
						timer = setTimeout(startLast, miliseconds);
						log('Setting indicator timer: ID-' + timer + ', Delay-' + miliseconds);
					}
				}
			}
		},
		clearTimer = function() {
			if (timer) {
				log('Removing indicator timer: ID-' + timer );
				clearTimeout(timer);
				timer = null;
			}
		},
		stop = function (selector) {
			jQuery('span.CSFinishButton a.finish').attr("class", "btn finish");
			finishDisabled = false;
			if (!CS.isLoadingOverlayEnabled()) {
				return;
			}

			if (selector) {
				var container = $(selector);
				container.children('.' + cssClass ).remove();
				container.children('.' + cssBackgroundClass).remove();
				container.hide();
				log('Stoping indicator for: ' + selector);
			} else {
				clearTimer();
				stopLast && stopLast();
			}
		};

		function isFinishDisabled() {
			return finishDisabled;
		}

		//expose
		indicator.start = start;
		indicator.stop = stop;
		indicator.isFinishDisabled = isFinishDisabled;

		return indicator;
	})(module || {});
})(CS);

/*
 * Data conversion functions for native, normal and localized form data
 */
(function(CS) {
	var module = CS.namespace('CS.dataConverter');
	module = (function(dataConverter) {
		var DATA_TYPE_DECIMAL = 'Decimal',
			DATA_TYPE_DATE = 'Date',
			DATA_TYPE_DOUBLE = 'Double',
			DATA_TYPE_INTEGER = 'Integer',
			DATA_TYPE_BOOLEAN = 'Boolean',
			DATA_TYPE_STRING = 'String',
			BIG_JS_ROUND_HALF_EVEN = 2,
			INTERNAL_DATE_FORMAT = 'yyyy-MM-dd',
			INTERNAL_DATETIME_FORMAT = 'yyyy-MM-dd HH:mm:ss',
			$ = jQuery.noConflict();

		/**
		 * Object to hold boolean converting rules.
		 * For now, all methods are the same
		 */
		var BooleanConverter = {
			TRUE : String(true),
			FALSE : String(false),
			normalizeValue :
				function normalizeValue(value) {
					'use strict';
					return String(String(value).toLowerCase() == this.TRUE);
				},
			localizeValue :
				function localizeValue(value) {
					'use strict';
					return String(String(value) == this.TRUE);
				},
			unlocalizeValue :
				function unlocalizeValue(value) {
					'use strict';
					return String(String(parseBoolean(value)) == this.TRUE);
				}
		};

		/**
		 * Converts a near-normal or a native data value to the normal form according to the attribute's data type.
		 * Use this on results of calculations.
		 * Return value if always a string.
		 *
		 * E.g. for a decimal attribute with scale 2:
		 * '1' -> '1.00'
		 * '1.201' -> '1.20'
		 */
		function normalizeValue(value, typeInfo) {
			var normalValue = null;
			if (value === null || (typeof value == 'string' && value.trim() === '') || value === CS.NULL_OPTION_VALUE) {
				normalValue = '';
			} else if (typeInfo.type == DATA_TYPE_DECIMAL) {
				normalValue = roundValue(value, typeInfo.scale);
			} else if (typeInfo.type == DATA_TYPE_DOUBLE) {
				if (isNaN(value) || !isFinite(value)) {
					normalValue = value = '';
					CS.log('normalizeValue: replacing invalid DATA_TYPE_DOUBLE ' + value + ' with ""');
				} else {
					normalValue = value;
				}
			} else if (typeInfo.type == DATA_TYPE_INTEGER) {
				normalValue = roundValue(value, 0);
			} else if (typeInfo.type == DATA_TYPE_DATE) {
				var dateValue;
				if (value instanceof Date) {
					dateValue = value;
				} else {
					dateValue = Date.parseExact(value, INTERNAL_DATE_FORMAT);
					if (!dateValue) {
						dateValue = Date.parseExact(value, INTERNAL_DATETIME_FORMAT);
					}
				}

				normalValue = dateValue != null ? dateValue.toString(INTERNAL_DATE_FORMAT) : '';
			} else if (typeInfo.type == DATA_TYPE_BOOLEAN) {
				normalValue = BooleanConverter.normalizeValue(value);
			} else {
				normalValue = String(value);
			}
			return normalValue;
		}

		function roundValue(value, scale) {
			if (isNaN(value) || !isFinite(value)) {
				CS.log('roundValue: replacing ' + value + ' with ""');
				return '';
			}
			try {
				var checkedValue = Big(value);

				if (!isNaN(checkedValue)) {
					value = checkedValue.round(scale, BIG_JS_ROUND_HALF_EVEN).toFixed(scale);
				}
			} catch (e) {}

			return value;
		}

		/**
		 * Converts a normalized value to the localized format using user's locale.
		 * Return value if always a string.
		 */
		function localizeValue(normalValue, typeInfo) {
			var localizedValue = null;

			if (normalValue === null || (typeof normalValue == 'string' && normalValue.trim() === '')){
				localizedValue = '';
			} else if (!typeInfo || !typeInfo.type) {
				CS.log('Attempted localizeValue but no type information provided: ', typeInfo);
				localizedValue = normalValue;
			} else if (typeInfo.type == DATA_TYPE_DECIMAL || typeInfo.type == DATA_TYPE_INTEGER) {
				// generate format string by repeating decimal zeroes _scale_times
				var format = '#,##0' + (typeInfo.scale ? '.' + new Array(typeInfo.scale + 1).join('0') : '');
				localizedValue = $.formatNumber(normalValue, { format: format, locale: this.userLanguage });
			} else if (typeInfo.type == DATA_TYPE_DATE) {
				// parse and format the value to check validity and normalize

				var date = normalValue instanceof Date ? normalValue : Date.parseExact(normalValue, INTERNAL_DATE_FORMAT);
				localizedValue = date != null ? date.toString(UserContext.dateFormat) : '';
			} else if (typeInfo.type == DATA_TYPE_BOOLEAN) {
				localizedValue = BooleanConverter.localizeValue(normalValue);
			} else {
				localizedValue = String(normalValue);
			}

			return localizedValue;
		}

		/**
		 * Converts a localized value to its normal form using user's locale.
		 * Return value if always a string.
		 */
		function unlocalizeValue(localizedValue, typeInfo) {
			var normalValue = null,
				self = this;

			if (localizedValue === null || (typeof localizedValue == 'string' && localizedValue.trim() === '')){
				normalValue = '';
			} else if (typeInfo.type == DATA_TYPE_DECIMAL || typeInfo.type == DATA_TYPE_INTEGER) {
				var value = jQuery.parseNumber(localizedValue, { locale: self.userLanguage });
				normalValue = normalizeValue(value, typeInfo);
			} else if (typeInfo.type == DATA_TYPE_DATE) {
				var date = (
					Date.parseExact(localizedValue, UserContext.dateFormat)
					|| Date.parseExact(localizedValue, Date.CultureStrings[Date.CultureStrings.lang]['M/d/yyyy'])
					|| Date.parse(localizedValue)
					);
				normalValue = date != null ? date.toString(INTERNAL_DATE_FORMAT) : null;
			} else if (typeInfo.type == DATA_TYPE_BOOLEAN) {
				normalValue = BooleanConverter.unlocalizeValue(localizedValue);
			} else {
				normalValue = String(localizedValue);
			}

			return normalValue;
		}

		function parseDate(normalValue) {
			return Date.parseExact(normalValue, INTERNAL_DATE_FORMAT);
		}

		function parseBoolean(value) {
			var boolValue = null;
			if (value !== null) {
				var tmpval = (''+value).trim();
				if (tmpval.match(/^true$/gi) !== null || tmpval.match(/^yes$/gi) !== null || tmpval.match(/^1$/gi) !== null) {
					boolValue = true;
				} else if (tmpval.match(/^false$/gi) !== null || tmpval.match(/^no$/gi) !== null || tmpval.match(/^0$/gi) !== null) {
					boolValue = false;
				}
			}
			return boolValue;
		}

		// expose...
		dataConverter.DATA_TYPE_DECIMAL = DATA_TYPE_DECIMAL;
		dataConverter.DATA_TYPE_DATE = DATA_TYPE_DATE;
		dataConverter.DATA_TYPE_DOUBLE = DATA_TYPE_DOUBLE;
		dataConverter.DATA_TYPE_INTEGER = DATA_TYPE_INTEGER;
		dataConverter.DATA_TYPE_BOOLEAN = DATA_TYPE_BOOLEAN;
		dataConverter.DATA_TYPE_STRING = DATA_TYPE_STRING;
		dataConverter.normalizeValue = normalizeValue;
		dataConverter.roundValue = roundValue;
		dataConverter.localizeValue = localizeValue;
		dataConverter.unlocalizeValue = unlocalizeValue;
		dataConverter.parseDate = parseDate;
		dataConverter.parseBoolean = parseBoolean;
		dataConverter.NORMAL_BOOLEAN_TRUE = BooleanConverter.TRUE,
		dataConverter.NORMAL_BOOLEAN_FALSE = BooleanConverter.FALSE;

		return dataConverter;
	})(module || {});
})(CS);

/*
 * Cross domain JavaScript API for custom VF pages in iframes and popups
 */
(function(CS) {
	var module = CS.namespace('CS.messageApi');
	module = (function(messageApi) {

		function init() {
			if (window.addEventListener) {
				// W3C standard
				addEventListener("message", CS.messageApi.processApiMessage, false);
			} else {
				// IE specific
				attachEvent("onmessage", CS.messageApi.processApiMessage);
			}

			// IE9 is missing native atob and btoa implementation, skip base 64 encoding for IE9
			if( jQuery.browser.msie && parseInt(jQuery.browser.version, 10) <= 9 ) {
				window.atob = function(str) { return str; };
				window.btoa = function(str) { return str; };
			}
		}

		/**
		 * @customCommands object contains set of methods that will be registered as legitimate call methods for
		 * usage over messaging API
		 */
		var CUSTOM_COMMANDS = {};

		function registerCustomCommands(customCommands) {
			if (customCommands) {
				for (var name in customCommands) {
					if (typeof name === 'string' && typeof customCommands[name] === 'function') {
						CUSTOM_COMMANDS[name] = customCommands[name];
						console.log("CS.messageApi is registering custom command : " + name);
					}
				}
			}
		}

		this.registerCustomCommand = function(name, handler) {
			if (COMMANDS[name]) {
				return; // already existing
			}
			if (typeof name === 'string' && typeof handler === 'function') {
				CUSTOM_COMMANDS[name] = handler;
				console.log("CS.messageApi is registering custom command : " + name);
			}
		}

		function processApiMessage(event) {
			var request;

			try {
				request = jQuery.parseJSON(decodeMessage(event.data));
			} catch (e) {
				/* This exception may happen when message is received in messageApi listener
				 * and message is not intended to be used with messageApi but some other listener.
				 * When this happens we leave silently and leave other listener to try to process
				 * the message.
				 */
				return;
			}

			try {
				var msgProcessor = new MessageProcessor(request);
				var response = msgProcessor.process();
				response.messageId = request.messageId;
				postSuccess(event.source, response);
			} catch (e) {
				postError(event.source, {errorMsg: e, messageId: request.messageId });
			}
		}

		function MessageProcessor(request) {
			var request = request;

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

			var COMMANDS = {
				'getAttribute': getAttribute,
				'setAttribute': setAttribute,
				'getConfigurationField': getConfigurationField,
				'setConfigurationField': setConfigurationField,
				'getAttributeFieldValue': getAttributeFieldValue,
				'setAttributeFieldValue': setAttributeFieldValue
			};

			this.process = function() {
				var commandName = request.command;
				if (commandName === undefined) {
					throw 'Message error. Command name undefined.';
				}

				var cmd = COMMANDS[commandName] || CUSTOM_COMMANDS[commandName];
				if (cmd === undefined) {
					throw 'Message error. Command does not exist : ' + commandName;
				}

				if (CUSTOM_COMMANDS[commandName]) {
					checkAccessKey(request);
				}

				var response = cmd.call(this, request);
				return response;
			}

			function getAttribute(request) {
				var attrRefId = request.attrRefId;
				var value = CS.getAttributeValue(attrRefId);

				if (value === undefined) {
					throw 'Attribute "' + attrRefId + '" does not exist.';
				}
				return {"value": value};
			}

			function getAttributeFieldValue(request) {
				var attrRefId = request.attrRefId;
				var fieldName = request.fieldName;
				var value = CS.getAttributeFieldValue(attrRefId, fieldName);

				if (value === undefined) {
					throw 'Attribute "' + attrRefId + '" field value "' + fieldName + '" does not exist.';
				}
				return {"value": value};
			}

			function getConfigurationField(request) {
				var cfgRefId = request.cfgRefId;
				var fieldName = request.fieldName;

				if (CONFIGURATION_FIELDS[fieldName] === undefined) {
					throw 'Configuration "' + cfgRefId + '" field value "' + fieldName + '" does not exist.';
				}

				var value = CS.getAttributeField(cfgRefId, fieldName);
				if (value === null) {
					throw 'Configuration "' + cfgRefId + '" not accessible.';
				}

				return {"value": value[0].value};
			}

			function setAttribute(request) {
				checkAccessKey(request);
				var attrRefId = request.attrRefId;
				var oldValue = CS.getAttributeValue(attrRefId);

				if (oldValue === undefined) {
					throw 'Attribute "' + attrRefId + '" does not exist.';
				}

				CS.setAttribute(attrRefId, request.value);
				return {"value": oldValue};
			}

			function setAttributeFieldValue(request) {
				checkAccessKey(request);
				var attrRefId = request.attrRefId;
				var fieldName = request.fieldName;
				var oldValue = CS.getAttributeValue(attrRefId);

				if (fieldName === undefined) {
					throw 'Message error. Attribute Field Name undefined : ' + fieldName;
				}

				var oldValue = CS.getAttributeFieldValue(attrRefId, fieldName);
				if (oldValue === undefined) {
					throw 'Attribute "' + attrRefId + '" field value "' + fieldName + '" does not exist.';
				}

				CS.setAttributeField(attrRefId, fieldName, request.value);
				return {"value": oldValue};
			}

			function setConfigurationField(request) {
				checkAccessKey(request);
				var cfgRefId = request.cfgRefId;
				var fieldName = request.fieldName;

				if (CONFIGURATION_FIELDS[fieldName] === undefined) {
					throw 'Message error. requested configuration field not existing : ' + fieldName;
				}

				var oldValue = CS.getAttributeField(cfgRefId, fieldName);
				if (oldValue === null) {
					throw 'Configuration "' + cfgRefId + '" not accessible. Please check if you are referencing proper configuration in hierarchy.';
				}

				var value = request.value;
				if (fieldName === CONFIGURATION_FIELDS.billingfrequency) {
					CS.setBillingFrequency(cfgRefId, value);
				} else if (fieldName === CONFIGURATION_FIELDS.contracttermperiod) {
					CS.setContractTermPeriod(cfgRefId, value);
				} else {
					CS.setAttributeField(cfgRefId, fieldName, value);
				}

				return {"value": oldValue[0].value};
			}

			function checkAccessKey(request) {
				var MESSAGING_ACCESS_KEY = 'sid_Client';

				if (request.accessKey != getCookie(MESSAGING_ACCESS_KEY)) {
					throw 'Mismatch for access key.';
				}
			}
		}

		function postSuccess(eventSource, response) {
			if (eventSource != undefined) {
				postMessage(eventSource, response.value, null, response.messageId);
			}
		}

		function postError(eventSource, response) {
			if (eventSource != undefined) {
				postMessage(eventSource, null, response.errorMsg, response.messageId);
			}
		}

		function postMessage(eventSource, value, errorMsg, messageId) {
			var message = JSON.stringify({
				"value": value,
				"errorMsg": errorMsg,
				"messageId": messageId
			});
			eventSource.postMessage(encodeMessage(message), '*');
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

		// public
		messageApi.init = init;
		messageApi.processApiMessage = processApiMessage;
		messageApi.registerCustomCommand = registerCustomCommand;
		messageApi.registerCustomCommands = registerCustomCommands;
		return messageApi;
	})(module || {});
})(CS);
CS.messageApi.init();
