/**************************************************
Description: This class contains unit tests for validating the behavior of Apex class API_AuthRules
History:
2018-03-21 dilshan.egodawela@auspost.com.au description here
**************************************************/

 
@isTest
public class ResourceV1AuthorisationRulesContact_Test {

    @testSetup static void setup() {
        //create test data
        Account a = TestDataProvider.createAndSaveBusinessAccount();
        a.LEGACY_ID__c = '60000000';
        update a;
        Account acc = APT_TestUtils.createOrganisation();
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.LEGACY_ID__c = '1001';
            insert acc;
        
        Billing_Account__c ba =  new Billing_Account__c(Name = 'BillingAccount', LEGACY_ID__c = '0007654321',Organisation__c = acc.Id, Type__c = 'CUST', Source_System__c ='PeopleSoft');
        insert ba;
        
        Contact c = new Contact(FirstName='Michael', LastName='Clark', OID_ID__c='C001001001', Email='michael.clark@auspost.com.au', AccountId=acc.Id);
        insert c;
        
        Contact c2 = new Contact(FirstName='John', LastName='Wick', OID_ID__c='C001001002', Email='michael.clark2@auspost.com.au', AccountId=acc.Id);
        insert c2;
        
        Id RecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Despatch Location').getRecordTypeId();
        
        Schema.Location location = new Schema.Location(Name = 'Test Location',Organisation__c = acc.Id,LocationType ='Warehouse',recordtypeid = RecordTypeId);
        insert location;
 
        Authorization_Rule__c authRule = new Authorization_Rule__c(AccessRole__c = 'Contract UI User', Billing_Account__c = ba.Id, Contact__c = c2.Id, Status__c = 'Active');
        Insert authRule;
        
        Authorization_Rule__c authRule2 = new Authorization_Rule__c(AccessRole__c = 'Send a Parcel UI User',Location__c = location.Id, Contact__c = c.Id, Status__c = 'Active');
        Insert authRule2;
        
        Billing_Account_Location__c billingAccountRule = new Billing_Account_Location__c(Billing_Account_Id__c = ba.Id ,Location__c = location.Id );
        insert billingAccountRule;
    }
    
    /********************************************
    Scenario:
    get Auth Rule records where contacts with locations that are related to the primary customer record of the contact
    *********************************************/
    static testMethod void testContactsWithLocations() {
        // TO DO: implement unit test
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = '/services/apexrest/v1.0/authorisation/rules/contact/C001001001';
        request.addParameter('accessType', 'Send a Parcel UI User,Contract UI User');

        request.httpMethod = 'GET';

        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        ResourceV1AuthorisationRulesContact.get();

        // Verify results

        System.debug(JSON.deserializeUntyped(response.responseBody.toString()));
        System.debug(response.responseBody.toString());
        //verify response status
        System.assert(response.statusCode == 200);
        
        Map<String,Object> results = (Map<String,Object>)JSON.deserializeUntyped(response.responseBody.toString());
        List<Object> temp = (List<Object>)results.get('response');
        Map<String,Object> temp2 = (Map<String,Object>)temp[0];
        System.debug(temp2.get('authRules'));
        
        List<Object> temp3 = (List<Object>)temp2.get('authRules');
        Map<String,Object> temp4 = (Map<String,Object>)temp3[0];
        
        //get location Id
        Schema.Location location = [select Id,Location_ID__c from Location limit 1];
        System.debug(location.Location_ID__c);
        
        Test.stopTest();
        //verify the location id with one returned via the webservice.
        System.assertEquals(temp4.get('locationId') ,location.Location_ID__c);
    }
    
        /********************************************
    Scenario:
    get Auth Rule records where contacts with billing accounts/accounts are related to the primary customer record of the contact
    *********************************************/
    static testMethod void testContactsWithBillingAccounts() {
        // TO DO: implement unit test
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = '/services/apexrest/v1.0/authorisation/rules/contact/C001001002';
        request.addParameter('accessType', 'Send a Parcel UI User,Contract UI User');

        request.httpMethod = 'GET';

        RestContext.request = request;
        RestContext.response = response;
        // Call the method to test
        ResourceV1AuthorisationRulesContact.get();

        // Verify results
        System.debug(JSON.deserializeUntyped(response.responseBody.toString()));
        System.debug(response.responseBody.toString());
        //verify response status
        System.assert(response.statusCode == 200);
        
        Map<String,Object> results = (Map<String,Object>)JSON.deserializeUntyped(response.responseBody.toString());
        List<Object> temp = (List<Object>)results.get('response');
        Map<String,Object> temp2 = (Map<String,Object>)temp[0];
        System.debug(temp2.get('authRules'));
        
        List<Object> temp3 = (List<Object>)temp2.get('authRules');
        Map<String,Object> temp4 = (Map<String,Object>)temp3[0];
        System.debug(temp4.get('billingAccountNumber'));
        
        Test.stopTest();
        //check the billing account number with returned vs created.
        System.assertEquals(temp4.get('billingAccountNumber') ,'0007654321');
    }
    
    
}