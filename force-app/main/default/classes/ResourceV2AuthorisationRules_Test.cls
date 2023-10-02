/***
 * @description This class contains unit tests for validating the behavior of Apex class ResourceV2AuthorisationRules
 * @author Nathan Franklin
 * @date 2019-08-05
 * @changelog
 * 2022-04-22 - Nathan Franklin - Updated test classes for conveyancers
 * 2023-10-02 - Mahesh Parvathaneni - Updated test classes for isBlocked attribute
 */
@isTest
public class ResourceV2AuthorisationRules_Test {

    @testSetup
    public static void setup() {
        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        testAccount.Business_Solutions_Customer__c = true;
        testAccount.Transfer_Case_Queue__c = 'Sorry We Missed You';
        Database.insert(testAccount);

        testAccount.Legacy_Id__c = '60000000';
        update testAccount;

        BAMApplicationSpecificFields__c appSetting = new BAMApplicationSpecificFields__c(
            Name = 'BSP_field1',
            SObject__c = 'ContactApplication__r',
            API_Name__c = 'Application_Name__c',
            Label__c = 'AppName'
        );
        insert appSetting;

        // for linking to applications only
        Product2 prodBSP = new Product2(Name = 'Test Generic Product');
        Product2 prodPS = new Product2(Name = 'Test Generic Product');
        insert new List<Product2>{prodBSP, prodPS};

        // insert applications
        List<BAMApplication__c> applications = new List<BAMApplication__c>{
                BAMTestUtility.createBamApplication('BSP', prodBSP.Id),
                BAMTestUtility.createBamApplication('PS', prodPS.Id)
        };
        insert applications;

        // insert 'Admin' role for each application
        List<BAMApplicationRole__c> roles = new List<BAMApplicationRole__c>{
                BAMTestUtility.createApplicationRole(applications[0]),
                BAMTestUtility.createApplicationRole(applications[1])
        };
        // remove default values
        roles[0].ShowOrganisation__c = false;
        roles[1].ShowOrganisation__c = false;
        insert roles;

        // insert accounts
        // produce accounts like this: BAM1, BAM2 etc..
        List<Account> accounts = TestDataProvider.createAccount('BAM', 2);
        accounts[0].Conveyancer_Is_a__c = true;
        accounts[0].Conveyancer_Number__c = 1;
        insert accounts;

        // only insert assets for account[0]
        // this means any contact of account[1] will not get any results because accounts[1] has no applications activated
        List<Asset> assets = new List<Asset>();
        assets.add(BAMTestUtility.createAsset(accounts[0].Id, prodBSP.Id, true));
        assets.add(BAMTestUtility.createAsset(accounts[0].Id, prodPS.Id, true));
        insert assets;

        // insert test billing accounts
        // account[0] will get these billing accounts
        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 2, new List<Account>{accounts[0]});
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P123456';
        testBillingAccList[1].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[1].LEGACY_ID__c = 'P223456';

        // account[1] will get these billing accounts
        testBillingAccList.addAll(TestDataProvider.createBillingAccount('', 2, new List<Account>{accounts[1]}));
        testBillingAccList[2].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[2].LEGACY_ID__c = 'P789456';
        testBillingAccList[3].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[3].LEGACY_ID__c = 'P6647584';
        insert testBillingAccList;

        // create contacts
        // C1230 is linked to account[0]
        // C1231 is linked to account[1]
        List<Contact> contacts = new List<Contact>();
        for(Integer i=0;i<accounts.size();i++) {
            Contact con = TestDataProvider.createContact('Contact', accounts[i].Id, null);
            con.FirstName = 'Contact ' + i;
            con.LastName = 'Contact ' + i;
            con.Status__c = 'Active';
            con.OID_ID__c = 'C123' + i;
            contacts.add(con);
        }
        insert contacts;

        // each contact will receive access to 2 applications (each application created above)
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

