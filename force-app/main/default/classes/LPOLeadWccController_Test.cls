/* @author Mav3rik
 * @date 2020-10-27
 * @group Lead
 * @tag Lead
 * @domain Core
 * @description Test class for LPOLeadWccController
 * @changelog
 * 2020-10-27 - Mav3rik - Created
 */
@IsTest
public class LPOLeadWccController_Test {
    
    /**
     * Data Preparation for creating the User with a Network Org ID
     */
    static User createPartnerCommunityUser(String alias, String email, String username, String communityNickname, String networkOrgId) {
        // Create community user account
        Account acc = new Account(Name='TestP', OwnerId = UserInfo.getUserId());
        insert acc;

        // Create community user contact
        Contact communityUserContact = new Contact(
            FirstName = 'Test',
            LastName = 'P',
            AccountId = acc.Id,
            Email = email
        );
        insert communityUserContact;

        // Get user profile
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'LPO Partner Community User' LIMIT 1];
        // Create user
        User newUser = new User(
            Alias = alias, Email = email, 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_AU', ProfileId = userProfile.Id, 
            TimeZoneSidKey='Australia/Sydney', UserName = userName,
            CommunityNickname=communityNickname, EmployeeNumber='1234567',
            ContactId = communityUserContact.Id,
            Network__c = networkOrgId
        );
        insert newUser;
        return newUser;
    }

    /**
     * Test when the Lead is updated with the Network ID
     */
    @IsTest
    static void testUpdateWCCPositive() {
        String givenOrgId = '111111';
        User givenUser = createPartnerCommunityUser('testp', 'testp@example.com', 'testp@example.com', 'tester p', givenOrgId);
        List<Lead> givenLeads = new List<Lead>();
        Lead givenLead1 = new Lead();
        givenLead1.FirstName = 'John';
        givenLead1.LastName = 'Smith';
        givenLead1.Email = 'john.smith@example.com';
        givenLead1.Phone = '5554443332';
        givenLeads.add(givenLead1);

        Test.startTest();
        System.runAs(givenUser) {
            Network__c givenNetwork = new Network__c();
            givenNetwork.Org_Id__c = givenOrgId;
            insert givenNetwork;
            List<Lead> actualLeads = LPOLeadWccController.updateWCC(givenLeads);
            String actualNetworkId = actualLeads[0].LPO_WCC__c;
            System.assert(actualLeads.size() == 1, 'There should be 1 Lead processed');
            System.assertEquals(givenNetwork.Id, actualNetworkId, 'It should match the Network ID');
        }
        Test.stopTest();
    }

    /**
     * Test when multiple Leads are updated with the Network ID
     */
    @IsTest
    static void testUpdateWCCPositiveBulk() {
        String givenOrgId = '111111';
        User givenUser = createPartnerCommunityUser('testp', 'testp@example.com', 'testp@example.com', 'tester p', givenOrgId);
        List<Lead> givenLeads = new List<Lead>();
        Lead givenLead1 = new Lead();
        givenLead1.FirstName = 'John';
        givenLead1.LastName = 'Smith';
        givenLead1.Email = 'john.smith@example.com';
        givenLead1.Phone = '5554443332';
        givenLeads.add(givenLead1);
        Lead givenLead2 = new Lead();
        givenLead2.FirstName = 'Jane';
        givenLead2.LastName = 'Smith';
        givenLead2.Email = 'jane.smith@example.com';
        givenLead2.Phone = '1112223334';
        givenLeads.add(givenLead2);
        Lead givenLead3 = new Lead();
        givenLead3.FirstName = 'Kevin';
        givenLead3.LastName = 'Hart';
        givenLead3.Email = 'kevin.hart@example.com';
        givenLead3.Phone = '7778889996';
        givenLeads.add(givenLead3);

        Test.startTest();
        System.runAs(givenUser) {
            Network__c givenNetwork = new Network__c();
            givenNetwork.Org_Id__c = givenOrgId;
            insert givenNetwork;
            List<Lead> actualLeads = LPOLeadWccController.updateWCC(givenLeads);
            System.assert(actualLeads.size() == 3, 'There should be 3 Lead processed');
            for (Lead l : actualLeads) {
                System.assertEquals(givenNetwork.Id, l.LPO_WCC__c, 'It should match the Network ID');
            }
        }
        Test.stopTest();
    }

    /**
     * Test when the Lead is updated with the Network ID from the LeadTrigger
     */
    @IsTest
    static void testUpdateWCCPositiveTrigger() {
        String givenOrgId = '111111';
        User givenUser = createPartnerCommunityUser('testp', 'testp@example.com', 'testp@example.com', 'tester p', givenOrgId);

        Test.startTest();
        System.runAs(givenUser) {
            Network__c givenNetwork = new Network__c();
            givenNetwork.Org_Id__c = givenOrgId;
            insert givenNetwork;

            List<Lead> givenLeads = new List<Lead>();
            Lead givenLead1 = new Lead();
            givenLead1.FirstName = 'John';
            givenLead1.LastName = 'Smith';
            givenLead1.Email = 'john.smith@example.com';
            givenLead1.Phone = '5554443332';
            givenLeads.add(givenLead1);
            insert givenLeads;
            
            Lead actualLead = [SELECT Id, LPO_WCC__c FROM Lead WHERE Email =: givenLead1.Email LIMIT 1];
            String actualNetworkId = actualLead.LPO_WCC__c;
            System.assertEquals(givenNetwork.Id, actualNetworkId, 'It should match the Network ID');
        }
        Test.stopTest();
    }

    /**
     * Test when the Lead is not updated with the Network ID because the Network is unavailable
     */
    @IsTest
    static void testUpdateWCCNegativeNoNetwork() {
        String givenOrgId = '';
        User givenUser = createPartnerCommunityUser('testp', 'testp@example.com', 'testp@example.com', 'tester p', givenOrgId);
        List<Lead> givenLeads = new List<Lead>();
        Lead givenLead1 = new Lead();
        givenLead1.FirstName = 'John';
        givenLead1.LastName = 'Smith';
        givenLead1.Email = 'john.smith@example.com';
        givenLead1.Phone = '5554443332';
        givenLeads.add(givenLead1);

        Test.startTest();
        System.runAs(givenUser) {
            List<Lead> actualLeads = LPOLeadWccController.updateWCC(givenLeads);
            String actualNetworkId = actualLeads[0].LPO_WCC__c;
            System.assert(actualLeads.size() == 1, 'There should be 1 Lead processed');
            System.assertEquals(null, actualNetworkId, 'It should have a null Network ID');
        }
        Test.stopTest();
    }

    /**
     * Test when the Lead is not updated with the Network ID because the Network already exists
     */
    @IsTest
    static void testUpdateWCCNegativeNetworkAlreadyExists() {
        String givenOrgId = '111111';
        User givenUser = createPartnerCommunityUser('testp', 'testp@example.com', 'testp@example.com', 'tester p', givenOrgId);
        List<Lead> givenLeads = new List<Lead>();
        Lead givenLead1 = new Lead();
        givenLead1.FirstName = 'John';
        givenLead1.LastName = 'Smith';
        givenLead1.Email = 'john.smith@example.com';
        givenLead1.Phone = '5554443332';
        givenLeads.add(givenLead1);

        Test.startTest();
        System.runAs(givenUser) {
            Network__c givenNetwork = new Network__c();
            givenNetwork.Org_Id__c = givenOrgId;
            insert givenNetwork;
            // Assign network
            givenLeads[0].LPO_WCC__c = givenNetwork.Id;
            List<Lead> actualLeads = LPOLeadWccController.updateWCC(givenLeads);
            String actualNetworkId = actualLeads[0].LPO_WCC__c;
            System.assert(actualLeads.size() == 1, 'There should be 1 Lead processed');
            System.assertEquals(givenNetwork.Id, actualNetworkId, 'It should already have a Network ID');
        }
        Test.stopTest();
    }

    /**
     * Test when the updateWCC is null
     */
    @IsTest
    static void testUpdateWCCNull() {
        String givenOrgId = null;
        User givenUser = createPartnerCommunityUser('testp', 'testp@example.com', 'testp@example.com', 'tester p', givenOrgId);
        List<Lead> givenLeads = new List<Lead>();
        Lead givenLead1 = new Lead();
        givenLead1.FirstName = 'John';
        givenLead1.LastName = 'Smith';
        givenLead1.Email = 'john.smith@example.com';
        givenLead1.Phone = '5554443332';
        givenLeads.add(givenLead1);

        Test.startTest();
        System.runAs(givenUser) {
            Network__c givenNetwork = new Network__c();
            givenNetwork.Org_Id__c = givenOrgId;
            insert givenNetwork;
            List<Lead> actualLeads = LPOLeadWccController.updateWCC(givenLeads);
            String actualNetworkId = actualLeads[0].LPO_WCC__c;
            System.assert(actualLeads.size() == 1, 'There should be 1 Lead processed');
            System.assertEquals(null, actualNetworkId, 'It should have a null Network ID');
        }
        Test.stopTest();
    }

    /**
     * Test when the updateWCC is empty
     */
    @IsTest
    static void testUpdateWCCEmpty() {
        String givenOrgId = '';
        User givenUser = createPartnerCommunityUser('testp', 'testp@example.com', 'testp@example.com', 'tester p', givenOrgId);
        List<Lead> givenLeads = new List<Lead>();
        Lead givenLead1 = new Lead();
        givenLead1.FirstName = 'John';
        givenLead1.LastName = 'Smith';
        givenLead1.Email = 'john.smith@example.com';
        givenLead1.Phone = '5554443332';
        givenLeads.add(givenLead1);

        Test.startTest();
        System.runAs(givenUser) {
            Network__c givenNetwork = new Network__c();
            givenNetwork.Org_Id__c = givenOrgId;
            insert givenNetwork;
            List<Lead> actualLeads = LPOLeadWccController.updateWCC(givenLeads);
            String actualNetworkId = actualLeads[0].LPO_WCC__c;
            System.assert(actualLeads.size() == 1, 'There should be 1 Lead processed');
            System.assertEquals(null, actualNetworkId, 'It should have a null Network ID');
        }
        Test.stopTest();
    }

}