/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : Main handler trigger for Membership Object
* @test : MembershipContactTrigger_Test
* @changelog :
*/

trigger MembershipContactTrigger on MembershipContact__c (before insert,before update,before delete,
                                    after insert,after update,after delete,after undelete) {
		if(!TriggerHelper.isTriggerDisabled(String.valueOf(MembershipContact__c.sObjectType))) {     // verify if triggers are disabled
        // domain based trigger dispatch
		(new MembershipContactTriggerHandler()).dispatch();
    }
}