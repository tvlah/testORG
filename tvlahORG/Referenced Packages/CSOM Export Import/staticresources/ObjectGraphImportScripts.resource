/************************************************************************************************
 *
 * ObjectGraphImport class
 *
 * This is the client-side controller of the ObjectGraphImport component.
 *
 ************************************************************************************************/
function ObjectGraphImport(rootItems, itemsMap, objectGraph, ogConfig, itemOptionsId, tableTemplateContainerId, tableTemplateId, breadcrumbsId, hierarchicalTableContainerId, summaryTableContainerId) {
	/*
	 * Common for both summary table and hierarchical view
	 */
	this.graph = new Graph(itemsMap, objectGraph, rootItems, ogConfig);
	var $j = jQuery;

	/*
	 * Hierarchical view
	 */
	this.browseStack = new BrowseStack();
	var hierarchicalTableRenderer = new HierarchicalTableRenderer(this.graph, tableTemplateContainerId, tableTemplateId, hierarchicalTableContainerId);
	this.breadcrumbsRenderer = new BreadcrumbsRenderer(breadcrumbsId);

	this.browseStack.pushLevel(new BrowseLevel(null, "Root items", this.graph.rootItems));
	CS.log("Root items", this.graph.rootItems);

	this.expandRow = hierarchicalTableRenderer.expandRow;
	this.collapseRow = hierarchicalTableRenderer.collapseRow;
	this.expandAll = function() {
		hierarchicalTableRenderer.expandAll(this.browseStack.getTopLevel().items);
	}
	this.collapseAll = function() {
		hierarchicalTableRenderer.collapseAll(this.browseStack.getTopLevel().items);
	}

	function descend(childCollection) {
		var splitChildCollection = childCollection.split("/");
		var parentId = splitChildCollection[0];
		var childCollectionName = splitChildCollection[1];
		var name = childCollectionName + " of " + this.graph.itemsMap[parentId].typeLabel + " " + this.graph.itemsMap[parentId].recName;

		var itemIds = this.graph.itemsMap[parentId].children[childCollectionName];

		this.browseStack.pushLevel(new BrowseLevel(parentId, name, itemIds));
	}
	this.descend = descend;

	function ascend(to) {
		var topLevel = this.browseStack.getTopLevel();
		while (topLevel != null && topLevel.htmlId != to) {
			topLevel = this.browseStack.popLevel();
		}
	}
	this.ascend = ascend;

	function rerenderBrowser() {
		$j(document).trigger("RerenderBrowser", [this.browseStack]);
	}
	this.rerenderBrowser = rerenderBrowser;

	/*
	 * Summary table related
	 */
	this.summaryTableModel = new SummaryTableModel(this.graph);
	this.summaryTableRenderer = new SummaryTableRenderer(this.summaryTableModel, tableTemplateContainerId, tableTemplateId, summaryTableContainerId);

	this.allOptionsController = new AllOptionsController(this.graph, this.summaryTableModel, this.browseStack);
	this.applyActionToAll = this.allOptionsController.applyActionToAll;

	function rerenderSummary() {
		$j(document).trigger("RerenderSummary");
	}
	this.rerenderSummary = rerenderSummary;

	rerenderSummary();

	this.getImportItems = function() {
		var compactedItems = [];
		for (var i = 0; i < this.summaryTableModel.summaryItems.length; ++i) {
			var item = this.graph.itemsMap[this.summaryTableModel.summaryItems[i]];

			var compactedOptions = {};
			for (var optLabel in item.options) {
				var opt = item.options[optLabel];
				var compactedOpt = {
					'label': optLabel,
					'selectedOption': opt.selectedOption
				};

				compactedOptions[opt.label] = compactedOpt;
			}

			var compactedItem = {
				'oId': item.oId,
				'options': compactedOptions
			};

			compactedItems.push(compactedItem);
		}

		return compactedItems;
	}
}

