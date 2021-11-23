/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 31/03/2017
  * @description  : Helper for network response trigger to update the case based on user inputs.
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    23.02.18     kalpita.talwadekar@auspost.com.au            updated code for case field update notifications MW0002003
    07.06.18     kalpita.talwadekar@auspost.com.au            updated code for coding standard follow - TDO-239
    23.03.20     saiswetha.pingali@auspost.com.au             REQ1978199 - Fix to set 'Resolution Result' when case is closed with a network response.
    22.03.21     suman.gunaganti@auspost.com.au               MW0004436 - Updated to skip case automation conditionally 
    
*******************************  History ************************************************/
public class NetworkResponseTriggerHelper {

    /**
      * @name       : manageResponses
      * @desciption : Method will look at CaseAction__c field on the response and decide what update needs to happen on the case
      * @param      : List<Network_Response__c> nwResList
      * @return     : NA
      *
      */
    public static void manageResponses( List<Network_Response__c> nwResList ) {
        try {
            List<Case> casesToUpdate = new List<Case>();

            //loop through all network responses
            for(Network_Response__c nRes: nwResList ) {
                
                //Skips case automation 
                if(nRes.SuppressCaseAutomation__c)
                    continue;
                //for cases that are still under investigation
                if('On hold'.equalsIgnoreCase(nRes.CaseAction__c )) {
                    //no status and ownership update on the case, as network user is still working on the case. Just note the current comments on the case
                    casesToUpdate.add(new Case(Id = nRes.RelatedCase__c,NetworkComments__c = nRes.Network_Comments__c));

                } else if('Close'.equalsIgnoreCase(nRes.CaseAction__c ) || 'Closed'.equalsIgnoreCase(nRes.CaseAction__c ) &&
                        nRes.isClosedByNetwork__c) { //for cases that are closed by network users once responded
                    //update the case status to closed and capture the network response
                    casesToUpdate.add(new Case(Id = nRes.RelatedCase__c,NetworkComments__c = nRes.Network_Comments__c,ResolutionCode__c = 'MyNetwork Resolution',Resolution_Result__c='Delivered as Addressed',
                            Status = 'Closed',AllocateToQueue__c = true, Root_cause__c = nRes.R_Root_cause__c));

                } else if('Close'.equalsIgnoreCase(nRes.CaseAction__c ) || 'Closed'.equalsIgnoreCase(nRes.CaseAction__c ) &&
                        !nRes.isClosedByNetwork__c) { //for cases that are closed before the network user responds (either Feedback cases or any tracking update etc.)
                    //update the case to capture the network response and let routing table send to the right SSSW Queue
                    casesToUpdate.add(new Case(Id = nRes.RelatedCase__c,NetworkComments__c = nRes.Network_Comments__c,
                            AllocateToQueue__c = true, Root_cause__c = nRes.R_Root_cause__c));

                } else if('Network Responded'.equalsIgnoreCase(nRes.CaseAction__c )) { //for cases responded by network users
                    //update the case to capture the network response and let routing table send to the right SSSW Queue
                    casesToUpdate.add(new Case(Id = nRes.RelatedCase__c, NetworkComments__c = nRes.Network_Comments__c,
                            Status = 'Network Responded', AllocateToQueue__c = true, Root_cause__c = nRes.R_Root_cause__c));

                } else if('CCC to review'.equalsIgnoreCase(nRes.CaseAction__c )) { // for cases that need further information from CCC users
                    //update the case to capture the network response and let routing table send to the right SSSW Queue
                    casesToUpdate.add(new Case(Id = nRes.RelatedCase__c, NetworkComments__c = nRes.Network_Comments__c,Status = 'Network Responded',
                            AllocateToQueue__c = true, Root_cause__c = nRes.R_Root_cause__c, ResolutionCode__c = '',
                            Permanent_Close__c=false, Resolution_Result__c = ''));

                }

            }
            // if case list is not empty, update the records
            if(!casesToUpdate.isEmpty()) {
                database.update(casesToUpdate);
            }
        }
        catch(Exception exp) { // exception block to capture unhandled exception if any
            //Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW',
                    'NetworkResponseTriggerHelper', 'manageResponses', null, LoggingLevel.ERROR);
        }
    }

}