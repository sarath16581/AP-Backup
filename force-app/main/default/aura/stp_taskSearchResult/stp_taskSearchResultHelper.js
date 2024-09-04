({
    /**
     *   Create Columns array from data object and populate data grid
     *
     */
    populateDataTable: function(component, rslt) {
        if (rslt) {
            var rowsData = rslt.rowData;
			var fieldsToSort = ["CaseObject__r.Calc_Case_Consignment__c","CaseObject__r.Priority","TaskUpdate__c"];
            //setting
            component.set("v.dataList", rowsData);
            console.log('1.stp_taskSearchResultHelper rowsData.length =' +rowsData.length);
			rowsData.map(function(element){ 
				if(element.CreatedDate) {
					var date = new Date(element.CreatedDate);			 
					element.CreatedDate = $A.localizationService.formatDateTime(date);
				}
			});

            var columnsData = rslt.columnData;

            //Pagination- No of rows displayed based on the page size attribute, default set as 20 rows
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

            columnsData.unshift({
                label: 'View',
                type: 'button',
                initialWidth: 150,
                typeAttributes: {
                    label: 'View Details',
                    name: 'view_detail',
                    title: 'Click to View Details',
                    iconName: 'utility:preview',
                    variant: 'brand'
                }
            });

			columnsData.map( function(element){
				if(fieldsToSort.includes(element.fieldName)) {
					element.sortable = true;
				}
			});

            component.set('v.columns',  columnsData);
            component.set('v.data', PagList);
        }
    },


	// myFunction: function(value, index, array) {
	// 	return value.fieldName == 'CaseObject__r.Enquiry_Type__c'
	// }
    /**
     *   Raise event to display Detail data
     *
     */
    handleViewDetails: function(component, row) {
        var notify = component.getEvent('notifyCompEvent');
        var consignmentNumber = row["CaseObject__r.Calc_Case_Consignment__c"];
        var consignmentId = row["CaseObject__r.ArticleTest__c"];

        var params = {
            notification: 'VIEW_DETAIL_CLICKED',
            payload: {
                taskId: row.Id,
                consignmentId: consignmentId,
                consignmentNumber: consignmentNumber
            }
        };
        notify.setParams(params);
        notify.fire();
    },

	sortData: function(component, fieldName, sortDirection) {
		var data = component.get("v.data");
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;          
        data.sort(function(a,b){
                var a = key(a) ? key(a) : '';
                var b = key(b) ? key(b) : '';
                return reverse * ((a>b) - (b>a));
            });
        component.set("v.data",data);
	},

    /**
    *   Function to acknowledge the tasks based on taskId.
    */
    acknowledgeTasksList: function(component, event, helper) {
        var selectedRowsList = component.get('v.selectedRows');
        var action = component.get("c.acknowledgeTasksList");
        action.setParams({
            "tasks": JSON.stringify(selectedRowsList)
        });
        action.setCallback(this, function(response) {
            var result = response.getReturnValue();

            if (response.getState() == "SUCCESS") {
                helper.showMyToast(component, helper, 'success', result);
                //refresh the tasks list once bulk acknowledged
                /*var notify = component.getEvent('notifyCompEvent');
                notify.setParams({
                    notification: 'REFRESH_SEARCH_RESULTS',
                    payload: {}
                });
                notify.fire();*/
                component.set('v.selectedRows', []);
                var notify1 = component.getEvent('notifyCompEvent');
                notify1.setParams({
                    notification: 'ACKNOWLEDGE_CLICKED',
                    payload: {}
                });
                notify1.fire();

            } else if (response.getState() == "ERROR") {
                console.log('ERROR:  stp_taskSearchResultHelper : acknowledgeTasksList()', response);
                var errors = response.getError();
                // notify if error
                if (errors) {
                    console.log(errors[0].message);
                    helper.showMyToast(component, helper, 'error', errors[0].message);
                } else {
                    console.log(errors[0].message);
                    helper.showMyToast(component, helper, 'error', 'Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
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