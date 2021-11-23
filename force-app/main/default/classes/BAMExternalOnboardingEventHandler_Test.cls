/***
 * @description Test class that covers the responses received from Camunda for provisioning/deprovisioning/csso event notification
 * @author Nathan Franklin
 * @date 2019-05-31
 * @group Merchant Portal
 * @changelog
 * 2019-08-12  ajudd@salesforce.com Added BAM Record Type Id conditions
 * 2020-05-25 - Nathan Franklin - Added new test cases for CSSO invite date
 */
@isTest
public class BAMExternalOnboardingEventHandler_Test {

    @testSetup
    public static void setup() {
        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        testAccount.Business_Solutions_Customer__c = true;
        testAccount.Transfer_Case_Queue__c = 'Sorry We Missed You';
        testAccount.Legacy_Id__c = '60000000';
        Database.insert(testAccount);

        Product2 prod = new Product2(Name = 'Test Generic Product');

        // insert applications
        List<BAMApplication__c> applications = new List<BAMApplication__c>{
                BAMTestUtility.createBamApplication('My App 1', prod.Id),
                BAMTestUtility.createBamApplication('TEST My App 2 Is Long Name', prod.Id)
        };
        insert applications;

        // insert roles for applications
        List<BAMApplicationRole__c> roles = new List<BAMApplicationRole__c>{
                BAMTestUtility.createApplicationRole(applications[0]),
                BAMTestUtility.createApplicationRole(applications[1])
        };
        insert roles;

        // insert accounts
        List<Account> accounts = TestDataProvider.createAccount('BAM Test Account', 2);
        insert accounts;

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

    }