/************************************************************************************************
 *
 * Graph class
 *
 * Model class holding the graph structures
 *
 ************************************************************************************************/
function Graph(itemsMap, objectGraph, rootItems, ogConfig) {
	this.itemsMap = itemsMap;
	this.objectGraph = objectGraph;
	this.rootItems = rootItems;
	this.ogConfig = ogConfig;
	var self = this;

	function itemOptionChanged(event, itemId, source, optionName, newValue) {
		self.itemsMap[itemId].optionChanged(source, optionName, newValue);
	}
	$j(document).bind("ItemOptionChanged", itemOptionChanged);

	for (var itemId in this.itemsMap) {
		var item = this.itemsMap[itemId];
		item = new GraphItem(this, item);
		this.itemsMap[itemId] = item;
	}
}

/************************************************************************************************
 *
 * GraphItem class
 *
 * Model class - Each object of this class represents an item in the graph.
 *
 ************************************************************************************************/
function GraphItem(graph, obj) {
	this.graph = graph;

	for (prop in obj) {
		this[prop] = obj[prop];
	}

	for (var option in this.options) {
		option.htmlName = this.oId + "_" + option.label;

		// validate basic option properties and provide clues. Also, avoid NPEs in later code (TypeError: can't do x with undefined)
		if (!option.label) {
			option.label = "Please provide a label for this option";
		}
		if (!option.type) {
			option.label += " <please provide a type for this option>";
			option.type = "text";
		}
	}

	for (var parentRel in this.parents) {
		var parentId = this.parents[parentRel];
		if (!parentId) {
			continue;
		}

		var parent = graph.itemsMap[parentId];
		if (!parent) {
			continue;
		}

		if (!parent.children) {
			parent.children = {};
		}

		if (!parent.children[this.typeLabelPlural]) {
			parent.children[this.typeLabelPlural] = [];
		}

		parent.children[this.typeLabelPlural].push(this.oId);
	}
}

/**
 * Return true if at least one option is defined on the item.
 */
GraphItem.prototype.itemHasOptions = function() {
	return this.options && this.options['Action'];
}

/**
 * Handle ItemOptionChanged event on a graph item. Do not use this to programatically change the
 * value of the item because an event will not be fired and the change will not be reflected in UI
 * and in other places
 */
GraphItem.prototype.optionChanged = function(source, optionName, newValue) {
	var changed = this.options[optionName].selectedOption != newValue;
	if (changed) {
		this.options[optionName].selectedOption = newValue;
		console.log("New option value for " + this.oId + " " + optionName + "=" + newValue);
	}
}

GraphItem.prototype.updateOption = function(optionName, newValue) {
	var changed = this.options[optionName].selectedOption != newValue;
	if (changed) {
		this.options[optionName].selectedOption = newValue;
		console.log("New option value for " + this.oId + " " + optionName + "=" + newValue);
		$j(document).trigger("ItemOptionChanged", [this.oId, null, optionName, newValue]);
	}
}

/************************************************************************************************
 *
 * IdGenerator class
 *
 * Generates unique Ids for html elements
 *
 ************************************************************************************************/
function IdGenerator() {}
IdGenerator.currentId = 0;
IdGenerator.nextId = function() {
	return (++IdGenerator.currentId) + "";
}

/*
 * Hierarchical view related classes
 */

/************************************************************************************************
 *
 * BrowseStack class
 *
 * Model class - stack of BrowseLevel objects representing the user's browsing history down the
 * data graph.
 *
 ************************************************************************************************/
function BrowseStack() {
	var levels = [];

	function getTopLevel() {
		return levels.length == 0 ? null : levels[levels.length - 1];
	}
	this.getTopLevel = getTopLevel;

	function getLevels() {
		return levels.length == 0 ? [] : levels;
	}
	this.getLevels = getLevels;

	function pushLevel(level) {
		var oldTopLevel = getTopLevel();
		levels.push(level);
		$j(document).trigger("BrowseStackPush", [oldTopLevel, level]);
	}
	this.pushLevel = pushLevel;

	function popLevel() {
		var oldTopLevel = levels.pop();
		var newTopLevel = getTopLevel();
		$j(document).trigger("BrowseStackPop", [oldTopLevel, newTopLevel]);
		return newTopLevel;
	}
	this.popLevel = popLevel;
}

