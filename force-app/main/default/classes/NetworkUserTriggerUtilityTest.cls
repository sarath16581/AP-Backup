/*******************************  History ************************************************
    Date                User                                        Comments
    29/03//2017          dion.gunn@auspost.com.au                   Test Class for network user creation.
                                                                    Covers NetworkUserTriggerUtility.cls
*********************************** HISTORY ***************************************************
* 07.06.18     kalpita.talwadekar@auspost.com.au            updated code for coding standard follow - TDO-241
* 15.03.2019   Swati.mogadala@auspost.com.au                inserted custom setting INC1300632
*
                                                                    
*******************************  History ************************************************/
@isTest
public class NetworkUserTriggerUtilityTest {

    @testSetup static void testDataCreation() {
        Profile p = [Select Id from Profile where Name ='MyNetwork Portal' limit 1];
        //insert an existing user 
        User u = TestDataProvider.createTestUsers();
        u.FirstName ='Test ManagerFirstName1';
        u.LastName = 'Test ManagerLastName1';
        u.Alias = 'nnmm';
        u.Email = 'Test1@example.com';
        u.Username = 'nnde@do.com';
        u.CommunityNickname = 'YOXI';
        u.ProfileId = p.id;       
        insert u;
        //INC1300632 adding custom setting record
        User__c newuser = new User__c( Org__c ='@MyNetwork.Ptest');
        insert newuser;
        
        //insert test network
        Network__c network = TestDataProvider.createTestNetwork();
        network.Portal_Licenses__c = 30;
        insert network;
        
        //insert test network
        Network__c network2 = TestDataProvider.createTestNetwork();
        network2.Portal_Licenses__c = 30;
        insert network2;
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
         Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                                                            accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);

        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        Database.insert(con);
        
