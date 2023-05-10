/*------------------------------------------------------------
Author:        Daric Dava (daric.antoni.a.dava@accenture.com)
Description:   Test class for MembershipTriggerHandler class
Test Class:    N/A
History
3/7/2018     Daric Dava (daric.antoni.a.dava@accenture.com)         Test coverage for MembershipTriggerHandler class
06/05/20202     Disha Kariya    Updated with recordtypes and commented unused code
09/05/202       Disha Kariya    Added mock and stubbing
------------------------------------------------------------*/
@IsTest
public class MembershipTriggerHandler_Test {

	/***************************************************************
     * Initialize Lookups
     **************************************************************/
    
//    public static Boolean isForceExceptionError = false;

//    @TestSetup static void setup() {
//
////        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
//        RecordType recType = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{'Facility'}).values()[0];
////        Id facilityIdVar = [SELECT Id FROM RecordType WHERE Name = 'Facility'].Id;
//
//        Account organisation = new Account(Name='TestOrg',ABN__c = '12345678910');
//        insert organisation;
//
//        Network__c networkFacility = new Network__c(Name = 'TestNetworkFacility',Org_ID__c = '123456', Org_Unit_Type__c='LPO');
//        insert networkFacility;
//
//        Account facility =  new Account(RecordTypeId = recType.Id, Licence_Type__c='LPO', Name='TestFacility', Network_Facility__c = networkFacility.Id, Is_a_facility__c=true);
//        insert facility;
//
//        Account license = new Account(Name='TestLicense',ParentId=organisation.Id,Licence_Type__c='LPO',Facility__c=facility.Id);
//        insert license;
//
//        Contact member = new Contact(FirstName='Test',LastName='Member', Email='sample@test.com', AccountId=organisation.Id);
//        insert member;
//
//        insert ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', license.Id, member.Id,  false)[0];
//
//    }


//    @IsTest static void insertNewMembershipWithStatusPending() {
////        Membership_Constants.METHOD_EXPIRESIBLING='expireSiblingAndActivateMembership';
////        Membership_Constants.CALLOUTEXCEPTION='MembershipTriggerHandler Exception';
////        Membership_Constants.CLASS_MEMBERSHIPTRIGGERHANDLER='MembershipTriggerHandler';
////        Membership_Constants.METHODEXCEPTION='METHODEXCEPTION';
////        Membership_Constants.ERROR='ERROR';
//        Integer numOfMembership = 205;
//        Account license = [SELECT Id,Name,ParentId FROM Account WHERE Name='TestLicense' LIMIT 1];
//        Contact member = [SELECT Id,Name,AccountId FROM Contact WHERE FirstName='Test' AND LastName='Member' LIMIT 1];
//
//        Test.startTest();
//        insert ApplicationTestDataFactory.getMembership(numOfMembership, 'Pending', 'New Membership', license.Id, member.Id,  false);
//        Test.stopTest();
//
//        List<Membership__c> membershipList = new List<Membership__c>([SELECT Id FROM Membership__c]);
//
//        System.assertEquals(numOfMembership+1,membershipList.size(), 'Incorrect number of membership created');
//    }

