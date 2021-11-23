({
    /** This is to set Modal size
    *   expected values for v.size is 'large' and 'medium'
    *   default value is medium , no need to explicitly mention it.
    */
	onInit: function(component, event) {
        var modalSize = component.get('v.size');
        console.log(modalSize);
        if(modalSize ==='large'){
            $A.util.removeClass(component.find("modal-container-1"),'slds-modal_medium ');
            $A.util.addClass(component.find("modal-container-1"),'slds-modal_large');
        }
    },


    /** on Close , handle this event to process on Close actions, If needed
    */
    onClose: function(component, event, helper) {
        component.set('v.showModal', false);
        var modalEvent = component.getEvent('modalEvent');
        var modal = component.get('v.modalId');
        modalEvent.setParams({
            type: 'CLOSE',
            modalId: modal
            });
        modalEvent.fire();
    }
})