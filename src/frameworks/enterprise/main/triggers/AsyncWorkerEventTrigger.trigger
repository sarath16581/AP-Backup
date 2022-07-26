/***
 * @description Platform Event trigger exclusive async workers (a part of the unit of work framework)
 *              This passed work off to our handler that is responsible to spaning a queueable for each of these events
 *
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Core
 * @test ApplicationUnitOfWorkAsyncEvent_Test, ApplicationUnitOfWork_Test, ApplicationUnitOfWorkBase_Test
 * @changelog
 */
trigger AsyncWorkerEventTrigger on AsyncWorkerEvent__e (after insert) {
	// check the kill switch if there is a catastrophic failure
	if(!SystemSettings__c.getInstance().DisableUOWExclusiveAsyncEvents__c) {
		ApplicationUnitOfWorkAsyncEventHandler.getInstance().dispatch(Trigger.new);
	}
}