({

    showModal: function(component, event) {
        component.set('v.isShowModal', true);
    },

    onClose: function(component, event, helper) {
        component.set('v.isShowModal', false);
        var appEvent = $A.get("e.c:AuraModalEvent");
        appEvent.setParams({type: 'OK', modalKey: component.get('v.modalKey')});
        appEvent.fire();
    },

    onCancel: function(component, event, helper) {
        component.set('v.isShowModal', false);
        var appEvent = $A.get("e.c:AuraModalEvent");
        appEvent.setParams({type: 'Cancel', modalKey: component.get('v.modalKey')});
        appEvent.fire();
    }
});