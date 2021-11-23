({
    fetchQualificationsList : function(cmp) {
       cmp.set('v.loaded', false);
       var action = cmp.get('c.getQualificationsList');
       action.setParams({ "recordId" : cmp.get("v.recordId")});
       action.setCallback(this, function(response) {
           if (response.getState() == "SUCCESS") {
             
               cmp.set("v.qualificationList", response.getReturnValue());
               cmp.set('v.loaded', true);
           }
           else if (response.getState() == "INCOMPLETE") {
               console.log("Response Incomplete");
           }else if (response.getState() == "ERROR") {
               var errors = response.getError();
               if (errors) {
                   if (errors[0] && errors[0].message) {
                       console.log("Error message: " + errors[0].message);
                   }
               } else {
                   console.log("Unknown error");
               }
           }
       });
       $A.enqueueAction(action);
   },
})