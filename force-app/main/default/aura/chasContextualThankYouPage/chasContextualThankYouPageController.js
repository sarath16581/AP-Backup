/**
 *
 * History :
 * --------------------------------------------------
 * 2021-03-12 Hara Sahoo - Created
 * 2021-05-12 Phap Mai - DDS-5820: Move the next steps configuration into metadata
 * 
**/
({
    onInit: function(component, event, helper) {
        // check if it is coming from a transfer to PO flow
        var mailProductsEnquiryType = component.get("v.wizardData.mailProductsEnquiryType");
        if(!$A.util.isEmpty(mailProductsEnquiryType)){
			//Snigdha:Change for INC2297209	
			if(mailProductsEnquiryType == 'Transfer to another post office')
			{
				component.set("v.header","We've got your transfer request");
			}
		}
                
        // fetch the EDD dates
        var eddFromDate = component.get("v.wizardData.deliveredByDateFrom");
        var eddToDate = component.get("v.wizardData.deliveredByDateTo");
        var edd = component.get("v.wizardData.deliveredByDateOrEDD");
        var eddPlusBusinessDays = component.get("v.wizardData.deliveredByDatePlusBusinessDays");
        var eddMonitorDateUntil = component.get("v.wizardData.deliveredByDateToUntil");// contact center will monitor the tracking until this date and communicate to the customer accordingly
        //check for delivered scan
        var hasDeliveredScan = component.get("v.wizardData.latestDeliveredScanWcid");
        
        if($A.util.isEmpty(hasDeliveredScan))
            {
            // format the EDD dates
            if(!$A.util.isEmpty(eddFromDate))
            {
                component.set("v.timeFrom",helper.convertDateToLocaleString(component,new Date(eddFromDate)).substring(0,6));
            }
            if(!$A.util.isEmpty(eddToDate))
            {
                component.set("v.timeTo",helper.convertDateToLocaleString(component,new Date(eddToDate)));
            }
            if(!$A.util.isEmpty(edd))
            {
                component.set("v.edd",helper.convertDateToLocaleString(component,new Date(edd)));
            }
            
            if(component.get("v.wizardData.isEnquiryDateWithinEDDPlusBusinessdays") || component.get("v.wizardData.isEnquiryDateWithinEDD"))
            {
                component.set("v.isWithinEDDPlusBusinessDays",true);
                component.set("v.hasTimeframe",true);
                // set the monitor until date 
                if(!$A.util.isEmpty(eddMonitorDateUntil))
                {
                    component.set("v.timeframeEDD",helper.convertDateToLocaleString(component,new Date(eddMonitorDateUntil))); 
                } else if(!$A.util.isEmpty(eddPlusBusinessDays))
                {
                    component.set("v.timeframeEDD",helper.convertDateToLocaleString(component,new Date(eddPlusBusinessDays))); 
                    
                }
            }
            // for default scenarios like non edd, medication, no delivery scans etc
            else if(component.get("v.wizardData.isEnquiryDatePastEDDPlusBusinessdays"))
            {
                component.set("v.isPastEDDPlusBusinessDays",true);
            } else
            {
            component.set("v.isDefault", true);
            }
        }


        
        if(component.get('v.analyticsTriggerEvent')) {
            // identify whether the case created is new or there's an existing enquiry
            var duplicateCaseText = 'new';
            var variationId = '';
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
        
        // DDS-5820: retrieve next steps configuration from metadata
        helper.retrieveNextStepsConfigurations(component);
    }
})