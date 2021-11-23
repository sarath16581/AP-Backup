({
    /**
    *   Called when component is initialised.
    */
    doInit  :   function(cmp,evt,hlpr){
        var caseId = cmp.get("v.caseID");
        if(!( caseId === '')) {

            var callBack = function(resp){
                var disputeObj = resp;
                cmp.set("v.disputes",disputeObj);
            };
            var errCallBack = function(resp){
                alert('Error:' + resp);
            };
            var loader = cmp.find('loader');
            var params = {caseID: caseId};

            AP_LIGHTNING_UTILS.invokeController(cmp, "getDisputedconNotesFromCaseId", params, callBack, errCallBack, false, loader);
        }
    },
    /**
    *   Called when View Button is clicked
    */
    onPreview   : function(cmp,evt,hlpr) {
       if( sforce != null){
         var caseId = cmp.get("v.caseID");
         var caseNumber = cmp.get("v.caseNumber");
         var openSubtab = function openSubtab(result) {
                 //Now that we have the primary tab ID, we can open a new subtab in it
                 var primaryTabId = result.id;
                     sforce.console.openSubtab(primaryTabId , '/apex/ConsignmentAttachment?id=' + caseId + '&casenumber=' + caseNumber , true,
                         caseNumber + ' Image Detail', null, openSuccess, 'salesforceSubtab');
                 };
                 var openSuccess = function openSuccess(result) {
                     //Report whether we succeeded in opening the subtab
                     if (result.success == true) {
                     } else {
                        // console.log('subtab cannot be opened');
                     }
                 };
                 sforce.console.getEnclosingPrimaryTabId(openSubtab);
       } else {
            var workspaceAPI = cmp.find("workspace");
            workspaceAPI.isConsoleNavigation().then(function(resp) {
                            // implement lightning console version here.
                        })
                        .catch(function(resp){
                            console.log(error);
                        });
       }
    }
})