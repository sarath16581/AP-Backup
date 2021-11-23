/*------------------------------------------------------------
Author:
Description:   Test Data factory for MembershipTriggerHandler_Test class

History
05/07/2018              Created constant class for Membership components
06/05/2020     Disha Kariya     Added record types for APLAC Membership
09/05/2020     Disha Kariya     Commented code as no more used
------------------------------------------------------------*/
@isTest
public class Membership_TestDataFactory {
        
//    public static List<Membership__c> createMembership(String stat, String licType, Account license,Contact member,Integer numOfTestMembership) {
//        List<Membership__c> memberships = new List<Membership__c>();
////        Map<String,Schema.RecordTypeInfo> membershipRecTypeMap = Schema.Sobjecttype.Membership__c.getRecordTypeInfosByName();
//        RecordType recType= RecordTypesSelector.newInstance().selectByDeveloperName('Membership__c', new Set<String>{Membership_constants.APLAC_RECORD_TYPE}).values()[0];
//        for(Integer i=0;i<numOfTestMembership;i++) {
//            Membership__c memberRec = new Membership__c(
//                Status__c = stat,
//                Member_Type__c='Sole Trader',
//                ABN__c = '12345678910',
//                Licensee_Type__c = licType,
//                WCC__c = '123456',
//                Contact__c = member.ID,
//                Account__c = license.ID,
//                Date_Signed__c = System.TODAY(),
//                APLAC_Welcome_Email_Sent__c = true,
//                RecordTypeId = recType.Id
//            );
//
//            memberships.add(memberRec);
//        }
//
//        return memberships;
//    }
//
//    public static List<Membership__c> updateMembershipStatusActive() {
//        List<Membership__c> membershipTestList = new List<Membership__c>([SELECT ID, Status__c from Membership__c where Status__c ='Pending']);
//        for(Membership__c member: membershipTestList) {
//            member.Status__c = 'Active';
//        }
//        update membershipTestList;
//        return membershipTestList;
//    }
    
}