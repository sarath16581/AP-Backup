/**
* @description
* Domain Module to handle the Article related functionality on a StarTrack case.
* Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
*
* This has been a port of parts of the StarTrack Calculate Case Depot. It deals with the following nodes:
* 1. Update Case Depot
* 2. Set 24/7 Business Hour
* 3. Set Case Business Hour
* 4. Default Case Business Hour
* 5. Set Depot Business Hour
* 6. Set Default Business Hour
*
* NOTE: The is wrapped in a domain class that filters all cases based on StarTrack cases only!
*       The cases passed through this module should only ever be StarTrack Cases!!
*
* @author Nathan Franklin
* @date 2021-06-14
* @group Domain
* @domain StarTrack
* @changelog
* 2021-08-26    Steve Judd  Modified calculateCaseDepot for MW0004540 to exclude Depot Collection when case is closed
* 2023-06-13 - Nathan Franklin - Refactored into new ApplicationModule framework
*/
public inherited sharing class StarTrackCalculateCaseDepotModule extends ApplicationModule {
    
    public static StarTrackCalculateCaseDepotModule newInstance() {
        return (StarTrackCalculateCaseDepotModule)Application.Utilities.newInstance(StarTrackCalculateCaseDepotModule.class);
    }
      
    // Setup which triggers this module should respond to
    public StarTrackCalculateCaseDepotModule() {
        getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
    }
    
    /**
	* Grab the Voice of Customer Incident recordTypeId
	*/
    public static Id voiceOfCustomerIncidentRecordTypeId {
        get {
            if(voiceOfCustomerIncidentRecordTypeId == null) {
                voiceOfCustomerIncidentRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'StarTrack_Voice_of_Customer_Incident'}).values()[0].Id;
            }
            return voiceOfCustomerIncidentRecordTypeId;
        }
        private set;
    }
    
    /**
	* Grab the Delivery Enquiry recordTypeId
	*/
    public static Id deliveryEnquiryRecordTypeId {
        get {
            if(deliveryEnquiryRecordTypeId == null) {
                deliveryEnquiryRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'StarTrack_PUD_Enquiry'}).values()[0].Id;
            }
            return deliveryEnquiryRecordTypeId;
        }
        private set;
    }
    
    /**
	* Grab the businessHours247 from custom settings
	*/
    public static Id businessHours247 {
        get {
            if(businessHours247 == null) {
                businessHours247 = StarTrack_Settings__c.getInstance().StarTrack_24_7_Business_Hour__c;
            }
            return businessHours247;
        }
        private set;
    }
    
    /**
	* Grab the businessHoursDefault from custom settings
	*/
    public static Id businessHoursDefault {
        get {
            if(businessHoursDefault == null) {
                businessHoursDefault = StarTrack_Settings__c.getInstance().StarTrack_Default_Business_Hour__c;
            }
            return businessHoursDefault;
        }
        private set;
    }
    
    /**
	* Called when a new Case is being inserted.
	*/
    public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            System.debug('StarTrackCalculateCaseDepotModule:onBeforeInsert');
            if(!records.isEmpty()) {
                
                // ensures the correct Network field is set for StarTrack cases
                calculateCaseDepot((List<Case>) records, null);
                
                // ensures the correct business hours are set for cases
                // NOTE: calculateCaseDepot may change the Network__c to what it originally was before the update occurred
                //       We use the updated value in our method
                calculateCaseBusinessHours((List<Case>) records, null);
                
            }
            
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackCalculateCaseDepotModule.class.getName(), 'onBeforeInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    /**
	* Called when a new Case is being inserted.
	*/
    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        try {
            System.debug('StarTrackCalculateCaseDepotModule:onBeforeUpdate');
            if(!records.isEmpty()) {
                
                // ensures the correct Network field is set for StarTrack cases
                calculateCaseDepot((List<Case>)records, (Map<Id, Case>)existingRecords);
                
                // ensures the correct business hours are set for cases
                // NOTE: calculateCaseDepot may change the Network__c to what it originally was before the update occurred
                //       We use the updated value in our method
                calculateCaseBusinessHours((List<Case>) records, (Map<Id, Case>)existingRecords);
                
            }
            
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackCalculateCaseDepotModule.class.getName(), 'onBeforeUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }
    
    /**
	* Ensures the correct Network is assigned to the Case record for a StarTrack Case
	* NOTE: LDC is no longer needed and is removed after confirming with business
	* 13-Sept-2021 - Modified Steve Judd to exclude depot collections cases from calculation when case is closed
	*
	*/
    public void calculateCaseDepot(List<Case> records, Map<Id, Case> existingRecords) {
        Boolean isInsert = (existingRecords == null);
        List<Case> casesForProcessing = new List<Case>();
        Set<Id> articleIds = new Set<Id>();
        
        for(Case record : records) {
            
            // From node: 'Case Related Consignment has Depot'
            // We need to reset the network field based on the Article field (only if the article has a value)....
            // If the Article field doesn't have a value, then we leave whatever network exists there
            // MW0004540 Do not change depot on case close if the enquiry type is Depot Collection
            if(record.RecordTypeId != voiceOfCustomerIncidentRecordTypeId && record.ArticleTest__c != null &&
                    (isInsert || ((!isInsert && ((existingRecords.get(record.Id)?.ArticleTest__c != record.ArticleTest__c || existingRecords.get(record.Id)?.Network__c != record.Network__c ) && !StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(record.Enquiry_Type__c)) ||
                    ((existingRecords.get(record.Id)?.ArticleTest__c != record.ArticleTest__c || existingRecords.get(record.Id)?.Network__c != record.Network__c ) && StarTrack_Constants.CASE_ENQUIRY_DEPOTCOLLECTION.equals(record.Enquiry_Type__c) && !StarTrack_Constants.CASE_STAT_CLOSED.equals(record.Status))
                    )))) {
                   
                   articleIds.add(record.ArticleTest__c);
                   casesForProcessing.add(record);
               }
        }
        
        // reset the Network field on the Case
        // This ensures that the network is in sync with the Depot assigned to the Article
        if(!casesForProcessing.isEmpty()) {
            // Grab the network from the article
            Map<Id, Article__c> articles = selectArticles(articleIds);
            //System.debug('articles fetched:'+articles);

            for(Case caseRecord : casesForProcessing) {
                System.debug('case articles:'+caseRecord.ArticleTest__c);
                // force the network value to whatever exists on the article
                // NOTE: PB is updating Network on insert, from Article.Network__c even if 
                // 		 Article.Network__c is blank and Case.Network is present
                //       But in update scenario, when network is changed, network is not updated if Article.Network__c is blank
                //       So have put a fix for this, to update always if Article.Network__c is not blank 
                if(!String.isBlank(articles.get(caseRecord.ArticleTest__c).Network__c)) {
                    caseRecord.Network__c = articles.get(caseRecord.ArticleTest__c).Network__c;
                }
            }
        }
    }
    
    /**
	* Ensures the correct business hours are set for cases
	* NOTE: calculateCaseDepot may change the Network__c to what it originally was before the update occurred
	*       We use the updated value in our method
	*/
    public void calculateCaseBusinessHours(List<Case> records, Map<Id,Case> existingRecords) {
        Boolean isInsert = (existingRecords == null);
        List<Case> casesForProcessing = new List<Case>();
        Set<Id> networkIds = new Set<Id>();
        
        for(Case record : records) {
            if(record.RecordTypeId == deliveryEnquiryRecordTypeId && record.Consignment_Next_Flight__c) {
                // This is different behaviour than in the original PB where this will only be done where Article or Network changes value
                // It Probably doesn't matter since any next flight case should always have 24/7 time
                
                // For all Next FLight delivery enquiries, we should always use 24/7 business hours
                // NOTE: this will do nothing if it's already set to 24/7
                record.BusinessHoursId = businessHours247;
                
            } else if(record.RecordTypeId == deliveryEnquiryRecordTypeId && record.Network__c != null) {
                
                // For all Cases with their Network field set, we need to make sure the correct business hours are applied
                // NOTE: This check should only happen if the Network field has changed value (or the record is new)
                // NOTE: We check for new/changed as inner if to prevent assigning the default business hours (the generic else statement in the main if block)
                // NOTE: The Network field may have been set in this class from the calculateCaseDepot method (it should still show up as a changed value here)
                if(isInsert || (!isInsert && existingRecords.get(record.Id)?.Network__c != record.Network__c)) {
                    if(record.Network__c != null) {
                        networkIds.add(record.Network__c);
                    }
                    casesForProcessing.add(record);
                } 
            } else {
                
                // Set the default business hours
                // NOTE: this will do nothing if it's already set to default
                // NOTE: The Domain that invokes this should filter out all non StarTrack cases so no need to check for a 'StarTrack' case
                record.BusinessHoursId = businessHoursDefault;    
            }
        }
        
        // ensure the business hours are set correct for Cases with a changed Network__c value
        if(!casesForProcessing.isEmpty()) {
            // grab the business hours from the networks
            Map<Id, Network__c> networks = selectNetworks(networkIds);
            
            for(Case caseRecord : casesForProcessing) {
                if(caseRecord.Network__c == null || networks.get(caseRecord.Network__c)?.Business_Hours__c == null) {
                    caseRecord.BusinessHoursId = businessHoursDefault;
                } else {
                    caseRecord.BusinessHoursId = networks.get(caseRecord.Network__c).Business_Hours__c;
                }
            }
        }
    }
    
    /**
	* Select articles based on id.
	*/
    public Map<Id, Article__c> selectArticles(Set<Id> casesArticleIds) {
        Map<Id, Article__c> articles = ArticlesSelector.newInstance(0, new Set<SObjectField>{Article__c.Id, Article__c.Network__c}).selectById(casesArticleIds);
        return articles;
    }
    
    /**
	* Select networks based on id.
	*/
    public Map<Id, Network__c> selectNetworks(Set<Id> casesNetworkIds) {
        Map<Id, Network__c> networks = NetworksSelector.newInstance(0, new Set<SObjectField>{Network__c.Id,Network__c.Business_Hours__c}).selectById(casesNetworkIds);
        return networks;
    }
    
}