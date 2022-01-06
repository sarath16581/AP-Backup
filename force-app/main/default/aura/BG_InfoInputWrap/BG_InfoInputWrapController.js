({
	doInit : function(cmp, event, helper) {
		var value = cmp.get('v.value');
        var defaultValue = cmp.get('v.default');
        if (!value && defaultValue) {
            cmp.set('v.value', defaultValue);
        }

        // [TS] IE bug with placeholder text on date input fields
        var type = cmp.get('v.type');
        var ua = window.navigator.userAgent;
        var is_ie = /MSIE|Trident/.test(ua);

        if ( is_ie && (type === 'date' || type === 'datetime' || type === 'time') ) {
            cmp.set('v.placeholder', '');
        }
    },
    
    reportValidity : function(cmp, event, helper) {
        cmp.find('field').reportValidity();
    },

    checkValidity : function(cmp, event, helper) {
        return cmp.find('field').checkValidity();
    },

    onchange : function(cmp, event, helper) {
        $A.enqueueAction(cmp.get('v.onchange'));
    },
    onchangeCheckRelatedQuestion : function(cmp, event, helper) {
        $A.enqueueAction(cmp.get('v.onchangeRelatedQuestionCheck'));
    },
    onfocus: function(cmp, event, helper) {
    },
    onchangeDualList: function(cmp, event, helper) {
        var selectedOptionValue = event.getParam("value");
        cmp.set("v.value",selectedOptionValue);
        //console.log('v.selectedValues===='+cmp.get("v.selectedValues"));
        $A.enqueueAction(cmp.get('v.onchangeRelatedQuestionCheck'));
    },
    onchangeCheckBox:function(cmp, event, helper){
        var selectedOptionValue = new Object();
        var tempVar = new Object();
        selectedOptionValue = event.getParam("value");        

        if(Object.keys(selectedOptionValue).length === 0){
            cmp.set("v.value",''); 
        }else{
            cmp.set("v.value",selectedOptionValue); 
        } 
        $A.enqueueAction(cmp.get('v.onchangeRelatedQuestionCheck'));
    },
    onchangeRadioGroup:function(cmp, event, helper){
        var selectedOptionValue = event.getParam("value");
         cmp.set("v.value",selectedOptionValue);
        $A.enqueueAction(cmp.get('v.onchangeRelatedQuestionCheck'));
    },
     onclick : function(cmp, event, helper) {
        // $A.enqueueAction(cmp.get('v.onclick'));
    },

    doNothing : function(cmp, event, helper) {
    },
    checkRelatedQuestion : function(cmp, event, helper) {        
        var GenEvent = cmp.getEvent("relatedQuestionEvent");
        GenEvent.setParam("ParentQuestionUniqueKey", cmp.get('v.uniqueKey'));
        GenEvent.setParam("selectedAnswer", cmp.get('v.value'));
        GenEvent.fire();
        console.log('event fired');
    },
	/*handleChange : function(component, event, helper) {
        console.log('handleChange..........'+component.get("v.name"));
        console.log('handleChange..........='+component.find('field'));
        if(component.get("v.validate")){
             var allValid = component.find('field').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        }
		//component.set("v.validate", false);
	}*/
})