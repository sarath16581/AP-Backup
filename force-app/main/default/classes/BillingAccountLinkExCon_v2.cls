/**************************************************
Type:       Controller Extension for Billing Account object
Purpose:    Provides ability to re-link a Billing Account to another Customer. Due to the inherent nature
            of the Master-Detail object relationship between the 2 objects in Salesforce, this workaround
            has been built to cater for the preferred process flow for Phase 1. It is recommended that
            the overall tactical solution be revisited in the next phase to develop a more streamlined, 
            automated alternative process. Once established, this controller class will not be required
            anymore and thus can be removed.            
Used By:    LinkAcct VF Page
History:
--------------------------------------------------
14.09.2011    Richard Enojas(Salesforce.com)    Created
27.09.2011    Richard Enojas(Salesforce.com)    Added logic to query for list of Billing Account fields
                                                and dynamically generate SOQL to be used in cloning 

12.10.2011    Jim Zhang                         Added new search field in query 
                                                Role_Type_Roll_Up__c
                                                Added search string length check to prevent sql error
22.11.2011    Carl Vescovi (Aus Post)           Cloned original controller, and modified to meet CDM team requirements. Specifically SOQL for fields not included in original.
25.05.2012    M. Isidro (Cloud Sherpas)         Added the date when the parent (Account) is changed for a particular Billing Account
08.10.2012    Richard Enojas(Salesforce.com)    Changed reparenting logic based on Sub Account/QC241 requirements. Organisation__c is now 'reparentable'.   
05.03.2020    Shashwat Nath (Accenture)         Fixed test class failure due to ABN duplicate check rule 
13.08.2021    Seth Heang						Uplift API version to 52, and migrate testmethod into a new test class: BillingAccountLinkExCon_v2Test
**************************************************/
public with sharing class BillingAccountLinkExCon_v2 {
    
    private ApexPages.StandardController stdCon;
    private Id BAcctId;
    private Boolean validSearch;
    
    public BillingAccountLinkExCon_v2(ApexPages.StandardController controller) {
        stdCon = controller;
        BAcctId = stdCon.getRecord().Id;
    }
    
    public String searchText {
        get;
        set{
            Integer counter = 0;
            String temp = value;
            temp = temp.replace('*', ' ');
            temp = temp.replace('?', ' ');
            List <String> sList = temp.split(' ', -1);
            for(String s : sList)
            {
                counter = counter + s.length();
            }
            if(counter < 2)
            {
                validSearch = false;
            }
            else
            {
                value = value.endsWith('*') ? value : value + '*';
                searchText = value;
                validSearch = true;
            } 
        }
    }
    
    public List<Account> results {
        get{
            if(results == null) results = new List<Account>();
            return results;
        }
        set;    
    }
    
    
    public ID CustId { get; set; }
    //public Billing_Account__c NewBA { get; set; }
    
    public PageReference doSearch() {
        
        results = null;
        if(validSearch)
        {
            // CV 22/11 - modified the following original SOSL query to include additional fields.
            //results = (List<Account>)[FIND :searchText IN ALL FIELDS RETURNING Account(Id, isPersonAccount, Name, Type, 
            //        Organisation_Alternate_Name__c, ABN__c, ACN__c, Phone, Role_Type_Roll_Up__c)] [0];
            results = (List<Account>)[FIND :searchText IN ALL FIELDS RETURNING Account(Id, isPersonAccount, Name, AccountNumber, Type, 
                    Organisation_Alternate_Name__c, ABN__c, ACN__c, Phone, Role_Type_Roll_Up__c)] [0];
        }
        return null;
    }
    
    public PageReference SelectCustomer() {    
               
        //Start of Sub Account (QC 241) changes in Phase 2. 
        //Organisation__c field in Billing Account has been set to 'reparentable' therefore no need to perform cloning of BA.
        Billing_Account__c BAtoLink = [SELECT Id, Organisation__c FROM Billing_Account__c WHERE Id=:BAcctId LIMIT 1];
        
        BAtoLink.Organisation__c = CustId;
        //BAtoLink.Date_Parent_Changed__c = Date.today();
        update BAtoLink;
        
        PageReference BAcctPage = new ApexPages.StandardController(BAtoLink).view();
        BAcctPage.setRedirect(true);

        return BAcctPage;
    }
}