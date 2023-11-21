/**
 * @description
 * Renders a captcha for some H&S forms
 * Requires the use of <script src='https://www.google.com/recaptcha/enterprise.js?render=explicit&onload=onloadCallback' async defer></script> and some EVENTS which is loaded in the HEAD markup of the community
 * 
 * @author Nathan Franklin
 * @date 2023-11-20
 * 
 * @changelog
 */
({
	onRender: function(cmp, event, helper) {
		document.dispatchEvent(new CustomEvent("grecaptchaRender", { "detail" : { element: 'recaptchaCheckbox'} }));
	},

	reset: function(cmp, event, helper) {
		document.dispatchEvent(new CustomEvent("grecaptchaReset"));
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
