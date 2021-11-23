({
    // Fetch the  files List
    doInit: function(component, event, helper) {
        // Fetch the related files
        helper.getRecordList(component);
    },

    // after upload query the new list again
    handleUploadFinished: function (component, event, helper) {
       alert('File attached successfully');
       // Load the refreshed List
       helper.getRecordList(component);
    },

    /* preview the file attached
    * param : User Context
    * param: RecId
    * */
    previewAttachment : function(component, event, helper) {
        var recId = event.target.id;
        var context = component.get("v.context");
        console.log('User Theme  ::  '+ context);
        console.log('recId  ::  '+ recId);
        $A.get('e.lightning:openFiles').fire({
            recordIds:[recId]
        });
    },
    openRelatedList: function(component, _event){
       var relatedListEvent = $A.get("e.force:navigateToRelatedList");
       relatedListEvent.setParams({
          "relatedListId": "Files",
          "parentRecordId": component.get("v.taskId")
       });
       relatedListEvent.fire();
    }

})