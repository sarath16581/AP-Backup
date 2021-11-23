/**
  * @author       : jerry.huang@salesforce.com
  * @date         : 17/12/2015
  * @description  : Trigger on Proof of Delivery object to call the Handler class to perform necessary action
  */
trigger ProofOfDeliveryTrigger on Proof_of_Delivery__c (after insert) {


    System.debug('####################################### Proof Of Delivery trigger: ' + SystemSettings__c.getInstance().Disable_Triggers__c + '#######################################');

    if (!SystemSettings__c.getInstance().Disable_Triggers__c)
    {
        if(trigger.isInsert){
            if(trigger.isBefore){
                System.debug('####################################### isInsert & isBefore #####################################');
                //doSomething();
            }
            if(trigger.isAfter){
                System.debug('####################################### isInsert & isAfter #####################################');
                //ProofOfDeliveryUtil.createSignatureAttachments(trigger.new);
                ProofOfDeliveryUtil.createSignatureAttachments(Trigger.newMap);
            }
        }
    }
}