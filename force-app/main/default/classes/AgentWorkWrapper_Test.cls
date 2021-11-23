@IsTest (IsParallel=true)
public class AgentWorkWrapper_Test {
    
    @IsTest
    public static void createWrapper(){
        Test.startTest();
        AgentWorkWrapper wrap = new AgentWorkWrapper();
        Test.stopTest();
        
		System.assert(wrap != null, 'AgentWorkWrapper initialised.');
    }
}