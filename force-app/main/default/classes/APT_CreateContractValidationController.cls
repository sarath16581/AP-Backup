/* Created by: Adrian Recio
 * Description: Main controller for APT_CreateContractValidation page
 * Date: 17/08/2017
 * 2021-10-28 Sautul Mehta - CI-96 Changes for APPC Contract Template Document Generation.
 * 2022-06-03 - Seth Heang - Hot Fix for validateDOVPresent not executing, bring validateDOVPresent into class constructor
 * 2022-07-19 - Talib Raza - REQ2862281: Condition added for 'DoV From ST Revision' in validateDOVPresent
*/
public with sharing class APT_CreateContractValidationController {
    public Boolean IsError{get; set;}
    public String apConId;
    public Apttus__APTS_Agreement__c apConVar;
    public Boolean IsAPPC {get;set;}
    public Integer appcCount {get;set;}
    
    public APT_CreateContractValidationController(){
        IsError = false;
        apConId = ApexPages.currentPage().getParameters().get('Id');
        appcCount = Integer.valueOf(ApexPages.currentPage().getParameters().get('count'));
        apConVar = [SELECT Id, APT_Contract_Type__c, APT_Is_Create_Contract_Batch_Job_Running__c, APT_APPC_Count__c,Contract_Expiration_Date__c, (Select Id from DoV_Languages__r) FROM Apttus__APTS_Agreement__c WHERE Id = :apConId]; 
        validateDOVPresent(apConVar); // Call DOV validation
        validateExpDate(apConVar); //validate expdate
    }
    
    /**
    * Generate the document for APPC product. 
    * Once the user clicks on the Create Contract button this controller and method will be called for APPC
    * For other products, we have another layer of page which will give the options to be selected for template
    * which is skipped for APPC product
    */
    public PageReference generateAPPCContractDocument(){    
        
        
        if(apConVar.APT_APPC_Count__c > 0){
            IsAPPC = true;   

            apConVar.APT_Is_Create_Contract_Batch_Job_Running__c = true;
            update apConVar;
        }
        
        List<id> listTemplateId = new List<id>();
        for(Apttus__APTS_Template__c a : [select id from Apttus__APTS_Template__c where name = :APT_Constants.R2T_APPC_CONTRACT]){               
            listTemplateId.add(a.id);
        }
        map<Id, String> templatepLevelMap = new map<Id, String>();
        map<Id, String> templateOutputFormatMap = new map<Id, String>();
        for(string templateId : listTemplateId){
            templatepLevelMap.put(templateId, APT_Constants.ACCESS_FULL);
            templateOutputFormatMap.put(templateId, APT_Constants.DOCUMENT_TYPE_PDF);
        } 
        Boolean mergeDocuments = false; 
        Boolean deleteGenDocs = false;
        createContract(apConId, listTemplateId, templatepLevelMap, templateOutputFormatMap, mergeDocuments, deleteGenDocs, UserInfo.getSessionId(), UserInfo.getOrganizationId());
        
        return new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + apConId);
        
    } 
    
    public void validateDOVPresent(Apttus__APTS_Agreement__c apConLocVar){
        // DOV is required before contract creation
        if(apConLocVar.DoV_Languages__r.size()==0 && (apConLocVar.APT_Contract_Type__c=='DoV Contract' || apConLocVar.APT_Contract_Type__c=='DoV From ST Revision')){
            IsError = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'DOV Language is required before contract creation.'));
        }
    }  
    
    public void validateExpDate(Apttus__APTS_Agreement__c apExpVar){
     
      if(apExpVar.Contract_Expiration_Date__c!=null&&apExpVar.Contract_Expiration_Date__c<system.today())
      {
       IsError = true;
       system.debug('show exception'+IsError);
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,APT_Constants.ERROR_MESSAGE_CANNOT_CREATE_CONTRACT));
      }
    
    }
    
    @future(callout=true)   
    public static void createContract(String idAgreement, list<Id> templateIdList, map<Id, String> templatepLevelMap, map<Id, String> templateOutputFormatMap, Boolean mergeDocuments, Boolean deleteGenDocs, string sessionId, string orgId){
        try{
            Apttus__ComplySystemProperties__c complySystemProperties = Apttus__ComplySystemProperties__c.getvalues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
                    
            String instanceURL = complySystemProperties.Apttus__InstanceUrl__c;
            String serverURL = instanceURL + APT_Constants.services_Soap_u_52_0  + orgId; //Merge server URL
                        
            if(!test.isRunningTest()) {
                Apttus.MergeWebService.generateDoc2(templateIdList[0], idAgreement, templatepLevelMap.get(templateIdList[0]), templateOutputFormatMap.get(templateIdList[0]), false, sessionId, serverURL);
            }
 
            Apttus__APTS_Agreement__c apConVar = new  Apttus__APTS_Agreement__c();
            apConVar.Id = idAgreement;
            apConVar.APT_Is_Create_Contract_Batch_Job_Running__c = false;
            update apConVar;

            set<String> setErrorMessages = new set<String>();
            APT_CreateContractUtility.sendEmailNotification(idAgreement, instanceURL, null, setErrorMessages);

        }
        catch(Exception ex){
            System.debug('APT_CreateContractValidationController.createContract() Exception: ' + ex.getMessage());
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'CPQ', 
                                                    APT_CreateContractValidationController.class.getName(), 'createContract', 
                                                    null, LoggingLevel.ERROR);
        }
    }
}