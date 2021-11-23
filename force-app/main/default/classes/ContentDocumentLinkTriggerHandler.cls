/*------------------------------------------------------------
Author:        Adrian Recio
Company:       Accenture
Description:   Handler class for ContentDocumentLink Trigger
Test Class:    ContentDocumentLinkTriggerHandler_Test
History
<Date>      <Authors Name>     <Brief Description of Change>
12-Sep-2018  Adrian Recio       Intial version which contains the after insert trigger handler and
                                method calls and method to assign the document type to content version
                                related to the inserted content document link based on its parent linkentityId.
24-Jun-2019  Ramtej Juloori		Removed Scheduled method to link files which is pushed to daily batch job instead
28-SEP-2021  Rajesh Punjabi     Added sharing file with partner functionality for DSR Object.
------------------------------------------------------------*/
public class ContentDocumentLinkTriggerHandler {
    // Constants
    public static final String ALL_USERS = 'AllUsers';
    public static final string INTERNAL_USERS='InternalUsers';
    public static final string VISIBILITY_INTERNAL_USERS='InternalUsers';
    public static final string SHARE_TYPE_V='V';
    public static final string METHOD_ONAFTERINSERT='onAfterInsert';
    public static final string METHOD_ONAFTERDELETE='onAfterDelete';
    public static final string METHOD_ONAFTERUPDATE='onAfterUpdate';
    public static final string CALLOUTEXCEPTION='ContentDocumentLinkTriggerHandler Exception';
    public static final string CLASS_CDLTRIGGERHANDLER='ContentDocumentLinkTriggerHandler';
    public static final string METHODEXCEPTION='METHODEXCEPTION';
    public static final string ERROR='ERROR';
    public static final string REC_TYPE_MSA = 'MSA & Service Schedule';
    public static final string REC_TYPE_DOV = 'DoV Contract';
    public static final string REC_TYPE_RENEWAL = 'Renewal Contract';
    public static final string REC_TYPE_COMMUNITY = 'Community Update Pack';
    public static final string REC_TYPE_INTENT = 'Letter of Intent';
    public static final string REC_TYPE_BILLPAY = 'Post Billpay Contract';
    public static final string REC_TYPE_REBATE = 'Rebate Contract';
    public static final string REC_TYPE_SECUREPAY = 'SecurePay Online Payments';
    public static final string DOC_TYPE_CONTRACT='Contract';
    public static final string DOC_TYPE_DOV='Deed of Variation';
    public static final string DOC_TYPE_RENEWAL='Renewal';
    public static final string NEW_CONTRACT='New Contract';
    public static final string DOV_CONTRACT='DoV Contract';
    public static final string RENEWAL_CONTRACT='Renewal Contract';
    public static final string MIGRATED_CONTRACT='Migrated Contract';
    // Instantiate document type map
    public static Map<String, Map<String,String>> documentTypeMap = ContentDocumentLinkTriggerHandler.buildDocumentTypeMap();
    // Instantiate recursive boolean variables
    public static Boolean IsDocumentTypeUpdate = false;
    public static Boolean IsFileLink = false;

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Trigger after insert handler
    Inputs:        cdlList - List of content documents
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/10/2018   Adrian Recio        Trigger after insert handler
    29/03/2019  Ramtej Juloori      commented linkExistingFiles method to link files under Apttus agreement and SF contract. 
                                    This method is moved to scheduler class, which is invoked on activating a contract and uploading a file to apttus contract.
	28-SEP-2021  Rajesh Punjabi     Added method call for sharing file with partner.
    ------------------------------------------------------------*/
    public static void onAfterInsert(List<ContentDocumentLink> cdlList){
		
        //.. share file with partner for DSR Object only.
        shareDSRFileWithCustomer(cdlList);
        
        // validate that disable trigger cloning is not disabled
        if(AgreementToSFContractTriggerHandler.disableCloning == false) {
            // Update document type of content version based on inserted content document link's entity Id
            cdlUpdateDocumentType(cdlList);
            
            // Boolean added to make sure recursive scenarios will not
            // be encountered when new set of cdl is inserted for the clone sf contract
            //commenting method link file from apttus contract to sf contract
            if (IsFileLink == false) {
                //cdlLinkExistingFiles(cdlList);                
            }
            
            //filter contetntdocuments which are created only for apttus contracts
            List<Id> relatedContractId = new List<Id>();
            for(ContentDocumentLink cdl :cdlList){
                if(cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Apttus__APTS_Agreement__c'){
                    relatedContractId.add(cdl.LinkedEntityId);
                }
            }
            
            //query the related sf contracts
            if(relatedContractId != null && relatedContractId.size() > 0){
                List<Contract> relatedContractList = [SELECT Id, Parent_Agreement__c FROM Contract WHERE Parent_Agreement__c IN :relatedContractId];
                if(relatedContractList != null && relatedContractList.size() > 0){                    
                    //schedule class to link apttus contract files to sf contract  
                    system.debug('invoking from ContentDocumentLinkTriggerHandler');          
                    APT_ContractFileShareScheduler fileShareScheduler = new APT_ContractFileShareScheduler();
                    //Removed Scheduled method to link files which is pushed to daily batch job instead
                    //fileShareScheduler.linkFilesHelper(relatedContractList,3,'file added');
                }                    
            }
        }
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Salesforce
    Description:   Trigger after delete handler
    Inputs:        cdlList - List of content documents
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/10/2018   Adrian Recio        Trigger after delete handler
    ------------------------------------------------------------*/
    public static void onAfterDelete(List<ContentDocumentLink> cdlList){
        // validate that disable trigger cloning is not disabled
        if(AgreementToSFContractTriggerHandler.disableCloning == false) {
            // On delet of cdl evaluate if file exist and roll up boolean value to parent apttus contract
            ContentVersionTriggerHandler.fileExistCheck(cdlList);
        }
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Method update document type of content version based on inserted content document link's entity Id
    Inputs:        cdlList - List of new content documents
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/10/2018   Adrian Recio        Method to create content document link from Files to SF Contract
    ------------------------------------------------------------*/

    public static void cdlUpdateDocumentType(List<ContentDocumentLink> cdlList) {
        // Link entity id set
        Set<Id> linkEntityIdSet = new Set<Id>();

        // Create a LinkedEntityID Set to use it in querying the Apttus Contract Map
        for(ContentDocumentLink cdlVar: cdlList){
            linkEntityIdSet.add(cdlVar.LinkedEntityId);
        }

        system.debug('linkEntityIdSet:' + linkEntityIdSet);

        // Query agreement list based on linkentityid set
        List<Apttus__APTS_Agreement__c> parentAgList = [SELECT ID, Name,RecordType.Name,
                                                        APT_Contract_Type__C, APT_has_file__c
                                                        from Apttus__APTS_Agreement__c
                                                         where ID IN :linkEntityIdSet];
        system.debug('parentAgList:' + parentAgList);
        updateDocumentType(parentAgList,cdlList);

    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Method that updates the document type of the file
                   ContentVersion is the object where custom fields for Salesforce Files are being utilized
    Inputs:        aptContractList - List of parent agreements
                   cdlList - List of content document link related to agreements
    Returns:       Database.SaveResult[] - update result
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/10/2018   Adrian Recio       First version.
    ------------------------------------------------------------*/
    public static void updateDocumentType(List<Apttus__APTS_Agreement__c> aptContractList,
                                          List<ContentDocumentLink> cdlList){
        // Create Content Document ID Set to help with our query
        Set<ID> cdIDSet = new Set<ID>();
        for(ContentDocumentLink cdl: cdlList){
            cdIDSet.add(cdl.ContentDocumentID);
        }
        
        // Retrieve the List of Content Version and specifying that it is the latest version
        List<ContentVersion> cvList = new List<ContentVersion>([Select ID, ContentDocumentID, Document_Type__c, IsLatest
                                                                from ContentVersion
                                                                where ContentDocumentID IN :cdIDSet AND IsLatest=TRUE]);
        system.debug('Document Type Update CV List - ' + cvList);
        // Create a map of the Apttus Contract to be used in retrieving the Apttus Contract record to determine the Document Type
        Map<ID, Apttus__APTS_Agreement__c> aptContractMap = new Map<ID, Apttus__APTS_Agreement__c>(aptContractList);
        
        // Create a map of to link Apttus Contract ID and ContentVersion ID to help with our scenarios
        Map<ID, ID> cdlAPTLinkMap = new Map<ID, ID>();
        
        // Iterate over ContentDocumentLink. Utilize the ContentDocumentID and LinkedEntityID
        for (ContentDocumentLink cdl: cdlList){
            // Check the ContentDocumentID values for both ContentDocumentLink and ContentVersion
            for (ContentVersion cvItem : cvList){
                if (cdl.ContentDocumentId==cvItem.ContentDocumentId){
                    cdlAPTLinkMap.put(cvItem.ID, cdl.LinkedEntityId);
                }
            }
        }

        // List of content version for document type update
        List<ContentVersion> cvListUpdate = new List<ContentVersion>();

        // Loop across content versions related to content document link and apttus contract
        for(ContentVersion cv : cvList){
            // Retrieve content document link and apttus contract related to content version
            if(cdlAPTLinkMap.containsKey(cv.ID)){
                Apttus__APTS_Agreement__c aptContract = aptContractMap.get(cdlAPTLinkMap.get(cv.ID));

                if(aptContract!=null) {
                    // Call method to identify content version document type based on contract type and record type
                    checkDocumentType(aptContract, cv);

                    // Add to update list
                    cvListUpdate.add(cv);
                }
            }
        }
        // Commit update list if list is not null
        if(cvListUpdate.size()>0){
            IsDocumentTypeUpdate = true;
            update cvListUpdate;
            //system.debug('Document Type Update CV List UPDATE - ' + cvListUpdate);
        }
    }

    /*------------------------------------------------------------
   Author:        Adrian Recio
   Company:       Accenture
   Description:   Method to build mapping of Apttus Contract recordtype and contract type to ContentVersion's document type.
   Inputs:        aptContract - parent agreement
                  cv - content version record
   Returns:       void
   History
   <Date>      <Authors Name>     <Brief Description of Change>
   5/10/2018   Adrian Recio       First version.
   ------------------------------------------------------------*/
    public static Map<String, Map<String,String>> buildDocumentTypeMap(){

        Map<String, Map<String,String>> docTypeMap = new Map<String, Map<String,String>>();

        // Create map containing the mapping of contract type to document type for MSA, community, billpay and rebate record types
        Map<String,String> contractDocTypeMap = new Map<String,String>();
        contractDocTypeMap.put(NEW_CONTRACT,DOC_TYPE_CONTRACT);
        contractDocTypeMap.put(MIGRATED_CONTRACT,DOC_TYPE_CONTRACT);
        contractDocTypeMap.put(DOV_CONTRACT,DOC_TYPE_DOV);
        contractDocTypeMap.put(RENEWAL_CONTRACT,DOC_TYPE_RENEWAL);

        docTypeMap.put(REC_TYPE_MSA,contractDocTypeMap); // MSA Recordtype mapping to contract type and document type
        docTypeMap.put(REC_TYPE_COMMUNITY,contractDocTypeMap); // Community Recordtype mapping to contract type and document type
        docTypeMap.put(REC_TYPE_BILLPAY,contractDocTypeMap); // Billpay Recordtype mapping to contract type and document type
        docTypeMap.put(REC_TYPE_REBATE,contractDocTypeMap); // Rebate Recordtype mapping to contract type and document type

        // Create map containing the mapping of contract type to document type for Letter of intent and secure pay record types
        Map<String,String> contractDocTypeMap2 = new Map<String,String>();
        contractDocTypeMap.put(NEW_CONTRACT,DOC_TYPE_CONTRACT);

        docTypeMap.put(REC_TYPE_INTENT,contractDocTypeMap2); // Letter of Intent Recordtype mapping to contract type and document type
        docTypeMap.put(REC_TYPE_SECUREPAY,contractDocTypeMap2); // Secure pay Recordtype mapping to contract type and document type

        return docTypeMap;
    }


    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Method to build mapping of Apttus Contract recordtype and contract type to ContentVersion's document type.
    Inputs:        aptContract - parent agreement
                   cv - content version record
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/10/2018   Adrian Recio       First version.
    ------------------------------------------------------------*/
    public static void checkDocumentType(Apttus__APTS_Agreement__c aptContract, ContentVersion cv){
        // Get document type mapping to contract type based on agreement recordtype name
        Map<string,string> contractDocTypeMap = documentTypeMap.get(aptContract.RecordType.Name);

        // If value exist, get document type based on agreement contract type
        if(contractDocTypeMap!=null){
            if(cv.Document_Type__c==null) {
                cv.Document_Type__c = contractDocTypeMap.get(aptContract.APT_Contract_Type__c);
            }
        }
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Trigger after insert handler
    Inputs:        cdlList - List of content documents
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    5/10/2018   Adrian Recio        Trigger after insert handler
    ------------------------------------------------------------*/
    //commenting method and moved logic to scheduler class
    /*public static void cdlLinkExistingFiles(List<ContentDocumentLink> cdlList){
        //Get the Ids for Apttus agreements
        Set<ID> cdlIdSet = new Set<ID>();
        for(ContentDocumentLink cdlVar: cdlList){
            cdlIdSet.add(cdlVar.LinkedEntityId);
        }

        system.debug('cdlIdSet:' + cdlIdSet);

        //Query all Apttus Agreements related to content document link
        List<Apttus__APTS_Agreement__c> aptContractList = new List<Apttus__APTS_Agreement__c>([SELECT ID, Name,RecordType.Name, APT_Contract_Type__C, APT_has_file__c,
                                                                                                (SELECT ID, Name, Parent_Agreement__c from SFCon_Agreements__r)
                                                                                                from Apttus__APTS_Agreement__c
                                                                                                where ID IN :cdlIdSet]);
        //Store child sf contracts in a separate list
        List<Contract> sfConList = new List<Contract>();
        for(Apttus__APTS_Agreement__c agVar: aptContractList){
            sfConList.addAll(agVar.SFCon_Agreements__r);
        }

        system.debug('aptContractList:' + aptContractList);
        system.debug('sfConList:' + sfConList);

        //If agreement and sf contract match exist, execute file linking logic
        if(aptContractList.size()>0 && sfConList.size()>0) {
            IsFileLink = true;
            Database.SaveResult[] resultFileLinkList = ContentDocumentLinkTriggerHandler.linkExistingFiles(aptContractList, sfConList);
            system.debug('resultFileLinkList:' + resultFileLinkList);
        }
    }*/

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Salesforce
    Description:   Method to  build map of Agreement (key) and SF Contract (Value)
    Inputs:        existConList - List of new Apttus__APTS_Agreement__c
    Returns:       Map<Id, Contract> - Map of Salesforce contracts where key is Contract Id
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio     Method to  build map of Agreement (key) and SF Contract (Value)
    ------------------------------------------------------------*/
    public static Map<Id, Contract> buildParentContractToCloneSFMap(List<Contract> existConList){
        Map<Id, Contract> existingContractMap = new Map<Id, Contract>();
        for(Contract conVar: existConList){
            existingContractMap.put(conVar.Parent_Agreement__c , conVar);
        }
        //system.debug('existingContractMap:' + existingContractMap);
        return existingContractMap;
    }
    
    
    /**
     * Author:         Rajesh Punjabi
     * Company:        Mav3rik
     * Description:    Share file with Partners after upload.
     * History
     * <Date>      <Authors Name>      <Brief Description of Change>
     * 28-09-2021  Rajesh Punjabi       Initial Version
	*/
    
    public static void shareDSRFileWithCustomer(List<ContentDocumentLink> cdlList){
        try{
            String strKeyPrefix = Deal_Support_Request__c.SObjectType.getDescribe().getKeyPrefix();
			Map<Id,ContentDocumentLink>  mapCdlDsr = new Map<Id,ContentDocumentLink>();
            
            for(ContentDocumentLink cdl:cdlList){
                if(String.valueOf(cdl.LinkedEntityId).startsWith(strKeyPrefix) ){
                    mapCdlDsr.put(cdl.LinkedEntityId, cdl);
                }
            }
            
     
            
            List<Deal_Support_Request__c> lstDSR = [SELECT Id, Requestor__c, Requestor__r.Profile.Name 
                                                    FROM Deal_Support_Request__c 
                                                    WHERE Id IN: mapCdlDsr.keySet() 
                                                    AND Requestor__c != null 
                                                    AND Requestor__r.Profile.Name = 'LPO Partner Community User'];
            
            for (Deal_Support_Request__c oDSR: lstDSR){
                if(mapCdlDsr.containsKey(oDSR.Id)){
                    ContentDocumentLink oCdl = mapCdlDsr.get(oDSR.Id);
                    oCdl.Visibility = ALL_USERS;
                }   
            }
            
        }
        catch(Exception ex){
            GlobalUtility.logMessage('Error', 'ContentDocumentLinkTriggerHandler', 'shareDSRFileWithCustomer', '', '', ex.getMessage(), '', ex, 0);
        }
    }
    
    
    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Salesforce
    Description:   Method to perform file linking for existing files
    Inputs:        aptContractList - List of apttus contracts
                   sfContractList - List of sf contracts
    Returns:       Database.SaveResult[] - file linking insert result
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio     Method to perform file linking for existing files
    ------------------------------------------------------------*/
    //commenting method and moved logic to scheduler class
    /*public static Database.SaveResult[] linkExistingFiles(List<Apttus__APTS_Agreement__c> aptContractList , List<Contract> sfContractList) {

        system.debug('aptContractList:' + aptContractList);
        system.debug('sfContractList:' + sfContractList);

        Database.SaveResult[] results;

        // Build map of Apttus Contract where Id (Key) and Apttus Contract (Value)
        Map<Id, Apttus__APTS_Agreement__c> aptContractMap = new Map<Id, Apttus__APTS_Agreement__c>(aptContractList);
        Set<Id> aptContractIdSet = aptContractMap.keySet();

        system.debug('aptContractMap:' + aptContractMap);
        system.debug('aptContractIdSet:' + aptContractIdSet);

        // Build map of SF Contract where Id (Key) and SF Contract (Value)
        Map<Id, Contract> sfContractMap = new Map<Id, Contract>();
        try {
            sfContractMap = new Map<Id, Contract>(sfContractList);
        }catch(Exception e){
            system.debug('SF Contract map assignment failed.');
        }
        Set<Id> sfContractIdSet = sfContractMap.keySet();

        system.debug('sfContractIdSet:' + sfContractIdSet);

        // Retrieve all content document links related to Apttus and SF Contracts where visibiity is for Internal Users
        List<ContentDocumentLink> cdlList = [SELECT ID, LinkedEntityID, ContentDocumentID, Visibility
                                            FROM ContentDocumentLink
                                            WHERE Visibility = :ContentDocumentLinkTriggerHandler.INTERNAL_USERS and
                                            (LinkedEntityID IN :aptContractIdSet or LinkedEntityID IN :sfContractIdSet)];

        system.debug('cdlList:' + cdlList);

        // Build map where LinkEntityId is key and list of content document link is the value
        Map<Id, List<ContentDocumentLink>> cdlGroupByLinkEntity = new Map<Id, List<ContentDocumentLink>>();

        for(ContentDocumentLink cdlVar: cdlList){
            // If key exist reuse existing list value
            if(cdlGroupByLinkEntity.containsKey(cdlVar.LinkedEntityID)){
                List<ContentDocumentLink> cdlTempList = cdlGroupByLinkEntity.get(cdlVar.LinkedEntityID);
                cdlTempList.add(cdlVar);
                cdlGroupByLinkEntity.put(cdlVar.LinkedEntityID,cdlTempList);
                // If not create a new list value
            }else{
                List<ContentDocumentLink> cdlTempList = new List<ContentDocumentLink>();
                cdlTempList.add(cdlVar);
                cdlGroupByLinkEntity.put(cdlVar.LinkedEntityID,cdlTempList);
            }
        }

        system.debug('cdlGroupByLinkEntity:' + cdlGroupByLinkEntity);

        // Call method to  build map of Agreement (key) and SF Contract (Value)
        Map<Id, Contract> existingContractMap = buildParentContractToCloneSFMap(sfContractList);

        system.debug('existingContractMap:' + existingContractMap);

        // List of content document link to be created
        List<ContentDocumentLink> cdlToCreate = new List<ContentDocumentLink>();

        for(Apttus__APTS_Agreement__c aptContract: aptContractList){

            // Get Content Document Link for Agreement
            List<ContentDocumentLink> cdChildlList = cdlGroupByLinkEntity.get(aptContract.Id);
            system.debug('cdChildlList:' + cdChildlList);

            // Get clone SF Contract
            Contract sfContractClone = existingContractMap.get(aptContract.Id);
            system.debug('sfContractClone:' + sfContractClone);

            // Get list of ContentDocumentLink
            List<ContentDocumentLink> cdChildlListClone = cdlGroupByLinkEntity.get(sfContractClone.Id);
            system.debug('cdChildlListClone:' + cdChildlListClone);

            // Validate all Apttus Contract ContentDocumentLink's cloning validity
            if(cdChildlList != null) {
                for (ContentDocumentLink cdl : cdChildlList) {

                    // Loop across clone SF Contract's content document link, if same contentdocumentId is found, linking is not necessary
                    Boolean IsDuplicateVar = false;
                    if (cdChildlListClone != null) {
                        for (ContentDocumentLink cdlClone : cdChildlListClone) {
                            if (cdlClone.ContentDocumentID == cdl.ContentDocumentID) {
                                IsDuplicateVar = true;
                            }
                        }
                    }

                    system.debug('cdl:' + cdl);
                    system.debug('IsDuplicateVar:' + IsDuplicateVar);

                    // If file linking is necessary create content document link from SF Contract to File
                    if (IsDuplicateVar == false) {
                        ContentDocumentLink cdlSFContract = new ContentDocumentLink();
                        cdlSFContract.ContentDocumentId = cdl.ContentDocumentID;
                        cdlSFContract.LinkedEntityId = sfContractClone.ID;
                        cdlSFContract.ShareType = ContentDocumentLinkTriggerHandler.SHARE_TYPE_V;
                        cdlSFContract.Visibility = ContentDocumentLinkTriggerHandler.VISIBILITY_INTERNAL_USERS;
                        cdlToCreate.add(cdlSFContract);
                    }
                }
            }
        }

        system.debug('cdlToCreate:' + cdlToCreate);

        // Create content document link if list has value
        if(cdlToCreate.size()>0){
            results = Database.insert(cdlToCreate, false);
        }
        //Added for Batch Job to get the RecId
        system.debug('insert results:' + results);
        return results;
    }*/

}