({
    fetchPickListValues : function(cmp, sobjectName, fieldApiName, valuesOrApiNames, setAttribute) {
        var action = cmp.get("c.getPickListValuesBoth");
        action.setParams({ 
            sObjectApiName: sobjectName,
            fieldApiName: fieldApiName,
            valuesOrApiNames: valuesOrApiNames
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var returnObj = JSON.parse((JSON.stringify(response.getReturnValue())));
                cmp.set(setAttribute, this.buildListFromMap(cmp, returnObj, valuesOrApiNames)); 
                
            } else if (response.getState() == "INCOMPLETE") {
                console.log("Incomplete request");
            } else if (response.getState() == "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);
    },
    
    
    buildListFromMap: function (cmp, inputMap, valuesOrApiNames) {
        var items = [];
        Object.keys(inputMap).forEach(function(key) {
            if( inputMap[key]!='Discovery' && inputMap[key]!='Operational Details'){
                if(valuesOrApiNames == null || valuesOrApiNames == 'values'){
                    var item = {
                        "label": inputMap[key],
                        "value": inputMap[key],
                    }; 
                } else {
                    var item = {
                        "label": key,
                        "value": key,
                    };
                }
                items.push(item);
            }
        });
        items.sort(function(a, b){
            var x = a.label.toLowerCase();
            var y = b.label.toLowerCase();
            if (x < y) {return -1;}
            if (x > y) {return 1;}
            return 0;
        }); 
        return items;
    },
    asArray: function(x) {
        if (Array.isArray(x)) return x;
        else return x ? [x] : [];
    }, 
})