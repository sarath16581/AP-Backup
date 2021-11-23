({
    doInit : function(cmp, event, helper) {
        var tileMap = cmp.get('v.tileMap');
        var tileList = cmp.get('v.tileList');
        var computedList = [];
        for (var i=0; i<tileList.length; i++) {
            computedList.push(tileMap[tileList[i]]);
        }
        cmp.set('v.computedTileList', computedList);
    },

    goToDestination : function(cmp, event, helper) {
        var compLinkDest = event.currentTarget.dataset.url;
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": compLinkDest
        });
        urlEvent.fire();
    }
})