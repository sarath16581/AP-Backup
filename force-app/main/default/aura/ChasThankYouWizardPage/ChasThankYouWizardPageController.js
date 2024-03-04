({
	onInit: function(component, event, helper) {
        
        // check if it is coming from a transfer to PO flow
        var mailProductsEnquiryType = component.get("v.wizardData.mailProductsEnquiryType");
        if(!$A.util.isEmpty(mailProductsEnquiryType))
        {
           component.set("v.header","We've got your transfer request");
        }

	    if(component.get('v.analyticsTriggerEvent')) {
            // identify whether the case created is new or there's an existing enquiry
	        var duplicateCaseText = 'new';
            if(component.get('v.wizardData.duplicateCase') != '') {
                duplicateCaseText = 'duplicate';
            }
            
            var analyticsObject = {
                form: {
                    name: 'form:' + component.get('v.pageTitle'),
                    step: component.get('v.currentStepName'),
                    stage: component.get('v.stage'),
                    product: component.get('v.wizardData.trackingId'),
                    referenceId: component.get('v.wizardData.caseNumber'),
                    detail: 'article status='+component.get('v.wizardData.trackStatusValue')+'|case='+duplicateCaseText ,
                }
            };
            analyticsObject = helper.buildAdditionalAttributes(analyticsObject, component.get('v.analyticsAdditionalAttributes'), component);

            window.AP_ANALYTICS_HELPER.trackByObject({
                trackingType: 'helpsupport-form-navigate',
                componentAttributes: analyticsObject
            });

        }
        

	}
})