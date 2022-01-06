({

    doInit: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
       
    },
    closeComp: function(component,event,helper){
        $A.get("e.force:closeQuickAction").fire();
        window.location.reload();
    }
    

 })