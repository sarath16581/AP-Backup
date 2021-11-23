({
	doInit : function(component, event, helper) {
		var urlParamStr = component.get('v.ETAInputs');
        if(urlParamStr == undefined || urlParamStr=='' ) {
        	urlParamStr = decodeURIComponent(window.location.search.substring(1));
        	}
        urlParamStr += '&';
        console.log('URL Param Str--'+urlParamStr);
		var urlParams = urlParamStr.split('&');
        var etaID='';
        var etaParam1='';
        var allowedChars=/^[0-9a-zA-Z=]+$/;
        var isValid=true;
		// Check the input values. Invoke the Callout only if parameters have valid chars
        for(var i=0;i<=1;i++){
                var params = urlParams[i].split('=');
        		if('id' === (params[0]).toLowerCase()) {
                    if(params[1] != '' && (params[1]).match(allowedChars)) etaID=urlParams[i].substr(3)
                    else isValid=false;
        			}
            	else if('param1' === (params[0]).toLowerCase()){
                    if(params[1] != '' && (params[1]).match(allowedChars)) etaParam1=params[1]
                    else isValid=false;
                	}
            	}                
            if(etaID != '' && isValid){
				console.log('Getting data for ETAID-param1-'+etaID+'-'+etaParam1);                
                helper.getRecvETA(component,etaID,etaParam1);
            }
	}
})