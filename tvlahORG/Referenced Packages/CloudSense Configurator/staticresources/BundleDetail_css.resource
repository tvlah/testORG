/**
Bundle Detail Page CSS Additions
*/
.hiddenQtyContainer {
	visibility: hidden;
	display: none;
}

.visibleQtyContainer {
	position: absolute;
	left: 0px;
	top: 0px;
	width: 100%;
	height: 100%;
	float: left;
	visibility: visible;
	display: block;
	z-index: 9999;
}

.hiddenQtyBox {
	visibility: hidden;
	display: none;
}

.visibleQtyBox {
	position: relative;
	left: 300px;
	top: 300px;
	float: left;
	visibility: visible;
	display: block;
	border: 1px #fff solid;
	opacity: 1;
	-moz-opacity: 1;
	z-index: 99999;
}

body .pbBody table.list.bundleDetail tr td,
body .pbBody table.list.bundleDetail tr th {
	border: none;
	font: 95%/1.3 sans-serif;
	padding: 6px 8px 2px 0;
}

body .pbBody table.bundleDetail tr td.detailCellNumber {
	border-top: 1px #eee solid;
	text-align: right;
}

body .pbBody table.bundleDetail tr td.detailCellText {
	border-top: 1px #eee solid;
	text-align: left;
}

body .pbBody table.bundleDetail tr.header td {
	border-top: 1px #eee solid;
	padding-bottom: 12px;
}

body .pbBody table.bundleDetail tr td.controls a {
	font-weight: bold;
	padding-left: 4px;
}

body .pbBody table.bundleDetail tr th.headingCellNumber {
	font-weight: bold;
	text-align: right;
}

body .pbBody table.bundleDetail tr th.headingCellText {
	font-weight: bold;
	text-align: left;
}

body .pbBody table.bundleDetail tr th.headingCellTextCentered {
	font-weight: bold;
	text-align: center;
}

body .pbBody table.bundleDetail tr th.headingCellTextCentered.leftBorder,
body .pbBody table.bundleDetail tr th.headingCellNumber.leftBorder {
	border-left: 1px solid #E0E3E5;
}

body .pbBody table.bundleDetail tr th.headingCellTextCentered.rightBorder,
body .pbBody table.bundleDetail tr th.headingCellNumber.rightBorder {
	border-right: 1px solid #E0E3E5;
}

body .pbBody table.bundleDetail tr th.headingCellTextCentered.bottomBorder {
	border-bottom: 1px solid #E0E3E5;
}

body .pbBody table.bundleDetail tr td.totalCellNumber {
	font-weight: bold;
	text-align: right;
}

body .pbBody table.bundleDetail tr td.totalCellText {
	font-weight: bold;
	text-align: left;
}

body .pbBody table.bundleDetail tr td.totalright {
	font-weight: bold;
	text-align: right;
}

body .pbBody table.bundleDetail tr td.spacer {
	width: 80px;
	line-height: 4px;
}

table.bundleDetail tr td.spacerheight {
	width: 80px;
	line-height: 4px;
	padding: 2px 0;
}

body .pbBody table.bundleDetail tr.subtotals td.totalCellText,
body .pbBody table.bundleDetail tr.subtotals td.totalCellNumber {
	border-top: 1px #ccc solid;
}

body .pbBody table.bundleDetail tr.grandtotal td.totalCellText,
body .pbBody table.bundleDetail tr.grandtotal td.totalCellNumber {
	border-top: 2px #666 solid;
}
