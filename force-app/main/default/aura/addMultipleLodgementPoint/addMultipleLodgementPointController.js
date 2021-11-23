/*****************************************************************************************
@description:   Javascript controller of the Lodgement Point Search Aura Component
                Make Calls to LWC Component to load the Lodgement point data & 
                and Apex Controller to Update DML on the DSR record
@author: Seth Heang
History:
-----------------------------------------------------------------------------------------
15/03/2021   	seth.heang@auspost.com.au			                created
*****************************************************************************************/
({
    /**
     * @decription Receive the selected record from LWC component's search functionality
     *             And Update to the component-level variable for data display in the table
     * @component  Update the component-level variable, recieved from the LWC component
     * @event      receive the selected recorded via custom event passing from LWC component
     * @helper     n/a
     *  */ 
    selectedRecords : function(component, event, helper) {
        var selectRecName = event.getParam('selRecords');
        if(selectRecName != undefined) {
            component.set("v.selectedRecords", selectRecName);
        }
    },
    /**
     * @decription Call helper method to perform DML update on the selected lodgement point records after Clicking 'Save' button
     *             The helper method will call Apex Controller to perform the DML update operation
     * @component  Pass component data to the helper 
     * @helper     call helper method which contains logic to perform DML update on selected record
     * @event      n/a
     *  */
    addMultiLodgementPoints : function(component, event, helper) {
        helper.updateLodgementPoints(component);
    }
})