/************************************************************************************************
 *
 * BrowseLevel class
 *
 * Model class - a level in the user's browsing history down the data graph.
 *
 ************************************************************************************************/
function BrowseLevel(parent, name, items) {
	this.items = items;
	this.parent = parent;
	this.htmlId = IdGenerator.nextId();
	this.name = name;
}

/************************************************************************************************
 *
 * HierarchicalTableRenderer class
 *
 * View class for the table of data representing siblings of nodes in the data graph
 *
 ************************************************************************************************/
function HierarchicalTableRenderer(graph, tableTemplateContainerId, tableTemplateId, hierarchicalTableContainerId) {
	var ANIM_TIME = 300;

	$j(document).bind("BrowseStackPush", renderPush);
	$j(document).bind("BrowseStackPop", renderPop);
	$j(document).bind("RerenderBrowser", rerender);

	function renderPush(evt, oldTopLevel, newTopLevel) {
		// copy the template table into new table, replace it's id and set rows
		var tableTemplateHtml = $j(CS.getId(tableTemplateContainerId)).html() + "";
		tableTemplateHtml = tableTemplateHtml.replace(tableTemplateId, newTopLevel.htmlId);
		$j(CS.getId(hierarchicalTableContainerId)).append(tableTemplateHtml);
		generateItemsTableRows(newTopLevel.items, $j(CS.getId(newTopLevel.htmlId) + ">tbody"));

		// animate the new table in
		$j(CS.getId(newTopLevel.htmlId)).css({"display": "inline", "float": "left", "clear": "none", "width": "1000px"});
		if (oldTopLevel != null) {
			$j(CS.getId(oldTopLevel.htmlId)).animate({"margin-left": "-1000px"}, ANIM_TIME, function() {
				$j(CS.getId(oldTopLevel.htmlId)).css("display", "none");
			});
		} else {
			$j(CS.getId(newTopLevel.htmlId)).css("margin-left", "1000px");
			$j(CS.getId(newTopLevel.htmlId)).animate({"margin-left": "0"}, ANIM_TIME);
		}
	}

	function renderPop(evt, oldTopLevel, newTopLevel) {
		$j(CS.getId(newTopLevel.htmlId)).css({"margin-left": "-1000px", "display": "inline"});
		$j(CS.getId(newTopLevel.htmlId)).animate({"margin-left": "0"}, ANIM_TIME, function() {
			$j(CS.getId(oldTopLevel.htmlId)).remove();
		});
	}

	function rerender(evt, browseStack) {
		$j(CS.getId(hierarchicalTableContainerId)).empty();
		var topLevel = browseStack.getTopLevel();

		var levels = browseStack.getLevels();
		for (var i = 0; i < levels.length; ++i) {
			var level = levels[i];

			// copy the template table into new table, replace it's id and set rows
			var tableTemplateHtml = $j(CS.getId(tableTemplateContainerId)).html() + "";
			tableTemplateHtml = tableTemplateHtml.replace(tableTemplateId, level.htmlId);
			$j(CS.getId(hierarchicalTableContainerId)).append(tableTemplateHtml);
			generateItemsTableRows(level.items, $j(CS.getId(level.htmlId) + ">tbody"));

			if (level === topLevel) {
				$j(CS.getId(level.htmlId)).css({"display": "inline", "float": "left", "clear": "none", "width": "1000px"});
			} else {
				$j(CS.getId(level.htmlId)).css({"display": "none", "float": "left", "clear": "none", "width": "1000px", "margin-left": "-1000px"});
			}
		}
	}

	/**
	 * Generated <tr> rows for the list of items
	 */
	function generateItemsTableRows(items, parent) {
		if (!items) {
			throw "items is undefined";
		}
		for (var i = 0; i < items.length; ++i) {
			parent.append(generateItemRowHtml(graph.itemsMap[items[i]]));
		}

		return parent;
	}

	/**
	 * generate html table row for item
	 *
	 * @param item a GraphItem object
	 */
	function generateItemRowHtml(item) {
		return $j("<tr>").append($j("<td>", {
			text: item.typeLabel
		})).append(
			$j("<td>", {
				id: item.oId,
				html: $j("<span>", {
					id: "expand_" + item.oId,
					"class": "expandLink"
				}).append(
					(item.parents || item.children ? generateExpandHtml(item.oId) : null)
				)
			}).append(
				$j("<span>", {
					text: item.recName
				})
			).append($j("<div>", {
				id: "details_" + item.oId,
				style: "display:none"
			}))
		).append($j("<td>").append(item.status))
		.append(
			OptionsCellRenderer.renderCell(item, $j("<td>"))
		);
	}

	function expandAll(items) {
		allRows(items, function(id) {
			expandRow(id);
		});
	}
	this.expandAll = expandAll;

	function collapseAll(items) {
		allRows(items, function(id) {
			collapseRow(id);
		});
	}
	this.collapseAll = collapseAll;

	function allRows(items, callback) {
		for (var i = 0; i < items.length; ++i) {
			callback(items[i]);
		};
	}

	function expandRow(id) {
		// skip if id is in expanded row or in hidden table
		if ($j("#details_" + id).css('display') != 'none' || $j("#details_" + id).parents("table.list").css('display') == 'none') {
			return;
		}

		$j("#expand_" + id).html(generateCollapseHtml(id));

		var item = graph.itemsMap[id];

		var details = "";
		for (var key in item.parents) {
			var parentId = item.parents[key];
			if (!parentId) {
				continue;
			}

			var graphItem = graph.itemsMap[parentId];
            if (!graphItem) {
                console.log('GI for ' + parentId + ' is null');
                graphItem = {recName: 'Null item'};
            }
			var parent = "<li><b>" + key + "</b> - " + graphItem.recName + "</li>";
			details += parent;
		}

		if (details) {
			details = "<span style='margin-left: 30px'>Parent records:</span><br><ul style='margin-top: 0px'>" + details + "</ul>";
		}

		var rows = "";
		var children = item.children;
		if (children) {
			for (var childCollectionName in children) {
				if (children[childCollectionName].length > 0) {
					var row = "<li><a href='javascript:csOGI.descend(\"" + item.oId + "/" + childCollectionName + "\");'><b>" + childCollectionName + "</b> - " + children[childCollectionName].length + " records</a></li>";
					rows += row;
				}
			}
		}

		if (rows) {
			rows = "<span style='margin-left: 30px'>Child collections:</span><br><ul style='margin-top: 0px'>" + rows + "</ul>";
		}

		$j("#details_" + id).html(details + rows);
		$j("#details_" + id).slideToggle(ANIM_TIME);
	}
	this.expandRow = expandRow;

	function collapseRow(id) {
		// skip if id is in collapsed row or in hidden table
		if ($j("#details_" + id).css('display') == 'none' || $j("#details_" + id).parents("table.list").css('display') == 'none') {
			return;
		}

		$j("#expand_" + id).html(generateExpandHtml(id));
		$j("#details_" + id).slideToggle(ANIM_TIME);
		$j("#details_" + id).empty();
	}
	this.collapseRow = collapseRow;

	function generateExpandHtml(id) {
		return $j("<a>", {
			"class": "expand",
			text: "[+]"
		}).click(function() { csOGI.expandRow(id); });
	}

	function generateCollapseHtml(id) {
		return $j("<a>", {
			"class": "expand",
			text: "[-]"
		}).click(function() { csOGI.collapseRow(id); });
	}
}

