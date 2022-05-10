({
    doInit: function(cmp, event, helper) {
        //fetch picklist values
        //helper.fetchPickListValues(cmp, 'Qualification_Template_Questions__c', 'Category__c', 'apiNames', 'v.productAndServicesList') ;
        helper.fetchPickListValues(cmp, 'Qualification_Template_Questions__c', 'Category__c', 'values', 'v.productAndServicesList') ;
        // helper.fetchProductCategoryValues(cmp, event,'v.productAndServicesList') ;       
        
    },
})