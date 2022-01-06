/***************************************************************************************
    Description: This test class is for CaseTrackingUtility
    History:
    --------------------------------------------------
    2014-06-24  Frank Chen
    2018-06-05  TDO-15 : Hasantha.Liyanage@auspost.com.au Unit tests re-written with scenario based tests.
    2018-10-11  disha.kariya@auspost.com.au Commented Test Method which are no more used
    2021-05-14  naseer.abbasi@auspost.com.au  Test updated w.r.t removal of User Support RT
****************************************************************************************/

@isTest
public class CaseTrackingUtility_Test {

    @testSetup
    static void setupTestData() {
        //create a test account to support user creation
        Account account = TestDataProvider.createAccount('Test Account', 1)[0];
        insert account;

        // create an account to support user creation
        Contact contact = new Contact(
                FirstName = 'hans',
                LastName = 'li',
                MobilePhone = '0400000000',
                Email = 'hans@gmail.com',
                AccountId = account.Id,
                Contact_Type__c = StarTrack_Constants.CONTACT_TYPE,
                Status__c = StarTrack_Constants.CON_STAT_ACTIVE
        );
        insert contact;

        // pull a profile for the user
        Profile profile = [
                SELECT Id
                FROM Profile
                WHERE Name = 'BSP Community User'
        ];

        // create a user for run as tests
        User user = new User(
                Email = 'user@testorg.a',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                ContactId = contact.Id,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profile.Id,
                Alias = 'lol',
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'theuser1' + System.currentTimeMillis() + '@testorg.com'
        );

        insert user;

        /* create a network to be assigned to cases */
        list<Network__c> networks = new list<Network__c>();
        for (Integer i = 0; i < 2; i++) {
            networks.add(
                    new Network__c(
                            Name = 'network_' + i,
                            Email__c = 'adf@daf.com',
                            Portal_Licenses__c = 99
                    )
            );
        }

        insert networks;

        set<Id> rtids = CaseTrackingUtility.getCaseSSSWRecordTypeId();
        Id rtid;
        for (Id theId : rtids) {
            rtid = theId;
        }

        // create cases for old test records
        list<Case> cases = new list<Case>();
        for (Integer i = 0; i < 10; i++) {
            Case cse = new Case();
            cse.RecordTypeId = rtid;
            cse.ReferenceID__c = '1234' + i;
            cse.Subject = 'Newsdd';
            cse.Status = 'Network Responded';
            cse.ProductCategory__c = 'Travel & ID';
            cse.Type = 'General Enquiry';
            cse.ProductSubCategory__c = 'KeyPass';
            cse.EnquirySubType__c = 'Article carded - no card left';
            cse.DateofIncident__c = date.today();
            cse.Network__c = networks[0].Id;
            cse.OwnerId = UserInfo.getUserId();
            cases.add(cse);
        }

        insert cases;

    }

    /**
     * SCENARIO: case tracking records created successfully
     **/
    @isTest
    static void CaseTrackingUtility_Test_updateCaseStatusTracking_created() {
        Test.startTest();
        // new records
        map<Id, Case> newCases = getCases();

        // old records
        map<Id, Case> oldCases = getCases();

        // query another network to assign
        list<Network__c> newtworks = [SELECT Id FROM Network__c WHERE name = 'network_1' LIMIT 1];

        // let's change the owner of the case to this user
        User user = [SELECT id FROM User WHERE email = 'user@testorg.a'];

        // change the field values to trigger the tracking logic
        for (Case cse : newCases.values()) {
            cse.status = 'Awaiting Network Response'; // change status
            cse.Network__c = newtworks.get(0).Id; // change network
            cse.NetworkComments__c = 'new comment'; // deferent comment
            cse.Network_Response__c = 'Delivered as addressed to letterbox';
            cse.OwnerId = user.Id; // owner changed
        }

        // testing the updateCaseStatusTracking for case after update
        CaseTrackingUtility.updateCaseStatusTracking(oldCases, newCases);

        Test.stopTest();

        list<StatusTracking__c> statusTrackings = [SELECT Id, FieldsChanged__c FROM StatusTracking__c];

        // status tracking records shoud be created
        System.assertNotEquals(0, statusTrackings.size(),
                'CaseTrackingUtility_Test_updateCaseStatusTracking_created : status tracking records should be created');

        // verify the out put
        String fieldsChangedCheck = statusTrackings.get(0).FieldsChanged__c;
        Boolean changeDetected = fieldsChangedCheck.contains('Status');


        // status tracking fields verification
        System.assertEquals(true, changeDetected,
                'CaseTrackingUtility_Test_updateCaseStatusTracking_created : Status tracking for the selected fields failed');


    }

