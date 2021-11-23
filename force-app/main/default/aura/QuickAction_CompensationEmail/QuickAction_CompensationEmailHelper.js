({
    /**
     * main method for sending compensation email
     * @param {*} component 
     * @param {*} event 
     */
    sendCompensationEmail : function(component, event)
    {
        // start spinning
        component.set('v.spin', true);

        // generate token action, this method will also invoke the email sending method
        let generateTokenAction = component.get('c.updateToken');

        // set params
        generateTokenAction.setParams({
            recordId : component.get('v.recordId'),
            urlEncode : true,
            sendCompensationEmail : true,
            resetAttemps: true
        });
        // set call back
        generateTokenAction.setCallback(this, function(response)
        {
            let state = response.getState();

            component.set('v.spin', false);

            if (state === 'SUCCESS')
            {
                this.toast('SUCCESS', 'Compensation email has been sent', 'success', 'sticky');
                this.refreshRecordPage();
            }
            else
            {   
                this.toastError(component, response.getError());
            }
            this.closeQuickAction();
        })

        // action enqueue
        $A.enqueueAction(generateTokenAction);
    },

    /**
     * 
     */
    closeQuickAction : function()
    {
        let action = $A.get("e.force:closeQuickAction");
        action.fire();
    },

    /**
     * 
     */
    refreshRecordPage : function()
    {
        $A.get('e.force:refreshView').fire()
    },

    /**
     * 
     * @param {*} title 
     * @param {*} message 
     * @param {*} type 
     * @param {*} mode 
     */
    toast : function(title, message, type, mode)
    {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title, message, type, mode
        });
        toastEvent.fire();
    },

    /**
     * 
     * @param {*} error 
     */
    toastError : function(component, error)
    {   
        this.toast('ERROR', this.getErrorMessage(error), 'error', 'sticky');
    },

    /**
     * parse the error object into text
     * @param {*} errors 
     * @returns 
     */
    getErrorMessage : function(errors)
    {
        let result = '';

        if ($A.util.isArray(errors))
        {
            errors.forEach(function(error)
            {
                // AuraHandledException message
                if (error.message)
                {
                    result += `AuraHandledException: ${error.message}. `
                }

                // page error message
                if (error.pageErrors && error.pageErrors.length > 0)
                {
                    error.pageErrors.forEach(function(pageError)
                    {
                        pageError.message && (result += `Page_Error: ${pageError.message} `);
                    })
                }

                // field error message
                if (error.fieldErrors && error.fieldErrors.length > 0)
                {
                    error.fieldErrors.forEach(function(fieldError)
                    {
                        fieldError.message && (result += `Field_Error: ${fieldError.message} `);
                    })
                }
            })
        }
        else
        {
            result = JSON.stringify(errors);
        }
        return result || JSON.stringify(errors);
    },
})