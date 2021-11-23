/*
@Description 		: Apex class to handle customer onboarding contact view lightning component 
@Author				: Ramtej Juloori
@Created			: 10/12/2018

================================ Modification Log =============================== 
Developer Name 	Date 			Comments

*/

public with sharing class CustomerOnboardingViewContactStatusCtrl{
    public String jsonCases {get; set;}
        
    private ApexPages.StandardSetController standardController;
    public List<string> caseIdList {get; set;}
    public CustomerOnboardingViewContactStatusCtrl(ApexPages.StandardSetController standardController)
    {
        this.standardController = standardController;
    }

    public Pagereference selectedCases(){
        
        List<Case> caseList = (List<Case>) standardController.getSelected();
        caseIdList = new List<String>();
        for(Case cs :caseList){
            caseIdList.add(cs.Id);
        }

        jsonCases = JSON.serialize(caseIdList);
        return null;
    }
    
    @AuraEnabled
    public static List<string> getCaseIds(){
        List<string> caseIdList = new List<string>();
        for(Case cs :[SELECT Id FROM Case WHERE Status != 'Closed' AND RecordType.Name = :Constants.RECORDTYPE_NAME_CUSTOMER_ONBOARDING]){
            caseIdList.add(cs.Id);
        }       
        return caseIdList;
    }
    
    /*
    @Description 		: Apex method to get the list of Contacts of related Assets (With Product TandC)
                            of the Parent Legal entity for the selected Cases 
    @Params             : List of Ids (Case Ids)
    @Return             : List<contactdetailsWrapper> - wrapper class with mapping of case and related 
                            Assets grouped with same name
    */
    @AuraEnabled
    public static List<parentCaseMappingWithContactDetails> getContacts(list<string> caseIds){
        try{
            if(caseIds.size() <= 0){
                caseIds = getCaseIds();
                system.debug('caseIds '+caseIds);
                if(caseIds.size() <= 0){
                    AuraHandledException e = new AuraHandledException('No Open cases found.');
                    e.setMessage('No Open cases found.');
                    system.debug(e);
                    throw e;
                }
            }
            //Query the list of cases using the Ids passed - Add the Case fields in Query to be used in 
            //lightning component
            system.debug('caseIds '+caseIds);
            if(caseIds != null && caseIds.size() > 0){
                List<Case> caseList = [SELECT Id, AccountId, CaseNumber, Parent.CaseNumber, ParentId FROM Case WHERE 
                ParentId IN :caseIds AND Parent.Status != 'Closed' AND Parent.RecordType.Name = :Constants.RECORDTYPE_NAME_CUSTOMER_ONBOARDING];              
                List<parentCaseMappingWithContactDetails> parentCaseContactMapping = new List<parentCaseMappingWithContactDetails>();               
                List<Id> accountIds = new List<Id>();
                Map<Id, List<Case>> parentChildCasesMapping = new Map<Id, List<Case>>();
                for(Case cs :caseList){
                    accountIds.add(cs.AccountId);
                    List<Case> tempCaseList = new List<Case>();
                    if(parentChildCasesMapping.containsKey(cs.ParentId)){
                        tempCaseList = parentChildCasesMapping.get(cs.ParentId);
                    }
                    tempCaseList.add(cs);
                    parentChildCasesMapping.put(cs.ParentId, tempCaseList);
                }
                //Map parent cases with its case numbers
                Map<string, case> parentCaseIdCaseMap = new Map<string, case>();
                for(Case cs :[SELECT Id, CaseNumber, Subject, Status FROM Case WHERE Id IN :parentChildCasesMapping.keySet()]){
                    parentCaseIdCaseMap.put(cs.Id, cs);
                }
                system.debug('parentChildCasesMapping '+parentChildCasesMapping);
                Map<Id, Map<string,List<Asset>>> accountToAssetMap = new Map<Id, Map<string,List<Asset>>>();
                //Iterate through the realated Assets of parent legal entity of the cases queried
                //With a contact specified and with Product 'TandC'
                SecurePost__c securePostSetting = SecurePost__c.getInstance(); // Get SecurePost Custome Setting for Asset Name
                for(Asset ass :[SELECT Id, Name, ContactId, 
                    Contact.Name, AccountId, Status FROM Asset WHERE Name = :securePostSetting.TandCName__c AND AccountId IN :accountIds AND
                    Product2.Name = 'TandC' AND ContactId != null]){
                        Map<string,List<Asset>> innerAssetMap = new Map<string,List<Asset>>();
                        if(accountToAssetMap.containsKey(ass.AccountId)){
                            innerAssetMap = accountToAssetMap.get(ass.AccountId);
                            if(innerAssetMap.containsKey(ass.Name)){
                                List<Asset> tempList = innerAssetMap.get(ass.Name);
                                tempList.add(ass);
                                innerAssetMap.put(ass.Name,tempList);
                            }
                            else{
                                innerAssetMap.put(ass.Name,new List<Asset>{ass});
                            }
                        }
                        else{
                            innerAssetMap.put(ass.Name,new List<Asset>{ass});
                        }               
                        accountToAssetMap.put(ass.AccountId, innerAssetMap);
                }
                for(Id parentCaseId :parentChildCasesMapping.keySet()){
                    parentCaseMappingWithContactDetails parentCaseMapConDetails = new parentCaseMappingWithContactDetails();
                    parentCaseMapConDetails.parentCase = parentCaseIdCaseMap.get(parentCaseId);
                    parentCaseMapConDetails.parentCaseId = parentCaseIdCaseMap.get(parentCaseId).Id;
                    parentCaseMapConDetails.parentCaseURL = URL.getSalesforceBaseUrl().toExternalForm()+'/'+parentCaseIdCaseMap.get(parentCaseId).Id;
                    parentCaseMapConDetails.parentCaseNumber = parentCaseIdCaseMap.get(parentCaseId).CaseNumber;
                    parentCaseMapConDetails.parentCaseStatus = parentCaseIdCaseMap.get(parentCaseId).Status;
                    parentCaseMapConDetails.parentCaseSubject = parentCaseIdCaseMap.get(parentCaseId).Subject;
                    Integer contactSize = 0;
                    List<contactdetailsWrapper> condetWrapList = new List<contactdetailsWrapper>();
                    for(Case cs :parentChildCasesMapping.get(parentCaseId)){
                        List<AssetGroupingWrapper> assetConMapList = new List<AssetGroupingWrapper>();
                        if(accountToAssetMap.containsKey(cs.AccountId)){
                            for(string assetName :accountToAssetMap.get(cs.AccountId).keySet()){
                                AssetGroupingWrapper assetConMap = new AssetGroupingWrapper(assetName, accountToAssetMap.get(cs.AccountId).get(assetName));
                                contactSize += accountToAssetMap.get(cs.AccountId).get(assetName).size();
                                assetConMapList.add(assetConMap);
                            }
                            contactdetailsWrapper condetWrap = new contactdetailsWrapper(cs,assetConMapList);
                            condetWrapList.add(condetWrap);
                        }
                    }
                    parentCaseMapConDetails.contactSize = string.valueOf(contactSize);
                    if(condetWrapList != null && condetWrapList.size()>0){
                        parentCaseMapConDetails.contactdetailsWrapper = condetWrapList;
                    	parentCaseContactMapping.add(parentCaseMapConDetails);
                    } 
                    
                }
                
                system.debug('parentCaseContactMapping '+parentCaseContactMapping);
                if(parentCaseContactMapping != null && parentCaseContactMapping.size() > 0){
                    return parentCaseContactMapping;
                }
                else{
                    AuraHandledException e = new AuraHandledException('No Contacts found.');
                    e.setMessage('No Contacts found.');
                    system.debug(e);
                    throw e;
                }
            }
            else{
                    AuraHandledException e = new AuraHandledException('Please select atlease one Case.');
                    e.setMessage('Please select atleast one Case.');
                    system.debug(e);
                    throw e;
            }
            
        }
        catch(exception ex){
            system.debug('ex message '+ex.getMessage()+' at '+ex.getstackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class parentCaseMappingWithContactDetails{
        @AuraEnabled public Case parentCase {get; set;}
        @AuraEnabled public List<contactdetailsWrapper> contactdetailsWrapper {get; set;}
        @AuraEnabled public string parentCaseId {get; set;}
        @AuraEnabled public string parentCaseURL {get; set;}
        @AuraEnabled public string parentCaseNumber {get; set;}
        @AuraEnabled public string parentCaseStatus {get; set;}
        @AuraEnabled public string parentCaseSubject {get; set;}
        @AuraEnabled public string contactSize {get; set;}
    }
    public class contactdetailsWrapper{
        @AuraEnabled public Case cs {get; set;}
        @AuraEnabled public List<AssetGroupingWrapper> AssetGroupingWrapperList {get; set;}

        public contactdetailsWrapper(Case cs, List<AssetGroupingWrapper> AssetGroupingWrapperList){
            this.cs = cs;
            this.AssetGroupingWrapperList = AssetGroupingWrapperList;
        }
        
    }

    public class AssetGroupingWrapper{
        @AuraEnabled public string assetName {get; set;}
        @AuraEnabled public List<Asset> assetList {get; set;}

        public AssetGroupingWrapper(string assetName, List<Asset> assetList){
            this.assetName = assetName;
            this.assetList = assetList;
        }
    }
}