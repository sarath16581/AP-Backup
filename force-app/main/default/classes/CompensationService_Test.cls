/***
 * @author Hasantha Liyanage
 * @date 2023-07-25
 * @domain Core
 * @description Test class for CompensationService
 * @changelog
 * 2023-07-25 - Hasantha Liyanage - Created
 */
@IsTest
private class CompensationService_Test {

    @IsTest
    static void updateCurrentArticleInfoOnCompensationRecord() {
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);

        CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{
                cases[0].Id => cases[0]
        });
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        CompensationService.getInstance().updateCurrentArticleInfoOnCompensationRecord(compensations);
        Test.stopTest();
        System.assertEquals(
                'REF0001',
                compensations[0].CurrentArticleId__c,
                'updateCurrentArticleInfoOnCompensationRecord : Current Article field should be updated'
        );
    }

    @IsTest
    static void approveCompensationRecord() {
        List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
        String recordTypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByName().get('EFT').getRecordTypeId();
        List<Compensation__c> compensations = ApplicationTestDataFactory.getCompensation(1, cases[0].Id, recordTypeId, true);
        Compensation__c compensation = compensations[0];
        compensation.Status__c = 'APPROVED';
        Compensation__c oldCompensation = compensation.clone(true, true, false, false);
        oldCompensation.Status__c = 'PENDING';
        oldCompensation.Approved__c = false;
        Map<Id, Compensation__c> existingRecords = new Map<Id, Compensation__c>{
                oldCompensation.Id => oldCompensation
        };

        Test.startTest();
        CompensationService.getInstance().approveCompensationRecord(compensations, existingRecords);
        Test.stopTest();
        System.assertEquals(
                true,
                compensations[0].Approved__c,
                'approveCompensationRecord : Approved field should be marked true'
        );
    }
}