        // insert the 'Admin' contact role for each contact application record for each contact that was created (total of 4 records)
        List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>();
        Map<Id, List<BAMContactRole__c>> contactApplicationsRoleMap = new Map<Id, List<BAMContactRole__c>>();
        for(Contact con : contacts) {
            for(Integer i = 0; i < contactsApplicationsMap.get(con.Id).size(); i+=2) {
                BAMContactApplication__c contactApp = contactsApplicationsMap.get(con.Id)[i];
                BAMContactRole__c role;

                // create a contact role for the first app linked to this contact
                contactApplicationsRoleMap.put(contactApp.Id, new List<BAMContactRole__c>());
                role = BAMTestUtility.createTestContactRole(contactApp.Id, roles[0].Id); // <-- Admin role
                contactRoles.add(role);
                contactApplicationsRoleMap.get(contactApp.Id).add(role);

                // create a contact role for the second app linked to this contact
                contactApp = contactsApplicationsMap.get(con.Id)[i+1];
                contactApplicationsRoleMap.put(contactApp.Id, new List<BAMContactRole__c>());
                role = BAMTestUtility.createTestContactRole(contactApp.Id, roles[1].Id); // <-- Admin role
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

        /******************************************************************************************
         * DEFINE GROUPS FOR THE FIRST ACCOUNT ONLY TO ENSURE GROUP DATA IS SURFACED IN API
         *******************************************************************************************/
        List<Billing_Account__c> groupBillingAccounts = TestDataProvider.createBillingAccount('', 2, new List<Account>{accounts[0]});
        groupBillingAccounts[0].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        groupBillingAccounts[0].LEGACY_ID__c = '432256';
        groupBillingAccounts[1].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        groupBillingAccounts[1].LEGACY_ID__c = '982364';
        insert groupBillingAccounts;

        // create a group only for the first account
        BAMGroup__c grp = BAMTestUtility.createTestGroup(accounts[0].Id);
        insert grp;

        List<BAMGroupBillingAccount__c> groupBillingAccountsLink = new List<BAMGroupBillingAccount__c>{
                new BAMGroupBillingAccount__c(Group__c = grp.Id, BillingAccount__c = groupBillingAccounts[0].Id),
                new BAMGroupBillingAccount__c(Group__c = grp.Id, BillingAccount__c = groupBillingAccounts[1].Id)
        };
        insert groupBillingAccountsLink;

        List<BAMLinkedEntity__c> groupLinkedEntities = new List<BAMLinkedEntity__c>{
                new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, Group__c = grp.Id, Status__c = 'Active'),
                new BAMLinkedEntity__c(ContactRole__c = contactRoles[1].Id, Group__c = grp.Id, Status__c = 'Active')
        };
        insert groupLinkedEntities;
    }