    /**
     * Scenario:
     *
     * An external onboarding request has been created as pending and we are simulating a response from Camunda to successfully complete the provisioning process
     * All records in the database are set to Pending for this test and only Role/App/Linked Entity group should be updated as a result of the platform event that was triggered
     * Everything should remain as Pending except for the Contact Application linked to the EOR record
     */
    public static testMethod void testProvisioningFulfilledResponse() {

        // grab all the BAM records that have been inserted in the setup
        // all should remain in Pending state except for the first one we update (which is the context of the platform event that is triggered)
        List<BAMContactRole__c> contactAppRoles = [Select Id, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ApplicationRole__r.Name, ContactApplication__r.Contact__r.Id, ContactApplication__r.Contact__r.Name,
                                                        (Select Id, BillingAccount__r.Name From LinkedEntities__r)
                                                    From BAMContactRole__c];

        // store the Id's of the first record se we can check to make sure it's statuses were all updated successfully
        Id contactApplicationId = contactAppRoles[0].ContactApplication__c;
        Id contactRoleId = contactAppRoles[0].Id;
        Id contactId = contactAppRoles[0].ContactApplication__r.Contact__c;

        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        // a part of this test is to set every second Role and it's related records to Pending
        // this gives us a good mix of data that is both Pending and Active
        List<Sobject> updates = new List<Sobject>();
        for(Integer i = 0; i < contactAppRoles.size(); i++) {
            updates.add(new BAMContactApplication__c(Id = contactAppRoles[i].ContactApplication__c, Status__c = 'Pending'));
            updates.add(new BAMContactRole__c(Id = contactAppRoles[i].Id, Status__c = 'Pending'));
            updates.add(new BAMLinkedEntity__c(Id = contactAppRoles[i].LinkedEntities__r[0].Id, Status__c = 'Pending'));

            // mark one of the linked entitiy records as pending delete... (only the first one will actually be deleted though since it's related Contact Application record is the context of the platform event)
            if(i == 0) {
                updates.add(new BAMLinkedEntity__c(Id = contactAppRoles[i].LinkedEntities__r[1].Id, Status__c = 'Active', Pending_Delete__c = true));
            } else {
                updates.add(new BAMLinkedEntity__c(Id = contactAppRoles[i].LinkedEntities__r[1].Id, Status__c = 'Pending'));
            }
        }
        System.debug(BAMExternalOnboardingEventHandler.reorderUnitsOfWork(new Map<Id, Sobject>(updates)).values());
        update BAMExternalOnboardingEventHandler.reorderUnitsOfWork(new Map<Id, Sobject>(updates)).values();

        // create an external onboarding request record with the correct setup so a provisioning response can be tested
        BAMExternalOnboardingRequest__c onboardingRequest = new BAMExternalOnboardingRequest__c(Contact_Application__c = contactApplicationId, Contact__c = contactId, Status__c = 'Pending', Type__c = 'Provision', RecordTypeId = bamExtObRTId);
        insert onboardingRequest;

        Test.startTest();

        // this is the event that Camunda would send to communicate the an app was provisioned successfully
        ExternalOnboardingEvent__e event = new ExternalOnboardingEvent__e(Application__c = contactAppRoles[0].ContactApplication__r.Application__r.AppKey__c, IsBam__c = true, RequestNumber__c = onboardingRequest.Id, Status__c = 'Fulfilled', Type__c = 'Provision');
        EventBus.publish(event);

        Test.stopTest();

        // verify the EOR record was marked as success
        onboardingRequest = [Select Id, Status__c From BAMExternalOnboardingRequest__c Where Id = :onboardingRequest.Id];
        System.assertEquals('Success', onboardingRequest.Status__c);

        // verify that the data was updated successfully
        contactAppRoles = [Select Id, ContactApplication__r.Status__c, Status__c, (Select Id, BillingAccount__r.Name, Status__c From LinkedEntities__r)
                            From BAMContactRole__c];

        System.assertEquals(false, contactAppRoles.isEmpty(), 'Something went wrong');

        Boolean foundTestRecord = false;
        for(Integer i = 0; i < contactAppRoles.size(); i++) {
            System.debug(' >> contactAppRoles[i]: ' + contactAppRoles[i]);
            System.debug(' >> contactAppRoles[i]: ' + contactAppRoles[i].LinkedEntities__r);
            if(contactAppRoles[i].Id == contactRoleId) {

                // make sure the appropriate status were updated from Pending to Active since the provisioning response was successful
                System.assertEquals('Active', contactAppRoles[i].Status__c);
                System.assertEquals('Active', contactAppRoles[i].ContactApplication__r.Status__c);

                // only 1 record left since the pending delete flag should have removed 1 of the linked entities
                System.assertEquals(1, contactAppRoles[i].LinkedEntities__r.size());
                System.assertEquals('Active', contactAppRoles[i].LinkedEntities__r[0].Status__c);

                foundTestRecord = true;

            } else {

                // make sure no other records were touched outside the scope of this test
                System.assertEquals('Pending', contactAppRoles[i].Status__c);
                System.assertEquals('Pending', contactAppRoles[i].ContactApplication__r.Status__c);
                System.assertEquals(2, contactAppRoles[i].LinkedEntities__r.size());
                System.assertEquals('Pending', contactAppRoles[i].LinkedEntities__r[0].Status__c);
                System.assertEquals('Pending', contactAppRoles[i].LinkedEntities__r[1].Status__c);

            }
        }

        // since we are looping, this will make sure the test record was found
        System.assert(foundTestRecord);
    }

