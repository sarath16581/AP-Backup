/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 31/03/2017
  * @description  : Trigger for network response object
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    
*******************************  History ************************************************/
trigger NetworkResponseTrigger on Network_Response__c (after insert, after update) {

    NetworkResponseTriggerHandler.execute();
    
}