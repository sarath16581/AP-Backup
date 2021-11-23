/**************************************************
Description:    Controller class for MyNetworkCasePDFGenerator.vfp
History:
--------------------------------------------------
2020-05-12 - Hara Sahoo Created
2020-08-24 - Disha Kariya Updated to allow mocking in test class
2021-06-22 - Ranjeewa Silva - Updated to include event message attachments into Case PDF.
**************************************************/

public with sharing class MyNetworkCasePDFController {
    //Loop variable
    public String caseIds {get;set;}
    public Integer caseCount {get;set;}
    public Set<Id> articleList;
    public List<String> lstCaseIds;
    public Set<Id> setCaseIds;
    // event message ids with attachments
    public String eventMessagesWithAttachments {get;set;}
    public myNetworkCasePDFController()
    {
        caseIds = System.currentPageReference().getParameters().get('selectedIds'); 
        lstCaseIds = caseIds.split(',');
        setCaseIds = new Set<Id>(((Set<Id>) JSON.deserialize(JSON.serialize(lstCaseIds), Set<Id>.class)));
        caseCount = lstCaseIds.size();
        articleList = getArticleIds(setCaseIds);
        system.debug('articleList'+ articleList);
        eventMessagesWithAttachments = '';

        //Extract the List and the Maps before further processing
        if(!lstCaseIds.isEmpty())
        {
            //Get the list of event messages related to the cases
//            Map<Id,EventMessage__c> casetoAttachmentMap = new Map<Id,EventMessage__c>([Select Id, Safe_Drop_GUID__c,Article__r.Case__c,Article__c,EventGeoLocation__Latitude__s,EventGeoLocation__Longitude__s,
//                                                                                       (SELECT Id, ParentId, Name FROM Attachments order by Createddate desc LIMIT 1)
//                                                                                       FROM EventMessage__c
//                                                                                       WHERE Article__c = :articleList]);
            Map<Id,EventMessage__c> casetoAttachmentMap = EventMessagesSelector.newInstance().selectByArticleId(articleList,  new Set<Object>{EventMessagesSelector.Options.WITH_ARTICLE, EventMessagesSelector.Options.WITH_ATTACHMENT});

            // grab attachment types that should be included in Case PDF.
            Set<String> attachmentTypesForCasePDF = getAttachmentTypesForCasePDF();

            for(EventMessage__c event : casetoAttachmentMap.values()) {

                // check if Safedrop or an attachment in one of the configured types
                if (String.isNotBlank(event.Safe_Drop_GUID__c)
                        || (String.isNotBlank(event.AttachmentGUID__c) && attachmentTypesForCasePDF.contains(event.AttachmentType__c))) {

                    eventMessagesWithAttachments += ((String.isBlank(eventMessagesWithAttachments) ? '' : ',') + event.Id);
                }
            }

        }
        system.debug('test' + eventMessagesWithAttachments);
    }
    public Set<Id> getArticleIds(Set<Id> setCaseIds)
    {
        List<Case> cases = New List<Case>();
        Set<Id> articles = new Set<Id>();
        if(!setCaseIds.isEmpty())
        {
//            cases = [SELECT Id,ArticleTest__c FROM CASE WHERE Id =: caseList];
            cases = SSSWCasesSelector.newInstance(new Set<SObjectField>{Case.Id, Case.ArticleTest__c}).selectById(setCaseIds).values();
        }
        for(Case cs: cases)
        {
            articles.add(cs.ArticleTest__c);
        }
        return articles;
    }

    /**
     * Grab the attachment types to be included in Case PDF from configuration.
     *
     * @return Set of attchment type developer names
     */
    private Set<String> getAttachmentTypesForCasePDF() {
        Set<String> output = new Set<String>();
        for(EventMessageAttachmentTypeMapping__mdt mapping : EventMessageUtil.getEventMessageAttachmentTypes().values()) {
            if(mapping.IsIncludedOnCasePrintOut__c) {
                output.add(mapping.DeveloperName);
            }
        }
        return output;
    }

}