    /**
     * Scenario:
     *
     * An external onboarding request has been created as pending and we are simulating a response from Camunda to throw an error due to problems provisioning
     * In this test we test a multiple responses received for different contacts.
     */
    public static testMethod void testProvisioningErrorResponse() {

        // grab a contact role / application from each created contact... (2 contacts)
        // we update the linked entities for these records to Pending_Delete__c = true.
        // Because of a provisioning error, this field should stay checked and the records should NOT be deleted
        List<BAMContactRole__c> contactAppRoles = [Select Id, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ApplicationRole__r.Name, ContactApplication__r.Contact__r.Id, ContactApplication__r.Contact__r.Name,
                                                        (Select Id, BillingAccount__r.Name From LinkedEntities__r)
                                                    From BAMContactRole__c Order By ContactApplication__r.Application__r.Name, ContactApplication__r.Contact__c
                                                    Limit 2];

        Set<Id> contactRoleIds = new Set<Id>();
        List<Sobject> updates = new List<Sobject>();
        List<Sobject> eorInserts = new List<Sobject>();

        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        for(Integer i = 0; i < contactAppRoles.size(); i++) {
            // use this for verification later
            contactRoleIds.add(contactAppRoles[i].Id);

            // set the linked entities to false.
            // at the end of the test these records should remain and still have Pending_Delete__c = true
            updates.add(new BAMLinkedEntity__c(Id = contactAppRoles[i].LinkedEntities__r[0].Id, Pending_Delete__c = true));
            updates.add(new BAMLinkedEntity__c(Id = contactAppRoles[i].LinkedEntities__r[1].Id, Pending_Delete__c = true));

            eorInserts.add(new BAMExternalOnboardingRequest__c(Contact_Application__c = contactAppRoles[i].ContactApplication__c, Contact__c = contactAppRoles[i].ContactApplication__r.Contact__c, Status__c = 'Pending', Type__c = 'Provision', RecordTypeId = bamExtObRTId));

        }
        update BAMExternalOnboardingEventHandler.reorderUnitsOfWork(new Map<Id, Sobject>(updates)).values();
        insert eorInserts;

        List<BAMExternalOnboardingRequest__c> eorRecords1 = [Select Id, Status__c, Contact_Application__c, Contact_Application__r.Application__c, Contact_Application__r.Application__r.AppKey__c,
                                                                        Contact_Application__r.Pending_Delete__c, Contact_Application__r.Pending_Deactivation__c, Contact_Application__r.Status__c
                                                                From BAMExternalOnboardingRequest__c];
        System.debug('>> eorRecords1' + eorRecords1);

        Test.startTest();

        // this is the event that Camunda would send to communicate the an app was provisioned failed
        List<ExternalOnboardingEvent__e> events = new List<ExternalOnboardingEvent__e>();
        events.add(new ExternalOnboardingEvent__e(Application__c = contactAppRoles[0].ContactApplication__r.Application__r.AppKey__c, IsBam__c = true, RequestNumber__c = eorInserts[0].Id, Status__c = 'Error', Type__c = 'Provision'));
        events.add(new ExternalOnboardingEvent__e(Application__c = contactAppRoles[1].ContactApplication__r.Application__r.AppKey__c, IsBam__c = true, RequestNumber__c = eorInserts[1].Id, Status__c = 'Error', Type__c = 'Provision'));
        EventBus.publish(events);

        Test.stopTest();

        // verify the EOR record was marked as error
        Set<Id> eorIds = new Set<Id>{eorInserts[0].Id, eorInserts[1].Id};
        List<BAMExternalOnboardingRequest__c> eorRecords = [Select Id, Status__c, Error__c From BAMExternalOnboardingRequest__c];
        for(BAMExternalOnboardingRequest__c record : eorRecords) {
            System.assertEquals('Error', record.Status__c);
            System.assertEquals(false, String.isEmpty(record.Error__c));
        }

        // verify that the data was updated successfully
        contactAppRoles = [Select Id, ContactApplication__r.Status__c, Status__c, (Select Id, Status__c, Pending_Delete__c From LinkedEntities__r)
                            From BAMContactRole__c];

        System.assertEquals(false, contactAppRoles.isEmpty(), 'Something went wrong');

        Boolean foundTestRecord = false;

        for(Integer i = 0; i < contactAppRoles.size(); i++) {
            if(contactRoleIds.contains(contactAppRoles[i].Id)) {

                // make sure no statuses were changed because of this error
                System.assertEquals('Active', contactAppRoles[i].Status__c);
                System.assertEquals('Active', contactAppRoles[i].ContactApplication__r.Status__c);

                // no records should have been deleted and Pending_Delete__c should still be set to true
                System.assertEquals(2, contactAppRoles[i].LinkedEntities__r.size());
                System.assertEquals('Active', contactAppRoles[i].LinkedEntities__r[0].Status__c);
                System.assertEquals(true, contactAppRoles[i].LinkedEntities__r[0].Pending_Delete__c);
                System.assertEquals('Active', contactAppRoles[i].LinkedEntities__r[1].Status__c);
                System.assertEquals(true, contactAppRoles[i].LinkedEntities__r[1].Pending_Delete__c);

                foundTestRecord = true;

            } else {

                // make sure no statuses were altered for other records outside the scope of this test
                System.assertEquals('Active', contactAppRoles[i].Status__c);
                System.assertEquals('Active', contactAppRoles[i].ContactApplication__r.Status__c);
                System.assertEquals(2, contactAppRoles[i].LinkedEntities__r.size());
                System.assertEquals('Active', contactAppRoles[i].LinkedEntities__r[0].Status__c);
                System.assertEquals('Active', contactAppRoles[i].LinkedEntities__r[1].Status__c);

            }
        }

        // since we are looping, this will make sure the test record was found
        System.assert(foundTestRecord);
    }

