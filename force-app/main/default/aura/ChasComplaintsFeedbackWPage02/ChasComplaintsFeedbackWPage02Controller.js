/*
  * @changeLog : 19/06/2020: hara.sahoo@auspost.com.au reset the showErrorSummary flag.
*/
({
    goForward: function (cmp, event, helper) {
        var isValid = helper.checkAllInputs(cmp, true);
        //-- If all validation success then navigating to next component
        if(isValid){
            helper.gotoNextPage(cmp);
        } else {
            helper.showErrorSummary(cmp)
        }
    },

    onchange: function (cmp, event, helper) {
        //reset the showErrorSummary flag
        cmp.set("v.showErrorSummary",'false');
        var srcCmp = event.getSource();
        var fieldName = event.getParam("name");
        helper.checkInputs([srcCmp], true);
        cmp.set('v.checkInputsOnRender', true);

    },
    goBackHandler: function (component, event, helper) {
        helper.gotoPrevPage(component);
     }
})