/**
 * 2018-07-12 - nathan.franklin@auspost.com.au :   Commented unused code out
 */
@isTest
private class FacilityDetail_Test {
    // test method for FacilityDetail

    static testMethod void FacilityDetailTest() {
        Network__c facility = new Network__c(Name='Test');
        insert facility;
        FacilityDetail cnt = new FacilityDetail();
        cnt.setId_Name(facility.Id + ',Business_Hub_3');
        String idName = cnt.getId_Name();
        cnt.getFields();
    }
}