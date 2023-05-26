/**
 * Test Class for accountStructureController_v2
 * @changelog
 * 30-09-2021 seth.heang@auspost.com.au	Migrate the testmode from the main class(accountStructureController_v2) to a new test class
 * */
@isTest
public class accountStructureController_v2Test {
    
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

        ca1.LEGACY_ID__c = '60000000';
        update ca1;
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
    }
}