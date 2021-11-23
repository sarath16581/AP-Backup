/**
    Created By - Mausam Padhiyar
    Created Date - 13th Mar, 2016
    Last Modified By -
    Last Modified Date - 
**/
public with sharing class APT_ViewAttachmentController {

    public String lineitemID;
    public ID AttachmentID {get; set;}
    /**
        Constructor
    **/
    public APT_ViewAttachmentController(ApexPages.StandardController controller) {

    }

    /**
        constructor used in APT_ViewAttachmentController_Test class
    **/
    public APT_ViewAttachmentController() {
    
    }
    
    /**
        This method will used for redirect
    **/
    public PageReference redirect(){
        try {
            lineitemID = apexpages.currentpage().getparameters().get(APT_Constants.PARAM_ID);
            List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE ParentId = :lineitemID ORDER BY LastModifiedDate DESC LIMIT 1];
            
            if(attachments != null && attachments.size() > 0) {
                AttachmentID = attachments[0].Id;
    
                PageReference pageRef = new PageReference(APT_Constants.SERVLET_TAG+AttachmentID);
                pageRef.setredirect(true); 
                return pageRef;
            } else {
                PageReference pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH+lineitemID);
                pageRef.setredirect(true); 
                return pageRef;
            }  
        }  catch(Exception ex) {          
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }
}