({
    // Fetch the attached files from the Apex controller
    getRecordList: function(component) {
        var action = component.get('c.getContentDocs');

        //Set up params for the Apex controller, in this case taskId
        action.setParams({
            "taskId":component.get('v.taskId')
        });

        // Set up the callback
        var self = this;
        action.setCallback(this, function(response)  {
            if(response.getState() == 'SUCCESS'){
                var files = response.getReturnValue();
                component.set('v.fileList', files);
                if(files.length >0){
                    component.set('v.hasFiles', true);
                }
            } else{
                var errors = response.getError();
                console.log('Error at loading attachments: '+errors[0].message);
            }
        });
        $A.enqueueAction(action);
    }

})