/************************************************************************************************
 *
 * AllOptionsController class
 *
 * Client-side controller for the "All options" drop down
 *
 ************************************************************************************************/
function AllOptionsController(graph, summaryTableModel, browseStack) {
	var currentTab;

	$j(document).bind("BrowseStackPush", handleBrowseEvent);
	$j(document).bind("BrowseStackPop", handleBrowseEvent);
	$j(document).bind("RerenderBrowser", function() {
		handleTabSwitchEvent("Hierarchy");
	});
	$j(document).bind("RerenderSummary", function() {
		handleTabSwitchEvent("Summary");
	});

	function handleBrowseEvent(evt, oldTopLevel, newTopLevel) {
		var allOptions = getAllActions(newTopLevel.items);
		updateApplyToAllTool(allOptions);
	}

	function handleTabSwitchEvent(newTabName) {
		currentTab = newTabName;
		var allActions = getAllActions(getVisibleItemIds());
		updateApplyToAllTool(allActions);
	}

	function getVisibleItemIds() {
		var itemIds;
		if (currentTab === "Summary") {
			itemIds = summaryTableModel.summaryItems;
		} else {
			itemIds = browseStack.getTopLevel().items;
		}

		return itemIds;
	}

	function getAllActions(topLevel) {
		var allActions = {};
		for (var i = 0; i < topLevel.length; ++i) {
			var item = graph.itemsMap[topLevel[i]];
			if (item.options["Action"] && item.options["Action"]) {
				for (var j = 0; j < item.options["Action"].options.length; ++j) {
					var action = item.options["Action"].options[j];
					allActions[action] = true;
				}
			}
		}

		return allActions;
	}

	function updateApplyToAllTool(allActions) {
		// get the applyToAllTool element for the currently active tab
		var applyToAllTool = $j("#applyToAllTool" + currentTab);
		var select = $j("#actionsForAll" + currentTab);
		select.empty();
		var actionsCount = 0;
		for (var action in allActions) {
			select.append("<option>" + action + "</option>");
			++actionsCount;
		}

		if (actionsCount === 0) {
			applyToAllTool.css("display", "none");
		} else {
			applyToAllTool.css("display", "inline");
		}
	}

	function applyActionToAll() {
		var selectedAction = $j("#actionsForAll" + currentTab + " option:selected").val();

		var itemsIds = getVisibleItemIds();
		for (var i = 0; i < itemsIds.length; ++i) {
			var itemId = itemsIds[i];
			var item = this.graph.itemsMap[itemId];
			if ($j.inArray(selectedAction, item.options["Action"].options) >= 0) {
				item.updateOption("Action", selectedAction);
			}
		}
	}
	this.applyActionToAll = applyActionToAll;
}

