/**************************************************
Description:    Contains functionality for Image capture and Consignment Search Used by Consignment Attachment Lightning component

History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created

**************************************************/

public with sharing class ImageUtility {
    // map ids from async api webservice calls to Guids
    private static map<string,string> imgGuidObjsByAsyncKey;
    public static string uniqueImgBucketorKey {public get; private set; }

    /**
    * Get data from event tables and disply in lightnign component
    *
    * @param caseId Get data for case
    * @param conNoteIds Get for the folloing connotes
    * @param ignoreSelectedGUID Donot get data for the following Event Message Attrachemnts
    */
    @auraEnabled
    public static  list<displayData> getDataforDisplayFromEvents(string caseId, list<string> conNoteIds, list<string> ignoreSelectedGUID){
        //ignoreSelectedEventMsgsAttach
        string   EVENT_TYPE_ATTACHMENT = 'Processed at sortation facility';
        string   EVENT_TYPE_CUBE = 'CUBE';

        map<string,displayData> ddataByUniqID = new map<string,displayData>();
        list<EventMessage__c> emLst =   [select id, Article__r.Consignment__c,Article__r.Consignment__r.name ,Article__c,Article__r.name, EventType__c, ActualDateTime__c ,Height__c,Weight__c, Length__c, Width__c
                ,(select id,name,msg_description__c,msg_name__c from Article_Attachment_Details__r)
        from  EventMessage__c
        where Article__r.Consignment__r.name in :conNoteIds
        //and EventType__c in (:EVENT_TYPE_CUBE , : EVENT_TYPE_ATTACHMENT )
        order by ActualDateTime__c desc Nulls last
        ];
        caseid = string.isBlank(caseid)?'':caseid;
        ignoreSelectedGUID = ignoreSelectedGUID == null? new list<string>():ignoreSelectedGUID;
        Set<string> ignoreRows = new  Set<string>();
        for(string ss : ignoreSelectedGUID){
            if(!string.isBlank(ss)){
                ignoreRows.add(ss);
            }
        }
        for(EventMessage__c emAtt: emLst ){
            list<Event_Message_Attachment__c> emAttLstch = emAtt.Article_Attachment_Details__r;
            for(Event_Message_Attachment__c emAttch:  emAttLstch){
                //do not create display row if in exclusion lst
                if((emAttch.msg_description__c != null && !ignoreRows.contains(emAttch.msg_description__c))  ) {
                    displayData ddVal = new displayData();
                    ddVal.UniqIdCaseConNoteArtGuid = caseid + '' + emAtt.Article__r.Consignment__c + emAtt.Article__c + emAttch.msg_description__c;
                    ddVal.consignmentID = emAtt.Article__r.Consignment__c;
                    ddVal.consignmentNum = emAtt.Article__r.Consignment__r.name;
                    ddVal.ArticleID = emAtt.Article__c;
                    ddVal.articleNum = emAtt.Article__r.name;
                    ddVal.CaseID = caseid;
                    ddVal.eventMessageAttchID = emAttch.id;
                    ddVal.guid = emAttch.msg_description__c;
                    ddVal.eventMessageAttchSelID = null;
                    ddVal.height = emAtt.Height__c;
                    ddVal.weight = emAtt.Weight__c;
                    ddVal.length = emAtt.Length__c;
                    ddVal.width = emAtt.Width__c;
                    ddataByUniqID.put(ddVal.UniqIdCaseConNoteArtGuid, ddVal);
                }
            }
        }
        return ddataByUniqID.values() ;
    }

    /**
    * Get data from event tables and display in lightning component
    *
    * @param contentVersionID Get image from the following file

    */
    @auraEnabled
    public static String getSelFiles(string contentVersionID){
        String rtn = '';
        if(!string.isBlank(ContentVersionID)){
            ContentVersion rtnCV = [select id, VersionData from ContentVersion where  id =  :ContentVersionID ];
            if(rtnCV != null){
                rtn = EncodingUtil.base64Encode(rtnCV.VersionData);
            }
        }
        return rtn;
    }

    /**
    * Get ID for files that are assigned to the case
    *
    * @param caseID Get details for this case
    */
    @auraEnabled
    public static list<ContentVersion> getDocumentIdForSelFiles(string caseID){
        list<ContentVersion> rtnLst = new list<ContentVersion>();
        set<string> docLink = new set<string>();
        list<ContentVersion> cvLst = new  list<ContentVersion>();
        if(!string.isBlank(caseID)){
            list<ContentDocumentLink> dblLst = [select id ,ContentDocumentId from ContentDocumentLink where LinkedEntityId =  :caseID];
            for(ContentDocumentLink cdl : dblLst ){
                docLink.add(cdl.ContentDocumentId);
            }
            if(docLink.size() > 0){
                cvLst  = [select id,PathOnClient,Title,contentDocumentid from ContentVersion where IsLatest = true and contentDocumentid in :docLink  ];
            }
        }
        return cvLst;
    }

    /**
    * Get rows of data from event tables for the case. This is diplayed in the Consignment Attachment component
    *
    * @param caseID Get details for this case
    */
    @auraEnabled
    public static list<displayData> getDataforDispForSelAttachofCase(String caseId){
        list<ContentVersion> cvLst =  ImageUtility.getDocumentIdForSelFiles(caseId);
        set<string> imageGUIDs = new set<string>();
        for(ContentVersion cv : cvLst ){
            imageGUIDs.add(cv.PathOnClient);
        }

        list<Event_Message_Attachment__c> emalst = [select id , EventMessage__c, Msg_Description__c, Msg_Name__c
                , EventMessage__r.EventType__c, EventMessage__r.ActualDateTime__c ,EventMessage__r.Height__c,EventMessage__r.Weight__c, EventMessage__r.Length__c, EventMessage__r.Width__c
                ,  EventMessage__r.Article__r.Consignment__c,  EventMessage__r.Article__r.Consignment__r.name , EventMessage__r.Article__c,EventMessage__r.Article__r.name
        from Event_Message_Attachment__c   where  Msg_Description__c in : imageGUIDs
        ];
        map<string,displayData> ddataByUniqID = new map<string,displayData>();
        for(Event_Message_Attachment__c emAtt : emalst){
            displayData ddVal = new displayData();
            ddVal.UniqIdCaseConNoteArtGuid = caseid + '' + emAtt.EventMessage__r.Article__r.Consignment__c + emAtt.EventMessage__r.Article__c + emAtt.msg_description__c;
            ddVal.consignmentID = emAtt.EventMessage__r.Article__r.Consignment__c;
            ddVal.consignmentNum = emAtt.EventMessage__r.Article__r.Consignment__r.name;
            ddVal.ArticleID = emAtt.EventMessage__r.Article__c;
            ddVal.articleNum = emAtt.EventMessage__r.Article__r.name;
            ddVal.CaseID = caseid;
            ddVal.eventMessageAttchID = emAtt.id;
            ddVal.guid = emAtt.msg_description__c;
            ddVal.eventMessageAttchSelID = null;
            ddVal.height =  emAtt.EventMessage__r.Height__c;
            ddVal.weight =  emAtt.EventMessage__r.Weight__c;
            ddVal.length =  emAtt.EventMessage__r.Length__c;
            ddVal.width =  emAtt.EventMessage__r.Width__c;
            ddataByUniqID.put(ddVal.UniqIdCaseConNoteArtGuid, ddVal);
        }
        return ddataByUniqID.values() ;
    }

    /**
    * Create Files and attach to case for the images selected by the user
    *
    * @param ImageAttachment File payload
    */
    @AuraEnabled
    public static String createCaseAttachments(String ImageAttachment ){
        string rtnImgObj = 'Image empty Noting To Save';
        if(!(ImageAttachment == null || ImageAttachment == '')  ){
            ImageAttachment att = (ImageAttachment)JSON.deserialize(ImageAttachment,ImageAttachment.class);
            // create content version
            string imgStr = att.base64Str;
            if(!(string.isBlank(imgStr) && string.isBlank(att.caseid) ) ){
                ContentVersion cont = new ContentVersion();
                cont.Title = String.valueOf(att.name);
                cont.PathOnClient = String.valueOf(att.guid);
                cont.VersionData = EncodingUtil.base64Decode(att.base64Str);
                cont.Origin = 'H';
                cont.ContentLocation = 'S';
                insert cont;

                att.contentVersionId = cont.id;
                Map<id,contentVersion> conVerWithDocIdById = new Map<id,contentVersion>([select id , contentDocumentid from contentVersion where id = :cont.id ]);
                contentVersion conV = conVerWithDocIdById.get(cont.id);
                ContentDocumentLink cdlCase = new ContentDocumentLink();
                cdlCase.LinkedEntityId = att.caseid;
                cdlCase.ContentDocumentId = conV.ContentDocumentId;
                att.contentDocumentid =   conV.ContentDocumentId;
                cdlCase.ShareType = 'V';

                insert cdlCase;
                // blank image value to reduce size of return value;
                att.base64Str = '';
                rtnImgObj = JSON.serialize(att);
            }
        }
        return rtnImgObj;
    }


    /**
    * Get disputed Item for case
    *
    * @param caseID Get details for this case
    */
    @AuraEnabled
    public static list<Disputed_Item__c> getDisputedconNotesFromCaseId(string caseID){
        return   [select id, Connote__c, name from Disputed_Item__c where Case__c = :caseID and Connote__c != null  ];
    }

    /**
    * Wrapper object for file Attachment
    *
    */
    public class ImageAttachment{
        public string name {get; set;}
        public string caseID {get; set;}
        public string base64Str {get; set;}
        public string guid      {get; set;}
        public string connoteID {get; set;}
        public string articleID {get; set;}
        public string eventMessageAttchSelID {get; set;}
        public string eventMsgDimensionID {get; set;}
        public string eventMsgAttachmentID {get; set;}
        public string contentDocumentID {get; set;}
        public string contentVersionID {get; set;}
    }

    /**
    * Wrapper object to display data from event tables
    *
    */
    public class displayData{
        @AuraEnabled public string UniqIdCaseConNoteArtGuid {get; set;}
        @AuraEnabled public integer rowNum {get; set;}
        @AuraEnabled public boolean isSelected {get; set;}
        @AuraEnabled public string caseID {get; set;}
        @AuraEnabled public string caseNum {get; set;}
        @AuraEnabled public string disputedID {get; set;}
        @AuraEnabled public string disputedItemName {get; set;}
        @AuraEnabled public string consignmentID {get; set;}
        @AuraEnabled public string consignmentNum {get; set;}
        @AuraEnabled public string articleID {get; set;}
        @AuraEnabled public string articleNum {get; set;}
        @AuraEnabled public string guid {get; set;}
        @AuraEnabled public string height {get; set;}
        @AuraEnabled public string weight {get; set;}
        @AuraEnabled public string length {get; set;}
        @AuraEnabled public string width {get; set;}
        @AuraEnabled public string eventMessageAttchSelID {get; set;}
        @AuraEnabled public string eventMessageAttchID {get; set;}
        @AuraEnabled public string eventMessageID {get; set;}
    }
}