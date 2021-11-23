({
    /**
    *   Promise wrapper function to call asynchronous functions
    */
    helperPromise : function(cmp,hlpr,paramObj, helperFunction) {
            return new Promise($A.getCallback(function(resolve, reject) {
            helperFunction(cmp,hlpr,paramObj, resolve, reject);
        }));
    },
    /**
    *   Called when component is initialised.
    */
    doInit  :   function(cmp,evt,hlpr){
        var caseId = cmp.get("v.caseID");
        var caseNum = cmp.get("v.caseNumber");
        var conNoteInputLst = cmp.get("v.connoteInputValues");
        var conNotes = cmp.get("v.conNotesDispObj");
        var caseArticleTest = cmp.get("v.caseArticleTest");
        var action = null;
        var vfBaseURL = "https://" + cmp.get("v.vfHost");
        // Listen for messages posted by the iframed VF page
        window.addEventListener("message", function (event) {
                              if (event.origin !== vfBaseURL) {
                                  // Not the expected origin: reject message
                                  return;
                              }
                              // Only handle messages we are interested in
                              if (event.data.topic === "com.mycompany.message") {
                                  // using call back so this section not used.
                              }
                          }, false);
        if(caseId){
            cmp.set('v.disableLoadImgBtn',false);
            cmp.set('v.mode','Case');
            var paramConNoteCaseId = {caseID: caseId};
            var callBkConNoteCaseId = function(resp){
               cmp.set("v.disputes",resp);
                var conNoteArr = hlpr.getConnoteFromDispute(resp);
                var caseArticleTest =  cmp.get("v.caseArticleTest");
                var connotObj = hlpr.createConnoteDispTblObj();
                if(caseArticleTest){
                   connotObj.connote = caseArticleTest;
                   conNoteArr.push(connotObj);
                }
                cmp.set("v.conNotesDispObj",conNoteArr);
            };
            var errorCallBkConNoteCaseId = function(resp){
                hlpr.doDisplayErrorORMsg(cmp,resp,"ERROR");
            }  ;
            var loader = cmp.find('loader');
            AP_LIGHTNING_UTILS.invokeController(cmp, "getDisputedconNotesFromCaseId", paramConNoteCaseId, callBkConNoteCaseId, errorCallBkConNoteCaseId, false, loader);
        } else if (conNoteInputLst){
            var  conNotesDispObj  = cmp.get("v.conNotesDispObj");
            var ival = 0;
            var connotObj = hlpr.createConnoteDispTblObj();
            connotObj.connote = conNoteInputLst;
            conNotesDispObj.push(connotObj);
            cmp.set("v.conNotesDispObj",conNotesDispObj);
            cmp.set('v.mode','Connote');
            cmp.set('v.disableLoadImgBtn',false);
            conNotesDispObj  = cmp.get("v.conNotesDispObj");
        } else {
            cmp.set('v.disableLoadImgBtn',true);
            hlpr.doDisplayErrorORMsg(cmp, "Nothing Set to display","MSG");
        }
    },
    /**
    *   Display error in Error and message section on component.
    */
    doDisplayErrorORMsg : function(cmp,errorMsg,errType){
        var msgOrErrors = cmp.get("v.msgOrErrors");
        var errObj = this.createMsgOrErrorObj();
        errObj.error = errorMsg;
        errObj.type = errType;
        if(msgOrErrors){
            msgOrErrors.push(errObj);
            cmp.set("v.msgOrErrors",msgOrErrors);
            cmp.set("v.disableLoadImgBtn",false);
        } else {
            alert("An irrecoverable Error has occured. Please try again.\nIf issue persists please contact system administrator:\n" + errObj.error);
        }
    },
    /**
    *   Get a List on connotes from Dispute Item related list , relate to Case
    */
    getConnoteFromDispute : function(disputeObj){
        var connoteArray = [];
        var conNoteDisp ;
        if(disputeObj != null){
            for(var i=0; i < disputeObj.length; i++ ){
               if(disputeObj[i].Connote__c != null && disputeObj[i].Connote__c !== undefined){
                   conNoteDisp = this.createConnoteDispTblObj();
                   conNoteDisp.connote = disputeObj[i].Connote__c;
                   connoteArray.push(conNoteDisp);
               }
            }
        }
        return connoteArray;
    },
    /**
    *   Function to create object to display in ConNote Table in markup. This is used by component attribute "conNotesDispObj"
    */
    createConnoteDispTblObj : function(){
        var obj = {connote:"", dotNetApiLoaded:"Not Started", imgApiLoadedCount:"",retrydotNetAPI:"",icon:"",hideSpinnerConNote:true};
        return obj;
    },
    /**
    *   Function to create object to display in data in main table in markup. This is used by component attribute "compDispTbl"
    */
    createCmpDispTblObj : function(){
        var obj = {rowNum:0, attachToCaseProcessed : false , preSelected:false ,disableCheckbox:true, imgApiLoaded:"Not Started", isSelected:false, caseID:"",caseNum:"",disputedID:"",disputedItemName:"",consignmentID:"",consignmentNum:"",articleID:"",articleNum:"",guid:"",height:"",weight:"",length:"",eventMessageAttchSelID:"",eventMessageAttchID:"",eventMessageID:"",guid:"",UniqIdCaseConNoteArtGuid:"",imgSrc:"Displayed from API"  };
        return obj;
    },
    /**
    *   Function to create object used in "Attach To Case"
    */
    createImgObjServerSideParam: function(){
        var obj = {name: "", caseID : "", guid : "" , connoteID : "",  articleID : "" , eventMessageAttchSelID : "",   eventMsgDimensionID : "" , eventMsgAttachmentID : "", base64Str : "" , eventMessageID  : "" };
        return obj;
    },
    /**
    *   Function to create object used parse the response returned by image API.
    */
    createResponseImgObj : function(){
     var obj = {errorMapLst:"", guid:"", iterationIdx:0, bucketName:"",img:""};
     return obj;
    },
    /**
    *   Function to create object error object used to display errors in "msgOrErrors".
    */
    createMsgOrErrorObj : function(){
     //Type can be : ERROR, MSG
        var obj = {description:"",type:"ERROR"};
        return obj;
    },
    /**
    *   Take the result returned by Image API and Display Error or The Image based on result obtained.
    */
    parseImageResult : function(cmp,dispIdx,result){
        var compDispLst = cmp.get("v.compDispTbl");
        var resp = this.parseResult(result);
        var cmpImgs = this.getImgCompArray(cmp);
        var errorMapLst = [];
        var iCnt = 0;
        if(result.errorMapLst){
            for(iCnt = 0 ; iCnt < result.errorMapLst.length; iCnt++ ){
                var errObj = {error:""}  ;
                if(result.errorMapLst[iCnt].hasOwnProperty('error')){
                    errObj.error = result.errorMapLst[iCnt].error  ;
                } else {
                    errObj.error = result.errorMapLst[iCnt].message  ;
                }
                errorMapLst.push(errObj);
            }
        }
        var errArray = resp.errorMapLst ;
        cmpImgs[dispIdx].loadImg(resp.img, errorMapLst );
        if(errArray.length > 0){
            compDispLst[dispIdx].imgApiLoaded = "Error";
            compDispLst[dispIdx].disableCheckbox = true;
        }else{
            compDispLst[dispIdx].imgApiLoaded = "Completed";
            compDispLst[dispIdx].disableCheckbox = false;
        }
        cmp.set("v.compDispTbl",compDispLst);
    },
    /**
    *   Display the conNote section of the table ie: object "conNotesDispObj" and set status as applicable.
    */
    parseConnoteResult : function(cmp,conNoteIdx,result){
        var conNoteLst = cmp.get("v.conNotesDispObj");
        if(result){
            var consignmentNumber = result.consignmentNumber;
            var payload = result.payload;
            if(payload.errorCode != 0){
                 conNoteLst[conNoteIdx].dotNetApiLoaded = "Error";
                 conNoteLst[conNoteIdx].icon = "utility:error";
                 this.doDisplayErrorORMsg(cmp,JSON.stringify(consignmentNumber + ' :' + payload.errorCode),"ERROR");
            }else{
                conNoteLst[conNoteIdx].dotNetApiLoaded = "Completed";
                conNoteLst[conNoteIdx].icon = "utility:check";
            }
        }
        conNoteLst[conNoteIdx].hideSpinnerConNote = true;
        cmp.set("v.conNotesDispObj",conNoteLst);
    },
    /**
    *   Display the conNote section of the table ie: object "conNotesDispObj" and set status as applicable.
    */
    parseResult: function(result){
        var resp = this.createResponseImgObj();
        var errorRtned = "";

        var rslt =  result;
        var rsltParsed =  rslt;
        resp.guid  = rsltParsed.guid;
        resp.img =  rsltParsed.base64Image;
        resp.errorMapLst =  rsltParsed.errorMapLst;
        return resp;
    },
    /**
    *   Image has been loaded into Image Container
    */
    doOnImageLoaded: function(cmp,evt){
     // do when image has been loaded
    },
    /**
    *   Do when Checkbox All is clicked
    */
    doEnableCheckBoxAll : function(cmp){
        var chkBxAll = cmp.find("chkBoxSelAll");
        var compDispTbl =  cmp.get("v.compDispTbl");
        var cnt = 0;
        var disableChkBx = true;
        for(cnt=0; cnt < compDispTbl.length; cnt++){
            if(!compDispTbl[cnt].preSelected && !compDispTbl[cnt].disableCheckbox ) {
                disableChkBx = false;
                break;
            }
        }
        cmp.set("v.disableSelectAllChkBx",disableChkBx);
    },
    /**
    *   Do when Checkbox is clicked
    */
    doCheckBoxClicked : function(cmp, evt){
        var chkBxCurrent = evt.getSource();
        var chkBxs = cmp.find("chkBoxSel");
        var chkBxAll = cmp.find("chkBoxSelAll");
        var attachToCaseBttn = cmp.find("AttachToCase");
        var compDispTbl =  cmp.get("v.compDispTbl");
        var iCnt = 0 ;
        var valSet = false;
        var isChecked = false;
        var selectedCnt = 0;
        var currentChkBkSelection = chkBxCurrent.get("v.checked");
        var rowNum = chkBxCurrent.get("v.value");
        var dispIdx = compDispTbl.findIndex(obj => (obj.rowNum == rowNum ) );
        if(dispIdx > -1){
            compDispTbl[dispIdx].isSelected = currentChkBkSelection;
            cmp.set("v.compDispTbl",compDispTbl);
        }
        for(iCnt=0;iCnt < compDispTbl.length; iCnt++){
            if(!compDispTbl[iCnt].preSelected && compDispTbl[iCnt].isSelected ){
                 isChecked = true;
                 break;
            }
        }
        attachToCaseBttn.set("v.disabled",!isChecked);
    },
    /**
    *   Do when Checkbox All is clicked
    */
    doCheckBoxAllClicked : function(cmp, evt){
        var chkBxAll = cmp.find("chkBoxSelAll");
        var chkAllVal = !chkBxAll.get("v.checked") ;
        var imgObjLst = cmp.get("v.compDispTbl");
        var attachToCaseBttn = cmp.find("AttachToCase");
        var valSet = false;
        var iCnt = 0;
        for(iCnt=0;iCnt < imgObjLst.length; iCnt++){
            if(!imgObjLst[iCnt].preSelected && !imgObjLst[iCnt].disableCheckbox ){
                valSet = true;
                imgObjLst[iCnt].isSelected = chkAllVal;
            }
        }
        if(valSet){
            attachToCaseBttn.set("v.disabled",!chkAllVal);
            cmp.set("v.compDispTbl",imgObjLst);
        }
    },
    /**
    *   Do when Checkbox All is clicked
    */
    doGetConnNotesDataSel : function(cmp,hlpr,obj, resolve, reject){
        //cmp,evt,caseId
        var mode = cmp.get('v.mode');
        if(mode === 'Case'){
            var caseId = cmp.get("v.caseID");
            var self = this;
            var callBack = $A.getCallback(function(result){
                var dispObjLst = result;
                hlpr.parseSelConnotsToDispData(cmp,hlpr,result,null);
                resolve(result);
            });
            var params = {caseId: caseId};
            var errCallBack = function(resp){
                var rtn = {cmp:cmp, resp:resp};
                reject(resp) ;
            };
            var loader = cmp.find('loader');
            AP_LIGHTNING_UTILS.invokeController(cmp, "getDataforDispForSelAttachofCase", params, callBack, errCallBack, false, loader);
        } else {
            resolve(true);
        }
    },
    /**
    *   Return a dummy success promise if required
    */
    doDummyPromiseSuccess : function(cmp,hlpr,arrayIdxObj, resolve, reject){
        resolve(true);
    },
    /**
    *   Trigger event for doNextDispPreSelFiles
    */
    doNextDispPreSelFiles : function(){
        var apiPayload =  $A.get("e.c:eAPIPayloadReturned");
        apiPayload.setParams({
            idx : 0,
            apiName: "doNextDispPreSelFiles",
            apiParams: [],
            payload: {}
        });
        apiPayload.fire();
    },
    /**
    *   Trigger event for doNextGetDocumentIdForSelFiles
    */
    doNextGetDocumentIdForSelFiles : function(){
        var apiPayload =  $A.get("e.c:eAPIPayloadReturned");
        apiPayload.setParams({
            idx : 0,
            apiName: "doNextGetDocumentIdForSelFiles",
            apiParams: [],
            payload: {}
        });
        apiPayload.fire();
    },
    /**
    *   Trigger event for doNextConsignmentSrchData
    */
    doNextConsignmentSrchData : function(){
        var apiPayload =  $A.get("e.c:eAPIPayloadReturned");
        apiPayload.setParams({
            idx : 0,
            apiName: "doNextConsignmentSrchData",
            apiParams: [],
            payload: {}
        });
        apiPayload.fire();
    },
    /**
    *   Trigger event for doNextAPIImage
    */
    doNextAPIImage : function(){
        var apiPayload =  $A.get("e.c:eAPIPayloadReturned");
        apiPayload.setParams({
            idx : 0,
            apiName: "doNextAPIImage",
            apiParams: [],
            payload: {}
        });
        apiPayload.fire();
    },
    /**
    *   Trigger event for doNextConsignmentSrch
    */
    doNextConsignmentSrch : function(){
        var apiPayload =  $A.get("e.c:eAPIPayloadReturned");
        apiPayload.setParams({
            idx : 0,
            apiName: "doNextConsignmentSrch",
            apiParams: [],
            payload: {}
        });
        apiPayload.fire();
    },
    /**
    *   Trigger event for doNextConsignmentSrch
    */
    doNextAttachToCase : function(){
        var apiPayload =  $A.get("e.c:eAPIPayloadReturned");
        apiPayload.setParams({
            idx : 0,
            apiName: "doNextAttachToCase",
            apiParams: [],
            payload: {}
        });
        apiPayload.fire();
    },
    /**
    *   Get Files that have been selected by User in case
    */
    doGetSelFiles : function(cmp,hlpr,arrayIdxData, resolve, reject){
        var caseId = cmp.get("v.caseID");
        let params = {contentVersionID: arrayIdxData.Id};
        var callBack = function(resp){
            resolve(resp);
        };
        var errCallBack = function(resp){
            reject(resp);
        };
        var loader = cmp.find('loader');
        AP_LIGHTNING_UTILS.invokeController(cmp, 'getSelFiles', params, callBack, errCallBack, false, null);
    },
    /**
    *   When button Attach To Case is clicked , attach the file to case
    */
    doAttachToCase : function(cmp,hlpr,arrayIdx, resolve, reject){
        var caseId = cmp.get("v.caseID");

        var compDispTbl =  cmp.get("v.compDispTbl");

        var imgObjs = cmp.find("imgCont");
        if(!imgObjs ){
            imgObjs = [];
        }else if(!Array.isArray(imgObjs)) {
            imgObjs = [imgObjs];
        }
        var imgSourceObj = compDispTbl[arrayIdx];
        var img = imgObjs[arrayIdx];
        var attchImg = hlpr.createImgObjServerSideParam();

        attchImg.name =  img.get("v.guid") ;
        attchImg.base64Str = img.get("v.imageBase64");
        attchImg.caseID =  caseId ;
        attchImg.guid = img.get("v.guid");
        attchImg.articleID =  imgSourceObj.articleID ;
        attchImg.connoteID = imgSourceObj.consignmentID;
        attchImg.eventMsgAttachmentID = imgSourceObj.eventMessageAttchID;
        attchImg.eventMessageID = imgSourceObj.eventMessageID;
        var params = {ImageAttachment:JSON.stringify(attchImg)};
        var callBack = function(resp){
            resolve(resp);
        };
        var errCallBack = function(resp){
            reject(resp);
        };

        var loader = cmp.find('loader');

        AP_LIGHTNING_UTILS.invokeController(cmp, 'createCaseAttachments', params, callBack, errCallBack, false, loader);
    },
    /**
    *   When button Attach To Case is clicked , attach the file to case
    */
    doGetDocumentIdForSelFiles : function(cmp,hlpr,param ,resolve, reject){
        var caseId = cmp.get("v.caseID");
        let params = {caseID: caseId};
        var callBack = function(resp){
            resolve(resp);
        };
        var errCallBack = function(resp){
            reject(resp);
        };
        var loader = cmp.find('loader');
        AP_LIGHTNING_UTILS.invokeController(cmp, 'getDocumentIdForSelFiles', params, callBack, errCallBack, false, loader);
    },
    /**
    *   Create object to display details from salesforce event tables
    */
    parseEventDataToDispData : function(cmp,hlpr,result){
        var dispObjArray = cmp.get("v.compDispTbl");
        if(!dispObjArray){
            dispObjArray = [];
        }
        if(result){
            var i = 0;
            var prevCnt = dispObjArray.length;
            for(i=0; i <result.length; i++){
                var dispObj = hlpr.createCmpDispTblObj();
                dispObj.rowNum = i + prevCnt;
                dispObj.isSelected = false;
                dispObj.preSelected = false;
                dispObj.caseID = result[i].caseID;
                dispObj.consignmentID = result[i].consignmentID;
                dispObj.consignmentNum = result[i].consignmentNum;
                dispObj.articleID = result[i].articleID;
                dispObj.articleNum = result[i].articleNum;
                dispObj.guid = result[i].guid;
                dispObj.height = result[i].height;
                dispObj.weight = result[i].weight;
                dispObj.width = result[i].width;
                dispObj.length = result[i].length;
                dispObj.eventMessageAttchSelID = result[i].eventMessageAttchSelID;
                dispObj.eventMessageAttchID = result[i].eventMessageAttchID;
                dispObj.eventMessageID = result[i].eventMessageID;
                dispObj.UniqIdCaseConNoteArtGuid = "";
                dispObjArray.push(dispObj);
            }
            cmp.set("v.compDispTbl",dispObjArray);
        }
    },
    /**
    *   Create object to display details from salesforce Even Message Attachment Sel
    */
    parseSelConnotsToDispData : function(cmp,hlpr,resolve,reject){
        var result = resolve;
        var dispObjArray = cmp.get("v.compDispTbl");
        if(dispObjArray == null){
            dispObjArray = [];
        }
        if(result != null){
            var i = 0;
            var prevCnt = dispObjArray.length;
            for(i=0; i <result.length; i++){
                var dispObj = hlpr.createCmpDispTblObj();
                dispObj.rowNum = i + prevCnt;
                dispObj.isSelected = true;
                dispObj.preSelected = true;
                dispObj.caseID = result[i].caseID;
                dispObj.consignmentID = result[i].consignmentID;
                dispObj.consignmentNum = result[i].consignmentNum;
                dispObj.articleID = result[i].articleID;
                dispObj.articleNum = result[i].articleNum;
                dispObj.guid = result[i].guid;
                dispObj.height = result[i].height;
                dispObj.weight = result[i].weight;
                dispObj.width = result[i].width;
                dispObj.length = result[i].length;
                dispObj.eventMessageAttchSelID = result[i].eventMessageAttchSelID;
                dispObj.eventMessageAttchID = result[i].eventMessageAttchID;
                dispObj.eventMessageID = result[i].eventMessageID;
                dispObj.UniqIdCaseConNoteArtGuid = "";
                dispObj.imgSrc = "Displayed from Linked Case";
                dispObjArray.push(dispObj);
            }
            cmp.set("v.compDispTbl",dispObjArray);
            var tmp = cmp.get("v.compDispTbl");
        }
    },
    /**
    *   Function to get data from Event tables in salesforce
    */
    doGetConsignmentDataFromSF : function(cmp,hlpr,paramObj ,resolve, reject){
        var caseId = cmp.get("v.caseID");
        var conNotesDispObj = cmp.get("v.conNotesDispObj");
        var compDispTbl = cmp.get("v.compDispTbl");
        var selFilesIDsObj =   cmp.get("v.selFilesIDsObj");
        var iCnt = 0;
        var setVal = new Set();
        var setAttch = new Set();
        var iCnt = 0;
        var conNoteIds = [];
        if(conNotesDispObj){
            for(iCnt = 0 ;iCnt < conNotesDispObj.length ; iCnt++){

                setVal.add(conNotesDispObj[iCnt].connote) ;
            }
            conNoteIds = Array.from(setVal);
        }
        iCnt = 0;
        var ignoreSelectedGUID  = [];
        if(compDispTbl){
            for(iCnt = 0 ;iCnt < compDispTbl.length ; iCnt++){
                if(compDispTbl[iCnt].preSelected && compDispTbl[iCnt].guid){
                    setAttch.add(compDispTbl[iCnt].guid);
                }
            }
            ignoreSelectedGUID  = Array.from(setAttch);
        }
        var params = {caseId: caseId,conNoteIds:conNoteIds,ignoreSelectedGUID :ignoreSelectedGUID};
        var callBack = function(resp){
            hlpr.setImageCountsOnUI(cmp,hlpr,params.conNoteIds,resp);
            resolve(resp);
        };
        var errCallBack = function(resp){
            reject(resp);
        };
        AP_LIGHTNING_UTILS.invokeController(cmp, 'getDataforDisplayFromEvents', params, callBack, errCallBack, false, null);
    },
    /**
    *   Count of Image rows returned by connotes
    */
    setImageCountsOnUI : function(cmp,hlpr,conNoteIds,eventRslt ){
        var conNotesDispObj = cmp.get("v.conNotesDispObj");
        var iCnt=0;
        for(iCnt = 0; iCnt < conNoteIds.length; iCnt++  ){
             var conNoteIdx = conNotesDispObj.findIndex(obj => obj.connote == conNoteIds[iCnt] );
             var conNoteArr = eventRslt.filter(obj => obj.consignmentNum == conNoteIds[iCnt]);
             conNotesDispObj[conNoteIdx].imgApiLoadedCount = conNoteArr.length;
        }
        cmp.set("v.conNotesDispObj",conNotesDispObj);
    },
    /**
    *   Get image container and always return Array version of component
    */
    getImgCompArray : function(cmp){
        var cmpImgs = cmp.find("imgCont");
        if(!cmpImgs){
            // if not found create empty array
            cmpImgs = [];
        } else if(!cmpImgs.length){
            //if found but not array , create array
            cmpImgs = [cmpImgs]  ;
        }
        return cmpImgs;
    },
    /**
    *   Callout to get Image from API
    */
    doGetAPIImage : function(cmp,hlpr,dispObjIdx, resolve, reject){
        var caseId = cmp.get("v.caseID");
        var compDispLst = cmp.get("v.compDispTbl");
        var callBack = function(result){
            if(result == null){
                reject('Error Image Search returned not payload') ;
            } else if(result.hasOwnProperty('errorMapLst') && result.errorMapLst != null ){
            // raise error
                reject(result);
            } else {
                resolve(result);
            }
        };
        var contReqEvt = $A.get("e.c:AsynchApexContinuationRequest");
        contReqEvt.setParams({
            className : "ImageUnsortable",
            methodName: "getImage",
            methodParams : [compDispLst[dispObjIdx].guid],
            useAsynchCallout : true,
            callback : callBack
        });
        contReqEvt.fire();
    },
    /**
    *   Callout to Consignment API
    */
    doConsignmentSrch : function(cmp,hlpr,paramObj, resolve, reject){
        var conNoteLst = cmp.get("v.conNotesDispObj");
        var conNote = paramObj.connote;
        var mode = cmp.get('v.mode');
        var callbackFun = function(result){
            if(result == null){
                reject('Error Consignment Search returned not payload') ;
            } else if(result.hasOwnProperty('error') && result.error != null ){
            // raise error
                reject(result.error);
            } else {
                resolve(result);
            }
        }
        var consumerSrchEvt = $A.get("e.c:AsynchApexContinuationRequest");
        consumerSrchEvt.setParams({
            className : "ImageConsignmentSearch",
            methodName: "searchConsignment",
            methodParams : [conNote],
            callback : callbackFun
        });
        consumerSrchEvt.fire();
    },
    /**
    *   Display the image on the image Container
    */
    doSetImgOnUI : function(cmp,guid,imgStr,errLst){
        var cmpImgs = cmp.find("imgCont");
        if(!cmpImgs){
            // if not found create empty array
            cmpImgs = [];
        } else if(!cmpImgs.length){
            //if found but not array , create array
            cmpImgs = [cmpImgs]  ;
        }
        cmpImgs
        .filter(cmpImgv => cmpImgv.get('v.guid') == guid)
        .forEach(cmpImg => { cmpImg.loadImg(imgStr, errLst );
                    // enable check here
        });
    }
})