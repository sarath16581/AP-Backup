({
	getRecvETA : function(component,etaId,etaParam1) {
		var action = component.get('c.getReceiverETA');
        action.setParams({
            id : etaId,
            param1 : etaParam1
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state == "SUCCESS") {
                var etaResp = response.getReturnValue();
                component.set('v.ETAMsg',etaResp);
                console.log('getRecvETA : Get Receiver ETA SUCCESS-');
            }
        });
        $A.enqueueAction(action);                  
	}
})