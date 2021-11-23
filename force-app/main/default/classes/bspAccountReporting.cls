/**************************************************
Type:         Controller for Account Reporting.
History:
--------------------------------------------------
2020-08-02    Jansi Rani. avula.jansirani@auspost.com.au  Initial Code for community uplift project.
**************************************************/
public with sharing class bspAccountReporting {
    
    public static String reportTypeDeveloperName = 'Report';
    public static String defaultDocumentType = 'DIFOT';
    
    /**
* Check for DIFOT files for the user's Account
* */
    @AuraEnabled(Cacheable=true)
    public static boolean isDIFOTFilesExists(){
        boolean isDIFOTFilesExists = false;
        
        try{
            Id reportTypeId = getCVReportRecordType();
            Set<Id> entityIdSet = new Set<Id>(); //userContact.AccountId != null ? new Set<Id> {userContact.AccountId} : new Set<Id>();
            //entityIdSet.addAll(bspBaseUplift.accessibleBillingAccounts.keySet());
            entityIdSet.add(bspBaseUplift.loginAccountId);
            
            Set<String> documentTypeSet =  new Set<String> { defaultDocumentType } ;
            Map<String, Object> cdlSearchParams = buildCDLSerchParams( entityIdSet, documentTypeSet,  new Set<String>(), null, null,  reportTypeId);
            Map<Id, ContentDocumentLink> cdlMap = new ContentDocumentLinksSelector().newInstance(1, 0).search(cdlSearchParams, true);
    
            if(!cdlMap.keySet().isEmpty()){
                isDIFOTFilesExists = true;
            }
            
        }catch(Exception ex){
            System.debug('Error in bspAccountReporting.isDIFOTFilesExists() ==>'+ex.getMessage());
        }
        return isDIFOTFilesExists;
    }
    
    /**
    * Build Content Document Link Search Params
    * */
    private static Map<String, Object> buildCDLSerchParams(Set<Id> entityIdSet,  Set<String> documentTypeSet , Set<String> documentIntervalSet, Date fromDate, Date toDate, Id reportTypeId){
        
        Map<String, Object> cdlSearchParams = new Map<String, Object>();
        
        if(!entityIdSet.isEmpty())
            cdlSearchParams.put('entityIds', entityIdSet );
        
        if(!documentTypeSet.isEmpty())
            cdlSearchParams.put('contentVersionDocumentTypes', documentTypeSet);
        
        if(!documentIntervalSet.isEmpty())
            cdlSearchParams.put('contentVersionDocumentIntervals',  documentIntervalSet);
        
        if(fromDate != null)
            cdlSearchParams.put('contentVersionDocumentFromDate', fromDate);
        
        if(toDate != null)
            cdlSearchParams.put('contentVersionDocumentToDate',toDate);
        
        if(reportTypeId != null)
            cdlSearchParams.put('contentVersionRecordTypeId', reportTypeId);
        
        return cdlSearchParams;
    }
    
    /**
    * Get 'Report' recordType Id from ContentVersion
    * */
    @AuraEnabled(Cacheable=true)
    public static Id getCVReportRecordType(){
        return new List<Id>(RecordTypesSelector.newInstance().selectByDeveloperName('ContentVersion', new Set<String>{reportTypeDeveloperName}).keySet())[0]; 
    }
    
    /**
    * Get Files
    * */
    @AuraEnabled(cacheable=true)
    public static SerchResultsWrapper getFiles(String reportType, String documentType , String documentInterval, Date fromDate, Date toDate, Integer pageNumber, Integer pageSize,  String sortByColumn, String sortByOrder, String selectedBillingAccount ){
        
        SerchResultsWrapper sWrapper = new SerchResultsWrapper();
        sWrapper.totalSearchCount = 0 ;
        
        if(!String.isEmpty(reportType)){
            reportTypeDeveloperName = reportType;
        }

        List<ContentVersion> cvList = new List<ContentVersion>();
        Map<String, String> contentDocIdNLinkedAccNameMap = new Map<String, String>();
        
        try{
            
            Id reportTypeId = getCVReportRecordType();
            System.debug('selectedBillingAccount='+selectedBillingAccount);
            Set<Id> entityIdSet = new  Set<Id>();
            if(!String.isEmpty(selectedBillingAccount)){
                if (selectedBillingAccount =='all'){
                    //entityIdSet.addAll(bspBaseUplift.accessibleBillingAccounts.keySet());
                    entityIdSet.add(bspBaseUplift.loginAccountId);
                }   
                else{
                    entityIdSet = new Set<Id> { selectedBillingAccount.split('&')[0] };
                }   
            }
            
            Set<String> docIntervalSet = documentInterval !='All' ? new Set<String> {documentInterval} : new Set<String>();
            Set<String> documentTypeSet = String.isEmpty(documentType) ? new Set<String> {documentType} : new Set<String>();
            Map<String, Object> cdlSearchParams = buildCDLSerchParams( entityIdSet,documentTypeSet, docIntervalSet, fromDate, toDate,  reportTypeId);
            
            //--get total count
            Map<Id, ContentDocumentLink> totalCDLMap = new ContentDocumentLinksSelector().search(cdlSearchParams, true);  
            
            if(!totalCDLMap.keySet().isEmpty()){
                sWrapper.totalSearchCount = totalCDLMap.keySet().size();
            }   
           
            Map<Id, ContentDocumentLink> cdlMap = new ContentDocumentLinksSelector().newInstance(pageSize, pageSize*(pageNumber-1)).search(cdlSearchParams, true);
            Set<Id> cdIdsSet = new Set<Id>();
            
            if(!cdlMap.keySet().isEmpty()){
                Map<String,String> conIdNlinkedIdMap = new  Map<String,String>();
                set<Id> linkedIdSet = new  set<Id>();
                for(ContentDocumentLink cdl : cdlMap.values()){
                    cdIdsSet.add(cdl.ContentDocumentId);
                    //System.debug('LinkedEntity.Name'+cdl.get('LinkedEntity.Name'));  //unable to get value 'LinkedEntity.Name'
                    conIdNlinkedIdMap.put(cdl.ContentDocumentId,cdl.LinkedEntityId);
                    linkedIdSet.add(cdl.LinkedEntityId);
                }
                contentDocIdNLinkedAccNameMap = buildMap(conIdNlinkedIdMap, linkedIdSet);   //unable to get value 'LinkedEntity.Name' from ContentDocumentLink, so querying 'Billing Account' again to get its names
                
                if(cdIdsSet.size() > 0){
                    Map<Id, ContentVersion> cvMap = ContentVersionsSelector.newInstance(sortByColumn, sortByOrder).selectByContentDocumentId(cdIdsSet, new set<Object>{ContentVersionsSelector.Options.IS_LATEST_VERSION});
                    if(cvMap != null) cvList = cvMap.values();
                }
            }
        }catch(Exception ex){
            throw ex;
        }

        sWrapper.paginatedSearchResults = cvList;
        sWrapper.contentDocIdNLinkedEntityNameMap = contentDocIdNLinkedAccNameMap;
        return  sWrapper;
    }
    
    /**
    * build ContentDocId and Billing Account Name Map
    * */  
    private static Map<String,String> buildMap(Map<String,String> conIdNlinkedIdMap, set<Id> linkedIdSet){

        set<String> billingAccIds = new set<string>();
        set<String> orgAccIds = new set<string>();
        Map<String,String> accIdNameMap = new Map<String,String>();
        Map<String,String> conDocIdNBillingAccNameMap = new Map<String,String>();

        for(Id accId : linkedIdSet){
            Schema.sObjectType entityType = accId.getSObjectType();
            if(entityType == Account.sObjectType) orgAccIds.add(accId);
            if(entityType == Billing_Account__c.sObjectType) billingAccIds.add(accId);
        }

        //Map<String,String>  conDocIdNBillingAccNameMap = new  Map<String,String>();
        if(billingAccIds.size() > 0){
            List<Billing_Account__c> billingAccList = [SELECT Id, Name FROM Billing_Account__c WHERE Id = :billingAccIds];    
            for(Billing_Account__c ba : billingAccList){
                accIdNameMap.put(ba.Id, ba.Name);
            }
        }

        if(orgAccIds.size() > 0){
            List<Account> accList = [SELECT Id, Name FROM Account WHERE Id = :orgAccIds];    
            for(Account acc : accList){
                accIdNameMap.put(acc.Id, acc.Name);
            }
        }

        System.debug('billingAccIdNNameMap='+accIdNameMap);
        
        for(String conDocId : conIdNlinkedIdMap.keySet()){
            conDocIdNBillingAccNameMap.put(conDocId, accIdNameMap.get(conIdNlinkedIdMap.get(conDocId)));
        }
        System.debug('conDocIdNBillingAccNameMap='+conDocIdNBillingAccNameMap);
        return conDocIdNBillingAccNameMap;
    }
    
    /**
    * inner class to store searched results of cases list
    * */
    public class SerchResultsWrapper{
        @AuraEnabled public Integer totalSearchCount{set;get;}
        @AuraEnabled public List<ContentVersion> paginatedSearchResults{get;set;}
        @AuraEnabled public Map<String, String> contentDocIdNLinkedEntityNameMap{get;set;}
    }
}