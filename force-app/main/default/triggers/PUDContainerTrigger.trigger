/*****************************************************************************************
@description:   Trigger for Container object
@author: Dattaraj Deshmukh
History:
-----------------------------------------------------------------------------------------
23/06/2022      created     dattaraj.deshmukh@slalom.com      Added a trigger handler framework.

*****************************************************************************************/

trigger PUDContainerTrigger on PUD_Container__c (after update, after insert) {
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(PUD_Container__c.SObjectType))) {
		(new PUDContainerTriggerHandler()).dispatch();
	}
    
}