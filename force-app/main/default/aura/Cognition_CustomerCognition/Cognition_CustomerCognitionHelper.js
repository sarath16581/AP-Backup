({
    sendToVF : function(component, helper) {
        //Prepare message in the format required in VF page
        var message = {
            "loadGoogleMap" : true,
            "mapData": component.get('v.mapData'),
            "mapOptions": component.get('v.mapOptions'),
            'mapOptionsCenter': component.get('v.mapOptionsCenter'),
            "action2Perform": "start",
            "refreshInterval": component.get('v.refreshInterval')

        } ;
        //Send message to VF
        helper.sendMessage(component, helper, message);
    },
    sendMessage: function(component, helper, message){
        //Send message to VF
        message.origin = window.location.hostname;
        var vfWindow = component.find("vfFrame").getElement().contentWindow;
        message = JSON.parse(JSON.stringify(message));
        vfWindow.postMessage(message, component.get("v.vfHost"));
    },
    sendToReportVF : function(component, helper,reqGUID,category,categoryName,seqValue, baseUrl, isInternalUser, refreshInterval) {
        //Prepare message in the format required in VF page
        var message = {
            "reqGUID": reqGUID,
            "category": category,
            "categoryName": categoryName,
            "seqValue":seqValue,
            "baseUrl":baseUrl,
            "isInternalUser": isInternalUser,
            "refreshInterval": refreshInterval
        };
        //Send message to VF
        helper.sendReportMessage(component, helper, message);
    },

    sendReportMessage: function(component, helper, message){
        //Send message to VF
        message.origin = window.location.hostname;
        var vfWindow = component.find("reportVfFrame").getElement().contentWindow;
        message = JSON.parse(JSON.stringify(message));

        vfWindow.postMessage(message, component.get("v.vfHost"));
    },

    /**
     * Loading the configurations when load of the application
     * @param component
     * @param event
     * @param helper
     */
    loadConfigs: function (component, event, helper) {
        helper.showSpinner(component);
        var action = component.get('c.loadConfigs');
        action.setCallback(this, function(response){
            helper.hideSpinner(component);
            var state = response.getState();
            var resp = response.getReturnValue();
            console.log('loadConfigs : ',resp);
            if (state == "SUCCESS") {
                component.set("v.isInternalUser",resp.isInternalUser);
                component.set('v.baseUrl', resp.baseUrl);
                component.set('v.refreshInterval', resp.refreshInterval);
            } else if (state === "ERROR") {
                var errors = response.getError();
                var message = 'Error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                // Display the message
                console.error('loadConfigs : ',message);
                component.set('v.errorMessage',message);
                component.set("v.displayError",true);
            }
        });
        $A.enqueueAction(action);
    },

    loadOptions: function (component, event, helper) {
        helper.showSpinner(component);
        var action = component.get('c.getAccountString');
        action.setCallback(this, function(response){
            helper.hideSpinner(component);
            var state = response.getState();
            var resp = response.getReturnValue();
            if (state == "SUCCESS") {
                component.set("v.showGoogleMap",true);

                var acc = resp.accName;

                if(acc!=null){
                    if(acc.length > 0){
                        var opts = Array();
                        var map = new Object();
                        for(var i=0; i<acc.length; i++){
                            opts.push({value: acc[i].split(',')[0], label: acc[i].split(',')[1]});
                            map[acc[i].split(',')[0]] = acc[i].split(',')[1];
                        }
                        component.set("v.options", opts);
                        component.set("v.accountMap", map);
                    }
                } else {

                    $A.util.removeClass(component.find('customer'), 'slds-show');
                    $A.util.addClass(component.find('customer'), 'slds-hide');
                    component.set("v.showGoogleMap",false);
                    var errorMsg = resp.errorMsg;
                    component.set('v.errorMessage',errorMsg);
                    component.set("v.displayError",true);

                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                var message = 'Error'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                // Display the message
                console.log('loadOptions : error ',message);

                $A.util.removeClass(component.find('customer'), 'slds-show');
                $A.util.addClass(component.find('customer'), 'slds-hide');
                component.set("v.showGoogleMap",false);
                component.set('v.errorMessage',message);
                component.set("v.displayError",true);
            }
        });
        $A.enqueueAction(action);
    },

    showSpinner : function (component){
        component.set("v.spinner", true);
    },

    hideSpinner : function (component){
        component.set("v.spinner", false);
    },

    submitQueryHelper : function (component, event, helper){
        component.set('v.disableUI',true);
        var selectedCust = component.get("v.selectedCustomer");
        var selectedDepot = component.get("v.selectedDepot");
        var customerMap = component.get("v.accountMap");
        var selectedCustName = customerMap[selectedCust];
        component.set('v.selectedCustomerName', selectedCustName);
        component.set('v.displayCustomerLogo',false);
        component.set('v.displayMapProgress',false);

        component.set('v.currentNumberOfCons',0);

        var action = component.get('c.submitQueryRequest');
        action.setParams({
            depotName : selectedDepot,
            customerNumber : selectedCust,
            customerName : selectedCustName
        });

        action.setCallback(this, function(response){
            this.processQueryStatusResponse(response,component);

            if(component.get('v.displayProgressBar')) {
                helper.queryStatusPollingHelper(component,event,helper);
            }

        });
        $A.enqueueAction(action);
    },

    processQueryStatusResponse : function(response,component) {
        var qsResponseData = response.getReturnValue();
        component.set('v.objClassController', qsResponseData);
        if(null == qsResponseData) {
            component.set('v.queryPercentage',100);
            component.set('v.queryMessage','ERROR: Failed to receive data');
        } else {
            component.set('v.queryPercentage',qsResponseData.PercentageComplete);
            component.set('v.queryMessage',qsResponseData.DisplayMessage);
        }
        component.set('v.displayProgressBar',true);
    },

    queryStatusPollingHelper : function(component, event, helper) {
        /** Polls the Cognition Server for latest status on the Query submitted earlier
         **/
        var reqGUID = component.get("v.objClassController.rGUID");
        var pollWait = parseInt($A.get("$Label.c.Cognition_QueryStatusPollInterval"));
        var pollingFunction = function() {
            var action = component.get('c.queryStatusInfo');
            action.setParams({
                reqGUID : reqGUID
            });

            action.setCallback(this, function(response) {
                helper.processQueryStatusResponse(response,component);
                if (component.get('v.queryPercentage') < 100 ) {
                    setTimeout($A.getCallback(pollingFunction),pollWait);
                } else if(!(component.get('v.queryMessage')).startsWith("ERROR:")) {
                    component.set("v.objClassController.rGUID",reqGUID);
                    helper.customerSummaryHelper(component, event, helper);
                }
            });
            $A.enqueueAction(action);
        }
        pollingFunction();
    },

    customerSummaryHelper : function(component, event, helper) {
        var reqGUID = component.get("v.objClassController.rGUID");
        console.log('customerSummaryHelper : reqGUID'+reqGUID);
        var selectedDepot = component.get("v.selectedDepot");

        var action = component.get('c.customerSummaryRequest');
        action.setParams ({
            reqGUID : reqGUID
        });
        action.setCallback(this, function(response){
            component.set('v.displayProgressBar',false);
            var state = response.getState();
            if(state === "SUCCESS") {
                var objCtrl = response.getReturnValue();
                console.log('objCtrl ->'+objCtrl);
                component.set('v.objClassController', objCtrl);
                if (null != objCtrl.customer_logo) {
                    component.set('v.displayCustomerLogo',true);
                }

                if(null != selectedDepot) {
                    window.setTimeout(
                        $A.getCallback( function() {
                            // Set Depot to the value selected last time
                            component.find("depotSelect").set("v.value", selectedDepot);
                        })
                    );
                } else {
                    // If Depot was not selecter earlier, then populate the Depot List
                    var depotsReturned = objCtrl.depotList;
                    if(null != depotsReturned) {
                        component.set('v.depotListOptions',objCtrl.depotList);
                    }
                }
                $A.util.removeClass(component.find('conSearch'), 'slds-hide');
                $A.util.addClass(component.find('conSearch'), 'slds-show');

                // keep the total number of consignments stored in the component, so we can access it anywhere in there
                component.set('v.totalNumberOfCons',component.get("v.objClassController.TotalNbr"));
                helper.customerDetailsHelper(component,helper);

            } else {
                component.set('v.errorMessage',"ERROR: Failed to retrieve Summary Data");
                component.set('v.displayError',true);
            }
        });
        $A.enqueueAction(action);
    },


    /**
     * Reset google maps, initialise
     * @param component
     * @param helper
     */
    resetGoogleMap : function(component, helper) {
        //Remove all Markers from Google Maps
        var message = {
            "action2Perform" : "clear",
            'requestGUID': component.get("v.objClassController.rGUID")
        } ;
        //Send message to VF
        helper.sendMessage(component, helper, message);
    },

    /**
     * Action to close the info popup on the map
     * @param component
     * @param helper
     */
    closeInfoWindow : function(component, helper) {
        //Remove all Markers from Google Maps
        var message = {
            "action2Perform" : "closeInfoWindow",
            'requestGUID': component.get("v.objClassController.rGUID")
        } ;
        //Send message to VF
        helper.sendMessage(component, helper, message);
    },

    /**
     * Obtain the marker text
     * @param info
     * @returns {*}
     */
    getMarkerText : function(info){
        if(typeof info.Consignment !== 'undefined'){
            return info.Consignment;
        } else if(typeof info.BookingNbr !== 'undefined'){
            return info.BookingNbr;
        }

    },

    /**
     * update the google map with markers once the customer details are recived
     * @param component
     * @param helper
     * @param cInfo
     */
    updateGoogleMap : function(component,helper,cInfo){
        /** Updates Google Maps with Consignment Markers. Sets the Bounds for map after
         *  loading all Consignments. If Refresh is enabled, then fires the Refresh event
         *  after refresh interval.
         **/
        if(cInfo.length>0){
            var reqGUID = component.get("v.objClassController.rGUID");
            var mapOptionsCenter = {
                "lat":parseFloat(cInfo[0].Latitude),
                "lng":parseFloat(cInfo[0].Longitude)
            };

            var mapData = Array();
            for(var i=0; i<cInfo.length; i++){
                if(null != cInfo[i].Latitude && null != cInfo[i].Longitude) {
                    if(parseFloat(cInfo[i].Latitude) != 0.0 &&
                        parseFloat(cInfo[i].Longitude) != 0.0){
                        mapData.push({"lat":parseFloat(cInfo[i].Latitude),
                            "lng":parseFloat(cInfo[i].Longitude),
                            "markerText":helper.getMarkerText(cInfo[i]),
                            "Type":cInfo[i].Type})
                    }
                }
            }
            var currentNumberOfCons = component.get('v.currentNumberOfCons');
            var totalNumberOfCons = component.get('v.totalNumberOfCons');

            // if more consignments means those are manually searched once, so we do not need to increment the count,
            // nor, we do not need to set the bounds, instead we need to zoom in so keep the setBounds false
            var setBounds = false;
            if(currentNumberOfCons < totalNumberOfCons ) {
                currentNumberOfCons += cInfo.length;
                setBounds = (currentNumberOfCons === totalNumberOfCons);
            }

            // prepare the message to post
            var message = {
                "mapData": mapData,
                "mapOptions": component.get('v.mapOptions'),
                'mapOptionsCenter': mapOptionsCenter,
                'requestGUID': reqGUID,
                "action2Perform": "update",
                "totalNumberOfCons": totalNumberOfCons,
                "setBounds": setBounds,
                "baseUrl" :component.get('v.baseUrl'),
                "isInternalUser" : component.get('v.isInternalUser'),
                "origin" : window.location.hostname
            };

            var vfWindow = component.find("vfFrame").getElement().contentWindow;
            message = JSON.parse(JSON.stringify(message));
            console.log('message  ',message);

            // post the message to google maps VF
            vfWindow.postMessage(message, component.get("v.vfHost"));
            if(!(component.get('v.displayMapProgress'))) {
                component.set('v.displayMapProgress',true);
            }

            // incremented number will be added to current number attribute, so we can access the number when it is the next iteration
            component.set('v.currentNumberOfCons',currentNumberOfCons);

            if(setBounds){
                component.set('v.disableUI',false);
                var currTime=new Date();
                component.set('v.lastRefresh',currTime.toString());
            }

        } else {
            component.set('v.disableUI',false);
        }
    },

    restart : function (component){
        component.set('v.objClassController',null);
        component.set('v.displayMapProgress',false);
        component.set('v.selectedCustomerName','');
    },

    closeReport : function (component){
        component.set("v.displayMapProgress",true);
        $A.util.removeClass(component.find('showstatsblock'), 'slds-hide');
        $A.util.addClass(component.find('showstatsblock'), 'slds-show');

        $A.util.removeClass(component.find('reportPage'), 'slds-show');
        $A.util.addClass(component.find('reportPage'), 'slds-hide');
        $A.util.removeClass(component.find('googleMapPage'), 'slds-hide');
        $A.util.addClass(component.find('googleMapPage'), 'slds-show');
    },

    /**
     *   Promise wrapper function to call asynchronous functions
     */
    helperPromise : function(component,helper, helperFunction) {
        return new Promise($A.getCallback(function(resolve, reject) {
            helperFunction(component,helper, resolve, reject);
        }));
    },

    /**
     *   Callout to API ConsignmentInfo
     */
    doAsyncConsignmentDetails : function(component,helper, resolve, reject){
        var callBack = function(result){
            if(result == null){
                reject('Error retrieve consignment details returned not payload') ;
            } else if(result.hasOwnProperty('errorMapLst') && result.errorMapLst != null ){
                // raise error
                reject(result);
            } else {
                resolve(result);
            }
        };

        var reqGUID = component.get("v.objClassController.rGUID");
        var conNumber = component.get('v.conNumber');
        var contReqEvt = $A.get("e.c:AsynchApexContinuationRequest");
        contReqEvt.setParams({
            className : "Cognition_IAsynchApexContinuationImpl",
            methodName: "ConsignmentInfo",
            methodParams : [reqGUID,conNumber],
            useAsynchCallout : true,
            callback : callBack
        });
        contReqEvt.fire();
    },
    parseAsyncConsignmentDetails : function(component,result,helper){
        var conNumber = component.get('v.conNumber');
        var msg = {};
        msg.title = "Retrieving data for "+conNumber;
        msg.isFound = 0;
        var conErr = $A.get("$Label.c.Cognition_ConSearchError");

        if (null != result.Type_EnumString &&
            result.Type_EnumString + '' != '') {
            msg.isFound=1;
            msg.title=result.Consignment+' - '+result.Type_EnumString;
            msg.status='';
            msg.status +=  result.ContextualParagragh1;
            msg.status += result.ContextualParagragh2;
            msg.depot = result.Depot;
            msg.EventDateTime=result.EventDateTime;
            msg.EventDesc=result.EventDesc;
            msg.etaData = 'Not Available';
            msg.ReceiverName = result.ReceiverName;

            // individual search result populated here, we call the map iFrame from here
            // let the map knows we found a consignment
            var message = [{
                Type: result.Type,
                Latitude: result.Latitude,
                Longitude: result.Longitude,
                Consignment: conNumber
            }];
            // updating gmap will send a js postMessage to gMap iFrame in the component.
            helper.updateGoogleMap(component,helper,message);
            if (null != result.ETADateTime && result.ETADateTime + '' != '') {
                msg.etaData = (result.ETADateTime).substring(0,10);
            }
            msg.despDateData = 'Not Available';
            if (null != result.DespatchDate && result.DespatchDate + '' != '') {
                msg.despDateData = (result.DespatchDate).substring(0,10);
            }
        } else {
            msg.isFound=2;
            msg.title = conErr.replace(/__CON__/,conNumber);
            console.log(' parseAsyncConsignmentDetails ',msg.title);
        }

        component.set('v.conSummary',msg);

    },

    /**
     *  get the async customer details and handle the call back
     * @param component
     * @param helper
     */
    customerDetailsHelper : function(component, helper) {
        // calling the Async customer details through the continuous framework
        helper.helperPromise(component, helper, helper.doAsyncCustomerDetails)
            .then($A.getCallback(function (result) {
                helper.parseAsyncCustomerDetails(component, result, helper);
                var totalNbr = component.get('v.totalNumberOfCons');
                var currNbr = component.get('v.currentNumberOfCons');

                // are there more records to be loaded, then load it
                if(totalNbr > currNbr){
                    // start the next call
                    helper.customerDetailsHelper(component,helper);
                }
            }))
            .catch($A.getCallback(function (result) {
                console.log('customerDetailsHelper:  Customer details promise error');
                helper.parseAsyncCustomerDetails(component, result, helper);
            }));
    },

    /**
     *   Callout to API CustomerDetails
     */
    doAsyncCustomerDetails : function(component,helper, resolve, reject){
        var callBack = function(result){
            if(result == null){
                reject('Error retrieve consignment details returned not payload') ;
            } else if(result.hasOwnProperty('errorMapLst') && result.errorMapLst != null ){
                // raise error
                reject(result);
            } else {
                resolve(result);
            }
        };
        var reqGUID = component.get("v.objClassController.rGUID");
        var FromSeq = component.get('v.currentNumberOfCons');
        var incrementSize = parseInt($A.get("$Label.c.Cognition_UpdateMapIncrementSize"));
        var ToSeq = incrementSize + FromSeq;

        console.log('doAsyncCustomerDetails : FromSeq ToSeq',FromSeq+'-'+ToSeq);
        // alright, now give me the first set customer details, so that I can send it to the maps,
        // if there are more ill come back
        var contReqEvt = $A.get("e.c:AsynchApexContinuationRequest");
        contReqEvt.setParams({
            className : "Cognition_IAsynchApexContinuationImpl",
            methodName: "CustomerDetails",
            methodParams : [reqGUID,FromSeq,ToSeq],
            useAsynchCallout : true,
            callback : callBack
        });
        contReqEvt.fire();
    },

    parseAsyncCustomerDetails : function(component,result,helper){
        var conNumber = component.get('v.conNumber');
        var conErr = $A.get("$Label.c.Cognition_ConSearchError");

        if(result && result.conInfo != 'undefined'){
            var consignmentList = result.conInfo;
            helper.updateGoogleMap(component,helper,consignmentList);
        } else {
            console.log('parseAsyncCustomerDetails : ERROR: [CustomerDetails] Failed to retrieve Consignment Location Data');
            component.set('v.errorMessage',"ERROR: [CustomerDetails] Failed to retrieve Consignment Location Data");
            component.set('v.displayError',true);
        }

    },

    /**
     * get the pickup detail records based on the GUid and the pickup number provided
     * @param component
     * @param helper
     * @param resolve
     * @param reject
     */
    doAsyncPickupDetails : function(component,helper, resolve, reject){
        var callBack = function(result){
            if(result == null){
                reject('Error retrieve pickup booking details returned not payload') ;
            } else if(result.hasOwnProperty('errorMapLst') && result.errorMapLst != null ){
                // raise error
                reject(result);
            } else {
                resolve(result);
            }
        };
        var reqGUID = component.get("v.objClassController.rGUID");
        var bookingBumber = component.get('v.conNumber');
        var contReqEvt = $A.get("e.c:AsynchApexContinuationRequest");

        contReqEvt.setParams({
            className : "Cognition_IAsynchApexContinuationImpl",
            methodName: "PickupInfo",
            methodParams : [reqGUID,bookingBumber],
            useAsynchCallout : true,
            callback : callBack
        });
        contReqEvt.fire();
    },
    
    parseAsyncPickupDetails : function(component,result,helper){
        var conNumber = component.get('v.conNumber');
        var msg = {};
        msg.title = "Retrieving data for "+conNumber;
        msg.isFound = 0;
        var conErr = $A.get("$Label.c.Cognition_PickupSearchError");

        console.log(' parseAsyncPickupDetails ');
        if (null != result.Type_EnumString &&
            result.Type_EnumString + '' != '') {
            msg.isFound=1;
            msg.title=result.BookingNbr+' - '+result.Type_EnumString;
            msg.depot = result.Depot;
            msg.EventDateTime=result.EventDateTime;
            msg.EventDesc=result.EventDesc;
            msg.etaData = 'Not Available';
            msg.DriverName = result.DriverName;
            msg.ServiceCode = result.ServiceCode;
            msg.ReadyTime = result.ReadyTime;
            msg.CloseTime = result.CloseTime;
            msg.Quantity = result.Quantity;
            msg.BookingInstructions = result.BookingInstructions;

            // individual search result populated here, we call the map iFrame from here
            // let the map knows we found a pickup
            var message = [{
                Type: result.Type,
                Latitude: result.Latitude,
                Longitude: result.Longitude,
                Consignment: conNumber
            }];
            // updating gmap will send a js postMessage to gMap iFrame in the component.
            helper.updateGoogleMap(component,helper,message);
        } else {
            msg.isFound=2;
            msg.title = conErr.replace(/__CON__/,conNumber);
        }

        component.set('v.conSummary',msg);

    }
    
})