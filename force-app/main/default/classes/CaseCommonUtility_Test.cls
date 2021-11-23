/**************************************************
Description:    Test Class for CaseCommonUtility
History:
--------------------------------------------------
26.09.2017    kalpita.talwadekar@auspost.com.au    updated test class for coverage on SOQL FIX Updates
2017-10-05    nathan.franklin@auspost.com.au    Removed an old test that tests links to article functionality
2017-10-16    nathan.franklin@auspost.com.au    Adding new conditions to assert NPS details only when cases are closed.
2018-06-25    disha.kariya@auspost.com.au       Removed NPSRequired__c and NPSTagDate__c field.
2018-07-10    nathan.franklin@auspost.com.au  Removed all NPS test methods. These are now covered in NPSSurveyUtil_Test
2019-03-18    gunith.devasurendra@auspost.com.au    Removed deprecated changes.
2019-05-06    gunith.devasurendra@auspost.com.au    Convert Workflow logic to route Cases when state is 'new'ed
2019-05-08    seth.p.heang@accenture.com            Adding test class to assert 'CAR' Case requestor field is populated with current user if left empty upon case creation
2020-11-17 - Ranjeewa Silva - Added test casses to verify Social Case routing behaviour
**************************************************/
@isTest
private with sharing class CaseCommonUtility_Test {
    
    
    @testSetup static void testDataCreate() {
        insert new Conveyancer_Number__c(SetupOwnerId=UserInfo.getOrganizationId(), Next_Id__c=123456);
    }

    //Added by David Catindoy - Sept 20, 2016
    @testSetup static void createUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='StarTrack Support']; 
        UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
        User supportUser = new User(Alias = 'spUser', Email='user@testorg.a', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
        Database.insert(supportUser);
    }
    
    // Constants
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';

    /**
     * For the purpose of testing a deprecated class
     * This can be removed in JUL-2022 with a destructive change to CaseUtilityWithoutSharing
     */
    @IsTest
    private static void testNothingFromCaseUtilityWithoutSharing() {
        CaseUtilityWithoutSharing cls = new CaseUtilityWithoutSharing();
    }

    /**
      * @description       This method tests scenario of associating case with contact with
                            no contacts with email provided
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testContactAssignmentEmailOrigin_NoContact(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Case csRec = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'Email',Type = 'General Enquiry');

            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
            System.assertEquals(null,cs.ContactId);
        }
    }
    
    /**
      * @description       This method tests scenario of associating case with contact
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testContactAssignmentEmailOriginContact(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',null);
            Database.insert(con);
            Case csRec = new Case(SuppliedEmail = 'bruce@wayne.com',Subject = 'Test',Origin = 'Email',Type = 'General Enquiry',ContactId=con.Id);
            
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
            System.assertEquals(con.Id,cs.ContactId);
        }
    }
    /**
      * @description       This method tests scenario of associating Portal cases from HS forms in the un-authenticated context
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testContactAssignmentPortalNocontact(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Case csRec = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'Portal',Type = 'General Enquiry'
                                  ,First_Name__c='Bruce',Last_Name__c='Wayne',CHASEnquiryType__c='Delivery issue');
            Case csRecBSP = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'BSP',Type = 'Investigation'
                                  ,First_Name__c='Bruce',Last_Name__c='Wayne',CHASEnquiryType__c='',EnquirySubType__c='Delivery complaint');

            Test.startTest();
                Database.insert(csRec);
                Database.insert(csRecBSP);
            Test.stopTest();
    }
    }

    /********************************************************************
    Name:       testassignContactIDToSnapItCase
    Purpose:    This method tests the testassignContactIDToSnapItCase
    Return:     void
    Param:      N/A
    History:    
    ---------------------------------------------------------------------
    12.05.2017  A. Rivera   Created
    *********************************************************************/  
    private static testMethod void testAssignContactIDToSnapItCase(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            
            Id recTypeId = accRecTypeMap.get('Consumer').getRecordTypeId();
            
            Account acc = TestUtility.createBusinessAccount('TestAccount1', accRecTypeMap.get('Organisation').getRecordTypeId());
            Contact con1 = new Contact(FirstName = 'TesTfirstName',LastName = 'TestlastName',Email = 'test@email.com',AccountId = acc.Id, phone = '0478738121');
            Contact con2 = new Contact(FirstName = 'TesTfirstName1',LastName = 'TestlastName1',Email = 'test@email.com',AccountId = acc.Id, phone = '0478738120');
            List<Contact> lstContact = new List<Contact>{con1, con2};
            Database.insert(lstContact);
            
            
            Account acct1 = new Account(FirstName = 'Bruce',LastName = 'Wayne', PersonEmail = 'bruce@wayne.com', RecordTypeId = recTypeId, PersonMobilePhone = '0478738121');
            Database.insert(acct1);
            
            Case csRec1 = new Case(Contact_Email__c = 'bruce@wayne.com',Subject = 'Test',Origin = 'Snap It',Type = 'General Enquiry',
                                    PrimaryContactFirstName__c = 'Bruce', PrimaryContactLastName__c = 'Wayne', Contact_Mobile__c = '0478738121',
                                    ProductCategory__c = 'Domestic Parcels', ProductSubCategory__c = 'Courier Post');
                                    
            Case csRec2 = new Case(Contact_Email__c = 'test@email.com',Subject = 'Test',Origin = 'Snap It',Type = 'General Enquiry',
                                    PrimaryContactFirstName__c = 'Bruce', PrimaryContactLastName__c = 'Wayne', Contact_Mobile__c = '0478738122',
                                    ProductCategory__c = 'Domestic Parcels', ProductSubCategory__c = 'Courier Post');    
                                    
            Case csRec3 = new Case(Contact_Email__c = 'test@email.com',Subject = 'Test',Origin = 'Snap It',Type = 'General Enquiry',
                                    PrimaryContactFirstName__c = 'Bruce', PrimaryContactLastName__c = 'Wayne', Contact_Mobile__c = '0478738121',
                                    ProductCategory__c = 'Domestic Parcels', ProductSubCategory__c = 'Courier Post');                         
                                    
            Case csRec4 = new Case(Contact_Email__c = 'test@email.com',Subject = 'Test',Origin = 'Snap It',Type = 'General Enquiry',
                                    PrimaryContactFirstName__c = 'TesTfirstName', PrimaryContactLastName__c = 'TestlastName', Contact_Mobile__c = '0478738123',
                                    ProductCategory__c = 'Domestic Parcels', ProductSubCategory__c = 'Courier Post');     
                                    
            Case csRec5 = new Case(Contact_Email__c = 'test@emailko.com',Subject = 'Test',Origin = 'Snap It',Type = 'General Enquiry',
                                    PrimaryContactFirstName__c = 'TesTfirstName', PrimaryContactLastName__c = 'TestlastName', Contact_Mobile__c = '0478738121',
                                    ProductCategory__c = 'Domestic Parcels', ProductSubCategory__c = 'Courier Post'); 
             
            Case csRec6 = new Case(Contact_Email__c = 'test@email.com',Subject = 'Test',Origin = 'Snap It',Type = 'General Enquiry',
                                    PrimaryContactFirstName__c = 'TesTfirstName', PrimaryContactLastName__c = 'TestlastName', Contact_Mobile__c = '0478738121',
                                    ProductCategory__c = 'Domestic Parcels', ProductSubCategory__c = 'Courier Post');                         
                                    
            List<Case> lstCase = new List<Case>{csRec1, csRec2, csRec3, csRec4,csRec5,csRec6};
            
            Test.startTest();
                Database.insert(lstCase);
            Test.stopTest();
            List<Case> lstcs = [SELECT Id FROM Case];
            //System.assertEquals(lstcs.size(),5);
        }


    }

    /**
      * @description       This method tests scenario of associating case with contact 
                            for origin other than portal & email, with contact details in case
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testLinkContactShortListedCases(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
                        
            Account acc = TestUtility.createPersonAccount('Wayne',accRecTypeMap.get('Consumer').getRecordTypeId());
            acc.FirstName = 'Bruce';
            acc.PersonEmail = 'bruce@wayne.com';
            Database.insert(acc);
            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',null);
            Database.insert(con);

            Case csRec = new Case(SuppliedEmail = 'bruce@wayne.com',Subject = 'Test',Origin = 'Phone',Type = 'General Enquiry',
                                    First_Name__c = 'Bruce',Last_Name__c = 'Wayne',ContactId=con.Id);
            
            Test.startTest();
            Database.insert(csRec);
            Test.stopTest();
            Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
            Account consumer = [SELECT PersonContactId FROM Account WHERE Id =: acc.Id LIMIT 1];
            //System.assertEquals(consumer.PersonContactId,cs.ContactId);
            System.assertNotEquals(consumer.PersonContactId,null);
            System.assertNotEquals(cs.ContactId,null);
        }
    }
    
    /**
      * @description       This method tests scenario of associating case with contact 
                            for origin other than portal & email, with contact details in case
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testLinkBusinessContact(){
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Account acc;
        Billing_Account__c billAcc;
        Contact con;
        System.runAs(TestUtility.createUser('Admin',adminProf.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            
            List<Account> accList = new List<Account>();
            // Creating temporary account used by Billing Account Trigger
            Account tempAcc = TestUtility.createBusinessAccount('Temporary Customer',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            tempAcc.LEGACY_ID__c = '60000000';
            accList.add(tempAcc);
            acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            acc.LEGACY_ID__c = '12345';
            accList.add(acc);
            Database.insert(accList);
            
            tempAcc.LEGACY_ID__c = '60000000';
            Database.update(tempAcc);
            
            
            billAcc = TestUtility.createBillingAccount('Bill Acc',acc.Id);
            Database.insert(billAcc);
            billAcc = [SELECT Customer_Number__c FROM Billing_Account__c WHERE Id =: billAcc.Id LIMIT 1];
            con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            con.BillingAccount__c = billAcc.Id;
            Database.insert(con);
        }
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Case csRec = new Case(SuppliedEmail = 'bruce@wayne.com',Subject = 'Test',Origin = 'Phone',Type = 'General Enquiry',
                                    First_Name__c = 'Bruce',Last_Name__c = 'Wayne',Billing_Number__c = billAcc.Customer_Number__c,ContactId=con.Id);
            
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
            System.assertEquals(con.Id,cs.ContactId);
        }
    }
    
    /**
      * @description       This method tests scenario of associating case with contact 
                            for origin other than portal & email, with contact details in case
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testLinkBusinessDiffContact(){
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Account acc;
        System.runAs(TestUtility.createUser('Admin',adminProf.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            
            List<Account> accList = new List<Account>();
            // Creating temporary account used by Billing Account Trigger
            Account tempAcc = TestUtility.createBusinessAccount('Temporary Customer',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            tempAcc.LEGACY_ID__c = '60000000';
            accList.add(tempAcc);
            acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            acc.LEGACY_ID__c = '12345';
            accList.add(acc);
            Database.insert(accList);
            
            tempAcc.LEGACY_ID__c = '60000000';
            Database.update(tempAcc);
            
            System.debug('** Billing Account ==>'+[SELECT Id,Legacy_Id__c FROM Account]);
            Billing_Account__c billAcc = TestUtility.createBillingAccount('Bill Acc',acc.Id);
            Database.insert(billAcc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            con.BillingAccount__c = billAcc.Id;
            Database.insert(con);
        }
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Case csRec = new Case(SuppliedEmail = 'bruce@wayne.com',Subject = 'Test',Origin = 'Phone',Type = 'General Enquiry',
                                    First_Name__c = 'Bruce',Last_Name__c = 'Wayne',Billing_Number__c = '12346');
            
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
            System.assertEquals(null,cs.ContactId);
        }
    }
    
    /**
      * @description       This method tests scenario of associating case with contact 
                            for origin other than portal & email, with contact details in case
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testLinkBusinessNoContact(){
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Account acc;
        System.runAs(TestUtility.createUser('Admin',adminProf.id,null)){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            
            List<Account> accList = new List<Account>();
            // Creating temporary account used by Billing Account Trigger
            Account tempAcc = TestUtility.createBusinessAccount('Temporary Customer',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            tempAcc.LEGACY_ID__c = '60000000';
            accList.add(tempAcc);
            acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            acc.LEGACY_ID__c = '12345';
            accList.add(acc);
            Database.insert(accList);
            
            tempAcc.LEGACY_ID__c = '60000000';
            Database.update(tempAcc);
            
            System.debug('** Billing Account ==>'+[SELECT Id,Legacy_Id__c FROM Account]);
            Billing_Account__c billAcc = TestUtility.createBillingAccount('Bill Acc',acc.Id);
            Database.insert(billAcc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            con.BillingAccount__c = billAcc.Id;
            Database.insert(con);
        }
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Case csRec = new Case(SuppliedEmail = 'bruce@wayne.com',Subject = 'Test',Origin = 'Phone',Type = 'General Enquiry',
                                    First_Name__c = 'Bruce',Last_Name__c = 'Wayne');
            
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Case cs = [SELECT ContactId FROM Case WHERE Id =: csRec.Id LIMIT 1];
            //System.assert(cs.ContactId != null);
        }
    }
    
    /**
      * @description       This method tests scenario of detecting cases from spam email
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testDetectSpamCase(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            SpamEmail__c spam = TestUtility.createSpamEmail('test@test.com');
            Database.insert(spam);
            
            Case csRec = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'Email',Type = 'General Enquiry');

            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Case cs = [SELECT Prevent_Email__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
            System.assertEquals(true,cs.Prevent_Email__c);
        }
    }
    
    /**
      * @description       This method tests scenario of detecting cases from email not in spam table
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testDetectNoSpamCase(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            SpamEmail__c spam = TestUtility.createSpamEmail('test1@test.com');
            Database.insert(spam);
            
            Case csRec = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'Email',Type = 'General Enquiry');

            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            Case cs = [SELECT Prevent_Email__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
            System.assertEquals(false,cs.Prevent_Email__c);
        }
    }
    
    /**
      * @description       This method tests scenario of detecting cases from spam email
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testOnHoldCase(){
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        List<User> userList = new List<User>();
        User caseOwner = TestUtility.createUser('Peter',adminProf.id,null);
        User runningUser = TestUtility.createUser('Wayne',prof.id,null);
        userList.add(caseOwner);
        userList.add(runningUser);
        Database.insert(userList);
        
        System.runAs(caseOwner){    // running with admin as Case OWD is private & criteria-based sharing rule cannot be tested in apex
            SpamEmail__c spam = TestUtility.createSpamEmail('test@test.com');
            Database.insert(spam);
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = new Case(SuppliedEmail = 'test@test.com',Subject = 'Test',Origin = 'Email',Type = 'General Enquiry',
                                    OwnerId = runningUser.Id);
            csRec.RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
            Database.insert(csRec);
            Test.startTest();
                csRec.Status = SSSWConstants.STAT_ON_HOLD;
                Database.update(csRec);
            Test.stopTest();
            Case cs = [SELECT OwnerId FROM Case WHERE Id =: csRec.Id LIMIT 1];
            System.assertEquals(caseOwner.Id,cs.OwnerId);
        }
    }
    
    /**
      * @description       This method tests scenario of preventing duplicate case for DDC user
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    /*
    private static testMethod void testValidateCaseDDC(){
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Profile ddcProf = [SELECT Id,Name FROM profile where Name = 'DDC Consumer Community User' LIMIT 1];
        UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account acc = TestUtility.createPersonAccount('Peter',accRecTypeMap.get('Consumer').getRecordTypeId());
        acc.FirstName = 'Parker';
        acc.PersonEmail = 'peter@wayne.com';
        Database.insert(acc);
        acc = [SELECT PersonContactId FROM Account WHERE Id =: acc.Id LIMIT 1];
        User ddcUser = TestUtility.createPortalUser('Wayne',ddcProf.id,acc.PersonContactId);
        
        User admin = TestUtility.createUser('Peter',adminProf.id,null);
        System.runAs(admin){
            TestUtility.createUniqueCaseCustomSetting();
        }
        
        System.runAs(ddcUser){
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,ddcUser.ContactId,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.ProductCategory__c = 'International Letters';
            csRec.ReferenceId__c = '12345';
            csRec.Address2__c  = '111 Bourke Street';
            Database.insert(csRec);
            
            Case dupeCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,ddcUser.ContactId,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            dupeCase.ProductCategory__c = 'International Letters';
            dupeCase.ReferenceId__c = '12345';
            dupeCase.Address2__c  = '111 Bourke Street';
            Test.startTest();
                try{
                    Database.insert(dupeCase);
                }
                catch(Exception exp){
                     System.assertEquals('System.DmlException',exp.getTypeName());
                     System.assert(exp.getMessage().contains(Label.DUPE_CASE_ERR_MSG));
                }
            Test.stopTest();
            System.assert(dupeCase.Id != null);
        }
    } */
    
    /**
      * @description       This method tests scenario of preventing duplicate case for BSP user
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testValidateCaseBSP(){
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Profile bspProf = [SELECT Id,Name FROM profile where Name = 'BSP Community User' LIMIT 1];
        
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                        accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);

        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        Database.insert(con);

        User bspUser = TestUtility.createPortalUser('Wayne',bspProf.Id,con.Id);
        User admin = TestUtility.createUser('Peter',adminProf.id,null);
        System.runAs(admin){
            TestUtility.createUniqueCaseCustomSetting();
        }
        
        System.runAs(bspUser){
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,bspUser.ContactId,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.ProductCategory__c = 'International Letters';
            csRec.ReferenceId__c = '12345';
            csRec.Address2__c  = '111 Bourke Street';
            Database.insert(csRec);
            
            Case dupeCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',null,bspUser.ContactId,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            dupeCase.ProductCategory__c = 'International Letters';
            dupeCase.ReferenceId__c = '12345';
            dupeCase.Address2__c  = '111 Bourke Street';
            Test.startTest();
                try{
                    Database.insert(dupeCase);
                }
                catch(Exception exp){
                     System.assertEquals('System.DmlException',exp.getTypeName());
                     System.assert(exp.getMessage().contains(Label.DUPE_CASE_ERR_MSG));
                }
            Test.stopTest();
            //System.assert(dupeCase.Id == null);
        }
    }
    
    /**
      * @description       This method tests scenario of preventing duplicate cases as agent
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testValidateCaseAgent(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.createUniqueCaseCustomSetting();
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.ProductCategory__c = 'International Letters';
            csRec.ProductSubCategory__c ='International Courier';
            csRec.ReferenceId__c = '12345';
            csRec.Address2__c  = '111 Bourke Street';
            Database.insert(csRec);
            
            Case dupeCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            dupeCase.ProductCategory__c = 'International Letters';
            dupeCase.ProductSubCategory__c ='International Courier';

            dupeCase.ReferenceId__c = '12345';
            dupeCase.Address2__c  = '111 Bourke Street';
            Test.startTest();
                Database.insert(dupeCase);
            Test.stopTest();
            System.assert(dupeCase.Id != null);
            Map<Id, Case> casesToCheck = new Map<Id, Case>([SELECT CaseLocality__c,Id FROM Case WHERE Id =: csRec.Id OR Id =: dupeCase.Id]);
            
//            csRec = [SELECT CaseLocality__c,Id FROM Case WHERE Id =: csRec.Id LIMIT 1];
//            dupeCase = [SELECT CaseLocality__c,Id FROM Case WHERE Id =: dupeCase.Id LIMIT 1];
           // System.debug('** dupeCase ==>'+ dupeCase);
            //System.assertEquals('International',dupeCase.CaseLocality__c);
//            System.assertEquals(csRec.CaseLocality__c, dupeCase.CaseLocality__c);
            System.assertEquals(casesToCheck.get(csRec.Id).CaseLocality__c, casesToCheck.get(dupeCase.Id).CaseLocality__c);
        }
    }
    
    /**
      * @description       This method tests scenario of associating article to case
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testLinkArticle(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.createUniqueCaseCustomSetting();
            // This causes a mock response to be generated
            Test.setMock(WebServiceMock.class, new AuspostTrackEventServiceMockImpl());
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.ProductCategory__c = 'International Letters';
            csRec.ReferenceId__c = '12345';
            csRec.Origin = 'Email';
            csRec.Address2__c  = '111 Bourke Street';
            csRec.Bypass_Data_enforcement__c = true;

            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();
            csRec = [SELECT ArticleTest__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
            System.assert(csRec.ArticleTest__c != null);
        }
    }
    
    /**
      * @description       This method tests scenario of case queue allocation
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testAllocateToQueue(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Case csRec;
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.createUniqueCaseCustomSetting();
            // This causes a mock response to be generated
            Test.setMock(WebServiceMock.class, new AuspostTrackEventServiceMockImpl());
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.AllocateToQueue__c = true;
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();            
        }
        csRec = [SELECT AllocateToQueue__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
        System.assertEquals(false,csRec.AllocateToQueue__c);
    }
    
//  Can be removed NOV-2020
//    /**
//      * @description       This method tests scenario of associating article to case
//      * @param             NA
//      * @return            Void
//      * @throws            NA
//      */
//    private static testMethod void testSubscribeArticle(){
//        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
//        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
//            TestUtility.createUniqueCaseCustomSetting();
//
//            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
//            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
//                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
//            Database.insert(acc);
//
//            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
//            Database.insert(con);
//
//            Article__c article = TestUtility.createArticle('12345',1,'Bruce','Peter','International Letters');
//            Database.insert(article);
//
//            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
//            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
//                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
//            csRec.ProductCategory__c = 'International Letters';
//            csRec.ReferenceId__c = '12345';
//            csRec.Origin = 'Email';
//            csRec.Address2__c  = '111 Bourke Street';
//            csRec.ArticleTest__c  = article.Id;
//            Database.insert(csRec);
//
//            Test.startTest();
//                csRec.Subscribed__c = true;
//                Database.update(csRec);
//            Test.stopTest();
//            article = [SELECT Subscribed__c FROM Article__c WHERE Id =: article.Id LIMIT 1];
//            System.assert(article.Subscribed__c);
//        }
//    }
    
    /**
      * @description       This method tests scenario of detecting cases from spam email
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCloseChildCases(){
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        List<User> userList = new List<User>();
        User caseOwner = TestUtility.createUser('Peter',adminProf.id,null);
        User runningUser = TestUtility.createUser('Wayne',prof.id,null);
        userList.add(caseOwner);
        userList.add(runningUser);
        Database.insert(userList);
        
        System.runAs(caseOwner){    // running with admin as Case OWD is private & criteria-based sharing rule cannot be tested in apex
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Article__c article = TestUtility.createArticle('12345',1,'Bruce','Peter','International Letters');
            Database.insert(article);
            
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            Database.insert(csRec);
            
            List<Case> childCases = new List<Case>();
            Case childCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            childCase.ParentId = csRec.Id;
            
            Case childClosedCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            childClosedCase.ParentId = csRec.Id;
            childClosedCase.Status =  'Closed';
            childClosedCase.ResolutionCode__c = 'Actioned';
            
            Case childCaseTwo = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            childCaseTwo.ParentId = csRec.Id;
            
            childCases.add(childCase);
            childCases.add(childClosedCase);
            childCases.add(childCaseTwo);
            
            Test.startTest();
                Database.insert(childCases);
            
                csRec.Status =  'Closed';
                csRec.ResolutionCode__c = 'Actioned';
                Database.update(csRec);
            Test.stopTest();
            Case cs = [SELECT Status FROM Case WHERE Id =: childCase.Id LIMIT 1];
            System.assertEquals('Closed',cs.Status);
        }
    }
    
    /**
      * @description       This method tests scenario of detecting cases from spam email
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testAvoidCustomerCloseCase(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){ 
            TestUtility.createEnquirySubTypeCustomSetting();
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Article__c article = TestUtility.createArticle('12345',1,'Bruce','Peter','International Letters');
            Database.insert(article);
            
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.EnquirySubType__c = 'Damaged/Missing contents';
            Database.insert(csRec);
            
            Test.startTest();
                csRec.Status =  'Closed';
                csRec.ResolutionCode__c = 'Actioned';
                csRec.Customer_Milestones_Violated__c = 4;
                csRec.ClosedBySystem__c = true;
                Database.update(csRec);
            Test.stopTest();
            Case cs = [SELECT Status,ResolutionCode__c,ClosedBySystem__c FROM Case WHERE Id =: csRec.Id LIMIT 1];
            System.assertEquals(false,cs.ClosedBySystem__c);
            System.assertEquals(null,cs.ResolutionCode__c);
            System.assertEquals('In Progress',cs.Status);            
        }
    }
    
    /**
      * @description       This method tests scenario of routing case
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCaseRouting(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){ 
            Group backOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SSSWBusinessBackOffice' LIMIT 1];
            SSSWRouting__c routing = TestUtility.createSSSWRouting('Domestic Parcels','Express','General Enquiry',null,'Consumer','Email','Any',SSSWConstants.RECTYPEROUTING);
            routing.IsNew__c = true;
            routing.ExcludeFromNPS__c = true;
            routing.IsActive__c = True;
            routing.Queue_ID__c = backOfcQueue.Id;
            Database.insert(routing);
            System.debug('Routing4--->'+routing);
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.Origin = 'Email';
            csRec.ProductCategory__c = 'Domestic Parcels';
            csRec.ProductSubCategory__c = 'Express';
            csRec.ReferenceId__c = '12345';
            csRec.Address2__c  = '111 Bourke Street';
            csRec.IsNewForRouting__c  = true;
            csRec.AllocateToQueue__c = true;
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();            
        }
        Case cs = [SELECT AllocateToQueue__c,OwnerId FROM Case LIMIT 1];
        System.assertEquals(false,cs.AllocateToQueue__c);
        System.assertEquals(Group.sObjectType,cs.OwnerId.getSObjectType());
    }

    private static testMethod void testSocialCaseRouting(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];

        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Case socialCase1 = TestUtility.createCase('Social Post','New',null, null, null, caseRecTypeMap.get('Social Record Type').getRecordTypeId());
        socialCase1.Origin = 'Social';
        socialCase1.IsNewForRouting__c  = true;
        socialCase1.AllocateToQueue__c = true;
        socialCase1.SocialPostTags__c = 'post tag1';//Ensure the social post tags on case match SSSW routing rule

        Case socialCase2 = TestUtility.createCase('Social Post','New',null, null, null, caseRecTypeMap.get('Social Record Type').getRecordTypeId());
        socialCase2.Origin = 'Social';
        socialCase2.IsNewForRouting__c  = true;
        socialCase2.AllocateToQueue__c = true;
        socialCase2.SocialPostTags__c = 'post';//Ensure the social post tags on case does not match SSSW routing rule

        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            Group backOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SSSWBusinessBackOffice' LIMIT 1];
            SSSWRouting__c routing = TestUtility.createSSSWRouting(null,null,null,null,null,'Social','All',SSSWConstants.RECTYPEROUTING);
            routing.SocialPostTags__c = 'post tag1;post tag2';
            routing.IsActive__c = true;
            routing.Queue_ID__c = backOfcQueue.Id;
            Database.insert(routing);

            Test.startTest();
            Database.insert(new Case[]{socialCase1, socialCase2});
            Test.stopTest();
        }
        Map<Id,Case> savedCases = new Map<Id, Case>([SELECT Id, AllocateToQueue__c,OwnerId FROM Case]);
        System.assertEquals(false, savedCases.get(socialCase1.Id).AllocateToQueue__c);
        System.assertEquals(Group.sObjectType,savedCases.get(socialCase1.Id).OwnerId.getSObjectType());

        System.assertEquals(false, savedCases.get(socialCase2.Id).AllocateToQueue__c);
        System.assertEquals(User.sObjectType,savedCases.get(socialCase2.Id).OwnerId.getSObjectType());
    }
    
    /**
      * @description       This method tests scenario of routing case
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCaseRoutingDescUpdate(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){ 
            Group backOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SSSWBusinessBackOffice' LIMIT 1];
            SSSWRouting__c routing = TestUtility.createSSSWRouting('Domestic Parcels','Express','General Enquiry',null,'Consumer','Email','Any',SSSWConstants.RECTYPEROUTING);
            routing.IsNew__c = true;
            routing.IsActive__c = True;
            routing.ExcludeFromNPS__c = true;
            routing.Queue_ID__c = backOfcQueue.Id;
            Database.insert(routing);
            System.debug('Routing1--->'+routing);
            
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.Origin = 'Email';
            csRec.ProductCategory__c = 'Domestic Parcels';
            csRec.ProductSubCategory__c = 'Express';
            csRec.ReferenceId__c = '12345';
            csRec.Address2__c  = '111 Bourke Street';
            csRec.IsNewForRouting__c  = true;
            csRec.AllocateToQueue__c = true;
            csRec.Bypass_Data_enforcement__c = true;
            Database.insert(csRec);
            
            Test.startTest();
                // CaseCommonUtility.isRouteCaseRecursive = false; // Gunith (2019-03-18): isRouteCaseRecursive not valid anymore due to Recursion logic
                csRec.Description = 'Description Updated';
                Database.update(csRec);
            Test.stopTest();            
        }
        Case cs = [SELECT AllocateToQueue__c,OwnerId FROM Case LIMIT 1];
        System.assertEquals(false,cs.AllocateToQueue__c);
        System.assertEquals(Group.sObjectType,cs.OwnerId.getSObjectType());
    }

    /**
      * @description       This method tests scenario of routing case with no matching sssw routing
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCaseNoRouting(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){ 
            Group backOfcQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SSSWBusinessBackOffice' LIMIT 1];
            SSSWRouting__c routing = TestUtility.createSSSWRouting('Domestic Parcels','Express','General Enquiry',null,'SMB','Email');
            routing.IsNew__c = true;
            routing.IsActive__c = True;
            routing.ExcludeFromNPS__c = true;
            routing.Queue_ID__c = backOfcQueue.Id;
            Database.insert(routing);
            System.debug('Routing2--->'+routing);

            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
            acc.ServiceSLA__c = 'Test SLA';
            Database.insert(acc);

            Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
            Database.insert(con);
            
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
                                                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
            csRec.Origin = 'Email';
            csRec.ProductCategory__c = 'Domestic Parcels';
            csRec.ProductSubCategory__c = 'Express';
            csRec.ReferenceId__c = '12345';
            csRec.Address2__c  = '111 Bourke Street';
            csRec.IsNewForRouting__c  = true;
            csRec.AllocateToQueue__c = true;
            Test.startTest();
                Database.insert(csRec);
            Test.stopTest();            
        }
        Case cs = [SELECT AllocateToQueue__c,OwnerId FROM Case LIMIT 1];
        System.assertEquals(false,cs.AllocateToQueue__c);
        System.assertEquals(User.sObjectType,cs.OwnerId.getSObjectType());
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testLinkContactExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseCommonUtility helper = new CaseCommonUtility();
            Test.startTest();
                helper.assignContactIDToCase(new List<Case>{null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testValidateCaseExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseCommonUtility helper = new CaseCommonUtility();
            Test.startTest();
            helper.validateCase(new List<Case>{null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testSpamExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseCommonUtility helper = new CaseCommonUtility();
            Test.startTest();
                helper.detectPermanentSpam(new List<Case>{null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testCloseChildExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseCommonUtility helper = new CaseCommonUtility();
            Test.startTest();
                helper.closeChildCases(new List<Case>{null},new Map<Id,Case>{null => null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testXferCaseExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseCommonUtility helper = new CaseCommonUtility();
            Test.startTest();
                helper.setOwnerToCurrentUser(new List<Case>{null},new Map<Id,Case>{null => null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testAvoidCaseCloseExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseCommonUtility helper = new CaseCommonUtility();
            Test.startTest();
                helper.avoidCustomerClose(new List<Case>{null},new Map<Id,Case>{null => null});
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }

// Can be removed NOV-2020
//    /**
//      * @description       This method is for covering exception and not a valid business scenario
//      * @param             NA
//      * @return            Void
//      * @throws            NA
//      */
//    private static testMethod void testSubscribeArticleExceptionScenario(){
//        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
//        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
//            TestUtility.severityLevelValue();
//            CaseCommonUtility helper = new CaseCommonUtility();
//            Test.startTest();
//                helper.setArticlesSubscribed(new List<Case>{null});
//            Test.stopTest();
//            Integer expCount = [SELECT count() FROM ExceptionLog__c];
//            System.assertEquals(1,expCount);
//        }
//    }
    
    /**
      * @description       This method is for covering exception and not a valid business scenario
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    private static testMethod void testRouteCaseExceptionScenario(){
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null)){
            TestUtility.severityLevelValue();
            CaseCommonUtility helper = new CaseCommonUtility();
            Test.startTest();
                helper.routeCase(new List<Case>{null},new Map<Id,Case>{null => null}, false);
            Test.stopTest();
            Integer expCount = [SELECT count() FROM ExceptionLog__c];
            System.assertEquals(1,expCount);
        }
    }
   // StarTrack R4.0 and R4.1 Test methods
    /**
      * @description       StarTrack - this method is to test closing of tasks and workflow emails after closing Case
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    static testmethod void testCloseBulkTasks() {    
        
        User supportUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'spUser' LIMIT 1];
        
        //System.runAs(supportUser){
            Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(); //Query for delivery enquiry record type
            //Create sample delivery enquiry case.
            Case testCase = TestDataProvider.createTestCase();
            testCase.RecordTypeId = deliveryRecType;
            testCase.Call_Purpose__c = 'Late Delivery';
            testCase.Subject = 'Sample Case';
            testCase.Origin = 'Phone';
            testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_DEF;
            testCase.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
            Database.insert(testCase);
            
            //Create child tasks
            List<Task> newTasks = new List<Task>();
            newTasks.add(new Task(RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId(), Status = StarTrack_Constants.TASK_STATUS_WAITING, WhatId = testCase.Id, Sub_Type__c = StarTrack_Constants.TASK_SUBTYPE_MASSTASKING, Priority='Low'));
            newTasks.add(new Task(RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(StarTrack_Constants.TASK_RECTYPE_OPERATION).getRecordTypeId(), Status = StarTrack_Constants.TASK_STATUS_WAITING, WhatId = testCase.Id, Sub_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING, Priority='Low'));
            Database.insert(newTasks);
            
            //Create child workflow emails
            List<workflow_Email__c> newWFs = new List<workflow_Email__c>();
            newWFs.add(new workflow_Email__c(Status__c = StarTrack_Constants.WFE_STATUS_OPEN, Case__c = testCase.Id, Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_MASSTASKING));
            newWFs.add(new workflow_Email__c(Status__c = StarTrack_Constants.WFE_STATUS_OPEN, Case__c = testCase.Id, Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING));
            Database.insert(newWFs);
            
            Test.startTest();
                Case caseRec = [SELECT Id,OwnerId, Status, ResolutionCode__c, Close_Bulk_Tasks__c FROM Case WHERE Id =: testCase.Id];
                caseRec.Close_Bulk_Tasks__c = true;
                Database.update(caseRec);
                
                caseRec.Status = StarTrack_Constants.CASE_STAT_CLOSED;
                caseRec.ResolutionCode__c = StarTrack_Constants.CASE_RESOLUTION_DUPLICATE;
                Database.update(caseRec);
            Test.stopTest();
            
            System.assertEquals(true, [SELECT Id, Status FROM Task WHERE Status != :StarTrack_Constants.TASK_STATUS_FINISHED AND WhatId = :testCase.Id].isEmpty());
            System.assertEquals(true, [SELECT Id, Status__c FROM workflow_Email__c WHERE Status__c != :StarTrack_Constants.WFE_STATUS_CLOSE AND Case__c = :testCase.Id].isEmpty());
        //}
    }
    
    /**
      * @description       StarTrack - This method is used to test notification automation
      * @param             NA     
      * @return            Void
      * @throws            NA
      */
    static testmethod void testNotificationAutomationModel() {    
        
        User supportUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'spUser' LIMIT 1];
        Id notificationRT = Schema.SObjectType.StarTrack_Automation_Rule__c.getRecordTypeInfosByName().get('StarTrack Notification Automation').getRecordTypeId();
        Database.insert(new StarTrack_Automation_Rule__c(RecordTypeId = notificationRT, Order__c = 1, Case_RecordType__c = 'Delivery Enquiry', Case_Status__c = 'Closed', Case_Action__c = 'Send Notification', SMS_Template__c = 'Sample', Email_Template__c = 'Delivered Consignment Notification - Customer Service'));
        Article__c consignment = new Article__c(Name = 'AJSGDH1234', Consignment_Summary_Status__c = 'Delivered');
        Database.insert(consignment);
        System.runAs(supportUser){
            Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(); //Query for delivery enquiry record type
            //Create sample delivery enquiry case.
            Case testCase = TestDataProvider.createTestCase();
            testCase.RecordTypeId = deliveryRecType;
            testCase.Call_Purpose__c = 'Late Delivery';
            testCase.Subject = 'Sample Case';
            testCase.ArticleTest__c = consignment.Id;
            testCase.Origin = 'Phone';
            testCase.Status = StarTrack_Constants.CASE_STATUS_INVESTIGATION;
            testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_DEF;
            testCase.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
            Database.insert(testCase);
            
            List<AuthorisedContacts__c> relContList = new List<AuthorisedContacts__c>();
            relContList.add(new AuthorisedContacts__c(First_Name__c = 'David', Last_Name__c = 'Catindoy', Contact_Email__c = 'davidcatindoy@gmail.com', Case__c = testCase.Id, Contact_Type__c = 'Sender', Initial_Contact__c = true, Notification_Required__c = true, Pref_Method_of_Contact__c = 'Email'));
            relContList.add(new AuthorisedContacts__c(First_Name__c = 'Joie', Last_Name__c = 'Castillo', Contact_Mobile_Number__c = '0412849506', Case__c = testCase.Id, Contact_Type__c = 'Receiver', Notification_Required__c = true, Pref_Method_of_Contact__c = 'Mobile'));
            relContList.add(new AuthorisedContacts__c(First_Name__c = 'Jen', Last_Name__c = 'Tan', Contact_Phone_Number__c = '0412849506', Case__c = testCase.Id, Contact_Type__c = 'Sender', Notification_Required__c = true, Pref_Method_of_Contact__c = 'Phone'));
            Database.insert(relContList);
            
            Test.startTest();
                Case caseRec = [SELECT Id, OwnerId, Status, ResolutionCode__c FROM Case WHERE Id =: testCase.Id];
                caseRec.Status = StarTrack_Constants.CASE_STAT_CLOSED;
                caseRec.ResolutionCode__c = StarTrack_Constants.CASE_RESOLUTION_DUPLICATE;
                Database.update(caseRec);
                
            Test.stopTest();
            
            System.assertEquals(StarTrack_Constants.CASE_STAT_PENCUSNOTIF, [SELECT Id, Status FROM Case WHERE Id = :testCase.Id].Status);
        }
    }

    /**
     * Generate an ID for an Object based on SObjectType
     *
     * @param sot SObjectType
     * @param seed Nth ID to generate
     *
     * @return The Id
     */
    public static String makeFakeId(Schema.SObjectType sot, Integer seed)
    {
        String result = String.valueOf(seed);
        return sot.getDescribe().getKeyPrefix() +
                '0'.repeat(12-result.length()) + result;
    }

    /**
     * Multiple Test Cases for AllocateToQueue__c after a Case status is made 'New'
     */
    static testMethod void testMarkRenewedCasesToRoute(){

        Integer idSeed = 1;

        List<Case> casesBeforeTrigger = new List<Case>();
        Map<Id,Case> casesAfterTrigger = new Map<Id, Case>();

        // Refers to a Case which hasn't gone through any changes => shouldn't route
        Case unchanged = new Case(Id = makeFakeId(Case.SObjectType, idSeed++));
        casesAfterTrigger.put(unchanged.Id, unchanged);
        casesBeforeTrigger.add(unchanged);

        // Refers to a Case.Status=New with No categories and types set => shouldn't route
        String reopenedNoTypesNoCategoriesId = makeFakeId(Case.SObjectType, idSeed++);
        Case reopenedNoTypesNoCategoriesBefore = new Case(Id = reopenedNoTypesNoCategoriesId, Status = 'Closed');
        Case reopenedNoTypesNoCategoriesAfter = new Case(Id = reopenedNoTypesNoCategoriesId, Status = 'New');
        casesAfterTrigger.put(reopenedNoTypesNoCategoriesBefore.Id, reopenedNoTypesNoCategoriesBefore);
        casesBeforeTrigger.add(reopenedNoTypesNoCategoriesAfter);

        // Refers to a Case.Status=New with categories and types set => should route
        String reopenedId = makeFakeId(Case.SObjectType, idSeed++);
        Case reopenedBefore = new Case(Id = reopenedId, Status = 'Closed', ProductCategory__c = 'Cat', ProductSubCategory__c = 'SubCat', EnquirySubType__c = 'SubType', Type = 'Type');
        Case reopenedAfter = new Case(Id = reopenedId, Status = 'New', ProductCategory__c = 'Cat', ProductSubCategory__c = 'SubCat', EnquirySubType__c = 'SubType', Type = 'Type');
        casesAfterTrigger.put(reopenedBefore.Id, reopenedBefore);
        casesBeforeTrigger.add(reopenedAfter);

        // Refers to a Case.Status=New and Case.RecordType as 'SSSW Delivery' => should route
        Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW Delivery').getRecordTypeId();
        String reopenedSsswId = makeFakeId(Case.SObjectType, idSeed++);
        Case reopenedSsswBefore = new Case(Id = reopenedSsswId, Status = 'Closed', RecordTypeId = deliveryRecType);
        Case reopenedSsswAfter = new Case(Id = reopenedSsswId, Status = 'New', RecordTypeId = deliveryRecType);
        casesAfterTrigger.put(reopenedSsswBefore.Id, reopenedSsswBefore);
        casesBeforeTrigger.add(reopenedSsswAfter);

        // Refers to a Case.Status=New and Case.RecordType as 'Social Record Type' => should route
        Id socialRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Social Record Type').getRecordTypeId();
        String reopenedSocialId = makeFakeId(Case.SObjectType, idSeed++);
        Case reopenedSocialBefore = new Case(Id = reopenedSocialId, Status = 'Closed', RecordTypeId = socialRecType);
        Case reopenedSocialAfter = new Case(Id = reopenedSocialId, Status = 'New', RecordTypeId = socialRecType);
        casesAfterTrigger.put(reopenedSocialBefore.Id, reopenedSocialBefore);
        casesBeforeTrigger.add(reopenedSocialAfter);

        // Refers to a Case.Status=New, RecordType as 'SSSW Delivery' and IsHLC__c=true => shouldn't route
        String reopenedSsswHlcId = makeFakeId(Case.SObjectType, idSeed++);
        Case reopenedSsswHlcBefore = new Case(Id = reopenedSsswHlcId, Status = 'Closed', RecordTypeId = deliveryRecType, IsHLC__c = true);
        Case reopenedSsswHlcAfter = new Case(Id = reopenedSsswHlcId, Status = 'New', RecordTypeId = deliveryRecType, IsHLC__c = true);
        casesAfterTrigger.put(reopenedSsswHlcBefore.Id, reopenedSsswHlcBefore);
        casesBeforeTrigger.add(reopenedSsswHlcAfter);

        // Refers to a Case.Status=New, RecordType as 'SSSW Delivery' and IsCR__c=true => shouldn't route
        String reopenedSsswCrId = makeFakeId(Case.SObjectType, idSeed++);
        Case reopenedSsswCrBefore = new Case(Id = reopenedSsswCrId, Status = 'Closed', RecordTypeId = deliveryRecType, IsCR__c = true);
        Case reopenedSsswCrAfter = new Case(Id = reopenedSsswCrId, Status = 'New', RecordTypeId = deliveryRecType, IsCR__c = true);
        casesAfterTrigger.put(reopenedSsswCrBefore.Id, reopenedSsswCrBefore);
        casesBeforeTrigger.add(reopenedSsswCrAfter);

        // Refers to a Case.Status=New, RecordType as 'SSSW Delivery', IsCR__c=true and IsHLC__c=true => shouldn't route
        String reopenedSsswHlcCrId = makeFakeId(Case.SObjectType, idSeed++);
        Case reopenedSsswHlcCrBefore = new Case(Id = reopenedSsswHlcCrId, Status = 'Closed', RecordTypeId = deliveryRecType, IsHLC__c = true, IsCR__c = true);
        Case reopenedSsswHlcCrAfter = new Case(Id = reopenedSsswHlcCrId, Status = 'New', RecordTypeId = deliveryRecType, IsHLC__c = true, IsCR__c = true);
        casesAfterTrigger.put(reopenedSsswHlcCrBefore.Id, reopenedSsswHlcCrBefore);
        casesBeforeTrigger.add(reopenedSsswHlcCrAfter);

        // Refers to a Case.Status=New, RecordType as 'SSSW Delivery', AllocateToQueue__c=true => should route, but the method doesn't change the routing status
        String reopenedSsswAllocateTrueId = makeFakeId(Case.SObjectType, idSeed++);
        Case reopenedSsswAllocateTrueBefore = new Case(Id = reopenedSsswAllocateTrueId, Status = 'Closed', AllocateToQueue__c = true, RecordTypeId = deliveryRecType);
        Case reopenedSsswAllocateTrueAfter = new Case(Id = reopenedSsswAllocateTrueId, Status = 'New', AllocateToQueue__c = true, RecordTypeId = deliveryRecType);
        casesAfterTrigger.put(reopenedSsswAllocateTrueBefore.Id, reopenedSsswAllocateTrueBefore);
        casesBeforeTrigger.add(reopenedSsswAllocateTrueAfter);

        CaseCommonUtility.markRenewedCasesToRoute(casesBeforeTrigger, casesAfterTrigger);

        System.assertEquals(false, unchanged.AllocateToQueue__c, 'a Case which hasnt gone through any changes => shouldnt route');
        System.assertEquals(false, reopenedNoTypesNoCategoriesAfter.AllocateToQueue__c, 'a Case.Status=New with categories and types set => should route');
        System.assertEquals(true, reopenedAfter.AllocateToQueue__c, 'a Case.Status=New and Case.RecordType as SSSW Delivery => should route');
        System.assertEquals(true, reopenedSsswAfter.AllocateToQueue__c, 'a Case.Status=New and Case.RecordType as Social Record Type => should route');
        System.assertEquals(true, reopenedSocialAfter.AllocateToQueue__c, 'a Case.Status=New, RecordType as SSSW Delivery and IsHLC__c=true => shouldnt route');
        System.assertEquals(false, reopenedSsswHlcAfter.AllocateToQueue__c, 'a Case.Status=New, RecordType as SSSW Delivery and IsCR__c=true => shouldnt route');
        System.assertEquals(false, reopenedSsswCrAfter.AllocateToQueue__c, 'a Case.Status=New, RecordType as SSSW Delivery, IsCR__c=true and IsHLC__c=true => shouldnt route');
        System.assertEquals(false, reopenedSsswHlcCrAfter.AllocateToQueue__c, 'a Case which hasnt gone through any changes => shouldnt route');
        System.assertEquals(true, reopenedSsswAllocateTrueAfter.AllocateToQueue__c, ' a Case.Status=New, RecordType as SSSW Delivery, AllocateToQueue__c=true => should route, but the method doesnt change the routing status');
    }
    
    /***************************************************************************************************
    *  Scenario:
    *      Populate the requestor's lookup field with current user if left empty on a case creation 
    * with 'Customer Analytics & Reporting Request (CAR)' record type
    ****************************************************************************************************/
    public static testmethod void populateRequestorWithCurrentUserWhenRequestorLeftEmpty(){
        Profile prof = [SELECT Id FROM Profile WHERE Name=: ADMIN_PROFILE];
        // Create a test user with System Admin profile
        User testuser = TestUtility.createUser('SethOrg',prof.id,null);
        // run as the test user
        System.runAs(testuser){
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            // set up a test organisation account from the setup
            Account testAcc  = TestDataProvider.createAccount('Test Adjustment Account', 1)[0];
            insert testAcc; 
            // query the 'CAR' case record type id
            Id CARcaseRecordTypeId = [select id from recordType where DeveloperName = 'CAR_Request'].id;
            
            Case testCase = new Case();
            // Create a new case and assign it as the 'CAR' record type
            testCase.RecordTypeId = CARcaseRecordTypeId;
            // Not Email2Case
            testCase.SuppliedEmail = null;
            // Set requestor to null
            testCase.requestor__c = null; 
            testCase.Work_Type__c = 'Parcel Post Dashboard Enquiry';
            // Assign case owner to current test user
            testCase.AccountId = testAcc.Id;
            testCase.Products_Services__c = 'Parcel Post;Star Track Express';
            testCase.Subject = 'Testing Requestor Population';
            testCase.Description = 'Test Description';

            // Set date time to 2 days ahead
            DateTime dt = System.now();
            dt.addDays(2);
            testCase.SLATargetDate__c = dt;
            
            test.startTest();
            insert testCase;
            test.stopTest();
            
            // get current user id
            Id userID = UserInfo.getUserId();
            // query the newly created case
            Case newCase = [Select id, requestor__c from Case WHERE Subject = 'Testing Requestor Population' LIMIT 1];
            // check that the requestor field is now populated with current user
            System.assertEquals(userID, newCase.Requestor__c, 'CaseCommonUtility_populateRequestorWithCurrentUserWhenRequestorLeftEmpty : Requestor field should be the current user');
            
        }
    }
}