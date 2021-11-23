({    
    onchange : function(cmp, event, helper) {
        var lastValue = cmp.get('v.lastValue');
        var newValue = cmp.get('v.value');

        if ((lastValue || newValue) && lastValue !== newValue) {
            cmp.set('v.lastValue', newValue);
            var changeEvent = cmp.getEvent("chasGenComponentEvent");
                
            changeEvent.setParams({
                name: cmp.get('v.name'),
                value: cmp.get('v.value'),
            });

            changeEvent.fire();
        }
    }
})