    /**
     * Scenario:
     *
     * A Customer Admin has modified a user's role from their existing role to a new role.
     * This test will simulate removing the old role and activating the new role AFTER a Fulfilled provisioning response has been received.
     */
    public static testMethod void testProvisioningRoleChangeFulfilledResponse() {
        List<BAMApplication__c> applications = [Select Id From BAMApplication__c Limit 1];
        BAMApplicationRole__c newRole = BAMTestUtility.createApplicationRole(applications[0], 'Super User');
        insert newRole;

        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        // grab an existing Contact role we will be removing.
        // this is specific to 1 contact
        BAMContactRole__c currentContactAppRole = [Select Id, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ApplicationRole__r.Name, ContactApplication__r.Contact__r.Id, ContactApplication__r.Contact__r.Name,
                                                            (Select Id, BillingAccount__r.Name From LinkedEntities__r)
                                                        From BAMContactRole__c
                                                        Where ContactApplication__r.Application__c = :applications[0].Id
                                                        Limit 1];

        // grab just 1 of the existing linked entities assigned to the existing contact role to add it to the new role
        // this allows us to test that Linked entities get activated correctly
        BAMLinkedEntity__c currentLinkedEntity = [Select Id, BillingAccount__c From BAMLinkedEntity__c
                                                    Where ContactRole__c = :currentContactAppRole.Id
                                                    LIMIT 1];

        // mark the existing role as pending delete
        // NOTE: It's Important to note that the existing will still be active until the provisioning has completed successfully
        BAMContactRole__c oldContactRole = new BAMContactRole__c(Id = currentContactAppRole.Id, Pending_Delete__c = true);
        update oldContactRole;

        // add the role change (new role) to the COntact Application
        BAMContactRole__c newContactRole = new BAMContactRole__c(ContactApplication__c = currentContactAppRole.ContactApplication__c, Status__c = 'Pending', ApplicationRole__c = newRole.Id);
        insert newContactRole;

        BAMLinkedEntity__c newLinkedEntity = new BAMLinkedEntity__c(ContactRole__c = newContactRole.Id, BillingAccount__c = currentLinkedEntity.BillingAccount__c, Status__c = 'Pending');
        insert newLinkedEntity;

        BAMExternalOnboardingRequest__c eorRecord = new BAMExternalOnboardingRequest__c(Contact_Application__c = currentContactAppRole.ContactApplication__c, Contact__c = currentContactAppRole.ContactApplication__r.Contact__c, Status__c = 'Pending', Type__c = 'Provision', RecordTypeId = bamExtObRTId);
        insert eorRecord;


        Test.startTest();

        // this is the event that Camunda would send to communicate the an app was provisioned failed
        List<ExternalOnboardingEvent__e> events = new List<ExternalOnboardingEvent__e>();
        events.add(new ExternalOnboardingEvent__e(Application__c = currentContactAppRole.ContactApplication__r.Application__r.AppKey__c, IsBam__c = true, RequestNumber__c = eorRecord.Id, Status__c = 'Fulfilled', Type__c = 'Provision'));
        EventBus.publish(events);

        Test.stopTest();

        // verify that the data was updated successfully
        List<BAMContactRole__c> contactAppRoles = [Select Id, ContactApplication__r.Status__c, Status__c, (Select Id, Status__c, Pending_Delete__c From LinkedEntities__r)
                                                    From BAMContactRole__c];

        System.assertEquals(false, contactAppRoles.isEmpty(), 'Something went wrong');

        Boolean foundTestRecord = false;

        for(Integer i = 0; i < contactAppRoles.size(); i++) {
            if(contactAppRoles[i].Id == newContactRole.Id) {

                // make sure no statuses were changed because of this error
                System.assertEquals('Active', contactAppRoles[i].Status__c);
                System.assertEquals('Active', contactAppRoles[i].ContactApplication__r.Status__c);

                // no records should have been deleted and Pending_Delete__c should still be set to true
                System.assertEquals(1, contactAppRoles[i].LinkedEntities__r.size());
                System.assertEquals('Active', contactAppRoles[i].LinkedEntities__r[0].Status__c);

                foundTestRecord = true;

            } else if(contactAppRoles[i].Id == oldContactRole.Id) {
                // this record should no longer exist since it was marked for deletion after the provisoning was fulfilled
                System.assertEquals(false, true, 'This record should have been deleted after a Fulfilled Provisioning');
            } else {

                // make sure no statuses were altered for other records outside the scope of this test
                System.assertEquals('Active', contactAppRoles[i].Status__c);
                System.assertEquals('Active', contactAppRoles[i].ContactApplication__r.Status__c);
                System.assertEquals(2, contactAppRoles[i].LinkedEntities__r.size());
                System.assertEquals('Active', contactAppRoles[i].LinkedEntities__r[0].Status__c);
                System.assertEquals('Active', contactAppRoles[i].LinkedEntities__r[1].Status__c);

            }
        }

        // since we are looping, this will make sure the test record was found
        System.assert(foundTestRecord);

    }

