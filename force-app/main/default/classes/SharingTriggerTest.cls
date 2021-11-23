@isTest(seeAllData=true)
private class SharingTriggerTest {
    static testMethod void userTriggerTest() {

    }

    static testMethod void triggerTest() {
        Network__c testFacility = new Network__c(Name='test', Portal_Licenses__c = 99);
        insert testFacility;

        Network__c testFacility2 = new Network__c(Name='test2', Portal_Licenses__c = 99);
        insert testFacility2;

        List<Case> testCases = new List<Case>();
        testCases.add(new Case(Status='New', subject='test1', Network__c=testFacility.Id, Type='General Enquiry',ReopenDate__c=System.today()));
        testCases.add(new Case(Status='In Progress', subject='test2', Network__c=testFacility.Id, Type='General Enquiry',ReopenDate__c=System.today()));
        testCases.add(new Case(Status='On Hold', subject='test3', Network__c=testFacility.Id, Type='General Enquiry',ReopenDate__c=System.today().addDays(2)));
        insert testCases;

        Profile prof = [select id from Profile where Name = 'MyNetwork Portal' limit 1];

        List<User> users = [Select Id From User Where IsActive = true and ProfileId =: prof.Id limit 3];

        Facility_User__c facilityUser1 = new Facility_User__c(Network__c=testFacility.Id, User__c=users[0].Id);
        insert facilityUser1;
        Facility_User__c facilityUser2 = new Facility_User__c(Network__c=testFacility.Id, User__c=users[1].Id);
        insert facilityUser2;

        Facility_User__c facilityUser3 = new Facility_User__c(Network__c=testFacility2.Id, User__c=users[2].Id);
        insert facilityUser3;

        facilityUser1.User__c = null;
        update facilityUser1;

        facilityUser2.User__c = users[0].Id;
        update facilityUser2;

        facilityUser1.User__c = users[2].Id;
        update facilityUser1;

        facilityUser1.Network__c = null;
        update facilityUser1;

        facilityUser1.Network__c = testFacility.Id;
        update facilityUser1;

        facilityUser2.Network__c = testFacility2.Id;
        update facilityUser2;

        //testCases[0].Network__c = null;
        //update testCases[0];

        testCases[0].Network__c = testFacility2.Id;
        update testCases[0];

        //testCases[0].Network__c = testFacility.Id;
        //update testCases[0];
    }
}