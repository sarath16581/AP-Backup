({
    onInit: function(component, event, helper) {
        component.set("v.resultMsg", '');
        component.set("v.showSearchResultMsg", false);
    },

    /**
     *   Handle click of data table row
     *
     */
    onNotificationComp: function(component, event, helper) {
        var payload = event.getParam("payload");
        var notification = event.getParam("notification");
        if (notification === 'SEARCH_BUTTON_CLICKED') {
            console.log('1.stp_tasksearchResult : search button clicked');
        }
    },

    /**
    *  When displaying My Finished task,
    *  Hide Acknowledge button
    *
    */
    onMyFinishedTasksDisplay:function(component,event, helper){
        var acknowledgeBtn = component.find("btnAcknowledge");
        if (acknowledgeBtn) {
            $A.util.addClass(acknowledgeBtn, 'slds-hide');
        }
    },

    /**
     *  Populate data into component
     *  Reset  attributes
     *
     */
    onPopulateData: function(component, event, helper) {

        var resultTable = component.find("searchResultTable");
        if(resultTable){
            var selectedRows = resultTable.get("v.selectedRows");
            selectedRows.length = 0;
            resultTable.set("v.selectedRows", selectedRows);
        }
        component.set("v.resultMsg", '');
        component.set("v.showSearchResultMsg", false);

        var params = event.getParam('arguments');
        if (params) {
            var payloadVal = params.payload;

            if (payloadVal.rowData.length > 0) {
                helper.populateDataTable(component, payloadVal);
            } else {
                component.set("v.showSearchResultMsg", true);
                component.set("v.resultMsg", 'No search results returned. Please refine your search.');
            }
        }
    },

    /**
    *   Task search  result - setting up pagination
    *   On click of 'Next' button
    *   to display the Next Items from the List
    */
    next: function (component, event, helper) {
        var sObjectList = component.get("v.dataList");
        var end = component.get("v.lastRec");
        var start = component.get("v.startRec");
        var pageSize = component.get("v.pageSize");
        var currentPageNumber = component.get("v.currentPageNumber");
        var totalRecs = component.get("v.totalRecords");
        var PagList = [];
        var counter = 0;
        for ( var i = end; i < end + pageSize ; i++ ) {
            if ( sObjectList.length > i ) {
                PagList.push(sObjectList[i]);
            }
            counter ++ ;
        }
        var last = Math.min((end + counter), totalRecs );
        var range =( start+counter) +'-'+last;
        currentPageNumber++
        component.set("v.currentRange", range);
        component.set("v.currentPageNumber",currentPageNumber);
        component.set("v.startRec", start+counter);
        component.set("v.lastRec", end + counter);
        component.set("v.data", PagList);
    },

    /**
    *   Task search  result - setting up pagination
    *   On click of 'Previous' button
    *   to display the Previous Items from the List
    *
    */
    previous: function (component, event, helper) {
        var sObjectList = component.get("v.dataList");
        var end = component.get("v.lastRec");
        var start = component.get("v.startRec");
        var pageSize = component.get("v.pageSize");
        var currentPageNumber = component.get("v.currentPageNumber");
        var totalRecs = component.get("v.totalRecords")
        var PagList = [];
        var counter = 0;
        for ( var i= start-pageSize; i < start ; i++ ) {
            if ( i > -1 ) {
                PagList.push(sObjectList[i]);
                counter ++;
            } else {
                start++;
            }
        }
        var last = Math.min((end - counter), totalRecs );
        var range =( start-counter) +'-'+last;
        currentPageNumber--
        component.set("v.currentRange", range);
        component.set("v.currentPageNumber",currentPageNumber);
        component.set("v.startRec", start - counter);
        component.set("v.lastRec", end - counter);
        component.set("v.data", PagList);
    },

    /**
     *  Handle click of data table row
     *  shows the details of the task
     */
    onRowActionClicked: function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'view_detail':
            helper.handleViewDetails(component, row);
            break;
        }
    },

	onDoSorting: function(component, event, helper) {
		console.log('This sorting function is getting called');
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
		component.set("v.sortBy", fieldName);
		component.set("v.sortDirection", sortDirection);
		console.log('sortBy'+fieldName);
		console.log('sortDirection'+sortDirection);
		helper.sortData(component, fieldName, sortDirection);
    },
    /**
    *   Handle when check box on data table is clicked
    *   Select the rows clicked
    */
    onRowSelection: function(component, event, helper) {
        component.set('v.selectedRows', []);
        var selectedRowsList = event.getParam('selectedRows');
        component.set('v.selectedRows', selectedRowsList);
    },

    /**
    *   Function to acknowledge the tasks based on taskId.
    *   Change owner to Partner portal user
    */
    handleOnAcknowledge: function(component, event, helper) {
        helper.acknowledgeTasksList(component, event, helper);
    }
})