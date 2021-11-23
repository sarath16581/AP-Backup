	$(document).ready(function() {
		var isDatePicker = false; 

		//setting up jqueryui date picker
	    $(".bw-input-field.date")
	        .datepicker({
				dateFormat: 'd/mm/yy',
				onSelect: function() { 
					$(".ui-datepicker a").removeAttr("href");
					$('#ui-datepicker-div').hide();
				}
			})
	        .mousedown(function() {
	        	isDatePicker = true;
	           	$('#ui-datepicker-div')
	        		.show()
	        		.mouseover(function() {
	        			isDatePicker = true;
	        		})
	        		.mouseout(function() {
	        			isDatePicker = false;
	        		})
	        		.mousedown(function() {
	        			$("input.date").change(function() {
	        				$('#ui-datepicker-div').hide();
	        			});
	        		});
	        	})
	        .mouseout(function() {
	        	isDatePicker = false; 
	        });
	
		// Datepicker handling
		$(document).mousedown(function() {			        
			if (!isDatePicker) {
				$('#ui-datepicker-div').hide();
			}
		});
	});
	
    function isNumericKey(evt)
    {
        var charCode = (evt.which) ? evt.which : event.keyCode
        if (charCode > 31 && (charCode < 48 || charCode > 57))
            return false;

        return true;
    }  
        
	var isAlreadyShown = false;
	function JS_ShowAttachment()
	{
		// VF will throw error the second time this icon is clicked, so use JS to prevent it
		if(!isAlreadyShown)
		{
			// call SF server side function
			SF_ShowAttachment();
			isAlreadyShown = true;
		}
	}

