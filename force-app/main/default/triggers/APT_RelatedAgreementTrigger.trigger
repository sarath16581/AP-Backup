/**

Created By: Garvita Rai 
Created Date:22nd Dec, 2015
Last Modified By:
Last Modified Date:
*/
trigger APT_RelatedAgreementTrigger on Apttus__APTS_Related_Agreement__c (after insert) {
    String result = APT_RelatedAgreementTriggerHandler.copyOperationalSchedule(trigger.new);
    if(result != APT_Constants.SUCCESS_LABEL){
        for(Apttus__APTS_Related_Agreement__c  relAgreement : trigger.new) {
            relAgreement.addError(result);
        }               
    }
}