({
    updateValue : function(cmp, event, helper) {
        cmp.set('v.value', event.target.value);
    },
})

// ({
//     onChangeFunction : function(component, event, helper) {

//         //-- Getting the text area details
//         var complaintDetails = event.getSource().get("v.value");
//         if(component.get('v.validateEmptyTxtArea') == true){
//             console.log('pppppp complaintDetails==='+complaintDetails);
//             //-- validating of Onchange if enter some data or empty
//             helper.validate(component, event, helper);
//         }
        
//         //-- Firing an Event if data is not empty to bind the change in Parent component
//         if(complaintDetails !=null && complaintDetails.trim().length > 0){
//             var compEvent = component.getEvent("chasGenComponentEvent");
//             compEvent.setParam("name", 'complaintDetails');
//             compEvent.setParam("value", complaintDetails);
//             compEvent.fire();
//         }else{
//             var compEvent = component.getEvent("chasGenComponentEvent");
//             compEvent.setParam("name", 'complaintDetails');
//             compEvent.setParam("value", null);
//             compEvent.fire();
//         }
        
//     },
    
//     itemsChange: function(component, event, helper) {

//         if(component.get('v.validateEmptyTxtArea') == true){
//             //-- validating  if enter some data or empty
//             helper.validate(component, event, helper);
//         }
        
//     }
// })