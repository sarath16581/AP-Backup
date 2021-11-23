/*****************************************************************************************
@description:   Javascript helper for the controller of the Lodgement Point Search Aura Component
                Make Calls to Apex Controller on Click of Save, to perform Update DML on the DSR record
@author: Seth Heang
History:
-----------------------------------------------------------------------------------------
15/03/2021   	seth.heang@auspost.com.au			                created
*****************************************************************************************/
({
    /**
     * @description Call Apex controller's method to perform update DML on the list of selected lodgement points
     *              And save the updated lodgement point and work centre code mapping back to DSR record
     *              Refresh the Salesforce's page view after successful update
     *  */ 
	updateLodgementPoints: function(cmp) {
        var dsrID = cmp.get('v.recordId');
        var action = cmp.get('c.addMultiLodgementPointsWCC');
        // convert the selected record list into a JSON format and send to the Apex Controller       
        action.setParams({ "dsrId" :dsrID,
                          "lodgementPointWCCs" : JSON.stringify(cmp.get("v.selectedRecords")),
                         });
        action.setCallback(this, function(response) {
            // declare toast event for display success/error message banner on salesforce page
            var toastEvent = $A.get("e.force:showToast");

            if (response.getState() === "SUCCESS") {
                //refresh detail section of Lightning page
                $A.get('e.force:refreshView').fire(); 

                
                toastEvent.setParams({
                    "type":"success",
                    "title": "Success!",
                    "message": "The Lodgement Points have been updated successfully."
                });
                toastEvent.fire();
            }
            // error state, display error message banner on salesforce page
            else if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        toastEvent.setParams({
                            "type":"error",
                            "title": "ERROR",
                            "message": "Encounters error while saving the lodgement point records!"
                        });
                        toastEvent.fire();
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }
})