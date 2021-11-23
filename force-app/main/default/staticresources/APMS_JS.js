

    function changeValueSelectedPricePlan(input, textid) {
        document.getElementById(textid).value = input.value;
        // need to force a rerender, so the variable is stored to server side
        reRenderDummy();
    }

    function isNumericKey(evt)
    {
        var charCode = (evt.which) ? evt.which : event.keyCode
        if (charCode > 31 && (charCode < 48 || charCode > 57))
            return false;

        return true;
    }  
        
    function changeValueExistingAccount(input, textid) {
        document.getElementById(textid).value = input.value;
        vfRefresh();
    }

    function updateSelectedPlanToServer() {
        // need to force a rerender, so the variable is stored to server side
        reRenderDummy2();
    }

    function CallJSPrevious() {
        callSFPrevious();
    }

	function selectTick(el){
		// this function would tick the Yes / No radio for ExistingAccount Yes/No question on landing page
		document.getElementById(el).checked = true;
		document.getElementById(el).click();
	}

    function accessEmailField(fieldID)
    {
        // this function makes the targeted email address disabled or enabled
        if(document.getElementById(fieldID).disabled==true)
        {        
            document.getElementById(fieldID).disabled=false;
        }
        else
        {        
            // if the field is rendered, then set it to blank, otherwise validation on incorrect email format will be fired.
            document.getElementById(fieldID).value = '';
            document.getElementById(fieldID).disabled=true;
        } 
    }

    function accessEmailField2(fieldID)
    {
        // this function makes the targeted email address disabled or enabled, and also reset CSS class.
        if(document.getElementById(fieldID).disabled==true)
        {        
            document.getElementById(fieldID).disabled=false;
            document.getElementById(fieldID).className='email-textbox';
        }
        else
        {        
            // if the field is rendered, then set it to blank, otherwise validation on incorrect email format will be fired.
            document.getElementById(fieldID).value = '';
            document.getElementById(fieldID).className='';
            document.getElementById(fieldID).disabled=true;
        } 
    }
    
    function SubmitOnClick (objSubmitBtn) 
    {
        objSubmitBtn.value = 'Processing...';
        objSubmitBtn.disabled = true;

        // also disable the Previous button
        document.getElementById('prevButton').value = 'Processing...';
        document.getElementById('prevButton').disabled=true;
                
        Submit();
    }