/************************************************************************************************
 *
 * BreadcrumbsRenderer class
 *
 * View class - renders the breadcrumbs component
 *
 ************************************************************************************************/
function BreadcrumbsRenderer(breadcrumbsId) {
	$j(document).bind("BrowseStackPush", renderPush);
	$j(document).bind("BrowseStackPop", renderPop);
	$j(document).bind("RerenderBrowser", rerender);

	function renderPush(evt, oldTopLevel, newTopLevel) {
		var breadcrumb = "<span id='" + newTopLevel.htmlId + "_breadcrumb'><a href='javascript:csOGI.ascend(\"" + newTopLevel.htmlId + "\");'>" + newTopLevel.name + "</a>&nbsp;|&nbsp;</span>";

		$j(CS.getId(breadcrumbsId)).append(breadcrumb);
	}

	function renderPop(evt, oldTopLevel, newTopLevel) {
		$j(CS.getId(oldTopLevel.htmlId) + "_breadcrumb").remove();
	}

	function rerender(evt, browseStack) {
		var levels = browseStack.getLevels();
		var breadcrumbs = "";
		for (var i = 0; i < levels.length; ++i) {
			var level = levels[i];
			breadcrumbs += generateCrumb(level);
		}

		$j(CS.getId(breadcrumbsId)).html(breadcrumbs);
	}

	function generateCrumb(level) {
		return "<span id='" + level.htmlId + "_breadcrumb'><a href='javascript:csOGI.ascend(\"" + level.htmlId + "\");'>" + level.name + "</a>&nbsp;|&nbsp;</span>";
	}
}

