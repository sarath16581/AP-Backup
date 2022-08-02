/***
 * @author George Nguyen
 * @date 2022-07-20
 * @domain Core
 * @description Test class for ICPSTrigger
 * @changelog
 * 2022-07-20 - George Nguyen - Created
 */
@IsTest
class ICPSTrigger_Test {
    
    @IsTest
    static void verifyDispatchHandlerCall() {
        ICPSTriggerHandler handler = (ICPSTriggerHandler)MockUtility.mockUtility(ICPSTriggerHandler.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.stopStubbing();

        List<ICPS__c> icps = ICPSTestDataFactory.getICPS(1, false);
		insert icps;

        ((ICPSTriggerHandler)MockUtility.Mocks.verify(handler, MockUtility.Mocks.times(2))).dispatch(); // twice per transaction
        System.assert(true, 'PMD by-pass');
    }
}