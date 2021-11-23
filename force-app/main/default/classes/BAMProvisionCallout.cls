/**************************************************
Description         :   
Function to trigger the provision and deprovision callout to Camunda
Inputs: Map with up to two payload strings - one for Provision, another for Deprovision for a contact
Output: none

Function will:
>for the contact passed in, and provision and deprovision payload on maps
>call the camunda provision and deprovision apis.

>If an error response is returned from either provision or deprovision:
>get all Pending EOR records for the contact
>if there are pending eor provision/deprovision records and a provision/deprovision error - then build list* to update eor records to fail. 
>pass list to handler to update the related External Onboarding Request records


History:
--------------------------------------------------
2019-05-31      ajudd@salesforce.com        Created
2019-08-12      ajudd@salesforce.com        Added BAM Record Type Id conditions
**************************************************/

public class BAMProvisionCallout {
	@future(callout=true)
    public static void processRequest(Id contactId, Map<String,String> payloadMap){
       
        Boolean bProvError = false;
        Boolean bDeprovError = false;
        Map<String,String> responseProvMap = new  Map<String,String>();
       
        //Get payload for each type  
        String sProvision = payloadMap.get(BAMProvision.FIELD_PROVISION);
        String sDeprovision = payloadMap.get(BAMProvision.FIELD_DEPROVISION);
        String sConApps = payloadMap.get('conapps');
        List<String> conAppIdList = sConApps.split(','); //put comma separated conapp ids into a list
        
        HttpResponse response;
        
        System.debug('sProvision ' + sProvision);
        //System.debug('sDeprovision ' + sDeprovision);
        System.debug('conAppIdList = ' + conAppIdList);
        
        String sProvErrorMessage;
        String sDeprovErrorMessage;
        
        if(sProvision != null){
            try{
                response = BAMIntegrationUtility.postRequest('BAM_PROVISION_REQUEST', sProvision);
                
                System.debug('BAMProvision::calloutToCamunda:response Status Code = ' + response.getStatusCode());
                System.debug('BAMProvision::calloutToCamunda:response Status = ' + response.getStatus());
                System.debug('BAMProvision::calloutToCamunda:response to string = ' + response.toString());
                System.debug('BAMProvision::calloutToCamunda:response Body = ' + response.getBody());
                
                //If '204' returned then request was successfully sent
                if(response.getStatusCode() == 204){
                    System.debug('Prov Success');
                }
                //Else camunda error returned - record to set against eor record
                else{
                    System.debug('Prov Camunda Error');
                    bProvError = true;
                    sProvErrorMessage = response.getStatus();
                }    
            }
            catch(Exception e){
                //System exception occured - record to set against eor record
            	System.debug('Prov System Error: ' + e);
                bProvError = true;
                sProvErrorMessage = 'System Error: ' + e;

                //Log error to Exception object for analysis
			    UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'BAM',
					    BAMProvisionCallout.class.getName(), 'processRequest-Provision',
					    'none', LoggingLevel.ERROR);

            }
        }
        
        if(sDeprovision != null){ 
            try{
                response = BAMIntegrationUtility.postRequest('BAM_DEPROVISION_REQUEST', sDeprovision);
                
                //If '204' returned then request was successfully sent
                if(response.getStatusCode() == 204){
                    System.debug('Deprov Success');
                }
                //Else camunda error returned - record to set against eor record
                else{
                    System.debug('Deprov Camunda Error');
                    bDeprovError = true;
                    sDeprovErrorMessage = response.getStatus();
                }    
            }
            catch(Exception e){
                //System exception occured - record to set against eor record
            	System.debug('Prov System Error: ' + e);
                bDeprovError = true;
                sDeprovErrorMessage = 'System Error: ' + e;

                //Log error to Exception object for analysis
			    UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'BAM',
					    BAMProvisionCallout.class.getName(), 'processRequest-Deprovision',
					    'none', LoggingLevel.ERROR);
            }
        }
        
        //If any error occured
        if(bProvError || bDeprovError){

            //Get external onboarding request BAM record type id
            Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;
            
            //Get latest Pending EOR records for contact applications being provisioned or deprovisioned
            List<BAMContactApplication__c> conappList = new List<BAMContactApplication__c>();
            conappList = [  SELECT Id, Application__r.AppKey__c, (SELECT Id, Type__c, Status__c 
                                    FROM BAM_External_Onboarding_Requests__r 
                                    WHERE Status__c = 'Pending' AND RecordTypeId = :bamExtObRTId 
                                    ORDER BY CreatedDate DESC LIMIT 1) 
                            FROM BAMContactApplication__c 
                            WHERE Id IN :conAppIdList];
            
            List<ExternalOnboardingEvent__e> eoeList = new List<ExternalOnboardingEvent__e>();
            //Loop through conapp with eor records to get details of eor records to update
            for(BAMContactApplication__c conapp : conappList){
                
                //If there is a Pending EOR for the contact apps being prov or deprov
                if(!conapp.BAM_External_Onboarding_Requests__r.isEmpty()){
                    
                    for(BAMExternalOnboardingRequest__c  eor:conapp.BAM_External_Onboarding_Requests__r){
                        
                        //If Pending EOR is provision and provision error occured 
                        if(eor.Type__c == 'Provision' && bProvError){
                            //then add record to the External Onboarding Event (platform event) list to set to error state
                            ExternalOnboardingEvent__e eoeRec = new ExternalOnboardingEvent__e();
                            eoeRec.RequestNumber__c = eor.Id;
                            eoeRec.Status__c = 'error';
                            eoeRec.ResponseText__c = sProvErrorMessage;
                            eoeRec.IsBam__c = true;
                            eoeRec.Type__c = 'Provision';
                            eoeRec.Application__c = conapp.Application__r.AppKey__c;
                            eoeList.add(eoeRec);
                        }
                        
                        //If Pending EOR is deprovision and deprovision error occured 
                        if(eor.Type__c == 'Deprovision' && bDeprovError){
                            //then add record to the EOR event list to set to error state
                            ExternalOnboardingEvent__e eoeRec = new ExternalOnboardingEvent__e();
                            eoeRec.RequestNumber__c = eor.Id;
                            eoeRec.Status__c = 'error';
                            eoeRec.ResponseText__c = sDeprovErrorMessage;
                            eoeRec.IsBam__c = true;
                            eoeRec.Type__c = 'Deprovision';
                            eoeRec.Application__c = conapp.Application__r.AppKey__c;
                            eoeList.add(eoeRec);
                        }
                    }
                }//end if eor record
            }//end loop conapp
            
            //pass error details to event handler
            if(eoeList.size() > 0){ 
                BAMExternalOnboardingEventHandler.processBAMResponses(eoeList);
                System.debug('Pass these event details to event handler ' + eoeList);
            }
            
        }//end error occured
            
    }
    
}