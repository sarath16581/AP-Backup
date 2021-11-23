({
    /**
     *   Initialise the StartrackPortalEventsController
     *   do all of the first time event here
     **/
    onInit : function(component,event,helper){
        var vfBaseURL = "https://" + component.get("v.vfHost");
    },

    /**
     *   Toggle display of Summary
     **/
    toggleDisplayConsignmentSummary : function(component,event,helper){
        var displayConsignmentSummary = component.get('v.displayConsignmentSummary');
        var consignmentSummaryIcon = component.find('consignmentSummaryIcon');
        // toggle back
        displayConsignmentSummary = !displayConsignmentSummary;
        if(displayConsignmentSummary){
            consignmentSummaryIcon.set('v.iconName','utility:chevrondown');
            var datConsignmentSummary = component.get('v.datConsignmentSummary');
            if(!datConsignmentSummary){
                //get summary data from SF
                helper.displayConsignmentSummary(component,helper);
            }

        } else {
            consignmentSummaryIcon.set('v.iconName','utility:chevronright');
        }
         component.set('v.displayConsignmentSummary', displayConsignmentSummary);
    },

    /**
     *  Scan events on populate data actions
     * @param component
     * @param event
     * @param helper
     */
    onPopulateData : function(component,event,helper){

        var params = event.getParam('arguments');

        if (params) {
            // clear and hide the consignment summary toggle section
            var consignmentSummaryIcon = component.find('consignmentSummaryIcon');
            var displayConsignmentSummary = component.get('v.displayConsignmentSummary');
            consignmentSummaryIcon.set('v.iconName','utility:chevronright');
            component.set('v.displayConsignmentSummary', false);
            component.set('v.datConsignmentSummary', null);

            // access the method parameters sent
            var consignmentId = params.payload.consignmentId;
            var consignmentNumber = params.payload.consignmentNumber;

            // set the parameter
            component.set('v.consignmentId',consignmentId);
            component.set('v.consignmentNumber',consignmentNumber);

            // load the events messages
            helper.getConsignmentEventMessages(component, helper, event);
            helper.getEventMessagesByArticle(component, helper, event);

            // get PODs
            helper.getPOD(component, helper, event);

        }
    }
})