({
    /**
     * Handles Initialization. Sets the URL for Google Map and Report VF pages
     * based on whether its hosted on Lightning Community or VF Page
     **/
    doInit : function(component, event, helper) {

        $A.util.removeClass(component.find('reportPage'), 'slds-show');
        $A.util.addClass(component.find('reportPage'), 'slds-hide');
        $A.util.removeClass(component.find('conSearch'), 'slds-show');
        $A.util.addClass(component.find('conSearch'), 'slds-hide');
        document.title = $A.get("$Label.c.Cognition_Title");
        component.set('v.lcHost', window.location.hostname);
        var commName = (window.location.pathname);
        if(commName.indexOf("/s/") != -1) {
            commName = commName.replace("/s/","");
            component.set('v.mapSource',commName + component.get('v.mapPage'));
            component.set('v.reportSource',commName + component.get('v.reportPage'));
        } else if(commName.indexOf("/apex/") != -1){
            commName = commName.substr(0,commName.indexOf("/apex/"));
            component.set('v.mapSource',commName + component.get('v.mapPage'));
            component.set('v.reportSource',commName + component.get('v.reportPage'));
        } else {
            component.set('v.mapSource',component.get('v.mapPage'));
            component.set('v.reportSource',component.get('v.reportPage'));
        }

        window.addEventListener("message", function(event) {
            if(event.data.state == 'LOADED'){
                //CognitionUtil.startTimer();
                component.set('v.vfHost', event.data.vfHost);
                console.log('VFHOST value++++'+component.get('v.vfHost'));
                helper.sendToVF(component, helper);
            } else if(event.data.state == 'FIRE_REFRESH'){
                if(component.isValid() && (component.get("v.selectedCustomer") != '')) {
                    var refreshEvent = component.getEvent("refreshEvent");
                    refreshEvent.fire();
                }
            }
        }, false);

        helper.loadOptions(component, event, helper);
        helper.loadConfigs(component, event, helper);
    },

    /**
     * Opens the Report VF Page and Hides the Map
     **/
    openActionWindow : function(component, event, helper ) {
		var ctarget = event.currentTarget;
		var seqValue = ctarget.dataset.seqvalue;
		var category = ctarget.dataset.category;
		var categoryName = ctarget.dataset.categoryname;
		var objVar = component.get('v.objClassController');
        var baseUrl = component.get('v.baseUrl');
        var isInternalUser = component.get('v.isInternalUser');
        var refreshInterval  = component.get('v.refreshInterval');
		var reqGUID = objVar.rGUID;
		component.set("v.displayMapProgress",false);
		
		$A.util.removeClass(component.find('showstatsblock'), 'slds-show');
		$A.util.addClass(component.find('showstatsblock'), 'slds-hide');
	    $A.util.removeClass(component.find('googleMapPage'), 'slds-show');
		$A.util.addClass(component.find('googleMapPage'), 'slds-hide');
		$A.util.removeClass(component.find('reportPage'), 'slds-hide');
		$A.util.addClass(component.find('reportPage'), 'slds-show');
		
		helper.sendToReportVF(component, helper,reqGUID,category,categoryName,seqValue, baseUrl, isInternalUser, refreshInterval);
		
	},

    /**
     * Handles manual refresh. Refreshes the Cognition page with latest data.
     **/
    refreshInformation : function (component, event, helper){
		helper.closeReport(component);
        component.set('v.conSummary','');
		component.set('v.conNumber','');
        $A.util.removeClass(component.find('conSearch'), 'slds-show');
        $A.util.addClass(component.find('conSearch'), 'slds-hide');
		
		helper.resetGoogleMap(component, helper);
        helper.submitQueryHelper(component, event, helper);        
    },

    /**
     * Closes the Report VF page.
     **/
    handleCloseReportVFClick: function (component, event, helper){
        helper.closeReport(component);
    },

    /**
     * Submits Query to Cognition with Customer Account only
     **/
    submitQueryWithoutDepot : function (component, event, helper){
		helper.closeReport(component);
        helper.resetGoogleMap(component, helper);
        component.set('v.selectedDepot',null);
        component.set('v.depotListOptions',null);

        component.set('v.conNumber','');
		component.set('v.conSummary','');
        $A.util.removeClass(component.find('conSearch'), 'slds-show');
        $A.util.addClass(component.find('conSearch'), 'slds-hide');
        if('' != component.get("v.selectedCustomer")) {
            helper.submitQueryHelper(component, event, helper);
        } else {
            helper.restart(component);
        }        
    },

    /**
     * Submits Query to Cognition with Customer Account & Depot.
     **/
    submitQueryWithDepot : function (component, event, helper){
		helper.closeReport(component);
        helper.resetGoogleMap(component, helper);
        console.log('Selected Depot ->'+component.get('v.selectedDepot'));
        var selectedDep = component.get('v.selectedDepot');

  		if(!selectedDep || selectedDep === ""){
            component.set('v.selectedDepot',null);
        }    

		component.set('v.conNumber','');
		component.set('v.conSummary','');
        $A.util.removeClass(component.find('conSearch'), 'slds-show');
        $A.util.addClass(component.find('conSearch'), 'slds-hide');        
        helper.submitQueryHelper(component, event, helper);
    },

    jQueryLoaded : function(component,event,helper){
        
    },
    
    clearSearch : function(component,event,helper){
        component.set('v.conSummary','');
		component.set('v.conNumber','');
    },

    /**
     * Handles Consignment search. Cleanses the input before submitting to Cognition.
     **/
    getConSummary : function (component, event, helper){
        var conNumber =  '' + component.get('v.conNumber');
        var cleanInput = conNumber.replace(/[\W_]+/g,'');
        if(cleanInput != '') {
            var maxLength = parseInt($A.get("$Label.c.Cognition_ConMaxLength"));
            if(cleanInput.length > maxLength) {
                var maxLengthErr = $A.get("$Label.c.Cognition_ConMaxLengthError");
                var msg={};
                msg.title=maxLengthErr.replace(/__LIMIT__/,maxLength);
                component.set('v.conSummary',msg);
            } else {
                
            	component.set('v.conNumber',cleanInput);
            	
            	var selectedSearchType = component.get('v.selectedSearchType');
            	if(selectedSearchType == $A.get("$Label.c.Cognition_ConsLabel")){
            	    //helper.consignmentDetailsHelper(component, event, helper);
            	    console.log(' selectedSearchType ',selectedSearchType);
                    helper.helperPromise(component, helper, helper.doAsyncConsignmentDetails).then($A.getCallback(function (result) {
                            console.log(' selectedSearchType doAsyncConsignmentDetails success',selectedSearchType);
                            helper.parseAsyncConsignmentDetails(component, result, helper);
                        })).catch($A.getCallback(function (result) {
                        console.log(' selectedSearchType doAsyncConsignmentDetails failed',selectedSearchType);
                            helper.parseAsyncConsignmentDetails(component, result, helper);
                        }));
            	}else{
            	    //helper.pickupDetailsHelper(component, event, helper);
            	    console.log(' async 55');
                    helper.helperPromise(component, helper, helper.doAsyncPickupDetails).then($A.getCallback(function (result) {
                            console.log(' async 66');
                            helper.parseAsyncPickupDetails(component, result, helper);
                        })).catch($A.getCallback(function (result) {
                            console.log(' async 77');
                            helper.parseAsyncPickupDetails(component, result, helper);
                        }));
            	}
            }
        }
    },

    /**
     * Handles Automatic Refresh. Resets map and submits Query with
     * Customer Account and Depot.
     **/
    handleRefreshEvent : function (component, event, helper){
        //CognitionUtil.startTimer();
        console.log('Recieved RefreshEvent-');        
        helper.resetGoogleMap(component, helper);
        helper.submitQueryHelper(component, event, helper);                        
    },


    changeSearchType : function(component,event,helper){
        component.set('v.conSummary','');
		component.set('v.conNumber','');
		
		var selectedSearchType = component.get('v.selectedSearchType');
		if(selectedSearchType == $A.get("$Label.c.Cognition_ConsLabel")){
		    component.set('v.searchTitle','Consignment Number');
		}else{
		    component.set('v.searchTitle','Pickup Booking Number');
		}
    },

})