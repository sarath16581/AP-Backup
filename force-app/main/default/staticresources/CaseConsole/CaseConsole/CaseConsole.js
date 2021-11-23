var $jq = jQuery.noConflict();
var $jqmodalDialog = $jq('<div></div>')
       .html('Are you sure you want the subtab to be refreshed?')
       .dialog({
            autoOpen: false,
            title: 'Message:',
            resizable: false,
            width: 200,
            height: 150,
            autoResize: true,
            modal: true,
            draggable: false,
            dialogClass: "myDialogClass",
            position: { my: "center top", at: "center center", of: window },
            buttons: [
            	{
            		text: 'OK', 
            	 	click: function() {
            	 		$jq(this).dialog( "close" );
            	 		sforce.console.getFocusedSubtabId(showTabId);
            	 	}
            	}
            ]
});
function SetTabSavedChanges() {
    sforce.console.getFocusedSubtabId(setTabClean);
};
function SetTabUnsavedChanges() {
    sforce.console.getFocusedSubtabId(setTabDirty);
};
function setTabClean(result) {
    sforce.console.setTabUnsavedChanges(false, displayResult, result.id);
};
function setTabDirty(result) {
    sforce.console.setTabUnsavedChanges(true, displayResult, result.id);
};
 function displayResult(result) {
    if (result.success) {
         console.log('Tab status has been successfully updated');
     } else {
         console.log('Tab status couldn’t be updated');
     }
};
function RefreshTab() {
console.log('inside refresh tab');
$jqmodalDialog.dialog({appendTo:'body'});
	$jqmodalDialog.dialog('open');
	console.log('finish refreshing');
}
function RefreshPrimaryTabById() {
    console.log('inside fn');
    var isError = document.getElementsByClassName('alert alert-danger');
    console.log(isError);
    if(isError.length==0) {
        showSavedDialog();
        sforce.console.getFocusedSubtabId(showTabId);
        //$jqmodalDialog.dialog('open'); 
    }
}
var showTabId = function showTabId(result) {
    console.log('Tab ID: ' + result.id);
    var toRefreshId = result.id;
    sforce.console.refreshSubtabById(toRefreshId, true, refreshSuccess);
        
};
var refreshSuccess = function refreshSuccess(result) {
    if (result.success == true) {
        console.log('Primary tab refreshed successfully');
    } else {
        console.log('Primary tab did not refresh');
    }
};