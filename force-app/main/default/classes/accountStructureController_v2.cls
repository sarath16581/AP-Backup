/**
 *     2020.18.11 Change made by @madhuri.awasthi@auspost.com.au Added an extra column Type__ field in the Excel and Query
 *     2021.18.02 Change made by @madhuri.awasthi@auspost.com.au Changed the Test method
 *     2021.24.06 Change made by @Suman.gunaganti@auspost.com.au Added new columns in org and billing account sections
 *     2021.28.09 Change made by seth.heang@auspost.com.au uplift the SF API version to 52
 */
public class accountStructureController_v2 {

    private Id currentId;
    
    // wrapper class to hold indent plus account-billing account info
    
    
    public List<infoWrapper> getInfo() {
    
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
            List<Contact> contacts = new List<Contact>();
            List<Billing_Account__c> billingAccounts = new List<Billing_Account__c>();
            Set<Id> billingAccountIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            Set<Id> billingAccountIdsWithAuthRules = new Set<Id>();
            List<BAMLinkedEntity__c> bamLinkedEntities = new List<BAMLinkedEntity__c>();
            List<BAMContactRole__c> bamContactRole = new List<BAMContactRole__c>();

            if(indent == 0) {
                accountList = [ Select id, Name, Organisation_Trading_Name__c, AccountNumber, Owner.Name , ABN__c, ACN__c, Holding_Role_Reference__r.Name, Sales_Director__r.Name, ParentId,(Select id, name, Payer_Account_Legacy_Id__c,type__c, SAP_marked_for_deletion__c, ABN__c, ACN__c, LEGACY_ID__c,Payer_Account_ID__r.Name, Organisation__r.Name from Billing_Accounts__r), (SELECT Id, AccountId FROM Contacts) from Account where Id in:loopSet ORDER BY Name];
            } else {
            accountList = [ Select id, Name, Organisation_Trading_Name__c, AccountNumber, Owner.Name, ABN__c, ACN__c, Holding_Role_Reference__r.Name, Sales_Director__r.Name, ParentId,(Select id, name, Payer_Account_Legacy_Id__c,type__c, SAP_marked_for_deletion__c, ABN__c, ACN__c, LEGACY_ID__c, Payer_Account_ID__r.Name, Organisation__r.Name from Billing_Accounts__r ORDER BY name ASC NULLS LAST), (SELECT Id, AccountId FROM Contacts) from Account where ParentId in:loopSet ORDER BY Name DESC NULLS FIRST];
            }
            //Collect Billing Accounts and contacts for all accounts
            for (account ac : accountList) {
                for (Billing_Account__c ba : ac.getSObjects('Billing_Accounts__r')) {
                    billingAccountIds.add(ba.Id);
                }
                for (contact c : ac.getSObjects('Contacts')) {
                    contactIds.add(c.Id);
                }
            }

            //Query BAM Linked entities for all accounts
            BAMLinkedEntities = [SELECT BillingAccount__c,ContactRole__c,ContactRole__r.ApplicationName__c,Name,Status__c, BillingAccount__r.LEGACY_ID__c, ContactRole__r.ApplicationRole__r.Application__r.AppKey__c
                                FROM BAMLinkedEntity__c 
                                WHERE Status__c = 'Active' And 
                                        ContactRole__r.Status__c = 'Active' And 
                                        ContactRole__r.ContactApplication__r.Status__c = 'Active' And 
                                        ContactRole__r.ContactApplication__r.Contact__r.Status__c = 'Active' And 
                                        ContactRole__r.ContactApplication__r.Contact__r.AccountId IN :accountList];
            // Query Contact roles for all the accounts in this iteration
            bamContactRole = [SELECT Id, ContactApplication__r.Contact__c, ContactApplication__r.AppKey__c 
                             FROM BAMContactRole__c
                             WHERE ContactApplication__r.Status__c = 'Active' And 
                                   ContactApplication__r.Contact__r.Status__c = 'Active' And 
                                   ApplicationRole__r.Role__c = 'Super Admin' And
                                   ApplicationRole__r.ShowOrganisation__c = true And
                                   ContactApplication__r.Contact__c IN :contactIds];
            
            // Query Authorisation rule for all Billing Accounts
            for (Authorization_Rule__c authRule : [SELECT Id, Billing_Account__c
                                                    FROM Authorization_Rule__c 
                                                    WHERE Billing_Account__c IN :billingAccountIds]) {
                billingAccountIdsWithAuthRules.add(authRule.Billing_Account__c);
                
            }
                
            loopSet.clear(); // purge for a rebuild at this level.
            for(account childAccount : accountList) {
                //account wrapper

                accountWrapper ac = new accountWrapper();
                Set<String> superAdminSet = new Set<String>();
                ac.name = childAccount.Name;
                ac.organisationTradingName = childAccount.Organisation_Trading_Name__c;
                ac.accountNumber = childAccount.AccountNumber;
                ac.abn = childAccount.ABN__c;
                ac.acn = childAccount.ACN__c;
                ac.ownerName = childAccount.owner.Name;
                ac.holdingRoleReferenceName = childAccount.Holding_Role_Reference__r.name;
                ac.salesDirectorName = childAccount.Sales_Director__r.Name;
                for(Contact c: childAccount.getSObjects('contacts')){
                    for (BAMContactRole__c contactRole : bamContactRole) {
                        if (c.id == contactRole.ContactApplication__r.Contact__c) {
                            superAdminSet.add(contactRole.ContactApplication__r.AppKey__c);
                        }
                    }
                }
                ac.superAdminTo = superAdminSet.size()>0?String.join(new List<String>(superAdminSet), ','):null;
              

                List<billingAccountWrapper> listOfBAs = new List<billingAccountWrapper>();

                for(Billing_Account__c ba : childAccount.getSObjects('Billing_Accounts__r')){ 
                    
                    Set<String> bamApplications = new Set<String>();
                    billingAccountWrapper  bcw = new billingAccountWrapper();
                    bcw.name = ba.name;
                    bcw.legacyId = ba.LEGACY_ID__c;
                    bcw.type = ba.type__c;
                    bcw.sapmarkedfordeletion = ba.SAP_marked_for_deletion__c;
                    bcw.abn = ba.ABN__c;
                    bcw.acn = ba.ACN__c;
                    bcw.payerAccountLegacyId = ba.Payer_Account_Legacy_Id__c;

                    if(billingAccountIdsWithAuthRules.contains(ba.Id)){
                        bcw.hasAuthorisationRule = true;
                    }

                    for (BAMLinkedEntity__c baml : BAMLinkedEntities) {
                        if (ba.Id == baml.BillingAccount__c) {
                            bamApplications.add(baml.ContactRole__r.ApplicationRole__r.Application__r.AppKey__c);
                            bcw.hasBAMRole = true;
                        }
                    }
                    bcw.bamApplications = bamApplications.size()>0?String.join(new List<String>(bamApplications), ','):null;
                    listOfBAs.add(bcw);
                }
                ac.BAList = listOfBAs;


                // for each child, add them to wrapper class including current indent
                system.debug('*** indent ='+indent);
                system.debug('*** childaccount ='+childAccount);
                Integer parentPosition = childAccount.ParentId<>null?getParentElementPosition(childAccount.ParentId, infoList): 0;
                if(parentPosition < infoList.size())
                    infoList.add(parentPosition, new infoWrapper(childAccount.Id, indent, ac));
                else 
                    infoList.add(new infoWrapper(childAccount.Id, indent, ac));
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
        public accountWrapper a {get; set;}
        public List<String> lList {get; set;}
        public Integer l {get; set;}
        public String accountId;
        
        public infoWrapper(String accountId, Integer l,  accountWrapper acct){
            this.a = acct;
            this.l = l;
            this.accountId = accountId;
            List<String> tmp = new List<String>();
            if (this.l>0) { 
                for(Integer i=0; i<l; i++) 
                tmp.add(String.valueOf(i)); 
                this.lList = tmp;
            }
        }
    }
    public class AccountWrapper {
        //public String accountId {get; set;}
        public String name {get; set;}
        public String organisationTradingName {get; set;}
        public String accountNumber {get; set;}
        public String abn {get; set;}
        public String acn {get; set;}
        public String ownerName {get; set;}
        public String holdingRoleReferenceName {get; set;}
        public String salesDirectorName {get; set;}
        public String superAdminTo {get; set;}
        public List<billingAccountWrapper> baList {get; set;}
    }

    public class BillingAccountWrapper {
        public String name {get; set;}
        public String legacyId {get; set;}
        public String type {get; set;}
        public Boolean sapMarkedfordeletion {get; set;}
        public String abn {get; set;}
        public String acn {get; set;}
        public String payerAccountLegacyId {get; set;}
        public Boolean hasAuthorisationRule {get; set;}
        public Boolean hasBAMRole {get; set;}
        public String bamApplications {get; set;}
    }

    public Integer getParentElementPosition(String ParentId, List<infoWrapper> infoList){
        for (Integer i = 0; i < infoList.size(); i++) {
            if (infoList.get(i).accountId == ParentId) {
                return i+1;
            }
        }
        return 0;
    }
        
    public PageReference toExcel() {
        
        try {
            PageReference secondPage = Page.buildHierarchyView_toExcel;
            secondPage.getParameters().put('aid',currentId);
            
            Blob blobFormExcel = null;
            if(!Test.isRunningTest()){
                blobFormExcel = secondPage.getContent();    
                system.debug('--- got to blob ----');
            }
            
            Attachment fAttach = new Attachment();
            fAttach.Name = 'HierarchyView.xls';
            fAttach.body = blobFormExcel;
            fAttach.parentId = currentId;
            if(!Test.isRunningTest()){
                insert fAttach;
                system.debug('--- inserted fAttach ---');
            }
            Attachment currentAttachment = null;
            Attachment[] attachments = [SELECT Id from Attachment where parentId = :currentId AND Name ='HierarchyView.xls' ORDER By CreatedDate Asc]; //get current versions of this pdf
            if(attachments != null){
                if(attachments.size() > 0){
                    currentAttachment = attachments[0];
                }
            }
            String Link = '';
            if (currentAttachment != null){
                Link = '../' + currentAttachment.Id;
            }
            PageReference prefRedirect = new PageReference(Link);
            prefRedirect.setRedirect(true);
            return prefRedirect;
        } catch (Exception ex)
        {
            return null; 
        }
    }
    
    
    /* 
     * API v28 onward, disallow the inclusion of testmethod in apex classes
     * Source: https://developer.salesforce.com/blogs/engineering/2013/04/apex-test-code-segregation
     * Therefore, Migrate below test code to 'accountStructureController_v2Test' 
    public static testmethod void TestAccountStructureController(){
        
        RecordType rectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        List<Account> accounts = new List<Account>();

        //create accounts
        Account ca1=new Account(name='test1', phone='123', email__c='test@test.com', recordtypeid=rectype.id);
        insert ca1;
        accounts.add(ca1);
        
        Account ca2=new Account(name='test2', phone='123', email__c='test@test.com', recordtypeid=rectype.id, parentid = ca1.id);
        insert ca2;
        accounts.add(ca2);
        
        Account ca3=new Account(name='test2', phone='123', email__c='test@test.com', recordtypeid=rectype.id, parentid = ca2.id);
        insert ca3;
        accounts.add(ca3);

        // insert test billing accounts
        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 2, new List<Account>{accounts[0]});
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P123456';
        testBillingAccList[1].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[1].LEGACY_ID__c = 'P223456';
        testBillingAccList.addAll(TestDataProvider.createBillingAccount('', 2, new List<Account>{accounts[1]}));
        testBillingAccList[2].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[2].LEGACY_ID__c = 'P789456';
        testBillingAccList[3].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[3].LEGACY_ID__c = 'P6647584';
        insert testBillingAccList;

        List<Contact> contacts = new List<Contact>();
        for(Integer i=0;i<accounts.size();i++) {
            Contact con = TestDataProvider.createContact('Contact 1', accounts[i].Id, null);
            con.FirstName = 'Contact ' + i;
            con.LastName = 'Contact ' + i;
            con.Status__c = 'Active';
            contacts.add(con);
        }
        insert contacts;

        Product2 prod = new Product2(Name = 'Test Generic Product');

        insert prod;

        // insert applications
        List<BAMApplication__c> applications = new List<BAMApplication__c>{
                BAMTestUtility.createBamApplication('My App 1', prod.Id),
                BAMTestUtility.createBamApplication('TEST My App 2 Is Long Name', prod.Id)
        };
        insert applications;

        // insert roles for applications
        BAMApplicationRole__c role1 = BAMTestUtility.createApplicationRole(applications[0]);
        role1.Role__c = 'Super Admin';
        List<BAMApplicationRole__c> roles = new List<BAMApplicationRole__c>{
                role1,
                BAMTestUtility.createApplicationRole(applications[1])
        };
        insert roles;

        Map<Id, List<BAMContactApplication__c>> contactsApplicationsMap = new Map<Id, List<BAMContactApplication__c>>();
        List<BAMContactApplication__c> contactApplications = new List<BAMContactApplication__c>();
        for(Contact con : contacts) {
            contactsApplicationsMap.put(con.Id, new List<BAMContactApplication__c>());

            // create contact application records for the contacts
            BAMContactApplication__c contactApp = BAMTestUtility.createTestContactApplication(con.Id, applications[0].Id);
            contactApplications.add(contactApp);
            contactsApplicationsMap.get(con.Id).add(contactApp);

            contactApp = BAMTestUtility.createTestContactApplication(con.Id, applications[1].Id);
            contactApplications.add(contactApp);
            contactsApplicationsMap.get(con.Id).add(contactApp);
        }
        insert contactApplications;

        // insert contact roles for each contact application record that was created
        List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>();
        Map<Id, List<BAMContactRole__c>> contactApplicationsRoleMap = new Map<Id, List<BAMContactRole__c>>();
        for(Contact con : contacts) {
            for(Integer i = 0; i < contactsApplicationsMap.get(con.Id).size(); i+=2) {
                BAMContactApplication__c contactApp = contactsApplicationsMap.get(con.Id)[i];
                BAMContactRole__c role;

                // create a contact role for the first app linked to this contact
                contactApplicationsRoleMap.put(contactApp.Id, new List<BAMContactRole__c>());
                role = BAMTestUtility.createTestContactRole(contactApp.Id, roles[0].Id);
                contactRoles.add(role);
                contactApplicationsRoleMap.get(contactApp.Id).add(role);

                // create a contact role for the second app linked to this contact
                contactApp = contactsApplicationsMap.get(con.Id)[i+1];
                contactApplicationsRoleMap.put(contactApp.Id, new List<BAMContactRole__c>());
                role = BAMTestUtility.createTestContactRole(contactApp.Id, roles[1].Id);
                contactRoles.add(role);
                contactApplicationsRoleMap.get(contactApp.Id).add(role);
            }
        }
        insert contactRoles;

        // insert a couple of linked entities for each of the contact roles that were inserted
        List<BAMLinkedEntity__c> linkedEntities = new List<BAMLinkedEntity__c>();
        for(Contact con : contacts) {
            for(BAMContactApplication__c contactApp : contactsApplicationsMap.get(con.Id)) {
                for(BAMContactRole__c contactRole : contactApplicationsRoleMap.get(contactApp.Id)) {
                    // insert linked entities for this role

                    // find all the linked entities linked to the contact account
                    // there should be a total of 2 linked entities for every contact role
                    for(Billing_Account__c billingAccount : testBillingAccList) {
                        if(Id.valueOf(billingAccount.Organisation__c) == Id.valueOf(con.AccountId)) {
                            linkedEntities.add(new BAMLinkedEntity__c(ContactRole__c = contactRole.Id, Status__c = 'Active', BillingAccount__c = billingAccount.Id));
                        }
                    }

                }
            }
        }
        insert linkedEntities;
        
        Test.startTest();
        //Test coverage for the VF page
        PageReference pageRef = Page.buildHierarchyView_v3;
        pageRef.getParameters().put('aid', ca3.id); 
        Test.setCurrentPageReference(pageRef);

        //Create an instance of the controller
                                    
        accountStructureController_v2 baExCon = new accountStructureController_v2();
        baExCon.toExcel();
        
        System.assertEquals('My App 1', baExCon.getInfo()[0].a.superAdminTo, 'first account should have contact with access to My App 1');
        
        Test.stopTest();
    }*/
    
}