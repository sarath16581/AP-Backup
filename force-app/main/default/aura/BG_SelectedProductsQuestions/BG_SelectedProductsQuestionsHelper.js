({
    checkAllValid:function(cmp, event){
        var inputCmpFields = cmp.find('field');
        var allValid;
        if(Array.isArray(inputCmpFields)){
            allValid = this.asArray(inputCmpFields).reduce(function (validSoFar, inputCmp) {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
            
        }else{
            inputCmpFields.reportValidity();
            allValid = inputCmpFields.checkValidity();
        }
        return allValid;
    } ,
    reportAllInValid:function(cmp, event){
        var inputCmpFields = cmp.find('field');
        if(Array.isArray(inputCmpFields)){
            var allValid = this.asArray(inputCmpFields).reduce(function (validSoFar, inputCmp) {
                inputCmp.reportValidity();
            }, true);
        }else{
            inputCmpFields.reportValidity();
        }
    } ,
    asArray: function(x) {
        if (Array.isArray(x)) return x;
        else return x ? [x] : [];
    },
})