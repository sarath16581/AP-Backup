({
    doInit : function(cmp, event, helper) {
        helper.loadInitCmp(cmp, event);
    },
    handleComponentEvent : function(cmp, event, helper) {
        //-- Needs to check below scroll how it works in SF1
        window.scrollTo(0, 100);
        helper.loadNextCmp(cmp, event);
    },
    closeModel: function(cmp, event){
        var GenEvent = cmp.getEvent("genCmpEvent");
        GenEvent.setParam("NextCmpToLoad", 'initCmp');
        GenEvent.setParam("hasBgSalesPermissionSet", false);
        GenEvent.fire();
    }
})