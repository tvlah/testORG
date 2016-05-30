/**
Configuration Page CSS Additions
*/
		.message {
			display: none;
		}
		.message.visible {
			display: block;
		}

		#popupOverlay {
			display: none;
			position: absolute;
			left: 0;
			padding-top: 100px;
			right: 0;
			top: 0;
			bottom: 0;
		}

		#popupOverlay div {
			border: 2px #000 solid;
			height: 480px;
			margin: 0 auto;
			width: 800px;
		}

		.lookupInput img.deleteIcon, .lookupInput div.deleteIcon {
			background-position: 0 -16px;
			height: 16px;
			width: 16px;
			margin: 2px 2px 0 3px;
			position: relative;
			float: left;
			cursor: pointer;
		}

		.lookupInput img.deleteIcon:hover, .lookupInput div.deleteIcon:hover {
			background-position: 0 -32px;
		}

		h2.mainTitle span.readOnly {
			font-size: 0.8em;
			margin-left: 10px;
		}
		h2.mainTitle span.required {
			font-size: 0.8em;
			margin-left: 10px;
			color: red;
		}

		/* Validation styles */
		td.labelCol.attrLabel {
			padding-right: 0;
		}
		td.labelCol.attrLabel label {
			border-right: 3px solid transparent;
			padding: 3px 3px 3px 0;
			display: inline-block;
		}
		td.labelCol.attrLabel label.requiredOn { border-right: 3px solid #C00; }

		td.attributeError input[type="text"],
		td.attributeError select,
		td.attributeError textarea,
		td.attributeError div { border: 1px solid #C00; }

		p.attributeErrorMessage {
			margin: 0;
			margin-top: 3px;
			color: #C00;
		}
