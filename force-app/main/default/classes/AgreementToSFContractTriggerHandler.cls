/*------------------------------------------------------------
Author:        Melissa Carino
Company:       Accenture
Description:   Trigger handler for Apttus__APTS_Agreement__c to clone Apttus Contract to Salesforce Contract
Test Class:    AgreementToSFContractTriggerHandlerTest
History
<Date>      <Authors Name>     <Brief Description of Change>
9-Sep-2018  Chester Borbon     Initial version to implement cloning of Apttus Contract to SF Contract on Apttus Contract Update to Activated
20-Sep-2018  Adrian Recio      Clean up and streamline onAfterUpdate and onBeforeDelete.
                               Added more comments and methods to make codebase reusable and readable.
19-Feb-2019   Kalpita T        Updated the entry for cloning of APT contract to create SF Contract to add extra checks
                               to exclude Status Categories - In Effect and In Signature            
29/03/1991    Ramtej           Commenting method to link files under Apttus agreement and SF contract. This method is moved to scheduler class, which is invoked on
                               activating a contract and uploading a file to apttus contract since creating file and creating/updating sf contract are not synchronous methods
                               and can't link files in the same transaction.    
24/06/2019    Ramtej           Removed Scheduled method to link files which is pushed to daily batch job instead
------------------------------------------------------------*/

