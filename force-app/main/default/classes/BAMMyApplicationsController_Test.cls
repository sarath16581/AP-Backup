@isTest
public class BAMMyApplicationsController_Test {
    @isTest
    private static void test_retrieveCurrentUserContactApplications() {
        //Create test data
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        // get app Id
        Id appId = recordIdMap.get('app');
        BAMApplication__c app = [SELECT Id, Name, AppKey__c FROM BAMApplication__c WHERE Id =: appId];
        // Get portal user Id
        Id businessPortalUserId = recordIdMap.get('User');
        User businessPortalUser = [SELECT Id FROM User WHERE Id =: businessPortalUserId];
        System.runAs(businessPortalUser) {
            String conAppJSON = BAMMyApplicationsController.retrieveCurrentUserContactApplications();
            List<BAMMyApplicationsController.ApplicationWrapper> wrappers = (List<BAMMyApplicationsController.ApplicationWrapper>) JSON.deserialize(conAppJSON, List<BAMMyApplicationsController.ApplicationWrapper>.class);
            System.assertEquals(1, wrappers.size());
            System.assertEquals(app.Name, wrappers[0].applicationName);
            System.assertEquals(app.AppKey__c, wrappers[0].applicationKey);
            System.assert(wrappers[0].isActive);
        }
    }

    @isTest 
    private static void test_retrieveUserContactInfo() {
        Map<String,Id> recordIdMap = BAMTestUtility.createBamBasicRecords();
        // get org oid 
        Id orgId = recordIdMap.get('acc');
        //Get contact Id
        Id contactId = recordIdMap.get('con'); 
        //Get contact role Id
        Id conRoleId = recordIdMap.get('conrole'); 
        // Get portal user Id
        Id businessPortalUserId = recordIdMap.get('User');
        User businessPortalUser = [SELECT Id FROM User WHERE Id =: businessPortalUserId];
        Contact con = [SELECT Id, Name FROM Contact WHERE Id =: contactId];
        System.runAs(businessPortalUser) {
            String conJSON = BAMMyApplicationsController.retrieveUserContactInfo();
            Contact userConInfo = (Contact) JSON.deserialize(conJSON, Contact.class);
            System.assertEquals(con.Name, userConInfo.Name);
        }
    }
}