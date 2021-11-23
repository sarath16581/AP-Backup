/**
 * Created by hasantha on 17/5/19.
 */
({
    doInit : function(component, event, helper) {
        var value = component.get('v.value');
        if(component.get('v.value') != 'undefined' && component.get('v.value') != '') {
            var paramComponent = component.get('v.paramComponent');
            paramComponent.set('v.'+component.get('v.attributeName'),component.get('v.value'));
            return;
        }

    },

})