({
    /**
     *   Initialise
     *
     */
    onInit: function(component, event, helper) {

        //Call the helper function to retrieve the Status values.
        helper.getStatus(component);
        //Call the helper function to retrieve the Task Update values.
        helper.getTaskUpdate(component);
        //Call the helper function to retrieve the Task Details.
        helper.getTaskDetails(component,helper);

        component.set('v.isReassign', false);

    },

    /**
     *   Populate task details into component
     *
     */
    onPopulateData: function(component, event, helper) {
        var params = event.getParam('arguments');
        if (params) {
            var payloadVal = params.payload;
            if (payloadVal.taskId) {
                component.set('v.taskId', payloadVal.taskId);
                // retrive the task
                AP_LIGHTNING_UTILS.helperPromise(component, helper, {}, helper.getTask)
                    .then($A.getCallback(function(result) {
                        component.set('v.taskObj', result);

                        var taskObjVal = result;
                        if (!taskObjVal) {
                            taskObjVal = [];
                        } else if (!Array.isArray(taskObjVal)) {
                            taskObjVal = [taskObjVal];
                        }


                        // prepare the result for display in UI
                        var rowDataArray = AP_LIGHTNING_UTILS.flattenQueryResult(result);
                        AP_LIGHTNING_UTILS.helperPromise(component, helper, {
                            fieldSetName: 'Task_Detail_Community',
                            objectName: 'Task'
                        }, helper.getColumnFieldNames)
                            .then($A.getCallback(function(result2) {
                                component.set('v.columns', result2);
                                component.set('v.data', taskObjVal);
                                if (result2.length > 0) {
                                    var colFields = result2[0];
                                    // chatter feed item component needs to be destroyed every time when we change the SubjectId,
                                    // this is done to reflect the selected task's feeds on the chatter feed section
                                    var feedComponent = component.get('v.feedItemComp');
                                    // if there is a component, destroy it
                                    if(feedComponent) {
                                        // Aura.Component type on the attribute somehow did not automatically destroyed it, so we had to forcefully do it.
                                        feedComponent.destroy();
                                    }

                                    // create a chatter feed component dynamically.
                                    $A.createComponent(
                                        "c:stp_chatterFeedItem",
                                        {
                                            "aura:id": "feedItemComponent",
                                            "taskReference" : payloadVal.taskId
                                        },
                                        function(newComponent, status, errorMessage){
                                            component.set('v.feedItemComp', newComponent);
                                        }
                                    );

                                    // attachment component needs to be destroyed every time when we select a differnt task to show that task's attachment
                                    var fileComponent = component.get('v.attachmentComp');
                                    // if there is a component, destroy it
                                    if(fileComponent) {
                                    	// Aura.Component type on the attribute somehow did not automatically destroyed it, so we had to forcefully do it.
                                    	fileComponent.destroy();
                                    }

                                    // create a chatter feed component dynamically.
                                    $A.createComponent(
                                    	"c:stp_taskAttachmentCmp",
                                    	{
                                    		"aura:id": "attachmentComp",
                                    		"taskId" : payloadVal.taskId
                                    	},
                                    	function(newComponent, status, errorMessage){
                                    		component.set('v.attachmentComp', newComponent);
                                    	}
                                    );
                                }
                            }))
                            .catch($A.getCallback(function(result) {
                                console.log('ERROR:  1.stp_taskDetailController : onPopulateData()', result);
                                helper.showMyToast(component, helper, 'error', result);
                            }));



                    }))
                .catch($A.getCallback(function(result) {
                    console.log('ERROR:  2.stp_taskDetailController : onPopulateData()', result);
                    helper.showMyToast(component, helper, 'error', result);
                }));
            }
        }
    },

    /* Function to save the task details based on taskId. */
    handleOnSave: function(component, event, helper) {
        helper.saveTaskDetails(component, helper);
    },

    /* Function to  the task details based on taskId. */
    handleOnAcknowledge: function(component, event, helper) {
        helper.acknowledgeTaskDetails(component, helper);
    },

    /* Function to save the task details based on taskId. */
    handleOnPost: function(component, event, helper) {
        helper.postToFeed(component, event, helper);
    },
    
    /* Post button is disabled when the text area is empty, if you submit empty will casue validation error in backend */
    onChangeChatFeed: function(component, event, helper) {
        helper.onChangeChatFeed(component, event, helper);
    },

    /* function to retrieve the deport Area only if it is a Reassign task */
    handleTaskUpdate: function(component, event, helper){
        var taskUpdateValue = component.find("taskUpdatepkl").get("v.value");
        console.log('taskUpdateValue :: ',taskUpdateValue);
        if(taskUpdateValue === 'Reassign'){
            component.set('v.isReassign', true);
        } else {
            component.set('v.isReassign', false);
        }
    },

    /*
    * When selecting tabs, placeholder
    */
    tabSelected: function(component,event,helper){
        console.log('TAB SELECTED');
        console.log(JSON.stringify(event));
    }


})