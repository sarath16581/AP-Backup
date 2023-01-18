({    
    
    invoke : function(component, event, helper) {
   // Get the Visualforce Page and its attributes
   var pageName = component.get("v.pageName");
   var proposalId = component.get("v.proposalId");
   
   // Get the Lightning event that opens a record in a new tab
   var redirect = $A.get("e.force:navigateToURL");
   
   // Pass the record ID to the event
   redirect.setParams({
      "url" : "/apex/" + pageName  + "?proposalId=" + proposalId
   });
        
   // Open the record
   redirect.fire();
	}
})