    @IsTest static void insertMembershipWithStatusActiveIntegration() {
        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();
        Account orgAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert orgAccount;
        Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1,false)[0];
        insert networkFacility;
        Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1,networkFacility.Id,false)[0];
        insert facilityAccount;
        Account licenceAccount = ApplicationTestDataFactory.getLPOAccounts(1,orgAccount.Id, facilityAccount.Id,false)[0];
        insert licenceAccount;
        Contact personContact = ApplicationTestDataFactory.getContacts(1, orgAccount.Id, false)[0];
        insert personContact;

        //

        Test.startTest();
        SystemSettings__c settings = SystemSettings__c.getInstance();
        settings.Disable_Triggers__c = false;
        upsert settings;
        insert ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', licenceAccount.Id, personContact.Id,  false);

        Test.stopTest();

        List<Membership__c> membershipList = new List<Membership__c>([SELECT Id, Account__r.APLAC_Member__c FROM Membership__c WHERE Account__c = :licenceAccount.Id AND Status__c = 'Active']);

        System.assertEquals(1,membershipList.size(), 'Incorrect number of membership active');
        System.assertEquals(true, membershipList[0].Account__r.APLAC_Member__c, 'Account APLAC Member not set');
    }

    @IsTest static void insertNewMembershipWithExistingStatusActive() {
        // =====================================
        // Data Preparation
        // =====================================
        Account orgAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1,true)[0];

        Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1,networkFacility.Id,true)[0];

        Account licenceAccount = ApplicationTestDataFactory.getLPOAccounts(1,orgAccount.Id, facilityAccount.Id,true)[0];

        Contact personContact = ApplicationTestDataFactory.getContacts(1, orgAccount.Id, true)[0];

        Membership__c member = ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', licenceAccount.Id, personContact.Id,  true)[0];

        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector mockAccoutsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HistoryTrackingSelector mockHTSelector = (HistoryTrackingSelector)MockUtility.mockSelector(HistoryTrackingSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        SObject accWithRelationships = ((List<SObject>)fflib_ApexMocksUtils.makeRelationship('Account', 'Membership__c', new List<Account>{licenceAccount}, 'account__c', new List<List<SObject>> { new List<SObject> {  }}))[0];
        Map<Id, Account> mockAccountMap = new Map<Id, Account>{accWithRelationships.Id => (Account)accWithRelationships};
        MockUtility.Mocks.when(mockAccoutsSelector.selectById(new Set<Id>{member.Account__c}, new Set<Object>{AccountsSelector.Options.WITH_ACTIVE_MEMBERSHIPS})).thenReturn(mockAccountMap);
		MockUtility.Mocks.when(mockHTSelector.selectByObjectApiNames((List<String>)fflib_Match.listContains(String.valueOf(Membership__c.SObjectType)))).thenReturn(new Map<Id,HistoryTracking__mdt>());
		MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================

        String errMessage = '';

        Test.startTest();
        List<Membership__c> memberRecList = new List<Membership__c>();

        memberRecList.addAll(ApplicationTestDataFactory.getMembership(1, 'Active', 'Update Membership', licenceAccount.Id, personContact.Id,  false));
        try{
			insert memberRecList;
        }
        catch(System.Exception e){
			errMessage = e.getMessage();
        }
        Test.stopTest();

        System.assertNotEquals('', errMessage, 'Validation did not run');
    }

