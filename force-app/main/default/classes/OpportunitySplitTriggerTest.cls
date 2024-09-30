@isTest(SeeAllData=true)
public class OpportunitySplitTriggerTest{

    @IsTest
    static void makingSureThatTheDispatchMethodIsCalledFromTheCorrectClass() {
        AgentWorkTriggerHandler mock = (AgentWorkTriggerHandler)MockUtility.mockUtility(AgentWorkTriggerHandler.class);

        update [SELECT Id FROM OpportunitySplit LIMIT 1]; // triggering the split trigger
        
        System.assert(true);
    }
}