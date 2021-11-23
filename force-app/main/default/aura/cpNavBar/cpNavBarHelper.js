({
	fetchMenuItems : function(component) {
		var action = component.get("c.getMenuItems");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = response.getReturnValue();
                
                var menuitems = [];
                var fmenuitems = result;
                var baseURL = $A.get("$Site").siteUrlPrefix;

                menuitems.push({label: 'Home', target: baseURL});
                
                for (var index in fmenuitems) {
                    var item = {};
                    item.label = fmenuitems[index].Label;
                    
                    var itemType = fmenuitems[index].Type;
                    var trg = baseURL + fmenuitems[index].Target;
                    
                    if (itemType == 'SalesforceObject' && fmenuitems[index].Target == 'CollaborationGroup')
                        trg = baseURL + '/group/' + fmenuitems[index].Target + '/' + fmenuitems[index].DefaultListViewId;
                      
                    item.target = trg;

                    //console.log('Type ' + fmenuitems[index].Type);
                    //console.log('label ' + fmenuitems[index].Label);
                    //console.log('target ' + trg);
                    
                    menuitems.push(item);
                } 
                component.set('v.menu', menuitems);
            }
        });
        $A.enqueueAction(action);
	}
})