/*
 * Summary table related classes
 */

/************************************************************************************************
 *
 * SummaryTableModel class
 *
 * Model class for the summary table
 *
 ************************************************************************************************/
function SummaryTableModel(graph) {
	this.summaryItems = [];
	this.graph = graph;

	for (var itemId in graph.itemsMap) {
		var item = graph.itemsMap[itemId];
		if (item.options['Action'] != null) {
			this.summaryItems.push(itemId);
		}
	}
}

/************************************************************************************************
 *
 * SummaryTableRenderer class
 *
 * View class for the summary table
 *
 ************************************************************************************************/
function SummaryTableRenderer(summaryTableModel, tableTemplateContainerId, tableTemplateId, summaryTableContainerId) {
	$j(document).bind("RerenderSummary", rerender);
	var summaryTableHtmlId = IdGenerator.nextId();

	function rerender() {
		$j(CS.getId(summaryTableContainerId)).empty();

		// copy the template table into new table, replace it's id and set rows
		var tableTemplateHtml = $j(CS.getId(tableTemplateContainerId)).html() + "";
		tableTemplateHtml = tableTemplateHtml.replace(tableTemplateId, summaryTableHtmlId);
		$j(CS.getId(summaryTableContainerId)).append(tableTemplateHtml);
		generateItemsTableRows(summaryTableModel.summaryItems, $j(CS.getId(summaryTableHtmlId) + ">tbody"));

		$j(CS.getId(summaryTableHtmlId)).css({"display": "inline", "float": "left", "clear": "none", "width": "1000px"});
	}

	/**
	 * Generated <tr> rows for the list of items
	 */
	function generateItemsTableRows(items, parent) {
		if (!items) {
			throw "items is undefined";
		}

		for (var i = 0; i < items.length; ++i) {
			parent.append(generateItemRowHtml(summaryTableModel.graph.itemsMap[items[i]]));
		}

		return parent;
	}

	/**
	 * generate html table row for item
	 *
	 * @param item a GraphItem object
	 */
	function generateItemRowHtml(item) {
		return $j("<tr>").append($j("<td>", {
			text: item.typeLabel
		})).append($j("<td>", {
			id: item.oId,
			text: item.recName
		})).append($j("<td>", {
			html: item.status,
			style: 'white-space:nowrap'
		})).append(
			OptionsCellRenderer.renderCell(item, $j("<td>"))
		);
	}
}

/************************************************************************************************
 *
 * OptionsCellRenderer class
 *
 * View class for item options
 *
 ************************************************************************************************/
function OptionsCellRenderer() {}
OptionsCellRenderer.renderCell = function (item, parent) {
	if (!parent) {
		return;
	}

	for (var i = 0; i < item.optionsRenderOrder.length; ++i) {
		var optName = item.optionsRenderOrder[i];
		parent.append(OptionsCellRenderer.renderOption(item, item.options[optName]));
	}

	return parent;
}