    /**
     * Scenario:
     * Ensure all rules are surfaced for Auth rule query
     */
    public static testMethod void testAuthRulesSuccess() {

        // this query is linked to C1230 which is linked to accounts[0] in test setup
        BAMContactRole__c contactRole = [Select ContactApplication__r.Id, ApplicationRole__r.Role__c, ContactApplication__r.Contact__c, ContactApplication__r.Contact__r.AccountId,
                                                (Select BillingAccount__r.Name, BillingAccount__r.Id, BillingAccount__r.LEGACY_ID__c, BillingAccount__r.Organisation__c, BillingAccount__r.MLID__c,
                                                        BillingAccount__r.Source_System__c, Group__c
                                                    From LinkedEntities__r
                                                    Where Status__c = 'Active')
                                            From BAMContactRole__c
                                            Where ContactApplication__r.Application__r.AppKey__c = 'BSP'
                                            And ContactApplication__r.Contact__r.OID_ID__c = 'C1230'
                                            And ContactApplication__r.Status__c = 'Active'
                                            And Status__c = 'Active'];

        List<Id> billingAccountIds = new List<Id>();

        // grab the billing accounts from the only group that should exists againt the org from the query above
        // this should return exactly 2 results
        BAMGroup__c grp = [Select Id, (Select BillingAccount__c From GroupBillingAccounts__r) From BAMGroup__c Where Organisation__c = :contactRole.ContactApplication__r.Contact__r.AccountId];
        for(BAMGroupBillingAccount__c grpBillingAccount : grp.GroupBillingAccounts__r) {
            billingAccountIds.add(grpBillingAccount.BillingAccount__c);
        }

        // these billing accounts should exist in the response from the API
        // this should return exactly 2 results
        for(BAMLinkedEntity__c linkedEntity : contactRole.LinkedEntities__r) {
            billingAccountIds.add(linkedEntity.BillingAccount__c);
        }

        Test.startTest();

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/api/2.0/authorisation/C1230/PS';
        request.httpMethod = 'GET';

        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        ResourceApiController.query();

        Test.stopTest();

        System.debug('Response Body: ' + response.responseBody.toString());

        System.assertEquals(200, response.statusCode);

        Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.debug(jsonResponse);

        System.assertEquals(true, jsonResponse.get('success'));

        Map<String, Object> responseObj = (Map<String, Object>)jsonResponse.get('response');
        List<Object> rulesObj = (List<Object>)responseObj.get('rules');

        // only 1 Role of 'Admin'
        System.assertEquals(1, rulesObj.size());

        // make sure the appropriate billing accounts exist
        Map<String, Object> rules0 = (Map<String, Object>)rulesObj[0];
        List<Object> ruleBillingAccounts = (List<Object>)rules0.get('billingAccounts');
        List<Object> ruleGroups = (List<Object>)rules0.get('groups');
        Set<String> responseRuleBillingAccounts = new Set<String>{String.valueOf(ruleBillingAccounts[0]), String.valueOf(ruleBillingAccounts[1])};
        Set<String> responseRuleGroups = new Set<String>{String.valueOf(ruleGroups[0])};
        System.assertEquals(2, responseRuleBillingAccounts.size());
        System.assertEquals(1, responseRuleGroups.size());

        // should only be 1 org returned and it should match the org from the contactrole record
        List<Object> responseOrgs = (List<Object>)responseObj.get('organisation');
        Map<String, Object> org0 = (Map<String, Object>)responseOrgs[0];
        System.assertEquals(1, responseOrgs.size());
        System.assertEquals(contactRole.ContactApplication__r.Contact__r.AccountId, org0.get('organisationId'));

        // should only be 1 contact returned
        List<Object> responseContacts = (List<Object>)responseObj.get('contact');
        Map<String, Object> contact0 = (Map<String, Object>)responseContacts[0];
        System.assertEquals(1, responseContacts.size());
        System.assertEquals(contactRole.ContactApplication__r.Contact__c, contact0.get('contactId'));

        // should only be 1 group returned
        List<Object> responseGroups = (List<Object>)responseObj.get('groups');
        Map<String, Object> group0 = (Map<String, Object>)responseGroups[0];
        System.assertEquals(1, responseGroups.size());
        System.assertEquals(grp.Id, group0.get('groupId'));

        // check that 4 billing accounts were returned (2 from the BillingAccount__c linked entities and 2 from the Group__c linked in linked entities)
        List<Object> responseBillingAccounts = (List<Object>)responseObj.get('billingAccounts');
        Set<String> responseBillingAccountIdList = new Set<String>();
        for(Object responseBillingAccount : responseBillingAccounts) {
            Map<String, Object> billingAccountObj = (Map<String, Object>)responseBillingAccount;
            responseBillingAccountIdList.add(String.valueOf(billingAccountObj.get('billingAccountId')));
			//validate isBlocked attribute included in the billingAccountObj
			System.assertEquals(true, billingAccountObj.containsKey('isBlocked'), 'Expected isBlocked attribute is included for the billing account');
        }

        System.assertEquals(4, responseBillingAccountIdList.size());
        System.assert(responseBillingAccountIdList.contains(String.valueOf(billingAccountIds[0])));
        System.assert(responseBillingAccountIdList.contains(String.valueOf(billingAccountIds[1])));
        System.assert(responseBillingAccountIdList.contains(String.valueOf(billingAccountIds[2])));
        System.assert(responseBillingAccountIdList.contains(String.valueOf(billingAccountIds[3])));
    }

    /**
     * Scenario:
     * Ensure no results are returned if rules exists but there are no assets to show that the application is activated for a particular org.
     */
    public static testMethod void testAuthRulesExistingWithoutActiveAsset() {

        Test.startTest();

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/api/2.0/authorisation/C1231/BSP';
        request.httpMethod = 'GET';

        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        ResourceApiController.query();

        Test.stopTest();

        System.debug('Response Body: ' + response.responseBody.toString());

        System.assertEquals(404, response.statusCode);
    }
}