({
	// Not required with force:recordData

    // fetchCaseStatus: function(cmp, event, helper) {
    //     var action = cmp.get("c.getCaseStatus");
        
    //     action.setParams({ "caseId" : cmp.get("v.recordId") });
    //     action.setCallback(this, function(response) {
    //         var state = response.getState();
    //         if (state === "SUCCESS") {
    //             console.log('(response.getReturnValue()=='+response.getReturnValue());
    //             if(response.getReturnValue() != null){
    //                 cmp.set('v.caseStatus',response.getReturnValue());
    //             }
    //         } else if (state === "INCOMPLETE") {
    //         } else if (state === "ERROR") {
    //             var errors = response.getError();
    //             if (errors) {
    //                 if (errors[0] && errors[0].message) {
    //                     console.log("Error message: " + errors[0].message);
    //                 }
    //             } else {
    //                 console.log("Unknown error");
    //             }
    //         }
    //     });
    //     $A.enqueueAction(action);
    // },

    fetchCaseComments : function(cmp) {
        var action = cmp.get("c.fetchCaseComments");
        
        action.setParams({ "caseId" : cmp.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() != null){
                    cmp.set('v.caseComments',response.getReturnValue());
                }
            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    createNewCaseComment : function(cmp, helper) {
    	cmp.set('v.isSendingComment', true);
    	cmp.find('submitButton').set('v.label', "");

        var action = cmp.get("c.creatCaseComment");
        action.setParams({ "caseId" : cmp.get("v.recordId"),
                          "caseCommentBody" : cmp.get("v.textAreaValue")});
        action.setCallback(this, function(response) {
    		cmp.set('v.isSendingComment', false);
    		cmp.find('submitButton').set('v.label', "Submit");

            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() != null){
                    var caseComments = cmp.get('v.caseComments');
                    caseComments.unshift(response.getReturnValue());
                    cmp.set('v.caseComments', caseComments);
                    var caseStatus = cmp.get('v.case.Enquiry_Status__c');
                    if (caseStatus === "Resolved" || caseStatus === "Action required") {
                        this.updateCaseStatus(cmp, "Customer Responded");
                    }
                    //-- hide new Div
                    cmp.set('v.showInput',false);
                    cmp.set('v.textAreaValue', "");

                    // push a new analytics event to show a new commend was created
                    helper.pushAnalyticsEvent(cmp, 'case', 'comment:submitted');
                }
            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    setLoggedInUserName : function(cmp) {
        var action = cmp.get("c.getCurrentUserName");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() != null){
                    cmp.set('v.loggedInUserName', response.getReturnValue());
                }
            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
            
        });
        
        $A.enqueueAction(action);
    },
    
    updateCaseStatus : function(cmp, newStatus, callback, helper) {
        var vcase = cmp.get('v.case');
        vcase.Status = newStatus; 
        if(newStatus === "Closed"){
            vcase.Permanent_Close__c = true;   // added by Jansi
            vcase.ResolutionCode__c = 'Customer - Self service'; // added by Jansi
        }
        cmp.set('v.case', vcase);
        cmp.set('v.isLoadingStatus', true);
		console.log('vcase:::JSON-------caseRecordData----');
		console.log(JSON.stringify(vcase));
		console.log(cmp.find('caseRecordData').get('v.recordId'));
		//console.log(cmp.find('caseRecordData').getAll);
        cmp.find('caseRecordData').saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                console.log("Save completed successfully.");
                cmp.find('caseRecordData').reloadRecord();
                cmp.getEvent("updateCaseStatus").fire();

                if(newStatus === "Closed") {
                    // analytics track after a case has been successfully closed
                    helper.pushAnalyticsEvent(cmp, 'case', 'closed');
                }

            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: ' + 
                            JSON.stringify(saveResult.error));
							console.log(JSON.stringify(saveResult));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
            if (callback) callback();
        }));
    },

    validateNewComment:  function(cmp) {
        var isValid = false;
        var commentsVal = cmp.get("v.value");
        if (!commentsVal || !commentsVal.trim()) {
            cmp.set("v.error", 'Please enter a comment');
        } else if (commentsVal.length > 1000) {
            cmp.set("v.error", 'Comment must not exceed 1,000 characters in length');
        } else {
            cmp.set("v.error", null);
            isValid = true;
        }
        return isValid;
    },

    /**
     * Trigger an anlytics message to the embedded analytics component
     */
    pushAnalyticsEvent: function(cmp, category, description) {
        var analyticsObject = {
            form: {
                name: 'form:enquiries',
                step: 'case:' + cmp.get('v.case.EnquirySubType__c'),
                referenceId: cmp.get('v.case.CaseNumber')
            }
        };

        window.AP_ANALYTICS_HELPER.trackByObject({
            trackingType: 'site-interact',
            componentAttributes: analyticsObject,
            interactionCategory: category,
            interactionDescription: description
        });
    }

})