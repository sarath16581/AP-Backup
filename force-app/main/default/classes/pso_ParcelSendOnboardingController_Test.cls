/**************************************************
Description:  Unit tests for Parcel Send Onboarding

History:
--------------------------------------------------
2019-04-22  hasantha.liyanage@auspost.com.au Created
2019-08-14  hasantha.liyanage@auspost.com.au modified all the test methods to support new rules structure.
2019-09-04  shashwat.a.nath@accenture.com created two new test methods for asset creation and updation functionality.
**************************************************/

@isTest
public class pso_ParcelSendOnboardingController_Test {

    @testSetup
    static void testSetup() {
        // CREATE VALID ACCOUNTS
        Map<String, Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();

        //create accounts
        Account ca1 = new Account(name = 'test1', phone = '123', email__c = 'test@test.com', recordtypeid = accRecTypeMap.get('Organisation').getRecordTypeId());
        insert ca1;

        Account ca2 = new Account(name = 'test2', phone = '123', email__c = 'test@test.com', recordtypeid = accRecTypeMap.get('Organisation').getRecordTypeId(), parentid = ca1.id);
        insert ca2;

        Account ca3 = new Account(name = 'test2', phone = '123', email__c = 'test@test.com', recordtypeid = accRecTypeMap.get('Organisation').getRecordTypeId(), parentid = ca2.id, Legacy_ID__c = '60000000');
        insert ca3;

        Account tempacct = [SELECT Id FROM Account WHERE Legacy_Id__c = '60000000' limit 1];
        system.assert(tempacct != null);

        Account acc = TestUtility.createBusinessAccount('Hans Enterprises', accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);
        acc.billingstreet = 'street';
        acc.billingcity = 'city';
        acc.billingstate = 'state';
        acc.billingpostalcode = '3000';
        acc.billingcountry = 'AU';
        acc.shippingstreet = 'street';
        acc.shippingcity = 'city';
        acc.shippingstate = 'state';
        acc.shippingpostalcode = '3000';
        acc.shippingcountry = 'AU';

        Database.update(acc);

        Organisation_Role__c customerRole = new Organisation_Role__c();
        customerRole.Organisation__c = acc.Id;
        customerRole.Role_Type__c = 'Customer'; // VALIDATE 1: organisation Role is Customer, otherwise not eligible
        insert customerRole;


        // 3 billing account's for same customer/Organisation
        // VALIDATE 4: if any Billing account name is 40 chars or less, otherwise not eligible
        // VALIDATE 5: if any Billing account is not marked for deletion, otherwise not eligible
        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 3, new List<Account>{
                acc
        });
        testBillingAccList[0].Source_System__c = 'TEAM'; //VALIDATE 3: TEAM and SAP Billing accounts only
        testBillingAccList[0].LEGACY_ID__c = 'P1234567';

        testBillingAccList[1].Source_System__c = 'PeopleSoft';
        testBillingAccList[1].LEGACY_ID__c = 'P1234568';

        testBillingAccList[2].Source_System__c = 'SAP ERP'; //VALIDATE 3: TEAM and SAP Billing accounts only
        testBillingAccList[2].LEGACY_ID__c = 'P1234569';
        testBillingAccList[2].MLID__c = 'MLEW'; // MLID is a required field when the source system is SAP ERP
        insert testBillingAccList;

        Contact con = TestUtility.createContact('Hans', 'Li', 'hans@li.com', acc.id);
        con.BillingAccount__c = testBillingAccList[0].Id;
        con.status__c = 'Active';
        Database.insert(con);

        // insert a  location to create a billing account location
        Map<String, Schema.RecordTypeInfo> locRecTypeMap = Schema.Sobjecttype.Location.getRecordTypeInfosByName();
        Schema.Location objLocation = new Schema.Location();
        objLocation.Name = 'Hogwarts';
        objLocation.LocationType = 'Site';
        objLocation.TimeZone = 'Australia/Sydney';
        objLocation.IsInventoryLocation = true;
        objLocation.Billing_Account__c = testBillingAccList[2].Id;
        objLocation.Organisation__c = acc.Id;
        objLocation.recordTYpeId = locRecTypeMap.get('Despatch Location').getRecordTypeId();
        insert objLocation;

        BAMGroup__c grp = BAMTestUtility.createTestGroup(acc.Id);
        grp.Despatch_Location__c = objLocation.Id;
        insert grp;

