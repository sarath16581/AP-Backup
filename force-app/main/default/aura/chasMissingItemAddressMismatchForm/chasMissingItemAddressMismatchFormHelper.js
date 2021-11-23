({

    pushAnalytics : function(cmp, step) {
        // we expect something to be returned here, if nothing returned means a technical issue
        if(cmp.get('v.wizardData.eddStatus') != '') {
            var duplicateCaseText = 'new';
            if(cmp.get('v.wizardData.duplicateCase') != '') {
                duplicateCaseText = 'duplicate';
            }
            
            var isEligibleForMyNetworkAssignment = cmp.get('v.wizardData.isEligibleForMyNetworkAssignment') ? 'yes' : 'no';
            
            // building the analytics params object
            var analyticsObject = {
                form: {
                    name: 'form:' + cmp.get('v.pageTitle'),
                    step: step,
                    stage: '',
                    detail: 'article status='+cmp.get('v.wizardData.trackStatusValue')+'|case='+duplicateCaseText + '|network eligibility='+isEligibleForMyNetworkAssignment,
                    product: cmp.get('v.wizardData.trackingId')
                }
            };
            
            // calling the analytics API methods
            window.AP_ANALYTICS_HELPER.trackByObject({
                trackingType: 'helpsupport-form-navigate',
                componentAttributes: analyticsObject
            });
            
        } else {
            console.log("ERROR : Status didn't receive!");
        }
    },
})