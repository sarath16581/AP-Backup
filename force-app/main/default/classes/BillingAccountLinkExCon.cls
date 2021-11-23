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
28.05.2015    C.McIntyre                        Added "with sharing" as part of security audit.                                                
                                                
**************************************************/
public with sharing class BillingAccountLinkExCon {
    
    private ApexPages.StandardController stdCon;
    private Id BAcctId;
    private Boolean validSearch;
    
    public BillingAccountLinkExCon(ApexPages.StandardController controller) {
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
            results = (List<Account>)[FIND :searchText IN ALL FIELDS RETURNING Account(Id, isPersonAccount, Name, Type, 
                    Organisation_Alternate_Name__c, ABN__c, ACN__c, Phone, Role_Type_Roll_Up__c)] [0];
        }
        return null;
    }
    
    public PageReference SelectCustomer() {    
        
        //start of dynamic SOQL logic
        //this has been localised since it is not required for other functions
        String selects = '';
        String dynQuery = '';
        String objectName = 'Billing_Account__c';
        String whereClause = 'Id =:BAcctId';
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();         
        list<string> selectFields = new list<string>();           
        
        if (fieldMap!= null){             
            for (Schema.SObjectField ft : fieldMap.values()){ 
                // loop through all field tokens (ft)                 
                Schema.DescribeFieldResult fd = ft.getDescribe(); 
                // describe each field (fd)                 
                if (fd.isCreateable() && fd.getName()!= 'Organisation__c'){ // field is creatable and not the Account reference                     
                    selectFields.add(fd.getName());                 
                }             
            }         
        }           
        
        if (!selectFields.isEmpty()){             
            for (string s:selectFields){                 
                selects += s + ',';             
            }             
            if (selects.endsWith(',')){
                selects = selects.substring(0,selects.lastIndexOf(','));
            }           
        }           
        
        dynQuery = 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
        
        //dynQuery will contain all the fields for Billing_Account__c that will be included in the cloning
        //end of dynamic SOQL logic
        
        system.debug(dynQuery);
        
        Billing_Account__c originalChild = Database.query(dynQuery);
        Billing_Account__c newChild = originalChild.clone(false, true, true, true);
        newChild.Organisation__c = CustId; // insert the new parent here
        
        insert newChild;
        
        List<Id> idsToPurge = new List<Id>();
        idsToPurge.add(originalChild.Id);
        delete originalChild;
        Database.emptyRecycleBin(idsToPurge);
        
        //NewBA = newChild;
        
        PageReference BAcctPage = new ApexPages.StandardController(newChild).view();
        BAcctPage.setRedirect(true);

        return BAcctPage;
    }
    
    public static testmethod void TestBAlink(){
        
        RecordType rectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        //create accounts
        Account ca1=new Account(name='test1', phone='123', email__c='test@test.com', recordtypeid=rectype.id);
        insert ca1;
        
        Account ca2=new Account(name='test2', phone='123', email__c='test@test.com', recordtypeid=rectype.id);
        insert ca2;
        
        //create billing account
        Billing_Account__c ba = new Billing_Account__c(organisation__c=ca1.Id);
        insert ba;
        
        Test.startTest();
        //Test coverage for the VF page
        PageReference pageRef = Page.LinkAccount;
        pageRef.getParameters().put('id', ba.id); 
        Test.setCurrentPageReference(pageRef);

        //Create an instance of the controller
        Apexpages.StandardController stdController = new Apexpages.StandardController(ba);                            
        BillingAccountLinkExCon baExCon = new BillingAccountLinkExCon(stdController);
        
        baExCon.searchText = 'test2';
        baExCon.results = null;
        baExCon.doSearch();
        baExCon.CustId = ca2.Id;
        baExCon.SelectCustomer();
        
        system.AssertEquals(true,baExCon.searchText!=null);
        system.AssertEquals(true,baExCon.results!=null);
        
        Test.stopTest();
    }
}