        Case csRec = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.id,con.id,
                                    caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRec.Network__c = network.Id;
        insert csRec;
        
    }
        
 
    /**********************************************************************
     *  Scenario:
     *      Checking for network user creation FROMportal
     ********************************************************************/
    @isTest
    static void testCreateNetworkUsers() {
        
        Network__c network = [Select Id from Network__c limit 1];
        
        //setup a network user on above network
        Facility_User__c nUserManager = new Facility_User__c();
        nUserManager.First_Name__c = 'Test ManagerFirstName';
        nUserManager.Last_Name__c = 'Test ManagerLastName';
        nUserManager.Timezone__c = 'New South Wales';
        nUserManager.User_Role__c = 'MyNetwork Super User';
        nUserManager.Email_Address__c = 'Test@example.com';
        nUserManager.Network__c = network.Id;
        nUserManager.is_myNetwork_User__c = true;
        Test.StartTest();
            //insert above network user
            insert nUserManager;
        Test.StopTest();

        Profile prof = [ SELECT id FROM Profile WHERE name = 'MyNetwork Portal' LIMIT 1];

        //query to see if user record inserted
        User userNetworkManager = [ SELECT Id, TimeZoneSidKey, ProfileId FROM User WHERE FirstName = 'Test ManagerFirstName' LIMIT 1];

        //User is created with the right timezone and profile.
        System.assertEquals(userNetworkManager.TimeZoneSidKey,'Australia/Sydney',
                                'NetworkUserTriggerUtilityTest_testCreateNetworkUsers: user is inserted with correct timezone as per field values set');

        System.assertEquals(userNetworkManager.ProfileId,prof.Id,
                                'NetworkUserTriggerUtilityTest_testCreateNetworkUsers: user is inserted with correct profile as per user role selected');

        //query permission sets for checking if user has them assigned to himself.
        PermissionSet superUserPS = [ SELECT Id FROM PermissionSet WHERE Name = 'MyNetwork_Employee_Apps_Super_User' LIMIT 1];
                                    
        PermissionSetLicense superUserPSL = [ SELECT id FROM PermissionSetLicense WHERE DeveloperName = 'CompanyCommunityPsl' LIMIT 1];

        //query permission set assignments
        List<PermissionSetAssignment> psaList = [ SELECT id FROM PermissionSetAssignment WHERE AssigneeId =: userNetworkManager.Id AND PermissionSetId =: superUserPS.Id];

        //query permission set license assignments
        List<PermissionSetLicenseAssign> pslaList = [ SELECT id FROM PermissionSetLicenseAssign WHERE AssigneeId =: userNetworkManager.Id AND PermissionSetLicenseId =: superUserPSL.Id];

        //asset to see if user has been assigned the appropriate permission sets.
        System.assertEquals(true, !psaList.isEmpty(), 
                             'NetworkUserTriggerUtilityTest_testCreateNetworkUsers: user has permission set assigned');

        System.assertEquals(true, !pslaList.isEmpty(),
                             'NetworkUserTriggerUtilityTest_testCreateNetworkUsers: user has permission set license assigned');

    }
    
    /**********************************************************************
     *  Scenario:
     *      Checking for valid user details on network user creation with first name, last name and email address, user role
     ********************************************************************/
    @isTest
    static void test_ValidUserDetails() {
        Network__c network = [Select Id from Network__c limit 1];

        //setup a network user on above network
        Facility_User__c nUserManager = new Facility_User__c();
        nUserManager.First_Name__c = 'Test ManagerFirstName1';
        nUserManager.Last_Name__c = 'Test ManagerLastName1';
        nUserManager.Timezone__c = 'New South Wales';
        nUserManager.Email_Address__c = 'Test1@example.com';
        nUserManager.Network__c = network.Id;
        
        Test.StartTest();
            try {
                //insert above network user
                insert nUserManager;
            } catch(Exception exp) {    
                System.assertEquals('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Please ensure all fields are completed when creating a new user: []', exp.getMessage(),
                                 'NetworkUserTriggerUtilityTest_test_ValidUserDetails: duplicate user found');
            }
            
        Test.StopTest();
    }
    
    /**********************************************************************
     *  Scenario:
     *      Checking for network user creation for a Network with less portal licenses
     ********************************************************************/
    @isTest
    static void test_NoPortalLicense() {
        Network__c network = [Select Id from Network__c limit 1];
        network.Portal_Licenses__c = 0;
        update network;
        
        //setup a network user on above network
        Facility_User__c nUserManager = new Facility_User__c();
        nUserManager.First_Name__c = 'Test ManagerFirstName1';
        nUserManager.Last_Name__c = 'Test ManagerLastName1';
        nUserManager.Timezone__c = 'New South Wales';
        nUserManager.User_Role__c = 'MyNetwork Super User';
        nUserManager.Email_Address__c = 'Test1@example.com';
        nUserManager.Network__c = network.Id;
        nUserManager.Is_MyNetwork_User__c = true; 
        
        Test.StartTest();
            try {
                //insert above network user
                insert nUserManager;
            } catch(Exception exp) {    
               System.assertEquals('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, This network has no available licenses. Please speak with support.: []', exp.getMessage(),
                                 'NetworkUserTriggerUtilityTest_test_NoPortalLicense: network has no portal license to assign');
            }
            
        Test.StopTest();
    }
    
    /**********************************************************************
     *  Scenario:
     *      Checking for network user updates and deletion
     ********************************************************************/
    @isTest
    static void testShareNetworkUsers() {
        
        List<Network__c> network = [Select Id from Network__c limit 2];
        Profile p = [Select Id from Profile where Name ='MyNetwork Portal' limit 1];
        //setup a network user on above network
        Facility_User__c nUserManager = new Facility_User__c();
        nUserManager.First_Name__c = 'Test ManagerFirstName';
        nUserManager.Last_Name__c = 'Test ManagerLastName';
        nUserManager.Timezone__c = 'New South Wales';
        nUserManager.User_Role__c = 'MyNetwork Super User';
        nUserManager.Email_Address__c = 'Test@example.com';
        nUserManager.Network__c = network[0].Id;
        nUserManager.is_myNetwork_User__c = true;
        
        Test.StartTest();
            //insert above network user
            insert nUserManager;
            nUserManager.User__c = [Select Id from User where profileId = :p.Id limit 1].Id;
            update nUserManager;
            nUserManager.Network__c = network[1].Id;
            update nUserManager;
            delete nUserManager;
        Test.StopTest();
        
    }

}