/**
 * Created by hasan on 24/11/2022.
 */

public with sharing class StarTrackTrackingIDSearchUtil {

    public static void getTrackingDetails(List<SObject> records, Map<Id, SObject> existingRecords) {
        List<Case> selectedCases = new List<Case>();
        for(Case cse:(List<Case>)records) {
            System.debug('StarTrackTrackingIDSearchModule:onAfterUpdate  cse '+cse);
            // if the reference has been changed
            if(existingRecords == null && cse.ReferenceID__c != null) {
                // todo check for record types
                selectedCases.add(cse);
            }
            selectedCases.add(cse);
        }

        System.debug('StarTrackTrackingIDSearchModule:onAfterUpdate selectedCases '+selectedCases.size());

        if(!selectedCases.isEmpty()) {
            System.enqueueJob(new TrackingSearchQueueable(selectedCases[0]));
        }
    }


    private without sharing class TrackingSearchQueueable implements Queueable, Database.AllowsCallouts {
        Case cse;
        Set<Id> caseRecordTypes = new Set<Id>{
                SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_PUD_Enquiry').getRecordTypeId()
                , SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_General_Enquiry').getRecordTypeId()
                , SObjectType.Case.getRecordTypeInfosByDeveloperName().get('StarTrack_Voice_of_Customer').getRecordTypeId()};

        public TrackingSearchQueueable(Case record) {
            this.cse = record;
        }

        public void execute(QueueableContext context) {
            try {
                System.debug('HASANTHA TEST MODULE 1 IN queable');
                if(this.cse.ArticleTest__c == null && this.cse.ReferenceID__c != null && caseRecordTypes.contains(this.cse.RecordTypeId)) {
                    System.debug('HASANTHA TEST MODULE 2 :this.cse '+this.cse.Id);
                    System.debug('HASANTHA TEST MODULE 3 :this.cse.ReferenceID__c'+ this.cse.ReferenceID__c);
                    StarTrackTrackingIDSearchService cont = StarTrackTrackingIDSearchService.newInstance();
                    cont.dateRange = '1';
                    cont.searchString = this.cse.ReferenceID__c;
                    cont.isConsole = false;
                    cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
                    cont.searchConsignment();

                    if(validate(cont.lst_article[0])) {
                        assignAndUpdateCase(cont.lst_article[0], this.cse);
                    }
                }
            } catch (Exception ex) {
                // Error Logged to Exception object for analysis
                UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, TrackingSearchQueueable.class.getName(), 'execute', '', LoggingLevel.ERROR);
            }
        }
    }

    /**
         * validate and assign the found article details
         * @param article
         * @param cse
         */
    public static void assignAndUpdateCase(Article__c article, Case cse) {
        case  caseToBeUpdated = new Case();
        caseToBeUpdated.Id = cse.Id;
        caseToBeUpdated.ArticleTest__c = article.Id; // TODO multiple consignments check
        caseToBeUpdated.Consignment_Unique_External_ID__c = article.ArticleID__c ;

        // Only if Case’s Enquiry Type is LDC
        if(StarTrack_Constants.CASE_ENQUIRY_LDC.equalsIgnoreCase(cse.Enquiry_Type__c)) {
            caseToBeUpdated.Total_Amount_of_Claim__c = article.Freight_Amount__c;
        }
        caseToBeUpdated.Delivery_Date__c = String.isNotBlank(article.CID__c) ? Date.valueOf(article.CID__c.left(4) + '-' + article.CID__c.mid(4, 2) + '-' + article.CID__c.right(2)) : null;
        System.debug('HASANTHA TEST MODULE 4  IN queable cse ' + caseToBeUpdated);
        update caseToBeUpdated;
    }

    /**
     * We can add more validations here if required
     * @param article
     *
     * @return
     */
    public static Boolean validate(Article__c article) {
        return validateAddressFields(article);
    }

    /**
     * Validating nominated address fields to check wheter a value is exists in one of those defined fields in the article record,
     * if a value exists return true as a valid address
     * @param article
     *
     * @return
     */
    public static Boolean validateAddressFields(Article__c article) {
        for(String field: StarTrack_Constants.ARTICLE_ADDRESS_FIELDS) {
            if(article.get(field) != null || String.isNotBlank(String.valueOf(article.get(field)))) {
                return true;
            }
        }
        return false;
    }
}