public without sharing class AgreementToSFContractTriggerHandler {

    // Variable declaration

    // Static final text
    public static final string INEFFECT_STATUS_CATEGORY = 'In Effect';
    public static final string INSIGNATURE_STATUS_CATEGORY = 'In SignatureS';
    public static final string INFILING_STATUS_CATEGORY = 'In Filing';
    public static final string REQUEST_STATUS_CATEGORY = 'Request';
    public static final string INAUTHOR_STATUS_CATEGORY = 'In Authoring';
    public static final string ACTIVATED_STATUS = 'Activated';
    public static final string SIGNED = '__signed';
    public static final string COMPLETED_STATUS= 'completed';

    // Describe apttus contract and sf contract fields
    public static Map <String,String> mapFieldsSFContract = getObjectMapping('Contract');
    public static Map <String,String> mapFieldsAPTContract = getObjectMapping('Apttus__APTS_Agreement__c');

    // Set of Standard SF Contract fields
    public static Set <String> sfContractStnFieldSet = new Set<String>{'name','accountid','name','startdate'};
    public static Set <String> aptContractStnFieldSet = new Set<String>{'recordtypeid','name','id'};

    // Boolean to disable cloning and file linking logic for special apttus contract update scenarios
    public static Boolean disableCloning = false;

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Salesforce
    Description:   Trigger after update handler
    Inputs:        oldMap - Map of old Apttus__APTS_Agreement__c
                   newList - List of new Apttus__APTS_Agreement__c
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio     Trigger after update handler
    ------------------------------------------------------------*/
    public static void onAfterUpdate(Map<Id, Apttus__APTS_Agreement__c> oldMap,
        List<Apttus__APTS_Agreement__c> newList) {
        // Validate that cloning is enable for agreement update execution and
        // if update didn't came from contentversion trigger
        if(AgreementToSFContractTriggerHandler.disableCloning==false &&
                ContentVersionTriggerHandler.IsFileExistUpdate == false &&
                ContentDocumentLinkTriggerHandler.IsDocumentTypeUpdate == false) {
            cloneApttusContract(newList); // Call method to clone Apttus Contract to SF Contract
        }
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Salesforce
    Description:   Trigger before delete handler
    Inputs:        oldList - Map of old Apttus__APTS_Agreement__c
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio     Trigger before delete handler
    ------------------------------------------------------------*/
    public static void onBeforeDelete(List<Apttus__APTS_Agreement__c> oldList){
        deleteCloneSFContract(oldList); // Call method to delete clone SF Contract
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Salesforce
    Description:   Retrieve activated contracts
    Inputs:        newList - List of new Apttus__APTS_Agreement__c
    Returns:       List<Apttus__APTS_Agreement__c> - List of active agreements
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio     Retrieve activated contracts
    ------------------------------------------------------------*/
    public static List<Apttus__APTS_Agreement__c> pullActivatedContracts(List<Apttus__APTS_Agreement__c> newList){
        List<Apttus__APTS_Agreement__c> activateAgreementList = new List<Apttus__APTS_Agreement__c>();
        for(Apttus__APTS_Agreement__c aptAgreement : newList){
            //if(aptAgreement.Apttus__Status_Category__c == INEFFECT_STATUS_CATEGORY &&
                    //aptAgreement.Apttus__Status__c == ACTIVATED_STATUS){
            if(!REQUEST_STATUS_CATEGORY.equalsIgnoreCase(aptAgreement.Apttus__Status_Category__c) &&
                !INAUTHOR_STATUS_CATEGORY.equalsIgnoreCase(aptAgreement.Apttus__Status_Category__c) &&
                !INFILING_STATUS_CATEGORY.equalsIgnoreCase(aptAgreement.Apttus__Status_Category__c) &&
                !INSIGNATURE_STATUS_CATEGORY.equalsIgnoreCase(aptAgreement.Apttus__Status_Category__c) ){
                activateAgreementList.add(aptAgreement);
            }
        }
        system.debug('activateAgreementList:' + activateAgreementList);
        return activateAgreementList;
    }

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
        system.debug('existingContractMap:' + existingContractMap);
        return existingContractMap;
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Salesforce
    Description:   Method to query custom meta data of field mappings between Apttus Contract to clone SF Contract
    Inputs:        Not required
    Returns:       List<APT_Contract_Cloning__mdt> - List of meta data contract mapping
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio     Method to query custom meta data of field mappings between Apttus Contract to clone SF Contract
    ------------------------------------------------------------*/
    public static List<APT_Contract_Cloning__mdt> mdtContractMapping(){
        // Query custom meta data mapping
        // Apttus_Contract_Field__c is the api name in the apttus contract object and
        // SF_Contract__c is the api name in the target sf contract object
        List<APT_Contract_Cloning__mdt> aptContractCloneMdtList = [SELECT Id, Apttus_Contract_Field__c, SF_Contract__c
                                                                     FROM APT_Contract_Cloning__mdt];
        system.debug('aptContractCloneMdtList:' + aptContractCloneMdtList);
        return aptContractCloneMdtList;
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Salesforce
    Description:   Cloning method that creates copy of Apttus Contract to SF Contract.
    Inputs:        newList - list of agreement records for cloning
    Returns:       Database.UpsertResult[] - cloning upsert results
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio     Cloning method that creates copy of Apttus Contract to SF Contract.
    ------------------------------------------------------------*/
    public static Database.UpsertResult[] cloneApttusContract(List<Apttus__APTS_Agreement__c> newList){

        List<APT_Contract_Cloning__mdt> aptContractCloneMdtList = mdtContractMapping();
        List<Contract> contractUpdateList = new List<Contract>(); // List of contracts to be inserted/updated
        List<Apttus__APTS_Agreement__c> activatedAgreementList = pullActivatedContracts(newList); // Retrieve Activated contracts

        Database.UpsertResult[] resultCloneContractList;

        // Pull existing clone Salesforce contracts
        List<Contract> existConList = [Select id, Parent_Agreement__c
        from Contract
        where Parent_Agreement__c IN : activatedAgreementList];
        system.debug('existConList:' + existConList);

        // Call method to  build map of Agreement (key) and SF Contract (Value)
        Map<Id, Contract> existingContractMap = buildParentContractToCloneSFMap(existConList);

        // Loop across active agreements to perform creation or sync of values to clone sf contract
        for (Apttus__APTS_Agreement__c ApttusAgreement : activatedAgreementList) {
            Contract contractUpdate = New Contract(); // New contract instance

            // Pull original salesforce contract clone if it is existing
            if (existingContractMap.containsKey(ApttusAgreement.Id)) {
                contractUpdate = existingContractMap.get(ApttusAgreement.Id);
            }

            system.debug('Clone match (contractUpdate):' + contractUpdate);

            // Loop across custom meta data contract mapping values to match against the apttus agreement contract to populate value
            for(APT_Contract_Cloning__mdt aptContractCloneMdt: aptContractCloneMdtList){
                // Validate that meta data api mapping configuration is aligned
                // with the field type that can be mapped across Apttus Contract and SF Contract object
                string sfContractString = aptContractCloneMdt.SF_Contract__c.tolowercase();
                string aptContractString = aptContractCloneMdt.Apttus_Contract_Field__c.tolowercase();

                if((mapFieldsSFContract.containsKey(sfContractString) || sfContractStnFieldSet.contains(sfContractString))
                        &&
                        (mapFieldsAPTContract.containsKey(aptContractString) || aptContractStnFieldSet.contains(aptContractString))
                        ) {
                    contractUpdate.put(aptContractCloneMdt.SF_Contract__c, ApttusAgreement.get(aptContractString));
                }
            }

            if (ApttusAgreement.Apttus__Contract_Start_Date__c != Null &&
                    ApttusAgreement.Apttus__Contract_End_Date__c != Null) {
                        //Since ContractTerm field accepts only 4 digits, dont copy the data if it exceeds the value
                        Integer MonthDiff = ApttusAgreement.Apttus__Contract_Start_Date__c.monthsBetween(ApttusAgreement.Apttus__Contract_End_Date__c);
                        if(MonthDiff > 0 && MonthDiff <= 9999){
                            contractUpdate.ContractTerm = MonthDiff;
                        }                        
            }

            system.debug('After mapping value (contractUpdate):' + contractUpdate);

            if (contractUpdate != NULL) {
                contractUpdateList.add(contractUpdate);
            }
        }

        system.debug('contractUpdateList:' + contractUpdateList);

        // Upsert contracts
        if (contractUpdateList.size() > 0) {
            resultCloneContractList = Database.upsert(contractUpdateList, false);
            system.debug('Upsert Result:' + resultCloneContractList);
            system.debug('Upsert Contract List:' + contractUpdateList);

            // Link files to clone sf contract
            // Commenting method to link files under Apttus agreement and SF contract. This method is moved to scheduler class, which is invoked on
            //activating a contract and uploading a file to apttus contract since creating file and creating/updating sf contract are not synchronous methods
            //and can't link files in the same transaction.
            //resultFileLinkList = ContentDocumentLinkTriggerHandler.linkExistingFiles(activatedAgreementList, contractUpdateList);
            system.debug('invoking from AgreementToSFContractTriggerHandler ');
            //schedule class to link apttus contract files to sf contract            
            APT_ContractFileShareScheduler fileShareScheduler = new APT_ContractFileShareScheduler();
            //Removed Scheduled method to link files which is pushed to daily batch job instead
            //fileShareScheduler.linkFilesHelper(contractUpdateList,2,'cloning contracts');
        }

        // Return list of fail/success result
        return resultCloneContractList;
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Salesforce
    Description:   Method to delete SF Contracts if parent Apttus Contract is deleted
    Inputs:        oldList - List of old apttus contracts
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio     Method to delete SF Contracts if parent Apttus Contract is deleted
    ------------------------------------------------------------*/
    public static void deleteCloneSFContract(List<Apttus__APTS_Agreement__c> oldList){
        List<Id> agreementGotDeleted = new List<Id>();  //Create a  new list
        for(Apttus__APTS_Agreement__c agmt : oldList){
            agreementGotDeleted.add(agmt.ID);
        }
        List<Contract> contractsAlreadyThere = [Select id , Parent_Agreement__c
                                                from Contract
                                                where  Parent_Agreement__c In : agreementGotDeleted];

        system.debug('Clone SF Contract for delete:' + contractsAlreadyThere);
        if(!contractsAlreadyThere.isEmpty()){
            delete contractsAlreadyThere;
        }
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Salesforce
    Description:   Method to get the Object Mapping based on Describe
    Inputs:        objName - Object api name for meta data describe
    Returns:       Map<String,String>  - Map of field api names that is custom, editable and not a formula
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    20-Sep-2018  Adrian Recio     Method to get the Object Mapping based on Describe
    ------------------------------------------------------------*/
    public static Map<String,String> getObjectMapping(String objName) {
        Map<String,String> mapFieldsApiNameLabel = new Map<String,String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();

        for (String fieldName: fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();

            // Retrieve all api label and name of Apttus Contract fields where type is custom, accessiable and not formula
            if(fieldResult.isAccessible() && fieldResult.isCustom() && fieldResult.getCalculatedFormula()==null) {
                mapFieldsApiNameLabel.put(fieldName.tolowercase(), fieldMap.get(fieldName).getDescribe().getLabel());
            }

        }
        system.debug('Mapping of - '+ objName + mapFieldsApiNameLabel);
        return mapFieldsApiNameLabel;
    }
    
    /*------------------------------------------------------------
    Author:        Shashwat  Nath
    Company:       Accenture
    Description:   Method to stop Activating the contract manually by changing the status
    Inputs:        Trigger.new
    Returns:       N/A
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    08-May-2019  Shashwat  Nath     Method to stop Activating the contract manually by changing the status
    ------------------------------------------------------------*/
    public static void restrictActivation(Map<id,Apttus__APTS_Agreement__c> contractMap) {
        boolean dontShowError = false;
        Map<Id,List<Attachment>> agreementAttachmentMap = new Map<Id,List<Attachment>>();
        Map<Id,List<String>> agreementFileTitleMap = new Map<Id,List<String>>();
        //Iterating over all the attachments to form a map of Contract and List of attachments to it
        try{
            for(Attachment atc : [Select id , name, parentid from attachment where parentId IN : contractMap.keyset()]){
                if(agreementAttachmentMap.keyset()!=null && agreementAttachmentMap.keyset().contains(atc.parentId)){
                    agreementAttachmentMap.get(atc.parentId).add(atc);
                }
                else{
                    agreementAttachmentMap.put(atc.parentId, new List<Attachment>{atc});    
                }
            }
            
            for(contentDocumentLink contDocLink : [Select id, contentdocumentId,LinkedEntityId, contentdocument.title from contentdocumentlink where LinkedEntityId IN : contractMap.keyset()]){
                 if(agreementFileTitleMap.keyset()!=null && agreementFileTitleMap.keyset().contains(contDocLink.LinkedEntityId)){
                    agreementFileTitleMap.get(contDocLink.LinkedEntityId).add(contDocLink.contentdocument.title);
                }
                else{
                    agreementFileTitleMap.put(contDocLink.LinkedEntityId , new List<String>{contDocLink.contentdocument.title});    
                }    
            }
            //Iterating over Contract
            for(Apttus__APTS_Agreement__c agr :contractMap.values()){
                // Checking if document signed field on Contract is checked or any attachment under contract is Signed
                if(!agr.Is_Document_Signed__c && (agreementAttachmentMap.keyset().size()>0 || agreementFileTitleMap.keyset().size()>0) ){
                    if(agreementAttachmentMap.keyset().size()>0){
                        for(Attachment atch : agreementAttachmentMap.get(agr.id)){
                            if(atch.name.contains(SIGNED) && COMPLETED_STATUS.equalsIgnoreCase(contractMap.get(atch.parentid).Docusign_Envelope_Status__c)){
                                dontShowError = true;
                                break;
                            }
                        }
                    }
                    if(!dontShowError){
                        for(String str : agreementFileTitleMap.get(agr.id)){
                            system.debug('*** Inside Agreement File Map ****');
                            if(str.contains(SIGNED) && COMPLETED_STATUS.equalsIgnoreCase(agr.Docusign_Envelope_Status__c)){
                                system.debug('*** Inside Agreement File Map 1****');
                                dontShowError =true;
                                break;
                            }
                        }
                        if(!dontShowError){
                            dontShowError = false;
                            //Throwing Error to show document is unsigned
                            agr.addError(Label.Unisgned_Document_Error);
                        }
                    } 
                }
                else if(agr.Is_Document_Signed__c && (!(agreementAttachmentMap.keyset().size()>0) && !(agreementFileTitleMap.get(agr.id).size()>0))){
                    //Throwing Error to show document is unsigned 
                    agr.addError(Label.Unisgned_Document_Error);
                }
            }
        }
        
        catch(exception ex){
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Docusign', 
                                                    'AgreementToSFContractTriggerHandler', 'restrictActivation', 
                                                    'AgreementToSFContractTrigger', LoggingLevel.ERROR);
        }
        
    }
}