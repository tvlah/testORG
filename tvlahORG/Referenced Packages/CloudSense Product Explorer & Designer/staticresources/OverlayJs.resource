
      		
      		function showProgress(displayText,displayImage) {
      			hideProgress();
		        jQuery("BODY").append('<div id="processing_overlay"></div>');
		            jQuery("BODY").append(
				      '<div id="processing_container">' +
				        //'<div id="processing_title">This is title</div>' +
				        '<div id="processing_content">' +
		    		            '<img src="'+displayImage+'" style="width:100px;" alt=""/>' +
				                '<br/><br/>'+displayText+
					    '</div>' +
				      '</div>');
				 
				//var pos = (jQuery.browser.msie && parseInt(jQuery.browser.version) <= 6 ) ? 'absolute' : 'fixed';
				var pos = 'fixed'; 
				
				jQuery("#processing_container").css({
					position: pos,
					zIndex: 99999,
					padding: 0,
					margin: 0
				});
				
				jQuery("#processing_container").css({
					minWidth: jQuery("#processing_container").outerWidth(),
					maxWidth: jQuery("#processing_container").outerWidth()
				});
				  
				var top = ((jQuery(window).height() / 2) - (jQuery("#processing_container").outerHeight() / 2)) + (-75);
				var left = ((jQuery(window).width() / 2) - (jQuery("#processing_container").outerWidth() / 2)) + 0;
				if( top < 0 ) top = 0;
				if( left < 0 ) left = 0;
				
				// IE6 fix
				//if( jQuery.browser.msie && parseInt(jQuery.browser.version) <= 6 ) top = top + jQuery(window).scrollTop();
				
				jQuery("#processing_container").css({
					top: top + 'px',
					left: left + 'px'
				});
				jQuery("#processing_overlay").height( jQuery(document).height() );
		    }
      		
      		function hideProgress() {
	      		jQuery("#processing_container").remove();
		        jQuery("#processing_overlay").remove();
		    }