({
    /**
    *   Called when component is initialised.
    */
    handleInit: function(cmp,evt,hlpr){
         hlpr.doInit(cmp,evt,hlpr);
    },
    /**
    *   Main Function that handles the return values from APS's and also calls functions
    *   to fire API's to simulate an asynchronous Loop.
    */
    handleAPIReturned: function(cmp, evt,hlpr){
        var idx = evt.getParam("idx");
        var apiName = evt.getParam("apiName");
        var payload = evt.getParam("payload");
        var apiParams = evt.getParam("apiParams");
        var msgOrErrors = cmp.get("v.msgOrErrors");
        var errObj = hlpr.createMsgOrErrorObj();
        if(apiName ==  "doNextGetDocumentIdForSelFiles"){
            hlpr.helperPromise(cmp,hlpr,{},hlpr.doGetDocumentIdForSelFiles)
                .then($A.getCallback(function(result){

                    if(result != null){
                        var selFilesIDsObj = cmp.get("v.selFilesIDsObj");
                        let iCnt = 0;
                        var docIdArray = [];
                        for(iCnt = 0 ;iCnt < result.length; iCnt++  ){
                            var obj = {Id:result[iCnt].Id,ContentDocumentId:result[iCnt].ContentDocumentId,PathOnClient:result[iCnt].PathOnClient, imgLoaded:"Not Started"};
                            docIdArray.push(obj);
                        }
                        selFilesIDsObj = docIdArray;
                        cmp.set("v.selFilesIDsObj",selFilesIDsObj);
                    }
                    hlpr.doNextDispPreSelFiles();
                }))
                .catch($A.getCallback(function(result){
                  hlpr.doDisplayErrorORMsg(cmp,JSON.stringify(result),"ERROR");
                }));
        } else if(apiName ==  "doNextDispPreSelFiles") {
            var selFilesIDsObj = cmp.get("v.selFilesIDsObj");
            var selIdx = selFilesIDsObj.findIndex(obj => obj.imgLoaded == "Not Started" );
            if(selIdx > -1 ){
                hlpr.helperPromise(cmp,hlpr,selFilesIDsObj[selIdx],hlpr.doGetSelFiles)
                    .then($A.getCallback(function(result){
                        selFilesIDsObj[selIdx].imgLoaded = "Completed";
                        cmp.set("v.selFilesIDsObj",selFilesIDsObj);
                        hlpr.doSetImgOnUI(cmp,selFilesIDsObj[selIdx].PathOnClient,result,[] );
                        hlpr.doNextDispPreSelFiles();
                    }))
                    .catch($A.getCallback(function(result){

                        hlpr.doDisplayErrorORMsg(cmp,JSON.stringify(result),"ERROR");
                    }));
            } else {
                hlpr.doNextConsignmentSrch();
            }
        } else if(apiName == "doNextConsignmentSrch"){
            var conNoteLst = cmp.get("v.conNotesDispObj");
            var conNoteIdx = conNoteLst.findIndex(obj => (obj.dotNetApiLoaded == "Not Started" || obj.dotNetApiLoaded == "Error"  ) );
            if(conNoteIdx > -1 ){
               conNoteLst[conNoteIdx].hideSpinnerConNote = false;
               conNoteLst[conNoteIdx].icon = "utility:search";
               conNoteLst[conNoteIdx].dotNetApiLoaded = "Processing";
               cmp.set("v.conNotesDispObj",conNoteLst);
               hlpr.helperPromise(cmp,hlpr,{connote:conNoteLst[conNoteIdx].connote},hlpr.doConsignmentSrch)
                   .then($A.getCallback(function(result){
                        hlpr.parseConnoteResult(cmp,conNoteIdx,result);
                        hlpr.doNextConsignmentSrch();
                   }))
                   .catch($A.getCallback(function(result){
                      conNoteLst[conNoteIdx].dotNetApiLoaded = "Error";
                      conNoteLst[conNoteIdx].icon = "utility:error";
                      conNoteLst[conNoteIdx].hideSpinnerConNote = true;
                      cmp.set("v.conNotesDispObj",conNoteLst);
                      hlpr.doDisplayErrorORMsg(cmp,JSON.stringify(result),"ERROR");
                   }));
            } else {
               hlpr.doNextConsignmentSrchData();
            }
        } else if (apiName == "doNextConsignmentSrchData"){
            var conNoteLst = cmp.get("v.conNotesDispObj");
            hlpr.helperPromise(cmp,hlpr,{},hlpr.doGetConsignmentDataFromSF)
                .then($A.getCallback(function(result){
                    hlpr.parseEventDataToDispData(cmp,hlpr,result);
                    hlpr.doNextAPIImage();
                }))
                .catch($A.getCallback(function(result){
                  hlpr.doDisplayErrorORMsg(cmp,JSON.stringify(result),"ERROR");
                }));

        } else if(apiName == "doNextAPIImage"){
            var compDispLst = cmp.get("v.compDispTbl");
            var dispIdx = compDispLst.findIndex(obj => (obj.preSelected == false &&  obj.imgApiLoaded == "Not Started" && obj.isSelected == false ) );
            if(dispIdx > -1){
                 hlpr.helperPromise(cmp,hlpr,dispIdx,hlpr.doGetAPIImage)
                     .then($A.getCallback(function(result){
                        hlpr.parseImageResult(cmp,dispIdx,result);
                        hlpr.doNextAPIImage();
                     }))
                     .catch($A.getCallback(function(result){
                        hlpr.parseImageResult(cmp,dispIdx,result);
                        hlpr.doNextAPIImage();
                     }));
            } else{
                cmp.set("v.disableLoadImgBtn",false);
                hlpr.doEnableCheckBoxAll(cmp);
                errObj.error = "Load Images Process completed";
                errObj.type = "MSG";
                msgOrErrors.push(errObj);
                cmp.set("v.msgOrErrors",msgOrErrors);
                //alert("Load Images Process completed");
            }
        }else if (apiName == "doNextAttachToCase"){
            var compDispTbl =  cmp.get("v.compDispTbl");
            var dispIdx = compDispTbl.findIndex(obj => (obj.preSelected == false &&  obj.attachToCaseProcessed == false && obj.isSelected == true ) );
            if(dispIdx > -1){
             hlpr.helperPromise(cmp,hlpr,dispIdx,hlpr.doAttachToCase)
                 .then($A.getCallback(function(result){
                     compDispTbl[dispIdx].attachToCaseProcessed = true;
                     compDispTbl[dispIdx].preSelected = true;
                     compDispTbl[dispIdx].disableCheckbox = true;
                     cmp.set("v.compDispTbl",compDispTbl);
                     hlpr.doNextAttachToCase();
                 }))
                 .catch($A.getCallback(function(result){
                   hlpr.doDisplayErrorORMsg(cmp,JSON.stringify(result),"ERROR");
                 }));
            } else {
                cmp.set("v.disableLoadAttachToCase",true);
                var attachToCaseBttn = cmp.find("AttachToCase");
                attachToCaseBttn.set("v.disabled",true);

                errObj.error = "Attach to case completed";
                errObj.type = "MSG";
                msgOrErrors.push(errObj);
                cmp.set("v.msgOrErrors",msgOrErrors);
                //alert("Attach to case completed");
            }
        }
        else{
            cmp.set("v.disableLoadImgBtn",false);
            hlpr.doEnableCheckBoxAll(cmp);
            errObj.error = "Load Images Process completed";
            errObj.type = "MSG";
            msgOrErrors.push(errObj);
            cmp.set("v.msgOrErrors",msgOrErrors);
            //alert("Load Images Process completed");
        }
    },
    /**
    *   Triggered when button Load Images is clicked
    */
    onLoadImages : function(cmp,evt,hlpr){
        cmp.set("v.disableLoadImgBtn",true);
        cmp.set("v.bttnLoadImgNotPressed",true);
        cmp.set("v.compDispTbl",[]);
        cmp.set("v.msgOrErrors",[]);
        var mode = cmp.get('v.mode');
        var caseId = cmp.get("v.caseID");
        var conNotes = cmp.get("v.conNotesDispObj");
        if(conNotes && conNotes.length > 0 ){
            if(mode === 'Case'){
               var obj = {};
               hlpr.helperPromise(cmp,hlpr,obj,hlpr.doGetConnNotesDataSel)
                    .then($A.getCallback(function(result) {
                        hlpr.doNextGetDocumentIdForSelFiles();
                    }))
                    .catch($A.getCallback(function(result) {
                       hlpr.doDisplayErrorORMsg(cmp,JSON.stringify(result),"ERROR");
                    }));
            }else{
             hlpr.doNextConsignmentSrch();
            }
        } else {
         hlpr.doDisplayErrorORMsg(cmp,"No Connotes specified to display","MSG");
        }
    },
    /**
    *   Triggered when button Attach To Case is clicked
    */
    onAttachToCase : function (cmp,evt,hlpr){
        hlpr.doNextAttachToCase();
    },
    /**
    *   Handler for event ImageLoadedEvent. Triggered when image is loaded in Image Container.
    */
    handleImageLoaded : function(cmp, evt, hlpr){
        hlpr.doOnImageLoaded(cmp,evt);
    },
    /**
    *   Handler Checkbox Click.
    */
    checkBoxClicked: function(cmp, evt, hlpr){
        hlpr.doCheckBoxClicked(cmp, evt);
    },
    /**
    *   Handler Checkbox All Click.
    */
    checkBoxAllClicked: function(cmp, evt, hlpr){
        hlpr.doCheckBoxAllClicked(cmp, evt);
    }
})