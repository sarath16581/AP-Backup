({

    /**
     *   Query search parameters from salesforce
     */
    handleSearchTask: function(component, helper, paramObj, resolve, reject) {
        var optionSelect = component.find('optionSelect');

        // This is to disable acknowledge button when displaying Finished task Search result
        if(optionSelect.get('v.value') === 'My Finished Tasks'){
             
             var notify1 = component.getEvent('notifyCompEvent');
             notify1.setParams({
                 notification: 'SEARCH_FINISHED_TASK',
                 payload: {}
             });
             notify1.fire();
        }

        var consignment = component.find('consignmentNumber');
        var consignmentId = consignment.get('v.value');

        if (consignmentId) {
            var params = {
                consignmentId: consignmentId
            };
        } else {
            var params = {
                filterType: optionSelect.get('v.value')
            };
        }
        var callBack = function(rslt) {
            resolve(rslt);
        };

        var errCallBack = function(rslt) {
            console.log('ERROR:  stp_taskSearchHelper : handleSearchTask()', rslt);
            reject(rslt);
        }
        var loader = component.get('v.loadingSpinner');
        AP_LIGHTNING_UTILS.invokeController(component, "searchTask", params, callBack, errCallBack, false, loader[0]);
    },

    /**
     *   Get Fields Column names
     */
    getColumnFieldNames: function(component, helper, paramObj, resolve, reject) {
        var optionSelect = component.find('optionSelect');

        var params = paramObj;
        var callBack = function(rslt) {
            resolve(rslt);
        };

        var errCallBack = function(rslt) {
            console.log('ERROR:  stp_taskSearchHelper : getColumnFieldNames()', rslt);
            reject(rslt);
        }
        var loader = component.get('v.loadingSpinner');
        AP_LIGHTNING_UTILS.invokeController(component, "readFieldSet", params, callBack, errCallBack, false, loader[0]);
    },

    /**
     *   Do on search Button Click
     */
    handleSearchButtonClick: function(component, helper) {
        helper.handleSearch(component, helper, 'SEARCH_BUTTON_CLICKED');
    },

    handleSearchRefresh: function(component, helper) {
        //REFRESH_SEARCH_RESULTS
        helper.handleSearch(component, helper, 'POPULATE_SEARCH_RESULTS');
    },

    handleSearch: function(component, helper, Notification) {
        AP_LIGHTNING_UTILS.helperPromise(component, helper, {}, helper.handleSearchTask)
            .then($A.getCallback(function(result) {
                var rowData = AP_LIGHTNING_UTILS.flattenQueryResult(result);

                AP_LIGHTNING_UTILS.helperPromise(component, helper, {
                    fieldSetName: 'Task_Results_Community',
                    objectName: 'Task'
                }, helper.getColumnFieldNames)
                    .then($A.getCallback(function(result) {
                        var columnData = helper.getColumnsArrayforDataGrid(component, helper, result);
                        var notify = component.getEvent('notifyCompEvent');
                        
                        notify.setParams({
                            notification: Notification,
                            payload: {
                                rowData: rowData,
                                columnData: columnData
                            }
                        });
                        notify.fire();
                    }))
                    .catch($A.getCallback(function(result) {
                        console.log('ERROR:  1.stp_taskSearchHelper : handleSearch()', result);
                        helper.showMyToast(component, helper, 'error', result);
                    }));
            }))
            .catch($A.getCallback(function(result) {
                console.log('ERROR:  2.stp_taskSearchHelper : handleSearch()', result);
                helper.showMyToast(component, helper, 'error', result);
            }));
    },

    getColumnsArrayforDataGrid: function(component, helper, result) {
        var rtn = [];

        if (result) {
            var iCnt = 0;
            for (iCnt = 0; iCnt < result.length; iCnt++) {
                var rowObj = {
                    label: '',
					sortable:'true',
                    fieldName: '',
                    type: 'string'
                };
                
                rowObj.fieldName = result[iCnt].fieldPath;
                rowObj.label = result[iCnt].label;
                rowObj.type = result[iCnt].type;
                rowObj.initialWidth = "400px";
                if (rowObj.fieldName != "CaseObject__r.ArticleTest__c") {
                    rtn.push(rowObj);
                }
            }
        }
        return rtn;
    },

    /**
     *   Display message on UI
     *   Usage :
     *   helper.showMyToast(component,helper,'info', 'test messaging toast info');
     *   helper.showMyToast(component,helper,'error', 'test messaging toast error');
     *   helper.showMyToast(component,helper,'success', 'test messaging toast success');
     *   helper.showMyToast(component,helper,'warning', 'test messaging toast warning');
     */
    showMyToast: function(component, helper, type, msg) {
        var toastEvent = $A.get("e.force:showToast");
        var mode = 'dismissible';
        if (type == 'error' || type == 'warning') {
            mode = 'sticky';
        }
        toastEvent.setParams({
            type: type,
            mode: mode,
            message: msg
        });
        toastEvent.fire();
    }
})