    /**
      * SCENARIO: case tracking records are not created created as there are no changes to tracked fields
     **/
    @isTest
    static void CaseTrackingUtility_Test_updateCaseStatusTracking_nochanges() {
        Test.startTest();
        // new records
        map<Id, Case> newCases = getCases();

        // old records
        map<Id, Case> oldCases = getCases();

        // let's not update anything but call the update case tracking method
        CaseTrackingUtility.updateCaseStatusTracking(oldCases, oldCases);

        Test.stopTest();

        // verify logic
        list<StatusTracking__c> statusTrackings = [SELECT Id, FieldsChanged__c FROM StatusTracking__c WHERE Case__c =: oldCases.keySet() ];

        // status tracking records shoud NOT be created
        // 10 are the initial insertion
        System.assertEquals(10, statusTrackings.size(),
                'CaseTrackingUtility_Test_updateCaseStatusTracking_nochanges : NO status tracking records should be created');

    }

    /**
     * SCENARIO: case tracking records updated successfully TODO
     **/
    @isTest
    static void CaseTrackingUtility_Test_updateCaseStatusTracking_updated() {
        Test.startTest();
        // new records
        map<Id, Case> newCases = getCases();

        // old records
        map<Id, Case> oldCases = getCases();

        // query another network to assign
        list<Network__c> newtworks = [SELECT Id FROM Network__c WHERE name = 'network_1' LIMIT 1];

        // let's change the owner of the case to this user
        User user = [SELECT id FROM User WHERE email = 'user@testorg.a'];

        // Verify the Logic
        // change the field values to trigger the tracking logic, assigning the case to a network
        for (Case cse : newCases.values()) {
            cse.status = 'Awaiting Network Response'; // change status
            cse.Network__c = newtworks.get(0).Id; // change network
            cse.Network_Response__c = 'Delivered as addressed to letterbox';
            cse.OwnerId = user.Id; // owner changed
        }

        // testing the updateCaseStatusTracking for case after update
        CaseTrackingUtility.updateCaseStatusTracking(oldCases, newCases);

        map<Id, Case> modifiedCases = getCases();

        for (Case cse : modifiedCases.values()) {
            cse.NetworkComments__c = 'new comment plus plus'; // comment added
        }

        // testing the updateCaseStatusTracking for case after update
        CaseTrackingUtility.updateCaseStatusTracking(newCases, modifiedCases);

        // verify results
        list<StatusTracking__c> statusTrackings = [SELECT Id, FieldsChanged__c, CreatedDate, Case__c FROM StatusTracking__c WHERE Case__c =: modifiedCases.keySet() Order by CreatedDate];

        system.assertEquals(true, statusTrackings[10].FieldsChanged__c.contains('Network Comments'),
                'CaseTrackingUtility_Test_updateCaseStatusTracking_updated : Changed, field type should be tracked');

        Test.stopTest();
    }

    /**
     * SCENARIO: case fax tracking records created successfully, this is a utility method and do not insert records
     **/
    @isTest
    static void CaseTrackingUtility_Test_newFaxTracking_created() {

        Test.startTest();

        // new records
        map<Id, Case> newCases = getCases();

        // query another network to assign
        list<Network__c> newtworks = [SELECT Id FROM Network__c WHERE name = 'network_1' LIMIT 1];

        // let's change the owner of the case to this user
        User user = [SELECT id FROM User WHERE email = 'user@testorg.a'];

        // change the field values to trigger the tracking logic
        for (Case cse : newCases.values()) {
            cse.status = 'Awaiting Network Response'; // change status
            cse.Network__c = newtworks.get(0).Id; // change network
            cse.NetworkComments__c = 'new comment'; // deferent comment
            cse.Network_Response__c = 'Delivered as addressed to letterbox';
            cse.OwnerId = user.Id; // owner changed
        }

        // create a fax record : case has to be inserted here, if you create this on the test setup,
        // fax trigger will create a tracking record will distrupt other unit tests
        Fax__c fax = new Fax__c();
        insert fax;

        // to verify test
        List<StatusTracking__c> statusTrackings = new List<StatusTracking__c>();

        // call the newFaxTracking method
        for (Case cse : newCases.values()) {
            statusTrackings.add(CaseTrackingUtility.newFaxTracking(cse, 'status', datetime.now(), fax.Id, 'CN', 'test'));
        }

        Test.stopTest();
        // verify outputs
        for (StatusTracking__c tracking : statusTrackings) {
            System.assertEquals(fax.Id, tracking.Fax__c,
                    'CaseTrackingUtility_Test_newFaxTracking_created : Fax tracking records should be created');
        }
    }

