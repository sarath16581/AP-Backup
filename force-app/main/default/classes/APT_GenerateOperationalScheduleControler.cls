/*
* Created by Apttus
* generates attachment document based on given parameters
* parentId : Parent Object ID. 
* templateName : name of Template used for creating the document
* docFormat : Format of document (DOC, DOCX, PDF, RTF) Default Format will be PDF
* Access to the given Attachment will be Full Access
* 09-11-2020 saiswetha.pingali@auspost.com.au INC1620158 Updated API version from URL_SERVICES_SOAP to services_Soap_u_38_0
*/
public with sharing class APT_GenerateOperationalScheduleControler {
    
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
    public APT_GenerateOperationalScheduleControler(){
        
        //set default parameters
        
        //templateId = 'a4yO00000000StI';
        //templateName = 'Jivi Test';
        pLevel = APT_Constants.ACCESS_LEVEL_EDIT;
        docFormat = APT_Constants.DOCUMENT_TYPE_PDF;
        isDraft = false;
        sessionId = UserInfo.getSessionId();
        //spingali - updated API version from URL_SERVICES_SOA to services_Soap_u_38_0
        serverUrl = URL.getSalesforceBaseUrl().toExternalForm() + APT_Constants.services_Soap_u_38_0 + UserInfo.getOrganizationId();
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
                attachmentId = Apttus.MergeWebService.generateDoc2(templateId, parentObjectId, pLevel, docFormat, 
                                                                isDraft, sessionId, serverUrl);
            }
                    
            //Redirects to newly created attachment page
            if(String.IsNotBlank(attachmentId)) {
                pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH  + attachmentId);
                pageRef.setRedirect(true);
            }    
            
        } Catch (Exception ex){
            
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,APT_Constants.ERROR_PREFIX + ex.getMessage()));
        }
        return pageRef;
    }
    
    /*
    * This method page input parameters and pass them to controller variables
    */
    private void getAPIParametersFromPageURL(){
        
        //Target object ID
        if(String.IsNotBlank(Apexpages.currentPage().getParameters().get(APT_Constants.URL_PARENTID))){
            parentObjectId = Apexpages.currentPage().getParameters().get(APT_Constants.URL_PARENTID);
        }
        
        //Getting Template ID
        List<Apttus__APTS_Template__c> templateList = new List<Apttus__APTS_Template__c>();
        if(String.IsNotBlank(Apexpages.currentPage().getParameters().get(APT_Constants.URL_TEMPLATENAME))){
            templateName = Apexpages.currentPage().getParameters().get(APT_Constants.URL_TEMPLATENAME);
            
            templateList = [select id from Apttus__APTS_Template__c where name like : templateName and Apttus__IsActive__c = true];
            
            if(templateList.size() > 0){
                templateId = templateList[0].id;
            }
        }
        
        
        
        if(String.IsNotBlank(Apexpages.currentPage().getParameters().get(APT_Constants.URL_TEMPLATEID))){
            templateId = Apexpages.currentPage().getParameters().get(APT_Constants.URL_TEMPLATEID);
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