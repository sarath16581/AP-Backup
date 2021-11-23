({
    invoke: function (component, event, helper) {
        var navService = component.find('navService');
        var recordId = component.get('v.recordId');
        var objectName = component.get('v.sObject');
        var mode = component.get('v.mode').toLowerCase();
        
        // Use workspace API to check if the lightning app is consoled-based or standard navigation
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response){
            // App is console-based navigation
            if(response === true){
                // Open the Record page in a new workspace tab in View mode first so that it persists after the Edit Modal closes
                var workspaceAPI = component.find("workspace");
                workspaceAPI.openTab({
                    url: '/lightning/r/'+objectName+'/'+recordId+'/view',
                    focus: true
                });
                // Open record page in edit mode, as a pop-up modal
                if (mode == 'edit') {
                    var workspaceAPI = component.find("workspace");
                    workspaceAPI.openTab({
                        url: '/lightning/r/'+objectName+'/'+recordId+'/edit',
                        focus: true
                    });
                }
            }
            // App is standard navigation
            else{
                // Navigate to relevant tab, and open the Record page in View mode first so that it persists after the Edit Modal closes
                var pageReference = {
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: recordId,
                        objectApiName: objectName,
                        actionName: 'view'
                    }
                };
                navService.navigate(pageReference);      
                // open record page in edit mode, as a pop-up modal
                if (mode == 'edit') {
                     var pageReference = {
                         type: 'standard__recordPage',
                         attributes: {
                             recordId: recordId,
                             objectApiName: objectName,
                             actionName: mode
                         },
                         state: {
                             navigationLocation: 'DETAIL',
                             backgroundContext: '/lightning/r/'+objectName+'/'+recordId+'/view'
                         }  
                         
                     };
                     navService.navigate(pageReference);       
                 }
            }
        }).catch(function(error){
            console.log('has error');
            console.log(error);
        })
         
    }        
})