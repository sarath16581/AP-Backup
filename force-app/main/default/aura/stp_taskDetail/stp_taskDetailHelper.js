({
    /**
    * Retrive Task details
    */
    getTask: function(component, helper, paramObj, resolve, reject) {
        var taskId = component.get('v.taskId');

        var params = {
            taskId: taskId
        };
        var callBack = function(rslt) {
            // disable the task fields based on the status
            if(rslt.Status === 'Not Started' || rslt.Status === 'Finished') {
                component.set('v.isTaskReadOnly', true);
            } else {
                component.set('v.isTaskReadOnly', false);
            }
            resolve(rslt);
        };

        var errCallBack = function(rslt) {
            reject(rslt);
        }
        var loader = component.get('v.loadingSpinner');
        AP_LIGHTNING_UTILS.invokeController(component, "getTask", params, callBack, errCallBack, false, loader[0]);
    },

    /**
     *   Get Fields Column names
     */
    getColumnFieldNames: function(component, helper, paramObj, resolve, reject) {

        var params = paramObj;
        var callBack = function(rslt) {
            resolve(rslt);
        };

        var errCallBack = function(rslt) {
            reject(rslt);
        }
        var loader = component.get('v.loadingSpinner');
        AP_LIGHTNING_UTILS.invokeController(component, "readFieldSet", params, callBack, errCallBack, false, loader[0]);
    },

    /**
    * Function to retrieve the status values for task detail.
    */
    getStatus: function(component) {
        var action = component.get("c.getStatus");
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = response.getReturnValue();
                component.set("v.statusPicklist", allValues);
            }
        });
        $A.enqueueAction(action);
    },

    /**
     *  Function to retrieve the task update values for task detail.
     */
    getTaskUpdate: function(component) {
        var action = component.get("c.getTaskUpdate");
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = response.getReturnValue();
                component.set("v.taskUpdatePicklist", allValues);
            }
        });
        $A.enqueueAction(action);
    },

    /**
     *  Function to retrieve the task details based on taskId.
     */
    getTaskDetails: function(component,helper) {

        var callBack = function(response) {
            component.set("v.taskObj", response);


            var taskObj = component.get('v.taskObj');
            var taskStatus = taskObj.Status;

            //Call the helper function to retrieve the getDepotArea.
                    helper.getDepotArea(component,helper);

            if(taskObj.Status === 'Finished') {
                component.set('v.isTaskReadOnly', true);
            }

            // disable the task fields based on the status
            if(response.Status === 'Not Started') {
                component.set('v.isTaskReadOnly', true);
            } else {
                component.set('v.isTaskReadOnly', false);
            }
        };
        var errCallBack = function(response) {
            var errors = response.getError();
            console.log('ERROR:  stp_taskDetailHelper : getTaskDetails()', result);
            if (errors) {
                helper.showMyToast(component, helper, 'error', errors[0].message);
            } else {
                helper.showMyToast(component, helper, 'error', 'Unknown error');
            }
        };

        var loader = component.get('v.loadingSpinner');
        AP_LIGHTNING_UTILS.invokeController(component, "getTask", {taskId: component.get('v.taskId')}, callBack, errCallBack, false, loader[0]);
    },


     /**
      * get DepotArea picklist from the parent Object.
      */
     getDepotArea: function(component,helper) {
         var taskObj = component.get('v.taskObj');
         var parentNetworkId = taskObj.Network__r.Parent_Network__c;
         console.log('getDepotArea :: parentNetwork ::',parentNetworkId);
         var params = { "parentNetworkId" : parentNetworkId };
         var callBack = function(result) {
              component.set('v.depotAreaPicklist',result);
              component.set('v.isInitialized',true);
              console.log('getDepotArea :: result::',result);
         }

         var errCallBack = function(result) {
            console.log('ERROR stp_TaskDetail : getDeportArea',result);
         }

         var loader = component.get('v.loadingSpinner');
         AP_LIGHTNING_UTILS.invokeController(component, "getDepotArea", params, callBack, errCallBack, false, loader[0]);
    },

    /**
     *  Function to save the task details based on taskId.
     */
    saveTaskDetails: function(component, helper) {
        var taskObj = component.get('v.taskObj');
        var taskId = component.get('v.taskId');

        //In case if this is not changed
        var depotArea = taskObj.Depot_Role__c;
        console.log('taskObject :: ', taskObj);
        console.log('taskId :: ', taskId);

        //validation if it is  to reassign the task, depot area must be selected
        var taskUpdateValue = component.find("taskUpdatepkl").get("v.value");
        console.log('taskUpdateValue :: ', taskUpdateValue);


        // depot area picklist is only visible for Reassign
        if(taskUpdateValue === 'Reassign' ){
            depotArea = component.find("depotAreaPkl").get("v.value");
            console.log('depotArea :: ', depotArea);
            if( !depotArea){
                 alert('Please select Depot Area for Parent network.');
                 return;
            }
        }

        var paramsCon = {
            taskId: taskId,
            taskObj: taskObj,
            depotAreaId: depotArea
        };
        console.log('paramsCon :: '+ paramsCon);

        var callBack = function(result) {
            console.log(result);
            //alert(taskObj.network__r.Name);
            helper.showMyToast(component, helper, 'success', result);
            //refresh the tasks list once bulk acknowledged
            var notify = component.getEvent('notifyCompEvent');
            // refresh the task details with new once
            var consignmentNumber = taskObj.CaseObject__r.Calc_Case_Consignment__c;
            var consignmentId = taskObj.CaseObject__r.ArticleTest__c;

            var notificationMessage;
            notificationMessage = 'REFRESH_SEARCH_RESULTS_AND_TASK_DETAILS';

            var depot = taskObj.Depot_Role__c;

            var params = {
                notification: notificationMessage,
                payload: {
                    taskId: taskId,
                    consignmentId: consignmentId,
                    consignmentNumber: consignmentNumber,
                    depotArea : depotArea
                }
            };
            notify.setParams(params);
            notify.fire();
        };

        var errCallBack = function(result) {
            var errors = result.getError();
            console.log('ERROR:  stp_taskDetailHelper : saveTaskDetails()', result);
            if (errors) {
                helper.showMyToast(component, helper, 'error', errors[0].message);
            } else {
                helper.showMyToast(component, helper, 'error', 'Unknown error');
            }
        };
        var loader = component.get('v.loadingSpinner');
        AP_LIGHTNING_UTILS.invokeController(component, "saveTaskDetails", paramsCon, callBack, errCallBack, false, loader[0]);
    },

    /**
     *  Function to acknowledge the task details based on taskId.
     */
    acknowledgeTaskDetails: function(component, helper) {
        var action = component.get("c.acknowledgeTaskDetails");
        action.setParams({
            "taskId": component.get('v.taskId')
        });
        var loader = component.get('v.loadingSpinner');
        loader[0].startWait();
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                loader[0].stopWait();
                var result = response.getReturnValue();
                helper.showMyToast(component, helper, 'success', result);

                // refresh the task details with new once
                var taskObj = component.get('v.taskObj');
                var notify = component.getEvent('notifyCompEvent');
                var consignmentNumber = taskObj.CaseObject__r.Calc_Case_Consignment__c;
                var consignmentId = taskObj.CaseObject__r.ArticleTest__c;
                var taskId = taskObj.Id;

                var params = {
                    notification: 'REFRESH_SEARCH_RESULTS_AND_TASK_DETAILS',
                    payload: {
                        taskId: taskId,
                        consignmentId: consignmentId,
                        consignmentNumber: consignmentNumber
                    }
                };
                notify.setParams(params);
                notify.fire();

            } else if (response.getState() == "ERROR") {
                loader[0].stopWait();
                var errors = response.getError();
                console.log('ERROR:  stp_taskDetailHelper : acknowledgeTaskDetails()', result);
                if (errors) {
                    helper.showMyToast(component, helper, 'error', errors[0].message);
                } else {
                    helper.showMyToast(component, helper, 'error', 'Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },

    /**
     *  Function to save the task details while posting a feed item.
     */
    postToFeed: function(component, event,helper) {

        var params = {
            chatterComment: component.get('v.chatterComment'),
            taskObj: component.get('v.taskObj')
        };

        var callBack = function(result) {
            component.set('v.taskId',''); // clear the task id so the chatterfeed will be refreshed when a feed is added.
            helper.showMyToast(component, helper, 'success', result);
            //refresh the tasks list once bulk acknowledged
            var notify = component.getEvent('notifyCompEvent');
            // refresh the task details with new once
            var taskObj = component.get('v.taskObj');
            var consignmentNumber = taskObj.CaseObject__r.Calc_Case_Consignment__c;
            var consignmentId = taskObj.CaseObject__r.ArticleTest__c;
            var taskId = taskObj.Id;
            var params2 = {
                notification: 'REFRESH_SEARCH_RESULTS_AND_TASK_DETAILS',
                payload: {
                    taskId: taskId,
                    consignmentId: consignmentId,
                    consignmentNumber: consignmentNumber
                }
            };
            notify.setParams(params2);
            notify.fire();
            component.set('v.chatterComment','');
            component.set('v.isPostDisabled', true);
        };

        var errCallBack = function(result) {
            var errors = result.getError();
            console.log('ERROR:  stp_taskDetailHelper : postToFeed()', result);
            if (errors) {
                helper.showMyToast(component, helper, 'error', errors[0].message);
            } else {
                helper.showMyToast(component, helper, 'error', 'Unknown error');
            }
        };
        var loader = component.get('v.loadingSpinner');
        AP_LIGHTNING_UTILS.invokeController(component, "postToFeed", params, callBack, errCallBack, false, loader);
    },

    /**
     *  Post button is disabled when the text area is empty, if you submit empty will cause validation error in backend
     */
    onChangeChatFeed:  function(component, event,helper) {
        if(component.get('v.chatterComment') == ''){
            component.set('v.isPostDisabled', true);
        } else {
            component.set('v.isPostDisabled', false);
        }

    },

    /**
     *   Display message on UI
     *   Usage :
     *   hlpr.showMyToast(component,hlpr,'info', 'test messaging toast info');
     *   hlpr.showMyToast(component,hlpr,'error', 'test messaging toast error');
     *   hlpr.showMyToast(component,hlpr,'success', 'test messaging toast success');
     *   hlpr.showMyToast(component,hlpr,'warning', 'test messaging toast warning');
     */
    showMyToast: function(component, helper, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        var mode = 'dismissible';
        if (type == 'error' || type == 'warning') {
            mode = 'sticky';
        }
        toastEvent.setParams({
            type: type,
            mode: mode,
            message: message
        });
        toastEvent.fire();
    }
})