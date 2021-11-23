public class StarTrackConsignmentDetails_ControllerX {


    public Case caseRecord {get; set;}
    public Article__c consignment {get; set;}
    public Set<String> tempFields {get; set;}
    public List<String> caseFields {get; set;}
    public Set<String> relatedCaseFields {get; set;}
    public List<String> relatedNoteFields {get; set;}
    public List<String> relatedSubdocketFields {get; set;}
    public List<String> relatedPODFields {get; set;}
    public List<Case> relatedCases {get; set;}
    public List<Case> relatedCasesIVR {get; set;}
    public List<Book_In_Note__c> relatedNotes {get; set;}
    public List<Sub_Docket__c> relatedSubdockets {get; set;}
    public List<Proof_of_Delivery__c> relatedPODs {get; set;}

    public String startTime {get; set;}

    public StarTrackConsignmentDetails_ControllerX(ApexPages.StandardController controller) {

        startTime = StarTrackIntegrationLogging.timeNowFormatted();
        consignment = new Article__c();
        tempFields = new Set<String>{'Id', 'Network__c', 'ArticleTest__c', 'ArticleTest__r.Name', 'RecordType.Name'};
        caseFields = new List<String>();
        relatedCaseFields = new Set<String>();
        relatedNoteFields = new List<String>();
        relatedSubdocketFields = new List<String>();
        relatedPODFields = new List<String>();
        relatedCases = new List<Case>();
        relatedCasesIVR = new List<Case>();
        relatedNotes = new List<Book_In_Note__c>();
        relatedSubdockets = new List<Sub_Docket__c>();
        relatedPODs = new List<Proof_of_Delivery__c>();

        for(Schema.FieldSetMember fsm : SObjectType.Case.FieldSets.getMap().get('Consignment_Detail_Page').getFields()){
            caseFields.add(fsm.getFieldPath());
        }
        tempFields.addAll(caseFields);
        caseFields.clear();
        caseFields.addAll(tempFields);
        if(!Test.isRunningTest()){
            controller.addFields(caseFields);
        }
        caseRecord = (Case) controller.getRecord();

        if(caseRecord.ArticleTest__c != null){
            queryConsignment();
        }
    }

    public void queryConsignment(){

        relatedCaseFields = new Set<String>();
        relatedNoteFields = new List<String>();
        relatedSubdocketFields = new List<String>();
        relatedPODFields = new List<String>();
        relatedCases = new List<Case>();
        relatedNotes = new List<Book_In_Note__c>();
        relatedSubdockets = new List<Sub_Docket__c>();
        relatedPODs = new List<Proof_of_Delivery__c>();

        String query = 'SELECT Id, Name, Source_System__c, ArticleID__c';
        for(Schema.FieldSetMember fsm : SObjectType.Case.FieldSets.getMap().get('StarTrack_Related_Cases_Fieldset').getFields()){
            relatedCaseFields.add(fsm.getFieldPath());
        }
        for(Schema.FieldSetMember fsm : SObjectType.Book_In_Note__c.FieldSets.getMap().get('StarTrack_Related_Notes').getFields()){
            relatedNoteFields.add(fsm.getFieldPath());
        }
        for(Schema.FieldSetMember fsm : SObjectType.Sub_Docket__c.FieldSets.getMap().get('StarTrack_Related_Sub_dockets').getFields()){
            relatedSubdocketFields.add(fsm.getFieldPath());
        }
        for(Schema.FieldSetMember fsm : SObjectType.Proof_of_Delivery__c.FieldSets.getMap().get('StarTrack_Related_PODs').getFields()){
            relatedPODFields.add(fsm.getFieldPath());
        }

        if(!relatedCaseFields.contains('origin'))
            relatedCaseFields.add('origin');

        for(String fieldKey : StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.keySet()) {
            if(!relatedCaseFields.contains(fieldKey.toLowerCase()))
                relatedCaseFields.add(fieldKey.toLowerCase());
        }

        query += ', (SELECT ' + String.join(new List<String>(relatedCaseFields), ',') + ' FROM Cases__r WHERE Id != \'' + caseRecord.Id + '\' ORDER BY CreatedDate DESC)';

        if(relatedNoteFields.size() > 0){
            query += ', (SELECT ' + String.join(relatedNoteFields, ',') + ' FROM Book_In_Notes__r)';
        }

        if(relatedSubdocketFields.size() > 0){
            query += ', (SELECT ' + String.join(relatedSubdocketFields, ',') + ' FROM Sub_Dockets__r)';
        }

        query += ' FROM Article__c WHERE Id = \'' + caseRecord.ArticleTest__c + '\'';

        consignment = Database.query(query);

        for(Case cse: consignment.Cases__r) {
            if('IVR'.equalsIgnoreCase(cse.Origin)) {
                // we only display IVR cases that are transactional.
                // any cases created with IVR that require touching by an agent shouldn't be dipslayed in the IVR list
                Boolean isIVR = true;
                for(String fieldKey : StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.keySet()) {
                    // if the value on the case is in the list of exclusions, then this case is considered non-transactional
                    if(StarTrack_Constants.NON_TRANSACTIONAL_IVR_EXCLUSIONS.get(fieldKey).contains(String.valueOf(cse.get(fieldKey)))) {
                        isIVR = false;
                        break;
                    }
                }

                if(isIVR) {
                    relatedCasesIVR.add(cse);
                } else {
                    relatedCases.add(cse);
                }
            } else {
                relatedCases.add(cse);
            }
        }
        
        relatedNotes.addAll(consignment.Book_In_Notes__r);
        relatedSubdockets.addAll(consignment.Sub_Dockets__r);

       if(relatedPODFields.size() > 0){
             //String podQuery = 'SELECT SignatureXString__c,' + String.join(relatedPODFields, ',') + ', AttachmentId__c, (SELECT Id, ParentId, Title FROM NotesAndAttachments ORDER BY CreatedDate DESC LIMIT 1) FROM Proof_of_Delivery__c WHERE Consignment__c = \'' + caseRecord.ArticleTest__c + '\' ORDER BY POD_Received_Date__c DESC';
             String podQuery = 'SELECT ' + String.join(relatedPODFields, ',') + ', AttachmentId__c, (SELECT Id, ParentId, Title FROM NotesAndAttachments ORDER BY CreatedDate DESC LIMIT 1) FROM Proof_of_Delivery__c WHERE Consignment__c = \'' + caseRecord.ArticleTest__c + '\' ORDER BY POD_Received_Date__c DESC';
             relatedPODs = Database.query(podQuery);
        }
    }

    public void attachPODSignatureToCase()
    {
        String sPODId = ApexPages.currentPage().getparameters().get('sPODId');
        //String sImage64 = apexpages.currentPage().getparameters().get('sImage64');
        String sSignedBy = apexpages.currentPage().getparameters().get('sSignedBy');
        String attachmentId = ApexPages.currentPage().getparameters().get('attachmentId');

        // Attach PDF to Case
        PageReference pdf = new PageReference('/apex/StarTrackProofOfDeliveryMerge?id=' + sPODId);

        Attachment attach = new Attachment();
        Blob body;
        
        if(consignment.Source_System__c == 'TRACK & TRACE'){
            try {
                if(Test.isRunningTest()){
                    body = Blob.valueOf('Test');
                }
                else{
                    body = pdf.getContentAsPDF();
                }
            } catch (VisualforceException e) {
    
            }
    
            attach.Body = body;
            attach.Name = 'Signature-' + (sSignedBy == null ? '' : sSignedBy) +'.pdf';
            attach.IsPrivate = false;
            attach.ContentType = 'application/pdf';
        } else{
            try{
                Attachment attachPOD = [SELECT Id, Body, IsPrivate, ContentType, Name FROM Attachment WHERE Id =:attachmentId];
                attach.Body = attachPOD.Body;
                attach.Name = attachPOD.Name;
                attach.IsPrivate = attachPOD.IsPrivate;
                attach.ContentType = attachPOD.ContentType;
            }catch(Exception e){
                System.debug(e.getMessage());
            }
        }
        
        if(attach.Body != null){
            attach.ParentId = caseRecord.Id;
            INSERT attach;
        }        
    }

    StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();
    public String reqTimeStamp {get; set;}
    public String respTimeStamp {get; set;}
    wwwAuspostComAuSchemaCustomercarema.SearchRequest request;
    AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse;
    AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = new AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();

    wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 emsStub = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
    wwwAuspostComAuSchemaCustomercarema.ConsignmentData emsResponse;

    public Continuation searchConsignment(){

        try {
            if (StarTrackConsignmentSearchUtil.isWaitDone(consignment.ArticleID__c)) {
                wwwAuspostComAuSchemaCustomercarema.Header header = new wwwAuspostComAuSchemaCustomercarema.Header();
                DateTime nowDT = DateTime.now();
                
                header.TimeStamp = nowDT;
                header.TransactionId = UserInfo.getUserName() + '_' + (nowDT).format('YYYYMMddHHmmss');
                header.SourceId = 'Salesforce';
                header.Action = 'Search';

                request = new wwwAuspostComAuSchemaCustomercarema.SearchRequest();

                request.Header = header;
                request.Type_x = 'UNIQUEEXTERNALID';
                request.Value = consignment.ArticleID__c;
                request.Action = 'FULL';
                            
                String endpoint = '';
                Map<String,String> httpHeaders = new Map<String,String>();
                String clientCert = '';

                // Basic Authentication
                if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 1){
                    endpoint = stSettings.StarTrack_ConSearch_BA_Endpoint__c;
                    httpHeaders.put('Authorization','Basic ' + stSettings.StarTrack_ConSearch_BA_Password__c);
                }
                // Client Certificate
                else if(stSettings.StarTrack_ConSearch_Authentication_Level__c == 2){
                    endpoint = stSettings.StarTrack_ConSearch_Cert_Endpoint__c;
                    clientCert = stSettings.StarTrack_ConSearch_Client_Cert__c;
                }

                // Continuation
                emsAsyncStub.endpoint_x = endpoint;
                if(!httpHeaders.isEmpty()){
                    emsAsyncStub.inputHttpHeaders_x = httpHeaders;
                }
                if(String.isNotBlank(clientCert)){
                    emsAsyncStub.clientCertName_x = clientCert;
                }    

                Continuation cont = new Continuation(Integer.valueOf(stSettings.Web_Service_Callout_Timeout__c));
                cont.continuationMethod = 'processSearchConsignment';

                reqTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
                emsAsyncResponse = emsAsyncStub.beginSearch_x(cont, request);

                return cont;
            } else {
                return null;
            }   

        }  catch(CalloutException e){
            GlobalUtility.logMessage('ERROR', 'StarTrackConsignmentDetails_ControllerX', 'searchConsignment', '', 'CalloutException', e.getMessage(), String.valueOf(request), e, 0);
            return null;
        }
        
    }

    public Object processSearchConsignment(){

        try{
            respTimeStamp = StarTrackIntegrationLogging.timeNowFormatted();
            // REQUEST/RESPONSE LOG
            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse('StarTrackConsignmentDetails_ControllerX', 'processSearchConsignment', consignment.ArticleID__c, 'INT-REQ - consignmentSearch - consignDetail (refresh)', reqTimeStamp, request);
                StarTrackIntegrationLogging.logRequestResponse('StarTrackConsignmentDetails_ControllerX', 'processSearchConsignment', consignment.ArticleID__c, 'INT-RES - consignmentSearch - consignDetail (refresh)', respTimeStamp, emsAsyncResponse.getValue());
            }

            StarTrackConsignmentSearchUtil.processResponse(emsAsyncResponse.getValue(), true);        

            List<String> fields = new List<String>();
            for(Schema.FieldSetMember fsm : SObjectType.Case.FieldSets.getMap().get('Consignment_Detail_Page').getFields()){
                fields.add(fsm.getFieldPath());
            }

            //added by ramya begin for INC1036289
            for(Schema.FieldSetMember fsm : SObjectType.Case.FieldSets.getMap().get('Consignment_Detail_Page_2').getFields()){
                fields.add(fsm.getFieldPath());
            }
            //added by ramya end

            //retrieve updated Case
            String caseQuery = 'SELECT Id, Network__c, ArticleTest__r.Name, RecordType.Name, ' + String.join(fields, ',') + ' FROM Case WHERE Id = \'' + caseRecord.Id + '\'';
            List<Case> caseObj = Database.query(caseQuery);
            caseRecord = caseObj[0];
            //retrieve updated Consignment
            queryConsignment();

        } catch(CalloutException e){
            GlobalUtility.logMessage('ERROR', 'StarTrackConsignmentDetails_ControllerX', 'processSearchConsignment', '', 'CalloutException', e.getMessage(), String.valueOf(request), e, 0);                        

            if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
                StarTrackIntegrationLogging.logRequestResponse('StarTrackConsignmentDetails_ControllerX', 'processSearchConsignment', consignment.ArticleID__c, 'INT-REQ - consignmentSearch - consignDetail (refresh) - ERROR', reqTimeStamp, request);
            }
        }
        return null;
    }

    public void logTime(){
        if (StarTrackIntegrationLogging.validForLogging(stSettings)) {
            StarTrackIntegrationLogging.logRequestResponse('PAGE RENDER - START (StarTrackConsignmentDetails_ControllerX)', 'StarTrackConsignmentDetails_ControllerX', '', 'PAGE RENDER - START', startTime, null);
            StarTrackIntegrationLogging.logRequestResponse('PAGE RENDER - END (StarTrackConsignmentDetails_ControllerX)', 'StarTrackConsignmentDetails_ControllerX', '', 'PAGE RENDER - END', StarTrackIntegrationLogging.timeNowFormatted(), null);
        }
    }
}