//    @IsTest static void insertUpdateMembershipWithoutExistingMembership() {
//        Account license = [SELECT Id,Name,ParentId FROM Account WHERE Name='TestLicense' LIMIT 1];
//        Contact member = [SELECT Id,Name,AccountId FROM Contact WHERE FirstName='Test' AND LastName='Member' LIMIT 1];
//
//        String errMessage = 'Error: Licensee doesn’t have an existing membership. Select Licensee Type of New Membership.';
//
//        Test.startTest();
//        delete [SELECT Id FROM Membership__c WHERE Account__c = :license.Id];
//        List<Membership__c> memberRecList = new List<Membership__c>();
//
//        memberRecList.addAll(ApplicationTestDataFactory.getMembership(1, 'Active', 'Update Membership', license.Id, member.Id,  false));
//        try{
//            insert memberRecList;
//        }
//        catch(System.DmlException e){
//            errMessage = e.getMessage();
//        }
//        Test.stopTest();
//
//        //System.assert(errMessage.contains('Licensee doesn’t have an existing membership. Select Licensee Type of New Membership.'));
//        System.assertNotEquals('', errMessage, 'No error when creating New Membership on already active member');
//    }

    @IsTest static void updateMembershipWithStatusPendingIntegration() {
//        Integer numOfMembership = 205;
        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();
        Account orgAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
        insert orgAccount;
        Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1,false)[0];
        insert networkFacility;
        Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1,networkFacility.Id,false)[0];
        insert facilityAccount;
        Account licenceAccount = ApplicationTestDataFactory.getLPOAccounts(1,orgAccount.Id, facilityAccount.Id,false)[0];
        insert licenceAccount;
        Contact personContact = ApplicationTestDataFactory.getContacts(1, orgAccount.Id, false)[0];
        insert personContact;
        List<Membership__c> membershipList = new List<Membership__c>();
        Membership__c member1 = ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', licenceAccount.Id, personContact.Id,  false)[0];
        membershipList.add(member1);
        Membership__c member2 = ApplicationTestDataFactory.getMembership(1, 'Pending', 'New Membership', licenceAccount.Id, personContact.Id,  false)[0];
        membershipList.add(member2);
        insert membershipList;
        System.debug('member--->'+membershipList);
        Account acc = [SELECT Id, (SELECT Id, Licensee_Type__c FROM Memberships__r) FROM Account where Id=:licenceAccount.Id];
        System.debug('acc.Memberships__r--->'+acc.Memberships__r);

        // =====================================
        // Stubbing
        // =====================================
        // Not needed. Need actual data


