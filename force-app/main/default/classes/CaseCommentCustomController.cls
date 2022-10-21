global with sharing class CaseCommentCustomController {
  public Case currentCase {get;set;}
  public List<CaseComment> caseComments {get;set;}

  public Boolean currentUserIsPartOfOmniGroup {
      get {
          return OmniChannelService.currentUserIsPartOfOmniGroup;
      }
  }
  
   public CaseCommentCustomController(ApexPages.StandardController stdController) 
    {      
      currentCase = [select 
                caseNumber,
                ProductCategory__c,
                ProductSubCategory__c,
                Description,Status,RecordType.DeveloperName 
              from Case 
              where id=:stdController.getId() 
              limit 1];
              
      caseComments = [SELECT 
                IsPublished, 
                CommentBody, 
                CreatedBy.Name, 
                CreatedById, 
                CreatedDate 
              FROM CaseComment 
              WHERE ParentId =: currentCase.id 
              ORDER BY CreatedDate DESC];
    }
    
    @RemoteAction 
    global static string addComment(id caseId, string comment, boolean isPublishedIn, boolean preventStatusChange){
      string result = '';
      CaseComment newComment = new CaseComment(ParentId = caseId, CommentBody = comment, isPublished = isPublishedIn);
      try{
        if(preventStatusChange) {
          Case c = [select PreventStatusChange__c from Case where id=:caseId limit 1];
          c.preventStatusChange__c = true;
          c.Email_Bypass_Data_enforcement__c = true;
          update c;
        }
        insert newComment;
      }catch(Exception ex){
        result = 'Error: ' + ex.getMessage();
      }        
        
      return result;
    }   
}