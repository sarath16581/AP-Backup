({
    doInit : function(component, event, helper) {
        var record = component.get("v.record");
        var field = component.get("v.field");
        if(record && record.hasOwnProperty('Id')){
            var val = record[field.fieldPath];
            component.set("v.cellValue", val );
            if(field.type == 'string')
                component.set("v.isTextField", true);
            else if(field.type == 'textarea'){ 
                component.set("v.isTextArea", true);
            }
            else if(field.type == 'date'){
                component.set("v.isDateField", true);
            } else if(field.type == 'datetime'){
                component.set("v.isDateTimeField", true);
            } else if(field.type == 'currency'){
                component.set("v.isCurrencyField", true);
            } else if(field.type == 'picklist'){
                component.set("v.isPicklistField", true);
            } else {
                component.set("v.isTextField", true);
            }
//            else if(field.type == 'REFERENCE'){
//                component.set("v.isReferenceField", true);
//                var relationShipName = '';
//                if(field.name.indexOf('__c') == -1) {
//                    relationShipName = field.name.substring(0, field.name.indexOf('Id'));
//                }
//                else {
//                    relationShipName = field.name.substring(0, field.name.indexOf('__c')) + '__r';
//                }
//                component.set("v.cellLabel", record[relationShipName].Name);
//            }
        }
    }
})