OptionsCellRenderer.renderOption = function (item, option) {
	switch (option.type) {
	case "checkbox":
		return renderCheckbox(item, option);
	case "select":
		return renderSelect(item, option);
	case "radio":
		return renderRadio(item, option);
	case "text":
		return renderText(item, option);
	}

	function renderCheckbox(item, option) {
		var id = item.oId;
		var checkboxId = IdGenerator.nextId();
		var input = $j("<input type='checkbox'/>").attr({
			id: checkboxId,
			name: option.htmlName,
			checked: (option.selectedOption == "true" ? "true" : null),
			"data-id": id,
			"data-label": option.label
		});
		input.change(buildOnchangeFunction(id, option.label));
		$j(document).bind("ItemOptionChanged", buildOptionChangedHandler(input, id, option.label));

		return $j("<div/>", {
			style: "white-space: nowrap"
		}).append(input).append(
			$j("<label>", {
				"for": checkboxId,
			}).append(" " + option.label)
		);
	}

	function renderSelect(item, option) {
		var id = item.oId;
		var selectId = IdGenerator.nextId();

		var select = $j("<select>", {
			id: selectId,
			name: option.htmlName,
			"data-id": id,
			"data-label": option.label
		});
		select.change(buildOnchangeFunction(id, option.label))
		$j(document).bind("ItemOptionChanged", buildOptionChangedHandler(select, id, option.label));

		for (var j = 0; j < option.options.length; ++j) {
			select.append($j("<option>", {
				value: option.options[j],
				selected: (option.options[j] == option.selectedOption ? "true" : null),
				text: option.options[j]
			}));
		}

		return $j("<div>", {
			style: 'white-space: nowrap'
		}).append($j("<label>", {
			"for": selectId,
			text: option.label + ": "
		})).append(select);
	}

	function renderRadio(item, option) {
		var id = item.oId;

		var radiosDiv = $j("<div>", {
			text: option.label + ":"
		});
		for (var j = 0; j < option.options.length; ++j) {
			var radioId = IdGenerator.nextId();
			var input = $j("<input type='radio'>").attr({
				id: radioId,
				name: option.htmlName,
				value: option.options[j],
				checked: (option.options[j] == option.selectedOption ? "true" : null),
				"data-id": id,
				"data-label": option.label
			});
			input.change(buildOnchangeFunction(id, option.label));
			$j(document).bind("ItemOptionChanged", buildOptionChangedHandlerForRadioButtons(input, id, option.label));

			radiosDiv.append(
				$j("<div>", {
					style: 'white-space: nowrap'
				}).append(input).append($j("<label>", {
					"for": radioId,
					text: " " + option.options[j]
				}))
			);
		}

		return radiosDiv;
	}

	function renderText(item, option) {
		var id = item.oId;
		var textId = IdGenerator.nextId();

		var input = $j("<input type='text'>").attr({
			id: textId,
			name: option.htmlName,
			value: option.selectedOption,
			"data-id": id,
			"data-label": option.label
		});
		input.change(buildOnchangeFunction(id, option.label));
		$j(document).bind("ItemOptionChanged", buildOptionChangedHandler(input, id, option.label));

		return $j("<div>", {
			style: 'white-space: nowrap'
		}).append($j("<label>", {
			"for": textId,
			text: option.label + ": "
		})).append(input);
	}

	function buildOnchangeFunction(id, label) {
		return function(event) {
			var src = event.srcElement ? event.srcElement : event.target;
			// the event originated from the user changing the UI element, so create the event and fire
			var value;
			if (src.type == "checkbox") {
				value = String(src.checked);
			} else {
				value = src.value;
			}
			$j(document).trigger("ItemOptionChanged", [id, src, label, value]);
		}
	}

	function buildOptionChangedHandler(input, id, label) {
		return function(event, itemId, source, optionName, newValue) {
			// if this component is the intended target...
			if (itemId === id && optionName === label) {
				// ...update the UI and do nothing else
				input.val(newValue);
			}
		}
	}

	function buildOptionChangedHandlerForRadioButtons(input, id, label) {
		return function(event, itemId, source, optionName, newValue) {
			// if this component is the intended target...
			if (itemId === id && optionName === label) {
				// check the option that is equal to the new value
				if (input.val() === newValue) {
					input.attr("checked", "checked");
				} else {
					input.removeAttr("checked");
				}
			}
		}
	}

	function escapeQuotes(str) {
		return str == null ? null : str.replace("\"", "\\\"");
	}
}