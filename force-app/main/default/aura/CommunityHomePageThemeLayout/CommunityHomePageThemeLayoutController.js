({
	handleClick : function(component, event, helper) {
        // access the elements in the nav bar and toggle between search and the other compnents
	    // search expand when click on search icon
	    var expandedSearch = component.find("cpsearch-expanded");
        // navigator div content
        var cpnavbar = component.find("cpnav");
        // profile in the navigator bar
        var cpprofilenav = component.find("cpprofilenav");
        // the search icon
        var collapsedSearch = component.find("cpsearch-collapsed");

        var profiletable = component.find("profiletable");


        // toggle the visibility when click on search icon and the cancel icon
        $A.util.toggleClass(expandedSearch, "slds-hide");
        $A.util.toggleClass(cpnavbar, "slds-hide");
        $A.util.toggleClass(cpprofilenav, "slds-hide");
        $A.util.toggleClass(collapsedSearch, "slds-hide");
        $A.util.toggleClass(profiletable, "expanded-table");
        return;
	},

    // temp function for investigation purpose
    handleOnBlur : function(component, event, helper) {
        alert('here');
    },

    init: function(component) {
        var device = $A.get("$Browser.formFactor");
        alert("You are using a " + device);
    }

})