//        Membership__c membership =  ApplicationTestDataFactory.getMembership(1, 'Pending', 'Update Membership', licenceAccount.Id, personContact.Id,  false)[0];
//
//        insert membership;

        Test.startTest();
        //Unable trigger execution
        SystemSettings__c settings = SystemSettings__c.getInstance();
        settings.Disable_Triggers__c = false;
        upsert settings;
        member2.Licensee_Type__c = 'Update Membership';
        member2.Status__c = 'Active';
        update member2;
        Test.stopTest();

        Membership__c membership = [SELECT Id, Status__c FROM Membership__c WHERE Id = :member1.Id];
        System.assertEquals('Expired', membership.Status__c, 'Previous Membership Status is not Expired');
        System.assertEquals('Active', member2.Status__c, 'New Membership Status is not Active');
    }

    @IsTest
    private static void testUnitValidateNewMembershipRecords() {
        // =====================================
        // Data Preparation
        // =====================================
        Account orgAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];

        Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1,true)[0];

        Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1,networkFacility.Id,true)[0];

        Account licenceAccount = ApplicationTestDataFactory.getLPOAccounts(1,orgAccount.Id, facilityAccount.Id,true)[0];

        Contact personContact = ApplicationTestDataFactory.getContacts(1, orgAccount.Id, true)[0];

        Membership__c member = ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', licenceAccount.Id, personContact.Id,  true)[0];
        System.debug('member--->'+member);

        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector mockAccoutsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		HistoryTrackingSelector mockHTSelector = (HistoryTrackingSelector)MockUtility.mockSelector(HistoryTrackingSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        SObject accWithRelationships = ((List<SObject>)fflib_ApexMocksUtils.makeRelationship('Account', 'Membership__c', new List<Account>{licenceAccount}, 'account__c', new List<List<SObject>> { new List<SObject> { member }}))[0];
        Map<Id, Account> mockAccountMap = new Map<Id, Account>{accWithRelationships.Id => (Account)accWithRelationships};
        MockUtility.Mocks.when(mockAccoutsSelector.selectById(new Set<Id>{member.Account__c}, new Set<Object>{AccountsSelector.Options.WITH_ACTIVE_MEMBERSHIPS})).thenReturn(mockAccountMap);
		MockUtility.Mocks.when(mockHTSelector.selectByObjectApiNames((List<String>)fflib_Match.listContains(String.valueOf(Membership__c.SObjectType)))).thenReturn(new Map<Id,HistoryTracking__mdt>());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        String errMessage = '';
        Test.startTest();
        List<Membership__c> memberRecList = new List<Membership__c>();

        memberRecList.addAll(ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', licenceAccount.Id, personContact.Id,  false));
        try{
			insert memberRecList;
        }
        catch(System.DmlException e){
			errMessage = e.getMessage();
        }
        Test.stopTest();
        System.assertNotEquals('', errMessage, 'Validation did not run');

    }

    //There is no code coverage for exception
//    @IsTest static void forceException(){
//        Account license = [SELECT Id,Name,ParentId FROM Account WHERE Name='TestLicense' LIMIT 1];
//        Contact member = [SELECT Id,Name,AccountId FROM Contact WHERE FirstName='Test' AND LastName='Member' LIMIT 1];
//
//        Test.startTest();
//        MembershipTriggerHandler_Test.isForceExceptionError = true;
//        insert Membership_TestDataFactory.createMembership('Pending','New Membership',license,member,1);
//        MembershipTriggerHandler_Test.isForceExceptionError = false;
//        Test.stopTest();
//    }

    //Commented below code as it was not used
//    public static Boolean isForceException(){
//        return Test.isRunningTest() && MembershipTriggerHandler_Test.isForceExceptionError;
//    }

	@IsTest static void austracSection75() {
        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();
        Account orgAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];

        Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1,true)[0];

        Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1,networkFacility.Id,true)[0];

        Account licenceAccount = ApplicationTestDataFactory.getLPOAccounts(1,orgAccount.Id, facilityAccount.Id,true)[0];

        Contact personContact = ApplicationTestDataFactory.getContacts(1, orgAccount.Id, true)[0];

        Membership__c member = ApplicationTestDataFactory.getMembership(1, 'Active', 'New Membership', licenceAccount.Id, personContact.Id,  true)[0];

        // =====================================
        // Stubbing
        // =====================================
		HistoryTrackingSelector mockHTSelector = (HistoryTrackingSelector)MockUtility.mockSelector(HistoryTrackingSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
		HistoryTracking__mdt newRegistration = (HistoryTracking__mdt)JSON.deserialize(
			String.join(new String[] {
				'{',
				'	"attributes": {',
				'		"type": "HistoryTracking__mdt"',
				'	},',
				'	"Id": "m1T0k000000CaX5EAK",',
				'	"MatchingValue__c": "New Registration",',
				'	"TargetValue__c": "{TODAY}",',
				'   "OverwriteExistingValue__c": true,',
				'	"ObjectName__r": {',
				'		"attributes": {',
				'			"type": "EntityDefinition"',
				'		},',
				'		"QualifiedApiName": "Membership__c"',
				'	},',
				'	"TrackedFieldName__r": {',
				'		"attributes": {',
				'			"type": "FieldDefinition"',
				'		},',
				'		"QualifiedApiName": "Type_of_Registration__c"',
				'	},',
				'	"TargetField__r": {',
				'		"attributes": {',
				'			"type": "FieldDefinition"',
				'		},',
				'		"QualifiedApiName": "S75_Status_New_Date__c"',
				'	}',
				'}'
			}, '\r\n'),
			HistoryTracking__mdt.class
		);
		HistoryTracking__mdt statusNew = (HistoryTracking__mdt)JSON.deserialize(
			String.join(new String[] {
				'{',
				'	"attributes": {',
				'		"type": "HistoryTracking__mdt"',
				'	},',
				'	"Id": "m1T0k000000CaXAEA0",',
				'	"MatchingValue__c": "New",',
				'	"TargetValue__c": "{TODAY}",',
				'   "OverwriteExistingValue__c": true,',
				'	"ObjectName__r": {',
				'		"attributes": {',
				'			"type": "EntityDefinition"',
				'		},',
				'		"QualifiedApiName": "Membership__c"',
				'	},',
				'	"TrackedFieldName__r": {',
				'		"attributes": {',
				'			"type": "FieldDefinition"',
				'		},',
				'		"QualifiedApiName": "S75_Status__c"',
				'	},',
				'	"TargetField__r": {',
				'		"attributes": {',
				'			"type": "FieldDefinition"',
				'		},',
				'		"QualifiedApiName": "S75_Status_New_Date__c"',
				'	}',
				'}'
			}, '\r\n'),
			HistoryTracking__mdt.class
		);
		HistoryTracking__mdt statusIssued = (HistoryTracking__mdt)JSON.deserialize(
			String.join(new String[] {
				'{',
				'	"attributes": {',
				'		"type": "HistoryTracking__mdt"',
				'	},',
				'	"Id": "m1T0k000000CaWvEAK",',
				'	"MatchingValue__c": "Issued",',
				'	"TargetValue__c": "{TODAY}",',
				'   "OverwriteExistingValue__c": true,',
				'	"ObjectName__r": {',
				'		"attributes": {',
				'			"type": "EntityDefinition"',
				'		},',
				'		"QualifiedApiName": "Membership__c"',
				'	},',
				'	"TrackedFieldName__r": {',
				'		"attributes": {',
				'			"type": "FieldDefinition"',
				'		},',
				'		"QualifiedApiName": "S75_Status__c"',
				'	},',
				'	"TargetField__r": {',
				'		"attributes": {',
				'			"type": "FieldDefinition"',
				'		},',
				'		"QualifiedApiName": "S75_Issued_Date__c"',
				'	}',
				'}'
			}, '\r\n'),
			HistoryTracking__mdt.class
		);

        Map<Id,HistoryTracking__mdt> mockedHistoryTrackingConfig = new Map<Id,HistoryTracking__mdt>(
			new List<HistoryTracking__mdt>{
				newRegistration,
				statusNew,
				statusIssued
			}
		);

        MockUtility.Mocks.when(mockHTSelector.selectByObjectApiNames((List<String>)fflib_Match.listContains(String.valueOf(Membership__c.SObjectType)))).thenReturn(mockedHistoryTrackingConfig);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================

		// test #1 insert: 
		//  - S75_Status__c: blank => New
		//  - Type_of_Registration__c: blank => New Registration
		member.S75_Status__c = 'New';
		member.Type_of_Registration__c = 'New Registration';
        MembershipTriggerHandler.austracHistoryTracking(
			new List<Membership__c>{ member }, 
			null
		);

		System.assertEquals(System.today(), member.S75_Status_New_Date__c, 'Should\'ve todays date populated');
		System.assertEquals(null, member.S75_Issued_Date__c, 'Shouldn\'t have been populated');

		// clone record
		member.S75_Status_New_Date__c = null;
		Membership__c member1 = (Membership__c)JSON.deserialize(JSON.serialize(member), Membership__c.class);
		member1.S75_Status__c = 'Issued';
		
		// test #2 update: S75_Status__c: New => Issued
		MembershipTriggerHandler.austracHistoryTracking(
			new List<Membership__c>{ member1 }, 
			new Map<Id,Membership__c>{ member.Id => member }			
		);

		System.assertEquals(null, member1.S75_Status_New_Date__c, 'Shouldn\'t have been populated');
		System.assertEquals(System.today(), member1.S75_Issued_Date__c, 'Should\'ve todays date populated');

		member.S75_Status__c = 'New';
		member.S75_Status_New_Date__c = System.today().addDays(-2);
		member.S75_Issued_Date__c = System.today().addDays(-2);

		// test #3 update: S75_Status__c: Issued => New
		MembershipTriggerHandler.austracHistoryTracking(
			new List<Membership__c>{ member }, 
			new Map<Id,Membership__c>{ member1.Id => member1 }			
		);

		System.assertEquals(System.today(), member.S75_Status_New_Date__c, 'Should\'ve been overwritten with todays date');
		System.assertEquals(System.today().addDays(-2), member.S75_Issued_Date__c, 'Shouldn\'t have been updated');
	}
}