    /**
     * Scenario:
     *
     * A customer admin has requested to remove access for a particular application for a user in their control.
     * We also test the deactivation process for a second Contact Application record.
     * This test will simulate a successful response and the Contact Application records will be removed or set to Inactive.
     */
    public static testMethod void testDeprovisioningFulfilledResponse() {

        // grab a 2 contact role / applications that will be deprovisioned and the other one will be deactivated
        // we update 1 Pending_Delete__c = true and the other will be set to Pending_Deactivation__c
        List<BAMContactRole__c> contactAppRoles = [Select Id, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ApplicationRole__r.Name, ContactApplication__r.Contact__r.Id, ContactApplication__r.Contact__r.Name,
                                                            (Select Id, BillingAccount__r.Name From LinkedEntities__r)
                                                        From BAMContactRole__c
                                                        Limit 2];

        List<BAMContactApplication__c> contactApps = new List<BAMContactApplication__c>{
                new BAMContactApplication__c(Id = contactAppRoles[0].ContactApplication__c, Pending_Delete__c = true),
                new BAMContactApplication__c(Id = contactAppRoles[1].ContactApplication__c, Pending_Deactivation__c = true)
        };
        update contactApps;

        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        List<BAMExternalOnboardingRequest__c> eorRecords = new List<BAMExternalOnboardingRequest__c>();
        eorRecords.add(new BAMExternalOnboardingRequest__c(Contact_Application__c = contactAppRoles[0].ContactApplication__c, Contact__c = contactAppRoles[0].ContactApplication__r.Contact__c, Status__c = 'Pending', Type__c = 'Deprovision', RecordTypeId = bamExtObRTId));
        eorRecords.add(new BAMExternalOnboardingRequest__c(Contact_Application__c = contactAppRoles[1].ContactApplication__c, Contact__c = contactAppRoles[1].ContactApplication__r.Contact__c, Status__c = 'Pending', Type__c = 'Deprovision', RecordTypeId = bamExtObRTId));
        insert eorRecords;

        Test.startTest();

        // this is the event that Camunda would send to communicate the app was successfully deprovisioned
        List<ExternalOnboardingEvent__e> events = new List<ExternalOnboardingEvent__e>();
        events.add(new ExternalOnboardingEvent__e(Application__c = contactAppRoles[0].ContactApplication__r.Application__r.AppKey__c, IsBam__c = true, RequestNumber__c = eorRecords[0].Id, Status__c = 'Fulfilled', Type__c = 'Deprovision'));
        events.add(new ExternalOnboardingEvent__e(Application__c = contactAppRoles[1].ContactApplication__r.Application__r.AppKey__c, IsBam__c = true, RequestNumber__c = eorRecords[1].Id, Status__c = 'Fulfilled', Type__c = 'Deprovision'));
        EventBus.publish(events);

        Test.stopTest();

        // verify that the data was updated successfully
        contactAppRoles = [Select Id, ContactApplication__r.Status__c, Status__c
                                From BAMContactRole__c];

        System.assertEquals(false, contactAppRoles.isEmpty(), 'Something went wrong');

        Boolean foundTestRecord = false;

        for(Integer i = 0; i < contactAppRoles.size(); i++) {
            if(contactAppRoles[i].ContactApplication__c == contactApps[0].Id) {
                System.assertEquals(false, true, 'This record should have been deleted.');
            } else if(contactAppRoles[i].ContactApplication__c == contactApps[1].Id) {
                System.assertEquals('Inactive', contactAppRoles[i].ContactApplication__r.Status__c);
                foundTestRecord = true;
            } else {

                // make sure no statuses were altered for other records outside the scope of this test
                System.assertEquals('Active', contactAppRoles[i].Status__c);
                System.assertEquals('Active', contactAppRoles[i].ContactApplication__r.Status__c);

            }
        }

        // since we are looping, this will make sure the test record was found
        System.assert(foundTestRecord);

    }

