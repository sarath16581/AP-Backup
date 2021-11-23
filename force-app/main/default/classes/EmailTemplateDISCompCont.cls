/**************************************************
Type:       Controller for Component.       
Purpose:    Reads and loads Case, Contact, Article and EventMessages objects for an
            email template or the PDF rendered fax.
Used by:    CaseItemSearch.component && SSSW_Case_FaxTemplate.page   
History:
-------------------------------------------------- 
16.12.2013  A. Tran (Bluewolf)  Created.
03/11/2014  C. Andronaco (Bluewolf) - This Controller is now utilised by SSSW_Case_FaxTemplate - new constructor added.
25/05/2018  Kalpita T    - MW0002003 updated for getting old nw resp and seeing if it is re-assigned case 
15/05/2020  Hara Sahoo Modified the removeUnselectedArticles method to be public, to make it reusable
**************************************************/

public without sharing class EmailTemplateDISCompCont {
    
    public EmailTemplateDISCompCont() {}   
    
    public transient Case myCase { get; private set; }
    public transient Contact myContact { get; private set; }

    //public transient Article__c article { get; private set; }
    //public transient List<EventMessage__c> eventMessages { get; private set; }

    public transient TIBCOArticleWrapper articleDetails {get; set;}
    public transient TIBCOConsignmentWrapper consignmentDetails {get; set;}
    public transient TIBCOSearchResult searchResult {get; private set;}


    public transient string logoUrl { get; private set;}

    public EmailTemplateDISCompCont(ApexPages.StandardController controller) {
        caseId = controller.getId();
    }

    public Id caseId {
        get;
        set {
            caseId = value;
            
            myCase = getCase();
            myContact = getContact(myCase.ContactId);
            //article = getArticle(myCase.ArticleTest__c);
            //eventMessages = getEventMessages(myCase.ArticleTest__c);

            if(!String.isBlank(myCase.ReferenceID__c))
            {
                searchResult = TIBCOArticleService.searchArticlesInSFDC(new String[] {myCase.ReferenceID__c});
                if (searchResult.trackResults.size() > 0) { 
                    articleDetails = searchResult.trackResults[0].articleDetails;
                    consignmentDetails = searchResult.trackResults[0].consignmentDetails;
                    removeUnselectedArticles(consignmentDetails, caseId);
                }
            }

            logoUrl = getLogoUrl();
        }
    }
    
    public String timaestamp {
        get {
            return System.now().format('dd/MM/yyyy h:00 a');
        }
    }
    
    private Case getCase() {
        String query = 'SELECT ';
        for(String disfield : this.getCaseFields()) {
            query += disfield + ', ';
        }
         //kalpi - MW0002003 updated for getting old nw resp and seeing if it is re-assigned case
        query += 'Id, (SELECT  to_Reassign_Network__c FROM Network_Responses1__r ORDER BY CreatedDate DESC) FROM Case WHERE Id = :caseId LIMIT 1';
        return Database.query(query);
    }
    
    private Contact getContact(Id contactId) {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : this.getItemSearchContactFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, DoNotDisclose__c FROM Contact WHERE Id = :contactId LIMIT 1';
        
        List<Contact> obj = Database.query(query); 
        return obj.size() > 0 ? obj[0] : null;
    }

    public static void removeUnselectedArticles(TIBCOConsignmentWrapper consignmentDetails, Id caseId) {
        if (consignmentDetails != null && !consignmentDetails.articles.isEmpty() && caseId != null) {       
            Set<String> childCaseArticleIds = new Set<String>();
            for (Case c : [SELECT ArticleTest__r.ArticleID__c FROM Case WHERE ParentId = :caseId]) {
                if (c.ArticleTest__r.ArticleID__c != null) {
                    childCaseArticleIds.add(c.ArticleTest__r.ArticleID__c);
                }
            }
            
            List<TIBCOArticleWrapper> articles = new List<TIBCOArticleWrapper>();
            for (TIBCOArticleWrapper aw : consignmentDetails.articles) {
                if (childCaseArticleIds.contains(aw.proxyArticle.ArticleID__c)) {
                    articles.add(aw);
                }
            }
            consignmentDetails.articles = articles;
        }
    }
    
    /*private Article__c getArticle(id articleID) {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : this.getItemSearchArticleFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, AdditionalServices__c, ContentsItems__c FROM Article__c WHERE id = :articleID LIMIT 1';
        
        List<Article__c> obj = Database.query(query); 
        return obj.size() > 0 ? obj[0] : null;
    } 
    
    private List<EventMessage__c> getEventMessages(id articleID) {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : this.getItemSearchEventMessagesFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id FROM EventMessage__c WHERE Article__c = :articleID ORDER BY ActualDateTime__c';
        
        List<EventMessage__c> obj = Database.query(query); 
        return obj.size() > 0 ? obj : null;
    }*/
    
    public Set<String> getCaseFields() {
        Set<String> distinctFields = new Set<String>();
        
        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.ContactNetworkInvestigation.getFields())
        {
            distinctFields.add(fm.getFieldPath());
        }
        
        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.ContactNetworkFeedback.getFields())
        {
            distinctFields.add(fm.getFieldPath());
        }
        
        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.ContactNetworkGeneralEnquiry.getFields())
        {
            distinctFields.add(fm.getFieldPath());
        }
        
        //Snigdha Start Change
        for(Schema.FieldSetMember fm : SObjectType.Case.FieldSets.PON_Investigation.getFields())
        {
            distinctFields.add(fm.getFieldPath());
        }       
        
        //Snigdha End Change     
        
        distinctFields.add('CaseNumber');
        distinctFields.add('Type');
        distinctFields.add('ArticleTest__c');
        distinctFields.add('ContactId');
        distinctFields.add('Network__r.Contact_Facility__c');
        distinctFields.add('Network__r.Name');
        distinctFields.add('Network__r.Fax_Number__c');
        distinctFields.add('NetworkComments__c');
        distinctFields.add('EmailThreadID__c');
        distinctFields.add('OwnerId');      
        distinctFields.add('Customer_Type__c');
        distinctFields.add('Description');
        distinctFields.add('ReferenceID__c');
        //Snigdha Start Change
        distinctFields.add('CreatedDate');
        distinctFields.add('SLATargetDate__c');
        distinctFields.add('Type');
        distinctFields.add('Instructions__c');
        //Snigdha End Change
        
        return distinctFields;
    }
    
    public List<Schema.FieldSetMember> getItemSearchContactFields() {
        return SObjectType.Contact.FieldSets.ContactItemSearch.getFields();
    }

    public List<Schema.FieldSetMember> getItemSearchArticleFields() {
        return SObjectType.Article__c.FieldSets.ArticleItemSearch.getFields();
    }
    
    public List<Schema.FieldSetMember> getItemSearchEventMessagesFields() {
        return SObjectType.EventMessage__c.FieldSets.EventMessageItemSearch.getFields();
    }
    
    private string getLogoUrl()
    {
        string output;
        AusPostSettings__c setting = AusPostSettings__c.getValues('AusPostLogo');
        if(setting != null)
        {
            output = setting.URL__c;
        }
        return output;
    }
}