({
	helperMethod : function() {
		
	},
    
    getLocalList: function(component) {
        //call apex class method
        var action = component.get('c.uName');
            action.setCallback(this,function(response){
            //store state of response
           var state = response.getState();
                component.set('v.objClassController', response.getReturnValue());
               if (state === "SUCCESS") {
                    //set response value in objClassController attribute on component
                    component.set('v.objClassController', response.getReturnValue());
               }
           });
          $A.enqueueAction(action);
    },
})