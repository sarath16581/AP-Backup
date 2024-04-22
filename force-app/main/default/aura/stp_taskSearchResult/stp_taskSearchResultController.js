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
	sortData: function(component,event,helper){
		console.log('sorting invoked');
		console.log(JSON.stringify(event));
		console.log(event.Ep.fieldName);
		console.log(event.Ep.sortDirection);
		let sortDirection = event.Ep.sortDirection;
		let fieldName = event.Ep.fieldName;
		//var payload = event.getParam("payload");
		console.log(JSON.stringify(component.get("v.dataList")));
		//toBeSorted(event.Ep.fieldName,event.Ep.sortDirection);
		var data = component.get("v.dataList");
		var reverse = sortDirection !== 'asc';
		data.sort(function(a, b) {
            var aVal = a[fieldName] || '';
            var bVal = b[fieldName] || '';

            // For numeric fields
            if (!isNaN(aVal) && !isNaN(bVal)) {
                return reverse ? aVal - bVal : bVal - aVal;
            }

            // For text fields
            if (typeof aVal === 'string' && typeof bVal === 'string') {
                return reverse ? bVal.localeCompare(aVal) : aVal.localeCompare(bVal);
            }

            // For other types, just return 0 to maintain the order
            return 0;
        });

        // Update the data with sorted data
        component.set('v.dataList', data);
		console.log(component.get('v.dataList'));
		var rowsData = component.get('v.dataList');
		var pageSize = component.get("v.pageSize");
            component.set("v.totalRecords", rowsData.length);
            component.set("v.startRec", 1);
            component.set("v.currentPageNumber", 1);
            component.set("v.lastRec", pageSize);
            var PagList = [];
            for ( var i=0; i< pageSize; i++ ) {
                if ( rowsData.length> i ){
                    PagList.push(rowsData[i]);
                }
            }

            // setting up the record range
            if(rowsData.length != 1){
                var last = Math.min((pageSize), rowsData.length );
                var range = '1 - '+last;
                component.set('v.currentRange', range);
            } else {
                var range = rowsData.length;
                component.set("v.currentRange", range);
            }
            component.set('v.data', PagList);
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