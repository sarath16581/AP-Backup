/**************************************************
Description: Generate Document Using Terms & Condition Template
History:
2016-07-12 Sagar Jogi Created
2019-05-31 anshul.goyal@auspost.com.au Modified | 31052019 |
**************************************************/

public with sharing class APT_GenerateDocForTermsANDCondition {
    
    private static Id templateId;
    private static String templateName;
    private static Id parentObjectId;
    private static String pLevel;
    private static String docFormat;
    private static Boolean isDraft;
    private static String sessionId;
    private static String serverUrl;
        
    /**
        Constructor
    **/    
    public APT_GenerateDocForTermsANDCondition (){

        pLevel = APT_Constants.ACCESS_LEVEL_EDIT;
        isDraft = false;
        sessionId = UserInfo.getSessionId();
//        serverUrl = URL.getSalesforceBaseUrl().toExternalForm() + APT_Constants.URL_SERVICES_SOAP + UserInfo.getOrganizationId();
        serverUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/38.0/' + UserInfo.getOrganizationId();
    }

    /*
    * This method creates document based on the page parameters
    */
    public PageReference generate(){
        
        PageReference pageRef = null;
        try{
            
            getAPIParametersFromPageURL();
            String attachmentId;
            
            if(System.Test.isRunningTest()){
                
                attachmentId = [SELECT Id FROM Attachment LIMIT 1].Id;
            } else {
                attachmentId = Apttus_Proposal.MergeWebService.generateDoc2(templateId, parentObjectId, pLevel, docFormat, 
                                                                isDraft, sessionId, serverUrl);
            }
                    
            //Redirects to newly created attachment page
            if(String.IsNotBlank(attachmentId)) {
                pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH  + parentObjectId);
                pageRef.setRedirect(true);
            }    
            
        } Catch (Exception ex){
            
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,APT_Constants.ERROR_PREFIX + ex.getMessage()));
        }
        return pageRef;
    }
    
    /**
        This method page input parameters and pass them to controller variables
    **/
    private void getAPIParametersFromPageURL(){
        
        //Target object ID
        if(String.IsNotBlank(Apexpages.currentPage().getParameters().get(APT_Constants.URL_PARENTID))){
            parentObjectId = Apexpages.currentPage().getParameters().get(APT_Constants.URL_PARENTID);
            system.debug('checkparent'+parentObjectId);
        }

        //31052019-get the Exempted_Product_Type__c flag from the proposal record which is set for the prod types(startrack operations and workforce verification)
        //query the current proposal record
        String prodType='';
        prodType= [SELECT Id,Exempted_Product_Type__c FROM Apttus_Proposal__Proposal__c WHERE Id=:parentObjectId].Exempted_Product_Type__c;

        Set <String> prodTypeForT_CSet = new  Set <String>();
        Map <String,String> prodTypeToTemplateName= new Map <String,String> ();
        //31052019-query the custom metadata records for the exempted prod types and prepare product ype to T& c flag set and Prod type to T7C template name
        for(R2T_Exempted_Proposal_Settings__mdt rec:  [SELECT MasterLabel, QualifiedApiName,APT_Terms_Condition_Template__c FROM R2T_Exempted_Proposal_Settings__mdt WHERE Is_T_C_Enabled__c=true]){
            prodTypeForT_CSet.add(rec.MasterLabel.toLowerCase());
            if(String.isNotBlank(rec.APT_Terms_Condition_Template__c)){
                prodTypeToTemplateName.put(rec.MasterLabel,rec.APT_Terms_Condition_Template__c);
            }
        }


        List<Apttus__APTS_Template__c> templateList = new List<Apttus__APTS_Template__c>();


        if(String.isNotBlank(prodType)&& prodTypeForT_CSet.contains(prodType.toLowercase())){
            templateName = prodTypeToTemplateName.get(prodType);
        }

        else{

            //Getting Template ID
            APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();

            if(r2tSystemProperty != null &&  !String.isEmpty(r2tSystemProperty.APT_Terms_Condition_Template__c)) {

                templateName = r2tSystemProperty.APT_Terms_Condition_Template__c;
            }

        }

        templateList = [select id from Apttus__APTS_Template__c where (name like : templateName OR id =:templateName) and Apttus__IsActive__c = true];
        system.debug('checktemplatesize'+templateList.size());
        if(templateList.size() > 0){
            templateId = templateList[0].id;
            system.debug('checktemplate'+templateId);
        }

        system.Debug('--->' + templateId);

        //Document Format Type
        //Checks if given format is valid format else returns default PDF format
        if(String.IsNotBlank(Apexpages.currentPage().getParameters().get(APT_Constants.URL_DOC_FORMAT))){
            String documentFormat = Apexpages.currentPage().getParameters().get(APT_Constants.URL_DOC_FORMAT);
            if(documentFormat.toLowerCase().equalsIgnoreCase(APT_Constants.DOCUMENT_TYPE_DOC) ||
                    documentFormat.toLowerCase().equalsIgnoreCase(APT_Constants.DOCUMENT_TYPE_DOCX) ||
                    documentFormat.toLowerCase().equalsIgnoreCase(APT_Constants.DOCUMENT_TYPE_PDF) ||
                    documentFormat.toLowerCase().equalsIgnoreCase(APT_Constants.DOCUMENT_TYPE_RTF)){
                docFormat = documentFormat;
            }
        }

        

    }
}