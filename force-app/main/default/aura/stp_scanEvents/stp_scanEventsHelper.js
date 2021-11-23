({

    /**
     *   Callout to Consignment API
     *   please note that the ImageConsignmentSearch is the actual consignment searched used in usortables project,
     *   ImageConsignmentSearch.searchConsignment() is a re use in the portal in order to bring the consignment
     *   details and update
     */
    doGetConsignmentSummary: function(component, helper, paramObj, resolve, reject) {
        var param = component.get('v.consignmentNumber'); //'6BHZ00001669'
        // spinner component has to be manually implemented as this call is going to be a Asynch request call.
        var loader = component.get('v.loadingSpinner');
        loader[0].startWait();

        var callback = function(result) {
            loader[0].stopWait();
            if (result == null) {
                reject('Error Consignment Search returned not payload');
            } else if (result.hasOwnProperty('error') && result.error != null) {
                // raise error
                reject(result.error);
            } else {
                resolve(result);
            }
        }

        // let's fire the async call to get the consignment detail, on call of this method will reach out to .NET
        // service and the .NET service come back to Salesforce and update the relevent consignment details along with event messages,
        // then we access the event messages with the getPOD method in this controller and to display them in the portal page.
        var consumerSrchEvt = $A.get("e.c:AsynchApexContinuationRequest");
        consumerSrchEvt.setParams({
            className: "ImageConsignmentSearch",
            methodName: "searchConsignment",
            methodParams: [param],
            callback: callback
        });
        consumerSrchEvt.fire();
    },


    /**
     *
     * Event related to selected consignment will be returned.
     *
     * @param component
     * @param helper
     * @param paramObj
     * @param resolve
     * @param reject
     */
    doGetConsignmentEvents: function(component, helper, paramObj, resolve, reject) {
        var consignmentId = component.get('v.consignmentId');
        if (consignmentId) {
            var params = {
                consignmentId: consignmentId
            };
            //var params = {consignmentId:'a1h5D000000DSsOQAW'};
            var callBack = function(rslt) {
                resolve(rslt);
            };

            var errCallBack = function(rslt) {
                reject(rslt);
            }
            var loader = component.get('v.loadingSpinner');
            AP_LIGHTNING_UTILS.invokeController(component, "getConsignmentEvents", params, callBack, errCallBack, false, loader[0]);
        }
    },


    /**
     * Events related to selected consignment's articles will be returned
     *
     * @param component
     * @param helper
     * @param paramObj
     * @param resolve
     * @param reject
     */
    doGetConsignmentEventsByArticle: function(component, helper, paramObj, resolve, reject) {
        var consignmentId = component.get('v.consignmentId');
        if (consignmentId) {
            var params = {
                consignmentId: consignmentId
            };
            //var params = {consignmentId:'a1h5D000000DSsOQAW'};
            var callBack = function(rslt) {
                resolve(rslt);
            };

            var errCallBack = function(rslt) {
                reject(rslt);
            }
            var loader = component.get('v.loadingSpinner');
            AP_LIGHTNING_UTILS.invokeController(component, "getArticleEvents", params, callBack, errCallBack, false, loader[0]);
        }
    },


    /**
     * read the Proof of Delivery obnject and access the attachment related to it to show the POSD image for Startrack in the portal
     *
     * @param component
     * @param helper
     * @param paramObj
     * @param resolve
     * @param reject
     */
    doGetPOD: function(component, helper, paramObj, resolve, reject) {
        var consignmentId = component.get('v.consignmentId');
        if (consignmentId) {
            var params = {
                consignmentId: consignmentId
            };
            //var params = {consignmentId:'a1h5D000000DSsOQAW'};
            var callBack = function(rslt) {
                resolve(rslt);
            };

            var errCallBack = function(rslt) {
                reject(rslt);
            }
            var loader = component.get('v.loadingSpinner');
            AP_LIGHTNING_UTILS.invokeController(component, "getPOD", params, callBack, errCallBack, false, loader[0]);
        }
    },


    /**
     * get object's field names based on the object and the field set name passed
     *
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
     * prepare and display the consignment summary on the scan events section
     */
    displayConsignmentSummary: function(component, helper) {
        // retrieve the consignment summary
        var loader = component.get('v.loadingSpinner');
        AP_LIGHTNING_UTILS.helperPromise(component, helper, {}, helper.doGetConsignmentSummary)
            .then($A.getCallback(function(result) {
                var datConsignmentSummary = result.payload.articleList;
                if (!datConsignmentSummary) {
                    datConsignmentSummary = [];
                } else if (!Array.isArray(datConsignmentSummary)) {
                    datConsignmentSummary = [datConsignmentSummary];
                }

                // start spinner
                loader[0].startWait();
                // retrieve field names for column headers
                AP_LIGHTNING_UTILS.helperPromise(component, helper, {
                    fieldSetName: 'StarTrack_Consignment_Summary',
                    objectName: 'Article__c',
                    isStandard: true
                }, helper.getColumnFieldNames)
                    .then($A.getCallback(function(result2) {
                        var colConsignmentSummary = result2;
                        // set the consignment details and the column names
                        component.set('v.colConsignmentSummary', colConsignmentSummary);
                        component.set('v.datConsignmentSummary', datConsignmentSummary);
                        // stop spinner for search result data table
                        loader[0].stopWait();
                    }))
                    .catch($A.getCallback(function(result) {
                        // stop spinner for search result data table
                        loader[0].stopWait();
                        helper.showMyToast(component, helper, 'error', result);
                    }));
            }))
            .catch($A.getCallback(function(result) {
                // stop spinner for search result data table
                loader[0].stopWait();
                helper.showMyToast(component, helper, 'error', result);
            }));
    },


    /**
     * retrieve the consignment event messages from EventMessage__c table by the consignment id,
     * field set used is StarTrack_Consignment_Events, then query the data and handover it to the lightning table.
     * @param component
     * @param helper
     * @param event
     */
    getConsignmentEventMessages: function(component, helper, event) {
        // get consignment events
        AP_LIGHTNING_UTILS.helperPromise(component, helper, {}, helper.doGetConsignmentEvents)
            .then($A.getCallback(function(result) {
               var data = result;
                console.log('data',data);
               if (!data) {
                   data = [];
               } else if (!Array.isArray(data)) {
                   data = [data];
               }

                // get field names after consignment events
                AP_LIGHTNING_UTILS.helperPromise(component, helper, {
                   fieldSetName: 'StarTrack_Consignment_Events',
                   objectName: 'EventMessage__c',
                   isStandard: false
                }, helper.getColumnFieldNames)
                   .then($A.getCallback(function(result2) {
                       var columns = result2;
                       console.log('columns==>', columns);
                       component.set('v.columnsEventMessages', columns);
                       //console.log('data.length()',data.length);
                       for(var i=0; i < data.length; i++){
                            if(data[i].Article__r.Name){
                                //Displaying parent field  for lightning:datatable
                                data[i].ArticleNumber = data[i].Article__r.Name;
                            }
                            if(data[i].Article__r.ArticleID__c){
                                 //Displaying parent field  for lightning:datatable
                                 data[i].ArticleId = data[i].Article__r.ArticleID__c;
                            }
                       }
                       console.log('data==>', data);
                       component.set('v.dataEventMessages', data);
                       component.set('v.showSearchResultMsg', true);
                   }))
                   .catch($A.getCallback(function(result) {
                       console.log(result);
                       helper.showMyToast(component, helper, 'error', result);
                   }));
            }))
            .catch($A.getCallback(function(result) {
                console.log(result);
                helper.showMyToast(component, helper, 'error', result);
        }));
    },


    /**
     * retrieve the consignment event messages from EventMessage__c table by the consignment id,
     * field set used is StarTrack_Consignment_Events, then query the data and handover it to the lightning table.
     * @param component
     * @param helper
     * @param event
     */
    getEventMessagesByArticle: function(component, helper, event) {
        // get event messages by articles
        AP_LIGHTNING_UTILS.helperPromise(component, helper, {}, helper.doGetConsignmentEventsByArticle)
            .then($A.getCallback(function(result) {
                var data = result;
                if (!data) {
                    data = [];
                } else if (!Array.isArray(data)) {
                    data = [data];
                }

                // read the coulumn field names via field set
                AP_LIGHTNING_UTILS.helperPromise(component, helper, {
                    fieldSetName: 'StarTrack_Consignment_Events',
                    objectName: 'EventMessage__c',
                    isStandard: false
                }, helper.getColumnFieldNames)
                .then($A.getCallback(function(result2) {
                    var columns = result2;
                    console.log('columns==>', columns);
                    component.set('v.columnsEventMessages', columns);
                    //console.log('data.length()',data.length);
                    for(var i=0; i < data.length; i++){
                         if(data[i].Article__r.Name){
                            //Displaying parent field  for lightning:datatable
                            data[i].ArticleNumber = data[i].Article__r.Name;
                        }
                        if(data[i].Article__r.ArticleID__c){
                             //Displaying parent field  for lightning:datatable
                             data[i].ArticleId = data[i].Article__r.ArticleID__c;
                        }
                    }
                    console.log('data==>', data);
                    component.set('v.columnsEventMessagesByArticle', columns);
                    component.set('v.dataEventMessagesByArticle', data);
                }))
                .catch($A.getCallback(function(result) {
                     console.log(result);
                    helper.showMyToast(component, helper, 'error', result);
                }));
            }))
            .catch($A.getCallback(function(result) {
                 console.log(result);
                helper.showMyToast(component, helper, 'error', result);
            }));
    },


    /**
     * get proof of delivery images, read the Proof of delivery table and column names to be displayed
     *
     * @param component
     * @param helper
     * @param event
     */
    getPOD: function(component, helper, event) {
        AP_LIGHTNING_UTILS.helperPromise(component, helper, {}, helper.doGetPOD)
            .then($A.getCallback(function(result) {
                var data = result;
                if (!data) {
                    data = [];
                } else if (!Array.isArray(data)) {
                    data = [data];
                }
                AP_LIGHTNING_UTILS.helperPromise(component, helper, {
                    fieldSetName: 'StarTrack_View_All_POD',
                    objectName: 'Proof_of_Delivery__c',
                    isStandard: false
                }, helper.getColumnFieldNames)
                    .then($A.getCallback(function(result2) {
                        var columns = result2;
                        component.set('v.columnsPOD', columns);
                        component.set('v.dataPOD', data);
                    }))
                    .catch($A.getCallback(function(result) {
                        helper.showMyToast(component, helper, 'error', result);
                    }));
            }))
            .catch($A.getCallback(function(result) {
                helper.showMyToast(component, helper, 'error', result);
            }));
    },

    /**
     *   Display message on UI
     *   Usage :
     *   hlpr.showMyToast(cmp,hlpr,'info', 'test messaging toast info');
     *   hlpr.showMyToast(cmp,hlpr,'error', 'test messaging toast error');
     *   hlpr.showMyToast(cmp,hlpr,'success', 'test messaging toast success');
     *   hlpr.showMyToast(cmp,hlpr,'warning', 'test messaging toast warning');
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
    },

    /**
     *   Promise wrapper function to call asynchronous functions
     */
    helperPromise: function(cmp, hlpr, paramObj, helperFunction) {
        return new Promise($A.getCallback(function(resolve, reject) {
            helperFunction(cmp, hlpr, paramObj, resolve, reject);
        }));
    }
})