    /**
     * Scenario:
     *
     * A customer admin has requested to remove access for a particular application and it failed
     * A failed deprovisioning should reset the deprovisioning state (remove the Pending_Delete__c flag and no status should be changed)
     */
    public static testMethod void testDeprovisioningFailedResponse() {
        // grab a contact role / application that will be deprovisioned
        // this one will be updated to Pending_Delete__c = true

        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        List<BAMContactRole__c> contactAppRoles = [Select Id, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ApplicationRole__r.Name, ContactApplication__r.Contact__r.Id, ContactApplication__r.Contact__r.Name,
                                                        (Select Id, BillingAccount__r.Name From LinkedEntities__r)
                                                    From BAMContactRole__c
                                                    Limit 1];

        List<BAMContactApplication__c> contactApps = new List<BAMContactApplication__c>{
                new BAMContactApplication__c(Id = contactAppRoles[0].ContactApplication__c, Pending_Delete__c = true)
        };
        update contactApps;

        List<BAMExternalOnboardingRequest__c> eorRecords = new List<BAMExternalOnboardingRequest__c>();
        eorRecords.add(new BAMExternalOnboardingRequest__c(Contact_Application__c = contactAppRoles[0].ContactApplication__c, Contact__c = contactAppRoles[0].ContactApplication__r.Contact__c, Status__c = 'Pending', Type__c = 'Deprovision', RecordTypeId = bamExtObRTId));
        insert eorRecords;

        Test.startTest();

        // this is the event that Camunda would send to communicate the app failed to deprovision
        List<ExternalOnboardingEvent__e> events = new List<ExternalOnboardingEvent__e>();
        events.add(new ExternalOnboardingEvent__e(Application__c = contactAppRoles[0].ContactApplication__r.Application__r.AppKey__c, IsBam__c = true, RequestNumber__c = eorRecords[0].Id, Status__c = 'Error', Type__c = 'Deprovision'));
        EventBus.publish(events);

        Test.stopTest();

        // verify that the data was updated successfully
        contactAppRoles = [Select Id, ContactApplication__r.Status__c, Status__c, Pending_Delete__c
                            From BAMContactRole__c];

        System.assertEquals(false, contactAppRoles.isEmpty(), 'Something went wrong');

        Boolean foundTestRecord = false;
        for(Integer i = 0; i < contactAppRoles.size(); i++) {
            if(contactAppRoles[i].ContactApplication__c == contactApps[0].Id) {
                // make sure no statuses were altered for other records outside the scope of this test
                System.assertEquals(false, contactAppRoles[i].Pending_Delete__c);
                System.assertEquals('Active', contactAppRoles[i].ContactApplication__r.Status__c);
                foundTestRecord = true;
            } else {
                // make sure no statuses were altered for other records outside the scope of this test
                System.assertEquals('Active', contactAppRoles[i].Status__c);
                System.assertEquals('Active', contactAppRoles[i].ContactApplication__r.Status__c);
            }
        }

        // since we are looping, this will make sure the test record was found
        System.assert(foundTestRecord);
    }