        BAMApplication__c app = BAMTestUtility.createBamApplication('PS');
        app.appKey__c ='PS';
        insert app;

        System.debug('app==>' + app);
        Asset prod = BAMTestUtility.createAsset(acc.Id, app.Product__c, true);
        insert prod;
        System.debug('prod==>' + prod);
        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(app);
        insert appRole;
        System.debug('approle==>' + appRole.Id);
        BAMContactApplication__c conApp = BAMTestUtility.createTestContactApplication(con.Id, app.Id);
        insert conApp;
        System.debug('conapp==>' + conapp.Id);
        BAMContactRole__c conRole = BAMTestUtility.createTestContactRole(conApp.Id, appRole.Id);
        insert conRole;
        System.debug('conrole==>' + conrole.Id);
        BAMLinkedEntity__c leBA = BAMTestUtility.createTestLinkedEntity(conRole.Id, testBillingAccList[0].Id, 'ba');
        leBA.Status__c =  'Active';
        insert leBA;

        BAMGroupBillingAccount__c leGrpBA = BAMTestUtility.createTestGroupBillingAccount(grp.Id, testBillingAccList[2].Id);
        insert leGrpBA;

        BAMLinkedEntity__c leGrp = BAMTestUtility.createTestLinkedEntity(conRole.Id, grp.Id, 'grp');
        leGrp.Status__c =  'Active';
        insert leGrp;

