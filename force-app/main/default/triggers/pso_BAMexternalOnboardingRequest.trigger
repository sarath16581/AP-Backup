/**
 * Created by hasantha on 14/8/19.
 * shashwat.a.nath@accenture.com added before Insert Event
 */

trigger pso_BAMexternalOnboardingRequest on BAMExternalOnboardingRequest__c (before insert, after insert, after update) {
    pso_OnboardingRequestTriggerHandler.execute();
}