    /**
     * Scenario:
     *
     * When an application is sent to Camunda for Provisioning, Camunda will check whether or not the Contact should enter into the CSSO flow and have a user record created for single sign on services.
     * This scenario tests when there was an error with the CSSO flow (Expired or other error)
     */
    public static testMethod void testCSSOProvisioningFailedResponse() {

        Contact con = [Select Id From Contact LIMIT 1];

        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        // grab a 2 contact role / applications that will be deprovisioned and the other one will be deactivated
        // we update 1 Pending_Delete__c = true and the other will be set to Pending_Deactivation__c
        List<BAMContactRole__c> contactAppRoles = [Select Id, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ApplicationRole__r.Name, ContactApplication__r.Contact__r.Id, ContactApplication__r.Contact__r.Name,
                                                            (Select Id, BillingAccount__r.Name From LinkedEntities__r)
                                                    From BAMContactRole__c
                                                    Where ContactApplication__r.Contact__c = :con.Id
                                                    LIMIT 1];

        List<BAMExternalOnboardingRequest__c> eorRecords = new List<BAMExternalOnboardingRequest__c>();
        eorRecords.add(new BAMExternalOnboardingRequest__c(Contact_Application__c = contactAppRoles[0].ContactApplication__c, Contact__c = contactAppRoles[0].ContactApplication__r.Contact__c, Status__c = 'Pending', Type__c = 'Provision', RecordTypeId = bamExtObRTId));
        insert eorRecords;

        Test.startTest();

        // this is the event that Camunda would send to communicate the app failed to deprovision
        List<ExternalOnboardingEvent__e> events = new List<ExternalOnboardingEvent__e>();
        events.add(new ExternalOnboardingEvent__e(IsBam__c = true, Contact__c = con.Id, Status__c = 'Error', Type__c = 'CSSO'));
        EventBus.publish(events);

        Test.stopTest();

        // verify that the contact record was updated successfully
        con = [Select Id, BAMCSSOError__c, BAMCSSOErrorMessage__c From Contact Where Id = :con.Id];

        System.assertEquals(true, con.BAMCSSOError__c);
        System.assertEquals(false, String.isEmpty(con.BAMCSSOErrorMessage__c));

        // check to make sure the CSSO failure process marked any matching EOR records as errored.
        List<BAMExternalOnboardingRequest__c> record = [Select Id From BAMExternalOnboardingRequest__c Where Status__c = 'Pending'];
        System.assertEquals(0, record.size());

    }

    /**
     * Scenario:
     *
     * When an application is sent to Camunda for Provisioning, Camunda will check whether or not the Contact should enter into the CSSO flow and have a user record created for single sign on services.
     * This scenario tests when a new request is Started
     */
    public static testMethod void testCSSOProvisioningStartedResponse() {

        Contact con = [Select Id From Contact LIMIT 1];

        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        List<BAMContactRole__c> contactAppRoles = [Select Id, ContactApplication__r.Contact__c, ContactApplication__r.Application__r.AppKey__c, ContactApplication__r.Application__r.Name, ApplicationRole__r.Name, ContactApplication__r.Contact__r.Id, ContactApplication__r.Contact__r.Name,
                                                        (Select Id, BillingAccount__r.Name From LinkedEntities__r)
                                                    From BAMContactRole__c
                                                    Where ContactApplication__r.Contact__c = :con.Id
                                                    LIMIT 1];

        List<BAMExternalOnboardingRequest__c> eorRecords = new List<BAMExternalOnboardingRequest__c>();
        eorRecords.add(new BAMExternalOnboardingRequest__c(Contact_Application__c = contactAppRoles[0].ContactApplication__c, Contact__c = contactAppRoles[0].ContactApplication__r.Contact__c, Status__c = 'Pending', Type__c = 'Provision', RecordTypeId = bamExtObRTId));
        insert eorRecords;

        Test.startTest();

        // this is the event that Camunda would send to communicate the app failed to deprovision
        List<ExternalOnboardingEvent__e> events = new List<ExternalOnboardingEvent__e>();
        events.add(new ExternalOnboardingEvent__e(IsBam__c = true, Contact__c = con.Id, Status__c = 'Started', Type__c = 'CSSO'));
        EventBus.publish(events);

        Test.stopTest();

        // verify that the contact record was updated successfully
        con = [Select Id, BAMCSSOError__c, BAMCSSOErrorMessage__c, BAMInviteRequestDate__c From Contact Where Id = :con.Id];

        System.assertEquals(false, con.BAMCSSOError__c);
        System.assertEquals(true, String.isEmpty(con.BAMCSSOErrorMessage__c));
        System.assertNotEquals(null, con.BAMInviteRequestDate__c);

    }

}