({
    /**
     *   Initialise
     *
     */
    onInit: function(component, event, helper) {
        // inject the main waiting queue component to the child components,
        // in this way we can cover the entire screen at once rather than individual child components
        var loader = component.find('loader');
        component.set("v.mainLoadingSpinner", [loader]);
        // hiding all the console logs, not in dev
        //console.log = function() {}

    },

    /**
     *  notifications router,
     *  this handler is to communicate between components, child components will notify the parent with the notification a
     *  then this handler act as a router.
     *  eg: when we need to refresh the search result section once the task is updated from the details section,
     *  the notification should raised to the parent and the target action will be triggered inside the router.
     *
     **/
    onNotifyCompEvent: function(component, event, helper) {
        var notification = event.getParam('notification');
        var payload = event.getParam('payload');
        var accordionSrchDtl = component.find("accordianSearchDetail");
        var accordionSelectedRslt = component.find("accordianSelectedResult");

        // on click of the search button, reset the details section and perdfor the search
        if (notification === 'SEARCH_BUTTON_CLICKED') {
            var accordianSearchDetail = component.find('accordianSearchDetailVisibility');
            if (accordianSearchDetail) {
                $A.util.removeClass(accordianSearchDetail, 'hideIfSearchNotClicked');
                component.set('v.showResult', false);
                $A.util.addClass(accordianSelectedResult, 'hideIfViewDetailsNotClicked');
            }
            accordionSrchDtl.set('v.activeSectionName', 'searchResult');

            // perform the search by accessing the search details component
            var searchDetailCmp = component.find('searchDetailCmp');
            searchDetailCmp.populateData(payload);

        // on click of the detail button, populate, show/hide details section
        } else if (notification === 'VIEW_DETAIL_CLICKED') {

            component.set('v.showResult', true);

            var accordianSelectedResult = component.find('accordianSelectedResultVisibility');
            if (accordianSelectedResult) {
                $A.util.removeClass(accordianSelectedResult, 'hideIfViewDetailsNotClicked');
            }
            accordionSelectedRslt.set('v.activeSectionName', 'selectedResult');

            // populate display the task details section
            var taskDetail = component.find("taskDetail");
            taskDetail.populateData(payload);

            // populate and display the scan events section
            var scanEvents = component.find("scanEvents");
            scanEvents.populateData(payload);

        } else if (notification === 'SEARCH_FINISHED_TASK') {
            component.set('v.isFinishedTask',true);

        } else if (notification === 'POPULATE_SEARCH_RESULTS') {
            // called from handleSearchRefresh()
            var searchDetailCmp = component.find('searchDetailCmp');
            searchDetailCmp.populateData(payload);

        } else if (notification === 'REFRESH_SEARCH_RESULTS_AND_TASK_DETAILS') {
            // called from acknowledgeTasksList(), acknowledgeTaskDetails() methods
            // refresh the search when the records are updated
            var searchComponent = component.find('searchCmp');
            searchComponent.refreshSearch();
            // refresh when the task details are updated, especially when the "Acknowledge" button for detail section is clicked
            var taskDetail = component.find("taskDetail");
            taskDetail.populateData(payload);

        }  else if (notification === 'ACKNOWLEDGE_CLICKED') {
            var searchComponent = component.find('searchCmp');
            // refresh the search result table.
            searchComponent.refreshSearch();
            // called from acknowledgeTasksList(), acknowledgeTaskDetails() methods
            var accordianSearchDetail = component.find('accordianSearchDetailVisibility');

            if (accordianSearchDetail) {
                $A.util.removeClass(accordianSearchDetail, 'hideIfSearchNotClicked');
                component.set('v.showResult', false);
                $A.util.addClass(accordianSelectedResult, 'hideIfViewDetailsNotClicked');
            }

            accordionSrchDtl.set('v.activeSectionName', 'searchResult');

        }
    }
})