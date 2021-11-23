({
    validateProducts: function (cmp) {
        var isValid = true;
        var selectedProds = cmp.get('v.selectedProducts');
        if(selectedProds == null || selectedProds.length < 1 || selectedProds[0] == undefined || selectedProds[0] === '')
            isValid = false;
        return isValid;
    },
    setProductSelectionErrorMessage : function (cmp, message) {
         cmp.set('v.prodErrorMessage', message);
    },
     setCurrentStepErrorStatus : function (cmp, currentStepHasError) {
        cmp.set('v.hasErrorInCurrentStep', currentStepHasError);
    }
})