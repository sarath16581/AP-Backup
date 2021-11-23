({
    /**
     *   Initialise
     *
     */
    onInit: function(component, event, helper) {
        component.set("v.consignmentNumber", "");
    },

    /**
     * on click of search button
     *
     */
    onSearchBttnClick: function(component, event, helper) {
        helper.handleSearchButtonClick(component, helper);
    },

    /**
    * to refresh the search result
    *
    */
    onSearchRefresh: function(component, event, helper) {
        helper.handleSearchRefresh(component, helper);
    }
})