    /**
     * SCENARIO: case tracking records created successfully when creating a new case record
     *
     **/
    // @isTest
    // static void CaseTrackingUtility_insertCaseStatusTracking_success() {

    //     Test.startTest();

    //     // create a network to be assigned to cases
    //     list<Network__c> networks = new list<Network__c>();
    //     for (Integer i = 0; i < 2; i++) {
    //         networks.add(
    //                 new Network__c(
    //                         Name = 'network_' + i,
    //                         Email__c = 'adf@daf.com',
    //                         Portal_Licenses__c = 99
    //                 )
    //         );
    //     }

    //     insert networks;

    //     set<Id> rtids = CaseTrackingUtility.getCaseSSSWRecordTypeId();
    //     Id rtid;
    //     for (Id theId : rtids) {
    //         rtid = theId;
    //     }

    //     // create cases for old test records
    //     list<Case> cases = new list<Case>();
    //     for (Integer i = 0; i < 20; i++) {
    //         Case cse = new Case();
    //         cse.RecordTypeId = rtid;
    //         cse.ReferenceID__c = '1234' + i;
    //         cse.Subject = 'Newsdd';
    //         cse.Status = 'Network Responded';
    //         cse.ProductCategory__c = 'Travel & ID';
    //         cse.ProductSubCategory__c = 'KeyPass';
    //         cse.EnquirySubType__c = 'Article carded - no card left';
    //         cse.DateofIncident__c = date.today();
    //         cse.Network__c = networks[0].Id;
    //         cse.OwnerId = UserInfo.getUserId();
    //         cases.add(cse);
    //     }

    //     insert cases;
    //     // new records
    //     map<Id, Case> newCases = new map<Id, Case>();
    //     newCases.putAll(cases);

    //     // create a new tracking record when the case is created
    //     CaseTrackingUtility.insertCaseStatusTracking(newCases);

    //     Test.stopTest();

    //     // verify tests
    //     List<StatusTracking__c> statusTrackings = [SELECT Id, FieldsChanged__c, Case__c FROM StatusTracking__c];

    //     System.assertNotEquals(0, statusTrackings.Size(),
    //             'CaseTrackingUtility_insertCaseStatusTracking_success : Fax tracking records should be created');

    // }

    /**
     * SCENARIO: case tracking records created successfully
     * TDO_NOTE: seems this method is not reference anywhere in the system, consider delete
     **/
    // @isTest
    // static void CaseTrackingUtility_Test_setStatusTracking_success() {
    //     Test.startTest();
    //     // new records
    //     map<Id, Case> newCases = getCases();

    //     // old records
    //     map<Id, Case> oldCases = getCases();

    //     // query another network to assign
    //     list<Network__c> newtworks = [SELECT Id FROM Network__c WHERE name = 'network_1' LIMIT 1];

    //     // let's change the owner of the case to this user
    //     User user = [SELECT id FROM User WHERE email = 'user@testorg.a'];

    //     DateTime lastChangedDateTime = System.now();
    //     lastChangedDateTime = lastChangedDateTime.addDays(-1);

    //     // change the field values to trigger the tracking logic
    //     for (Case cse : newCases.values()) {
    //         cse.status = 'Awaiting Network Response'; // change status
    //         cse.Network__c = newtworks.get(0).Id; // change network
    //         cse.NetworkComments__c = 'new comment'; // deferent comment
    //         cse.Network_Response__c = 'Delivered as addressed to letterbox';
    //         cse.OwnerId = user.Id; // owner changed
    //         cse.Last_Status_Change__c = lastChangedDateTime;
    //     }

    //     // testing the updateCaseStatusTracking for case after update
    //     CaseTrackingUtility.setStatusTracking(newCases, oldCases);

    //     Test.stopTest();

    //     // verify test
    //     for (Case cse : newCases.values()) {
    //         System.assertNotEquals(lastChangedDateTime, cse.Last_Status_Change__c,
    //                 'CaseTrackingUtility_Test_setStatusTracking_success : Last_Status_Change__c value should be changed');
    //     }

    // }

