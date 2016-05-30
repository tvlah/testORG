#processing_overlay
{
	position: absolute;
	//zIndex: 99998;
	z-Index: 100;
	top: 0px;
	left: 0px;
	width: 100%;
	height: auto;
	//background-color:#cccccc;
	background-color:#000000;
	filter:progid:DXImageTransform.Microsoft.Alpha(opacity=50);
	opacity:0.7;
	//cursor:wait;
	cursor:default;
}						
#processing_container 
{
    font:bold 10px verdana;
	min-width: 800px; /* Dialog will be no smaller than this */
	max-width: 800px; /* Dialog will wrap after this width */
	height: 580px; 
	background: #ddd;
	border: solid 1px #00303f;
	color: #00303f;
}

#overlayIframe 
{
    font:bold 10px verdana;
	min-width: 750px; /* Dialog will be no smaller than this */
	max-width: 750px; /* Dialog will wrap after this width */
	height: 550px; 
	background: #ddd;
	border: solid 0px #00303f;
	color: #00303f;
}

#processing_title {
	font-size: 14px;
	font-weight: bold;
	text-align: center;
	line-height: 1.75em;
	background-color:#669900;
	color: #FFF;
	/*border: solid 1px #FFF;*/
	border-bottom: solid 1px #999;
	cursor: default;
	padding: 0em;
	margin: 0em;
}

#processing_content {
	text-align: center;
	padding: 1em 1.75em;
	margin: 0em;
	vertical-align:middle;
}
