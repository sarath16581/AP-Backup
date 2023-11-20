({
	onRender: function(cmp, event, helper) {
		document.dispatchEvent(new CustomEvent("grecaptchaRender", { "detail" : { element: 'recaptchaCheckbox'} }));		
	},

	onInit: function(cmp, event, helper) {
		
		document.addEventListener("grecaptchaVerified", $A.getCallback(function(e) {
			var cmpEvent = cmp.getEvent("captchaEvent");
			cmpEvent.setParams({"token" : e.detail.response });
        	cmpEvent.fire();
        }));
        
        document.addEventListener("grecaptchaExpired", $A.getCallback(function() {
            var cmpEvent = cmp.getEvent("captchaEvent");
			cmpEvent.setParams({"token" : "" });
        	cmpEvent.fire();
        })); 
	}

})
