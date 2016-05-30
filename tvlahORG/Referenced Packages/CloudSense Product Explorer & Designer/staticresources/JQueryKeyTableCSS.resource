/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * DataTables features
 */

.dataTables_wrapper {
	position: relative;
	min-height: 302px;
	_height: 302px;
	clear: both;
}

.dataTables_processing {
	position: absolute;
	top: 0px;
	left: 50%;
	width: 250px;
	margin-left: -125px;
	border: 1px solid #ddd;
	text-align: center;
	color: #999;
	font-size: 11px;
	padding: 2px 0;
}

.dataTables_length {
	width: 40%;
	float: left;
}

.dataTables_filter {
	width: 50%;
	float: right;
	text-align: right;
}

.dataTables_info {
	width: 60%;
	float: left;
}

.dataTables_paginate {
	width: 44px;
	* width: 50px;
	float: right;
	text-align: right;
}

/* Pagination nested */
.paginate_disabled_previous, .paginate_enabled_previous, .paginate_disabled_next, .paginate_enabled_next {
	height: 19px;
	width: 19px;
	margin-left: 3px;
	float: left;
}

.paginate_disabled_previous {
	background-image: url('../images/back_disabled.jpg');
}

.paginate_enabled_previous {
	background-image: url('../images/back_enabled.jpg');
}

.paginate_disabled_next {
	background-image: url('../images/forward_disabled.jpg');
}

.paginate_enabled_next {
	background-image: url('../images/forward_enabled.jpg');
}



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * DataTables display
 */
table.display {
	margin: 0 auto;
	width: 100%;
	clear: both;
	border-spacing: 0px;
}

table.display thead th {
	padding: 0px 0px;
	border-bottom: 1px solid black;
	border-spacing: 0px;
	font-weight: bold;
	cursor: pointer;
	* cursor: hand;
}

table.display tfoot th {
	padding: 0px 0px;
	border-top: 1px solid black;
	font-weight: bold;
}

table.display tr.heading2 td {
	border-bottom: 1px solid #aaa;
}

table.display td {
	padding: 0px 0px;
}

table.display td.center {
	text-align: center;
}



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * DataTables sorting
 */

.sorting_asc {
	background: url('../images/sort_asc.jpg') no-repeat center right;
}

.sorting_desc {
	background: url('../images/sort_desc.jpg') no-repeat center right;
}

.sorting {
	background: url('../images/sort_both.jpg') no-repeat center right;
}



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Row striping
 */
table.display tr.odd_gradeA {
	background-color: #ddffdd;
}

table.display tr.even_gradeA {
	background-color: #eeffee;
}

table.display tr.odd_gradeC {
	background-color: #ddddff;
}

table.display tr.even_gradeC {
	background-color: #eeeeff;
}

table.display tr.odd_gradeX {
	background-color: #ffdddd;
}

table.display tr.even_gradeX {
	background-color: #ffeeee;
}

table.display tr.odd_gradeU {
	background-color: #ddd;
}

table.display tr.even_gradeU {
	background-color: #eee;
}


table.KeyTable td.focus {
	border: 1px solid #3366FF;
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Cell borders
 */
/*
 * Good old IE - not doing transparent borders
 */
table.display td {
	border: 0px solid transparent;
}

tr.odd_gradeA td {
	border: 0px solid #ddffdd;
}

tr.odd_gradeA td {
	border: 0px solid #ddffdd;
}

tr.even_gradeA td {
	border: 0px solid #eeffee;
}

tr.odd_gradeC td {
	border: 0px solid #ddddff;
}

tr.even_gradeC td {
	border: 0px solid #eeeeff;
}

tr.odd_gradeX td {
	border: 0px solid #ffdddd;
}

tr.even_gradeX td {
	border: 0px solid #ffeeee;
}

tr.odd_gradeU td {
	border: 0px solid #ddd;
}

tr.even_gradeU td {
	border: 0px solid #eee;
}




/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Misc
 */
div.box {
	height: 100px;
	padding: 10px;
	overflow: auto;
	border: 1px solid #8080FF;
	background-color: #E5E5FF;
}
