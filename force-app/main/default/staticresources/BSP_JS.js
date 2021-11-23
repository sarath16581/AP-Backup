
	
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

function JsCloseCase()
{
    VfCloseCase();
}

    function JS_DisplayAttachmentButtonED()
    {
        // call server function to rerender page section (EnquiryDetail, Attachment button)
        SF_DisplayAttachmentButtonED();
    }