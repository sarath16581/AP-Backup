({
    /**
    *   Call this function to load image into component
    *
    */
    doLoadImg : function(cmp,evt,hlpr){
        var params = evt.getParam('arguments');
        var iterationIdx = cmp.get("v.iterationIdx");
        var w = cmp.get('v.width');
        var h = cmp.get('v.height');
        var b = cmp.get('v.border');
        var dw = cmp.get('v.defwidth');
        var dh = cmp.get('v.defheight');
        var db = cmp.get('v.defborder');
        var imgStr = params.imageBase64str;
        var errMapLst = params.errorMapLst;
        if(!(imgStr == null || imgStr == "")){
            if(w == ""){
                cmp.set('v.width',dw);
            }
            if(h == ""){
                cmp.set('v.height',dh);
            }
            if(b == ""){
                cmp.set('v.border',db);
            }
        }
        var errMsgsDisp = cmp.find('errMsgsDisp');
        var imgSpinner = cmp.find('imgSpinner');
        var isLoadedVal = false;
        if(!errMapLst || errMapLst.length < 1 ){
            $A.util.addClass(errMsgsDisp, 'slds-hide');
            cmp.set('v.imageBase64',imgStr) ;
            isLoadedVal = true;
        } else {
             $A.util.removeClass(errMsgsDisp, 'slds-hide');
             $A.util.addClass(imgSpinner, 'slds-hide');
             isLoadedVal = false;
             cmp.set('v.errorMsgs', errMapLst);
        }
        cmp.set('v.imageLoaded', isLoadedVal);
        var compEvent = cmp.getEvent("ImageLoadedEvent");
        var hasImage = {hasImage: (imgStr == null || imgStr == ""?false:true ), iterationIdx:iterationIdx };
        compEvent.setParams({isLoaded : isLoadedVal, message: hasImage });
        compEvent.fire();
    },
    /**
    *   do When On Mouse Over
    *
    */
    handleonMouseOver:function(cmp,evt,hlpr){
        //mouse over
    },
    /**
    *   show popOver
    *
    */
     handleShowPopover : function(cmp,evt,hlpr){
        hlpr.handleShowPopover(cmp,evt);
     },
     /**
     *   Pop Image out
     *
     */
     handleShowPopOut : function(cmp,evt,hlpr) {
        hlpr.handleShowPopOut(cmp,evt);
     },
     /**
     *   Handle on Click
     *
     */
     handleClick : function(cmp,evt,hlpr){

        var imgShowing = cmp.get("v.imgShowing");

        if(imgShowing){
            hlpr.handleShowPopOut(cmp,evt);
        } else {
            hlpr.handleShowPopover(cmp,evt);
        }

     }
})