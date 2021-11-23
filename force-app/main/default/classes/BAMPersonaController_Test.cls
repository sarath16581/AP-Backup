/**
 * Created by Nathan on 2019-05-16.
 */
@isTest
public class BAMPersonaController_Test {
    public static Id bspProfileId = [Select Id From Profile Where Name = :BspConstants.BSP_COMMUNITY_PROFILE_NAME].Id;
	public static Id merchantPortalNetworkId = [Select Id From Network Where Name = 'Australia Post Merchant Portal'].Id;
    public static Id businessPortalProfileId = [Select Id From Profile Where Name = :BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME].Id;
	

    @testSetup
	public static void setup() {
		List<Account> accounts = TestDataProvider.createAccount('BAM Test Account', 2);
		insert accounts;

		// create custom setting
		AusPostSettings__c setting = new AusPostSettings__c();
		setting.Name = 'BAM_MERCHANT_PORTAL_ID';
		setting.ApplicationName__c = merchantPortalNetworkId;
		insert setting;

		List<Contact> contacts = new List<Contact>();
		for(Integer i=0;i<accounts.size();i++) {
			Contact con = TestDataProvider.createContact('Contact 1', accounts[i].Id, null);
			con.FirstName = 'Contact ' + i;
			con.LastName = 'Contact ' + i;
			con.Status__c = 'Active';
			contacts.add(con);
		}

		// set the cnumber of the contacts used for testing
		contacts[0].OID_ID__c = '12345'; // group 1
		contacts[1].OID_ID__c = '12345'; // group 1
		insert contacts;

		// connect associated users for some of the contacts only
		// we will use this as a part of our persona testing
		List<User> users = new List<User>();

		// contacts[0] is bsp community
		users.add(TestUtility.createPortalUser('Testing0', bspProfileId, contacts[0].Id));

		// contacts[1] is business portal community
		users.add(TestUtility.createPortalUser('Testing1', businessPortalProfileId, contacts[1].Id));
		insert users;

        // future to get around MIXED DML issues
		giveAllPortalAccess();
	
    }
    /**
	 * Assign all users to the business portal community using the specified permission set.
	 * This needs to be done in a future to avoid mixed dml operation error
	 */
	@future
	private static void giveAllPortalAccess() {
		Set<String> cNumbers = new Set<String>{'12345'};
		List<User> users = [Select Id From User Where Contact.OID_ID__c In :cNumbers];

		// add all users to the business portal permission set
		List<PermissionSetAssignment> businessPortalAssignments = new List<PermissionSetAssignment>();
		PermissionSet permissionSet = [Select Id From PermissionSet Where Name = 'Merchant_Portal_Access'];
		for(User us : users) {
			businessPortalAssignments.add(new PermissionSetAssignment(PermissionSetId = permissionSet.Id, AssigneeId = us.Id));
		}
		insert businessPortalAssignments;
	}

    @isTest
    static void test_getUserDetails(){
        User u = TestDataProvider.createTestUsers();
        insert u;
        System.runAs(u) {
            User user = BAMPersonaController.getUserDetails();
            System.assertEquals(u.Id, user.Id);
        }
    }
    @isTest
    static void test_getIdPInitUrl(){
        // create custom setting
        String dummyURL = '/dummy/url';
		AusPostSettings__c setting = new AusPostSettings__c();
		setting.Name = 'BAM-IdP-Init-Login';
		setting.URL__c = dummyURL;
		insert setting;
        
        String url = BAMPersonaController.getIdPInitUrl();
        System.assertEquals(dummyURL, url);
    }
    @isTest
    static void test_switchPersona(){
        User switchUser = [Select Id
								From User
								Where Contact.OID_ID__c = '12345'
								And IsActive = true
								And ProfileId = :businessPortalProfileId
								And Contact.FirstName = 'Contact 1'
								Limit 1];

         User user = [Select Id
								From User
								Where Contact.OID_ID__c = '12345'
								And IsActive = true
								And ProfileId = :bspProfileId
								And Contact.FirstName = 'Contact 0'
								Limit 1];

        System.runAs(user) {
            BAMPersonaController.currentNetworkId = merchantPortalNetworkId;
            // switch the federation id to the new persona the user wants to switch to.
            // Salesforce forces the use of federation id when using Login handlers, hence the need to set the handler
            BAMPersonaController.switchPersona(switchUser.Id);
        }

		// verify that the federation was updated successfully
		switchUser = [Select Id, FederationIdentifier From User Where Id = :switchUser.Id];
		System.assertNotEquals(null, switchUser.FederationIdentifier, 'The persona was not switched correctly.');
    }

    @isTest
    static void test_getCurrentUserPersonas(){
        List<BAMUserUtility.UserPersona> personas;
        BAMPersonaController.currentNetworkId = merchantPortalNetworkId;
		User u = [Select Id From User Where Contact.OID_ID__c = '12345' And IsActive = true And ProfileId = :businessPortalProfileId Limit 1];
		System.runAs(u) {

			Test.startTest();

			personas = BAMPersonaController.getCurrentUserPersonas();

			Test.stopTest();
			System.assertEquals(2, personas.size(), 'Incorrect Number of Personas Returned.');
		}
	}
}