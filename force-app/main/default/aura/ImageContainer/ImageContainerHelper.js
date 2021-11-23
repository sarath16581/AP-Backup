({
    /**
    *   Show Popover
    */
    handleShowPopover : function(cmp,evt){
        var popup = cmp.find('myPopup');
        var imgShowing = cmp.get("v.imgShowing");
        $A.util.addClass(popup, "show");
        cmp.set("v.imgShowing",true);
    },
    /**
    *   remove popover
    */
    handleShowPopOut : function(cmp,evt){
        var popup = cmp.find('myPopup');
        $A.util.removeClass(popup, "show");
        cmp.set("v.imgShowing",false);
    }
})