({
    doRefreshRevenue: function(component, event, helper) {
        try {
            var opportunityId = component.get("v.recordId");
            console.log('Calling RefreshRevenue with opportunityId:', opportunityId);
            
            if (!opportunityId) {
                console.error('Record ID is not set.');
                throw new Error('Record ID is not set.');
            }
            
            var action = component.get("c.RefreshRevenue");
            action.setParams({ opportunityId: opportunityId });

            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    // handle successful refresh, show a toast message
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "Revenue refreshed successfully.",
                        "type": "success"
                    });
                    toastEvent.fire();
                    
                    // Call the reloadData method of the LWC
                    var lwcCmp = component.find("opportunityRevenueReportComponent");
                    if (lwcCmp) {
                        lwcCmp.reloadData(); // Invoke the LWC method
                    } else {
                        console.error('Could not find the LWC component');
                        throw new Error('Could not find the LWC component.');
                    }
                } else {
                    // handle error
                    var errors = response.getError();
                    var message = 'Unknown error'; // default error message
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        message = errors[0].message;
                    }
                    throw new Error(message);
                }
            });

            $A.enqueueAction(action);

        } catch (error) {
            // Catch any errors and display them in a toast message
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "message": error.message,
                "type": "error"
            });
            toastEvent.fire();
        }
    }
});