        Billing_Account__c BA = BAMTestUtility.createTestBillingAccount(acc.Id, 'Name acct');
        insert BA;

        
        
    }

    @isTest
    static void relatedRecordsByContact_Test() {
        Contact contact = [SELECT id FROM COntact WHERE email = 'hans@li.com'];
        pso_ParcelSendOnboardingController.DisplayRecordsResponse response = pso_ParcelSendOnboardingController.getRelatedRecordsByContact(contact.Id);

        system.assertNotEquals(0, response.applications.size());
        system.assertNotEquals(0, response.contactRoles.size());
        system.assertNotEquals(0, response.linkedEntities.size());
        system.assertNotEquals(0, response.groups.size());
        system.assertNotEquals(0, response.groupBillingAccounts.size());
        system.assertNotEquals(0, response.billingAccounts.size());

    }



    /**
    * testing the standard controller
     *
     */
    @isTest
    static void validateStandardController_Test() {
        Contact contact = [SELECT id FROM COntact WHERE email = 'hans@li.com'];

        ApexPages.StandardController sc = new ApexPages.StandardController(contact);
        pso_ParcelSendOnboardingController ctrl = new pso_ParcelSendOnboardingController(sc);

        PageReference pageRef = Page.pso_ParcelSendOnboarding;
        pageRef.getParameters().put('id', String.valueOf(contact.Id));
        Test.setCurrentPage(pageRef);

        system.assertNotEquals(null, ctrl.contact,
                'pso_ParcelSendOnboardingController_Test : validateStandardController_Test() standard controller constructor should populate the contact');

    }


    /**
     * testing the get status method, this will also test the validate method on the pso_ParcelSendOnboarding class
     */
    @isTest
    static void getStatus_success_Test() {
        Contact contact = [SELECT id FROM COntact WHERE email = 'hans@li.com'];
        pso_ParcelSendOnboarding.Response response = pso_ParcelSendOnboardingController.getStatus(contact.Id);

        system.assertEquals(true, response.isSuccess,
                'pso_ParcelSendOnboardingController_Test : getStatus_Test() get status should be successfull');

    }


    /**
     * get the contact by Id
     */
    @isTest
    static void getContact_Test() {
        Contact contact = [SELECT id FROM COntact WHERE email = 'hans@li.com'];

        Object so = pso_ParcelSendOnboardingController.getContact(contact.Id);

        system.assertNotEquals(null, so,
                'pso_ParcelSendOnboardingController_Test : getContact_Test() requested contact should be retrieved');

    }

    /**
     * testing of create the External Onboarding Request record
     */
    @isTest
    static void createOnboardingRequest_Test() {
        Contact contact = [SELECT id FROM COntact WHERE email = 'hans@li.com'];

        pso_ParcelSendOnboarding.Response response = pso_ParcelSendOnboardingController.createOnboardingRequest(contact.Id);

        system.assertEquals(true, response.isSuccess,
                'pso_ParcelSendOnboardingController_Test : createOnboardingRequest_Test() external onboarding request record should be created');

    }


    /**
     * test coverage for the inner classes
     */
    @isTest
    static void data_Test() {
        pso_ParcelSendOnboardingController.StatusResponse sr1 = new pso_ParcelSendOnboardingController.StatusResponse( 'Status', 'OnboardingStatus', 'Message');
        pso_ParcelSendOnboardingController.StatusResponse sr2 = new pso_ParcelSendOnboardingController.StatusResponse( 'Status', 'Message');
        pso_ParcelSendOnboardingController.StatusResponse sr3 = new pso_ParcelSendOnboardingController.StatusResponse();

    }


    /**
     * send onboarding request : mock test the endpoint call
     */
    @isTest
    static void sendOnboardingRequest_success_Test() {
        Contact contact = [SELECT id FROM COntact WHERE email = 'hans@li.com'];
        list<string> params = new list<String>{
                contact.Id
        };

        Test.startTest();
        // create external onb record
        pso_ParcelSendOnboardingController.createOnboardingRequest(contact.Id);
        Continuation continuation = (Continuation) AsynchApexContinuationController.invoke('pso_IAsynchApexContinuationImpl', 'sendOnboardingRequest', params, true);
        Map<String, HttpRequest> requests = continuation.getRequests();
        String requestLabel = requests.keyset().iterator().next();
        HttpResponse response = new HttpResponse();
        response.setBody(pso_ParcelSendOnboarding.prepareAndCalloutRequest(params));
        Test.setContinuationResponse(requestLabel, response);
        AsynchApexContinuationController.statInfo sInfo = new AsynchApexContinuationController.statInfo();
        sInfo.continuationId = requestLabel;
        sInfo.classname = 'pso_IAsynchApexContinuationImpl';
        sInfo.params = params;
        object rtnObj = AsynchApexContinuationController.restCallback(sInfo);
        test.stopTest();


        // test response call back
        pso_IAsynchApexContinuationImpl asynchApexContinuationImpl = new pso_IAsynchApexContinuationImpl();
        HttpRequest req = new HttpRequest();
        list<String> strLst = new list<String>{
                '1'
        };
        asynchApexContinuationImpl.setHTTPRequest(req, 'pso_IAsynchApexContinuationImpl', 'sendOnboardingRequest', params);

        // build mock response
        HttpResponse httpResp = new HttpResponse();
        pso_IAsynchApexContinuationImpl.HttpResponseInfo testInfo = new pso_IAsynchApexContinuationImpl.HttpResponseInfo();
        testInfo.payload = '{"status": "ok"}';
        testInfo.methodName = 'sendOnboardingRequest';
        httpResp.setBody(JSON.serialize(testInfo));
        // build mock response end

        Object objTmp = asynchApexContinuationImpl.parseResponse(httpResp);

        system.debug('HASANTHA ' + objTmp);
        System.assertNotEquals('', ((pso_IAsynchApexContinuationImpl.HttpResponseInfo) objTmp).payload);
    }



    /**
     * create a platform event with externalOnboardingEvent method
     */
    @isTest
    static void externalOnboardingEvent_success() {
        Contact contact = [SELECT id FROM COntact WHERE email = 'hans@li.com'];

        pso_ParcelSendOnboardingController.createOnboardingRequest(contact.Id);

        List<BAMExternalOnboardingRequest__c> savedExternalOnboardingRequests = pso_ParcelSendOnboarding.getExternalOnboardingRequests(new List<String>{contact.Id}, new List<String> {'Error','Pending'});
        // Create a test event instance
        ExternalOnboardingEvent__e eoe = new ExternalOnboardingEvent__e(
                RequestNumber__c = savedExternalOnboardingRequests[0].Id,
                ResponseText__c = 'response body from Bulk 1 hans test only',
                Application__c = 'Parcel Send',
                Status__c = 'Fulfilled',
                Type__c = 'Provisioning'
        );

        Test.startTest();

        // Publish test event
        Database.SaveResult sr = EventBus.publish(eoe);

        Test.stopTest();

        // Verify SaveResult value
        System.assertEquals(true, sr.isSuccess());

        // Verify that a case was created by a trigger.
        savedExternalOnboardingRequests = pso_ParcelSendOnboarding.getExternalOnboardingRequests(new List<String>{contact.Id}, null);
        // Validate that this case was found
        System.assertEquals('Success', savedExternalOnboardingRequests[0].Status__c);
    }

    /**
     * status change check up on creating platform event,
     * platform event trigger updates the onboarding request record's status
     */
    @isTest static void externalOnboardingEvent_pending() {
        Contact contact = [SELECT id FROM COntact WHERE email = 'hans@li.com'];

        pso_ParcelSendOnboardingController.createOnboardingRequest(contact.Id);

        List<BAMExternalOnboardingRequest__c> savedExternalOnboardingRequests = pso_ParcelSendOnboarding.getExternalOnboardingRequests(new List<String>{contact.Id}, new List<String> {'Error','Pending'});
        // Create a test event instance
        ExternalOnboardingEvent__e eoe = new ExternalOnboardingEvent__e(
                RequestNumber__c = savedExternalOnboardingRequests[0].Id,
                ResponseText__c = 'response body from Bulk 1 hans test only',
                Application__c = 'Parcel Send',
                Status__c = 'Started',
                Type__c = 'Provisioning'
        );

        Test.startTest();

        // Publish test event
        Database.SaveResult sr = EventBus.publish(eoe);
        Test.getEventBus().deliver();
        Test.stopTest();

        // Verify SaveResult value
        System.assertEquals(true, sr.isSuccess());

        // Verify that a case was created by a trigger.
        savedExternalOnboardingRequests = pso_ParcelSendOnboarding.getExternalOnboardingRequests(new List<String>{contact.Id}, null);
        // Validate that this case was found
        System.assertEquals('Pending', savedExternalOnboardingRequests[0].Status__c);

    }

    /**
     * check on recive of a failed onboarding request
     */
    @isTest static void externalOnboardingEvent_error() {
        Contact contact = [SELECT id FROM COntact WHERE email = 'hans@li.com'];

        pso_ParcelSendOnboardingController.createOnboardingRequest(contact.Id);

        List<BAMExternalOnboardingRequest__c> savedExternalOnboardingRequests = pso_ParcelSendOnboarding.getExternalOnboardingRequests(new List<String>{contact.Id}, null);
        // Create a test event instance
        ExternalOnboardingEvent__e eoe = new ExternalOnboardingEvent__e(
                RequestNumber__c = savedExternalOnboardingRequests[0].Id,
                ResponseText__c = 'response body from Bulk 1 hans test only',
                Application__c = 'Parcel Send',
                Status__c = 'Error',
                Type__c = 'Provisioning'
        );

        Test.startTest();

        system.debug('HASANTHA TEST '+eoe);

        // Publish test event
        Database.SaveResult sr = EventBus.publish(eoe);
        Test.getEventBus().deliver();
        Test.stopTest();
        // Verify SaveResult value
        System.assertEquals(true, sr.isSuccess());

        // Verify that a case was created by a trigger.
        savedExternalOnboardingRequests = pso_ParcelSendOnboarding.getExternalOnboardingRequests(new List<String>{contact.Id}, null);


        // Validate that this case was found
        System.assertEquals('Error', savedExternalOnboardingRequests[0].Status__c);

        // unsuccessful response generated
        pso_ParcelSendOnboarding.Response response = pso_ParcelSendOnboardingController.getStatus(contact.Id);

        system.assertEquals(false, response.isSuccess,
                'pso_ParcelSendOnboardingController_Test : externalOnboardingEvent_error() failed request');

    }

    /**
     *  testing the delete lock contact record toggle
     **/
    @isTest static void externalOnboardingRequest_deleteLockPending() {

        Contact contact = [SELECT id, Delete_Locked__c FROM Contact WHERE email = 'hans@li.com'];

        Test.startTest();
        pso_ParcelSendOnboardingController.createOnboardingRequest(contact.Id);


        List<BAMExternalOnboardingRequest__c> savedExternalOnboardingRequests = pso_ParcelSendOnboarding.getExternalOnboardingRequests(new List<String>{contact.Id}, new List<String> {'Error','Pending'});

        System.assertEquals(savedExternalOnboardingRequests[0].Contact__c,contact.Id);
        // check for the contact record delete lock when pending request available
        savedExternalOnboardingRequests[0].Status__c = 'Pending';
        update savedExternalOnboardingRequests[0];
        Test.stopTest();
        System.assertEquals(true, [SELECT id, Delete_Locked__c from contact WHERE Id =: savedExternalOnboardingRequests[0].Contact__c].Delete_Locked__c);

    }

    /**
  *  testing the delete lock contact record toggle
  **/
    @isTest static void externalOnboardingRequest_deleteLockNotPending() {

        Contact contact = [SELECT id, Delete_Locked__c FROM Contact WHERE email = 'hans@li.com'];

        Test.startTest();
        pso_ParcelSendOnboardingController.createOnboardingRequest(contact.Id);
        List<BAMExternalOnboardingRequest__c> savedExternalOnboardingRequests = pso_ParcelSendOnboarding.getExternalOnboardingRequests(new List<String>{contact.Id}, new List<String> {'Error','Pending'});

        System.assertEquals(savedExternalOnboardingRequests[0].Contact__c,contact.Id);
        // check for the contact record delete lock when NOT pending request available
        savedExternalOnboardingRequests[0].Status__c = 'Error';
        update savedExternalOnboardingRequests[0];
        Test.stopTest();
        System.assertEquals(false, [SELECT id, Delete_Locked__c from contact WHERE Id =: savedExternalOnboardingRequests[0].Contact__c].Delete_Locked__c);

    }
    
     /**
     * create a platform event with externalOnboardingEvent method
     * @author : shashwat.a.nath@accenture.com
     */
    @isTest
    static void parcelSendAssetCreationTest() {
        Contact contact = [SELECT id, accountId FROM COntact WHERE email = 'hans@li.com'];
        
        Product2 prod = new Product2(Name = 'Parcel Send');
        insert prod ;
        BAMApplication__c app = [Select id from BAMApplication__c where appKey__c ='PS'];
        app.Product__c = prod.id;
        update app;
        
         Id bamExtObRTId = Schema.SObjectType.BAMExternalOnboardingRequest__c.getRecordTypeInfosByName().get('Parcel Send Onboarding').getRecordTypeId();
        
        BAMExternalOnboardingRequest__c onboardingRequest = new BAMExternalOnboardingRequest__c(Contact__c = contact.id, Status__c = 'Pending', Type__c = 'Provision', RecordTypeId = bamExtObRTId);
        
        Test.startTest();

        // Insert the Request
        Database.SaveResult sr = Database.insert(onboardingRequest);

        Test.stopTest();

        // Verify SaveResult value
        System.assertEquals(true, sr.isSuccess());

        // Verify that an asset record was created
        List<Asset> assetCreatedList = [SELECT id , Product_Name__c ,Product2Id , status from Asset where Product_Name__c ='Parcel Send' AND AccountId=:contact.accountId];
        // Validate that this Asset with status Active of type Parcel Send was found
        System.assertEquals('Active', assetCreatedList[0].Status);
        
    }
    
    /**
     * create a platform event with externalOnboardingEvent method to Test Existing asset status Asset upadtion for Parcel Send
     * @author : shashwat.a.nath@accenture.com
     */
    @isTest
    static void parcelSendAssetUpdationTest() {
        Contact contact = [SELECT id, accountId FROM COntact WHERE email = 'hans@li.com'];
        
        Product2 prod = new Product2(Name = 'Parcel Send');
        insert prod ;
        BAMApplication__c app = [Select id from BAMApplication__c where appKey__c ='PS'];
        app.Product__c = prod.id;
        update app;
        
        Asset assetToBeUpdated = new Asset();
        assetToBeUpdated.recordtypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('General').getRecordTypeId();
        // Setting the asset name
        assetToBeUpdated.name = 'Parcel Send';
        // setting the Account Id
        assetToBeUpdated.AccountId = contact.accountId;
        // setting the Product Id
        assetToBeUpdated.Product2Id = prod.id;
        // setting the status to Inactive
        assetToBeUpdated.Status = 'Inactive';
        
        insert assetToBeUpdated;
        
        Id bamExtObRTId = Schema.SObjectType.BAMExternalOnboardingRequest__c.getRecordTypeInfosByName().get('Parcel Send Onboarding').getRecordTypeId();
        
        BAMExternalOnboardingRequest__c onboardingRequest = new BAMExternalOnboardingRequest__c(Contact__c = contact.id, Status__c = 'Pending', Type__c = 'Provision', RecordTypeId = bamExtObRTId);
        Test.startTest();

        // Insert the Request
        Database.SaveResult sr = Database.insert(onboardingRequest);

        Test.stopTest();

        // Verify SaveResult value
        System.assertEquals(true, sr.isSuccess());

        // Verify that an asset record was created
        List<Asset> assetUpdatedList = [SELECT id , Product_Name__c ,Product2Id , status from Asset where id=:assetToBeUpdated.id];
        // Validate that this Asset with status Active of type Parcel Send was found
        System.assertEquals('Active', assetUpdatedList[0].Status);
        
    }

}