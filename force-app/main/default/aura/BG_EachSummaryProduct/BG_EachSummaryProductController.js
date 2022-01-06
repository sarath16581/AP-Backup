({
    doInit : function(cmp, event, helper) {
        var key = cmp.get("v.key");
        var map = cmp.get("v.selectedProductsQuestions");
        // set the values of map to the value attribute	
        // to get map values in lightning cmp use "map[key]" syntax. 
        cmp.set("v.productQuestions" , map[key]);
        cmp.set("v.revenue",   cmp.get('v.selectedProductsQuestions.'+key+'.revenue'));
        cmp.set("v.notes",   cmp.get('v.selectedProductsQuestions.'+key+'.notes'));
    }
})