public with sharing class ChasCustomCaseListAndDetailController {


    /**
* Description: Fetch all the cases in des order of modified date for the given Case
* */
    
    @AuraEnabled
    public static CaseComment[] fetchCaseComments( String caseId){ 
        System.debug('----- fetchCaseComments ----- START'); 
        
        CaseComment[] caseComments = null;
        try{
            caseComments = [SELECT Id, CommentBody, CreatedBy.FirstName, LastModifiedDate from CaseComment where parentId=:caseId ORDER BY LastModifiedDate DESC];
            System.debug('caseComments='+caseComments);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'Error occoured while fetching Csae comments for the Case ->'+caseId+' , the error is ==>'+ex);
        }
        System.debug('----- fetchCaseComments ----- END');
        return caseComments;
        
    }
    
    /**
* Description: Create/Insert the CaseComment under the given Case
* */  
    @AuraEnabled
    public static CaseComment creatCaseComment( String caseId, String caseCommentBody){ 
        System.debug('----- creatCaseComment ----- START'); 
        System.debug('caseId='+caseId+', caseCommentBody='+caseCommentBody);
        CaseComment caseComment = null;
        try{
            //String caseNumber = ChasUtil.createCaseComment(caseId, caseCommentBody);
            String caseCommentId = ChasUtil.createCaseCommentAndReturnId(caseId, caseCommentBody);
            System.debug('caseCommentId='+caseCommentId);
            if(caseCommentId !=null){
                caseComment = [SELECT Id, CommentBody, CreatedBy.FirstName, LastModifiedDate FROM CaseComment WHERE Id=:caseCommentId];// and ParentId=:caseId  ORDER BY LastModifiedDate DESC LIMIT 1];
                               //CommentBody=:caseCommentBody and ParentId=:caseId  ORDER BY LastModifiedDate DESC LIMIT 1];
            System.debug('inserted caseComment='+caseComment);
            }
            
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'Error occoured while fetching Csae comments for the Case ->'+caseId+' , the error is ==>'+ex);
        }
        System.debug('----- creatCaseComment ----- END');
        return caseComment;
        
    }
      /**
* Description: return current user name
* */   @AuraEnabled
    public static String getCurrentUserName(){
        //return UserInfo.getName();
        return UserInfo.getFirstName();
    }
         /**
* Description: Updating Case Status
* */ 
    @AuraEnabled 
    public static void UpdateCaseStatus(String caseId, String caseStatus){
        System.debug('----- UpdateCaseStatus ----- START'); 
        System.debug('caseId='+caseId+', caseStatus='+caseStatus);
        /*try{
            Case toBeUpdateCase = new Case(
                Status = caseStatus,
                Id= caseId);
            Update toBeUpdateCase;
            System.debug('toBeUpdateCase is success='+toBeUpdateCase);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR,'Error occoured while updating Case Status ==>'+ex);
        }*/
        System.debug('----- UpdateCaseStatus ----- END'); 
    }
             /**
* Description: Get Case Status
* */ 
    @AuraEnabled 
    public static String getCaseStatus(String caseId){
        System.debug('----- getCaseStatus ----- START'); 
        System.debug('caseId='+caseId);
        String caseStatus = null;
        try{
            Case caseObj = [SELECT Id, Status FROM Case WHERE  Id=:caseId LIMIT 1];
            if(caseObj != null){
                caseStatus = caseObj.Status;
            }
            System.debug('caseObj='+caseObj);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR,'Error occoured while updating Case Status ==>'+ex);
        }
        System.debug('----- getCaseStatus ----- END'); 
        return caseStatus;
    }
    
    @AuraEnabled 
    public static List<Case> getLoggedInUserCaseList(){
        System.debug('----- getLoggedInUserCaseList ----- START'); 
        List<Case> caseList = null;
        try{
            String loggedInUserId=UserInfo.getUserId();
            if(loggedInUserId !=null){
                //caseList = [SELECT Id,  CHASEnquiryType__c, CaseNumber, LastModifiedDate,Enquiry_Status__c FROM Case WHERE OwnerId=:loggedInUserId ORDER BY LastModifiedDate DESC  LIMIT 2000];
                // We need to show all the cases that this user has created, the owner will be set a case queue.
                caseList = [SELECT Id,  CHASEnquiryType__c, CaseNumber, LastModifiedDate,Enquiry_Status__c FROM Case WHERE CreatedById=:loggedInUserId ORDER BY LastModifiedDate DESC  LIMIT 2000];
            }
            System.debug('caseList='+caseList);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR,'Error occoured getLoggedInUserCaseList ==>'+ex);
        }
        System.debug('----- getLoggedInUserCaseList ----- END'); 
        return caseList;
    }
    
}