/**
 * Created by hasantha on 16/4/19.
 */
({
    /**
     * show message method to invoke to display the message,
     * this will display 3 typoes of messages, Error Info and Success
     *
     * @param component
     * @param event
     * @param helper
     */
    showMessage : function(component, event, helper) {
        var params = event.getParam('arguments');
        var message = params.message;
        var type = params.type;

        // initialise all the messages
        component.set('v.success',false);
        component.set('v.error',false);
        component.set('v.info',false);

        // based on the type recived, the message with the type will be displayed
        if(type == 'success'){
            component.set('v.success',true);
        } else if(type == 'error') {
            component.set('v.error',true);
        } else if(type == 'info') {
            component.set('v.info',true);
        }

        component.set('v.message',message);
        component.set('v.type',type);
    },
})