    /**
      * SCENARIO: Testing of update old tracking method would update the tracking time elements
     **/
    @isTest
    static void CaseTrackingUtility_Test_updateOldTracking() {

        Test.startTest();

        // create a network to be assigned to cases
        list<Network__c> networks = new list<Network__c>();
        for (Integer i = 0; i < 2; i++) {
            networks.add(
                    new Network__c(
                            Name = 'network_' + i,
                            Email__c = 'adf@daf.com',
                            Portal_Licenses__c = 99
                    )
            );
        }

        insert networks;

        // set<Id> rtids = CaseTrackingUtility.getCaseSSSWRecordTypeId();
        Id rtid;
        // for (Id theId : rtids) {
        //     rtid = theId;
        // }
        DescribeSObjectResult result = Schema.getGlobalDescribe().get('Case').getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeInfo = result.getRecordTypeInfosByName();
        for (String rtName : recordTypeInfo.keySet()) {
            if (rtName.contains('SSSW')) {   // open up record type for USQ case; Eric Shen 15-07-2015
                rtid = recordTypeInfo.get(rtName).getRecordTypeId();
            }   
        }        
        // create cases for old test records
        list<Case> cases = new list<Case>();
        for (Integer i = 0; i < 20; i++) {
            Case cse = new Case();
            cse.RecordTypeId = rtid;
            cse.ReferenceID__c = '1234' + i;
            cse.Subject = 'Newsdd';
            cse.Status = 'Network Responded';
            cse.ProductCategory__c = 'Travel & ID';
            cse.ProductSubCategory__c = 'KeyPass';
            cse.EnquirySubType__c = 'Article carded - no card left';
            cse.DateofIncident__c = date.today();
            cse.Network__c = networks[0].Id;
            cse.OwnerId = UserInfo.getUserId();
            cse.type = 'testing';
            cases.add(cse);
        }

        insert cases;
        // new records
        map<Id, Case> newCases = new map<Id, Case>();
        newCases.putAll(cases);

        // create a new tracking record when the case is created
        CaseTrackingHelper helper = new CaseTrackingHelper();
        helper.insertCaseStatusTracking(newCases.values());

        BusinessHours stdBusinessHours = [select id from BusinessHours where Name = 'Default' LIMIT 1];
        System.debug('newCases.keySet()--->'+newCases.keySet());
        List<StatusTracking__c> statusTracking1 = [SELECT id, case__C FROM StatusTracking__c];
        System.debug('SELECT id, case__C FROM StatusTracking__c'+statusTracking1);
        List<StatusTracking__c> statusTrackings = [
                SELECT Id, EndDate__c, Duration__c, DurationHours__c, DurationMins__c, DurationSeconds__c, BusinessHours__c, StartDate__c
                FROM StatusTracking__c
                WHERE Case__c = :newCases.keySet()
        ];
        System.debug('statusTrackings'+statusTrackings);
        // setting the business hours to ignore null pointer exception in BusinessHours.diff
        for (StatusTracking__c track : statusTrackings) {
            track.BusinessHours__c = stdBusinessHours.Id;
        }

        // verify logic
        CaseTrackingUtility.updateOldTracking(statusTrackings);

        Test.stopTest();

        // verify test
        statusTrackings = [
                SELECT Id, EndDate__c, Duration__c, DurationHours__c, DurationMins__c, DurationSeconds__c
                FROM StatusTracking__c
                WHERE Case__c = :newCases.keySet()
        ];

        // chec the changed field values
        boolean isTracked = false;
        for (StatusTracking__c track : statusTrackings) {
            isTracked = (track.EndDate__c != null);
        }

        System.assertEquals(true, isTracked,
                'CaseTrackingUtility_Test_updateOldTracking : Time related fields should be updated');

    }

    /**
    * SCENARIO: Get the coverage for SSSWCaseRecordTypeIds, getSSSWStatusRecordTypeId, setLastStatusChange
    * as part of the TDO test-re-write project modification to actual logics are out-of scope
    **/
    @isTest
    static void CaseTrackingUtility_Test_coverageForDepricated() {
        //CaseTrackingUtility.getSSSWStatusRecordTypeId();
        map<Id, Case> cases = getCases();
        //CaseTrackingUtility.setLastStatusChange(cases.values());
    }

    /**
     * Test data provider method toextract all the cases
     *
     * @return map<Id, Case> return cases
     */
    private static map<Id, Case> getCases() {
        return new map<Id, Case>([
                SELECT
                        Id, ReferenceID__c, Subject, Status, ProductCategory__c,
                        EnquirySubType__c, ProductSubCategory__c, DateofIncident__c,
                        Network__c, OwnerId, RecordTypeId, NetworkComments__c, Network_Response__c, IsClosed,
                        Last_Status_Change__c, BusinessHoursId, Time_With_Customer__c, Time_With_Support__c,
                        Case_Age_In_Business_Hours__c
                FROM
                        Case
        ]);
    }

}