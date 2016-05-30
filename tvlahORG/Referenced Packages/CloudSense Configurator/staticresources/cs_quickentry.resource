// QuickEntry.js
CS.namespace('qe');

(function() {
	var $ = jQuery.noConflict();
	
	var QUICK_ENTRY_ID_PREFIX = '#Quick_Entry__';
	var STRING = 'string';
	
	this.QuickEntry = function QuickEntry(attrName) {
		if (!(this instanceof QuickEntry)) return new QuickEntry(attrName);
		
		var	prodDefName = CS.getAttributeFieldValue(attrName, 'Product_Definition'),
			prodDef = CS.products[prodDefName];
		
		if (prodDef == undefined) {
			throw {
				name: 'QuickEntryError',
				message: 'Could not find product for QuickEntry (attr: ' + attributeName + '): ' + prodDefName
			}
		}
		
		var table = $(QUICK_ENTRY_ID_PREFIX + attrName);
		var attrDefs = prodDef.attributeDefinitions;
		
		var headerRow = $('<tr>').append($('<th>'));
		var rowBuilder = new RowBuilder();

		for (var attr in attrDefs) {
			if (attrDefs.hasOwnProperty(attr)) {
				headerRow.append($('<th>').addClass('headerRow').text(attr));
				rowBuilder.addColumn(attr, attrDefs[attr]);
			}
		}
		
		table.prepend($('<thead>').addClass('rich-table-head').append(headerRow));
		
		var row = rowBuilder.build(attrName, 0);
		CS.log(row);
		table.append(row);
		
	}
	
	function RowBuilder() {
		if (!(this instanceof RowBuilder)) return new RowBuilder();

		var ControlFactory = new (function () {
			var controls = {
				'user input': '<input type="text" id="${attrRef}" /' + '>'
			}

			this.getInstance = function(type, params) {
				if (!(typeof type === STRING)) return '<span>[unrecognised]</span>';
				
				var control = controls[type.toLowerCase()];
				if (control === undefined) return '<span>[not supported]</span>';
				
				for (var param in params) {
					if (params.hasOwnProperty(param)) {
						var pattern = '\\$\\{' + param + '\\}';
						var re = new RegExp(pattern);
						control = control.replace(re, params[param]);
					}
				}
				
				return control;
			}
		})();
				
		var cols = [];
		
		
		this.addColumn = function(name, def) {
			def.name = name;
			cols[cols.length] = def;
		}
		
		this.build = function(ref, idx) {
			ref += '|' + idx;
			var row = $('<tr>').attr('id', ref);
			row.append($('<td>').append($('<span><a href="#">edit</a> | <a href="#">del</a></span>')));

			for (var i = 0, max = cols.length; i < max; i++) {
				row.append($('<td>').append(buildAttributeControl(ref, cols[i], idx)));
			}

			return row;
		}
		
		function buildAttributeControl(ref, def, idx) {
			
			var attrRef = extendReference(ref, def.name, idx);
			
			var control = ControlFactory.getInstance(def.type, {attrRef: attrRef});
			return $(control);
		}
		
		function extendReference(ref, name, idx) {
			name = name.replace(/[\s\|]/g, '_').replace(/'"/g, '');
			return ref + ':' + name + '|' + idx;
		}
	}
	
}).call(CS.qe);
