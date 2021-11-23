/*
 * @changelog
 * 2021-08-27 - Seth Heang - uplift SF API version to 52 and Migrate test method to accountStructureController_Test Apex Class
 * 							 The class is pending for decommission in future date
*/
public class accountStructureController {
    

    private Id currentId;
    
    // wrapper class to hold indent plus account-billing account info
    
    
    public List<InfoWrapper> getInfo() {
    
        List<infoWrapper> infoList = new List<infoWrapper>();
    
        // first, get to top record in hierarchy. No more efficient way other than to query for parent via loop
    
        currentId = ApexPages.currentPage().getParameters().get('aId'); // assumes aId is passed in via URL
        
        Boolean top = false;
        while ( !top ) {
            //Change below
            Account a = [ Select a.Id, a.ParentId From Account a where a.Id =: currentId limit 1 ];
            
            if ( a.ParentID != null ) {
                currentId = a.ParentID;
            }
            else {
                top = true;
            }
        }
    
    // now we have top record in var currentId, need to iterate over the chidren, and collect billing account info whilst doing so.
    // also need to store the indent we're at, so can indent during visualisation
    
        Set<id> loopSet = new Set<id>();
        loopSet.add(currentId);
        Integer indent = 0; // this keeps track of which indent in hierarchy we're up to. 0 = top
        
        while (loopSet.size()>0) {
            // query for child account records
            List<account> accountList = new List<account>();
            if(indent == 0) {
                accountList = [ Select id, Name, AccountNumber, Owner.Name, Owner.EmployeeNumber, ABN__c,(Select id, name, Credit_Person_Code__c,Payer_Account_ID__r.Name, Organisation__r.Name from Billing_Accounts__r) from Account where Id in:loopSet ];
            } else {
            accountList = [ Select id, Name, AccountNumber, Owner.Name, Owner.EmployeeNumber, ABN__c,(Select id, name, Credit_Person_Code__c,Payer_Account_ID__r.Name, Organisation__r.Name from Billing_Accounts__r) from Account where ParentId in:loopSet ];
            }
            loopSet.clear(); // purge for a rebuild at this level.
            for(account childAccount : accountList) {
                // for each child, add them to wrapper class including current indent
                system.debug('*** indent ='+indent);
                system.debug('*** childaccount ='+childAccount);
                infoList.add(new infoWrapper(indent, childAccount));
                system.debug('**** new info record created:'+infoList);
                loopSet.add(childAccount.Id); // building for next hierachial while..do loop
            }
            indent++; // increase indent variable to reflect depth of hierarchy level
        }
        
        // now we have a list of records that have an indent level, account details, and associated billing account info.
        return infoList;
        
    }
    
    public List<Billing_Account__c> getChildBAs(Id oid){
            return [Select id, name from Billing_Account__c where Organisation__c =:oid];
        }
    
    
    public class infoWrapper {
        public Account a {get; set;}
        public List<String> lList {get; set;}
        public Integer l {get; set;}
        
        public infoWrapper(Integer l, Account acct){
            this.a = acct;
            this.l = l;
            List<String> tmp = new List<String>();
            if (this.l>0) { for(Integer i=0; i<l; i++) tmp.add(String.valueOf(i)); this.lList = tmp;}
        }
        
        
        
    }
    
    public PageReference toExcel() {
        PageReference secondPage = Page.buildHierarchyView_toExcel;
         secondPage.getParameters().put('aid',currentId);
        secondPage.setRedirect(true);
        return secondPage; 
    }
    
    /*
     * Following Summer '13 release or API 28.0 or later, 
     * Test methods are no longer be able to compile in the same Apex class. Therefore, the test code is now moved to reportingAggregateUtils_Test()
     * Source: https://developer.salesforce.com/blogs/engineering/2013/04/apex-test-code-segregation
     *
	public static testmethod void TestAccountStructureController(){
        
        RecordType rectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        //create accounts
        Account ca1=new Account(name='test1', phone='123', email__c='test@test.com', recordtypeid=rectype.id);
        insert ca1;
        
        Account ca2=new Account(name='test2', phone='123', email__c='test@test.com', recordtypeid=rectype.id, parentid = ca1.id);
        insert ca2;
        
        Account ca3=new Account(name='test2', phone='123', email__c='test@test.com', recordtypeid=rectype.id, parentid = ca2.id, Legacy_ID__c = '60000000');
        insert ca3;
        
        //create billing account
        Billing_Account__c ba = new Billing_Account__c(organisation__c=ca3.Id);
        insert ba;
        
        Test.startTest();
        //Test coverage for the VF page
        PageReference pageRef = Page.buildHierarchyView;
        pageRef.getParameters().put('aid', ca3.id); 
        Test.setCurrentPageReference(pageRef);

        //Create an instance of the controller
                                    
        accountStructureController baExCon = new accountStructureController();
        baExCon.getInfo();
        baExCon.toExcel();
        
        
        
        Test.stopTest();
    }*/
    
}