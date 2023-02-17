/***
 * @author George Nguyen
 * @domain Core
 * @description Test class for AgentWorkTriggerHandler 
 * @changelog
 * 2023-02-16 - George Nguyen - this class was created a long time ago. I have refactor it to use our framework. 
 */
@IsTest
public class AgentWorkTriggerHandlerTest {

	@IsTest
	private static void main() {

		AgentWorkTriggerHandler handler = new AgentWorkTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(AgentWork.SObjectType, handler.getSObjectType(), 'Expected the correct sobject type');
		System.assertNotEquals(null, AgentWorkTriggerHandler.getUnitOfWorkSObjectTypes(), 'Expected valid list of sobject types to be returned');
	}
    
}