public class UpdatePublicViewCountController {
    
    public String updated {get; set;}
    
    public UpdatePublicViewCountController() {
        Id knowledgeArticleId = ApexPages.currentPage().getParameters().get('Id');
        try {
            FAQ__kav f = [Select Id, knowledgeArticleId, Title from FAQ__kav where knowledgeArticleId = :knowledgeArticleId and Language='en_US' and PublishStatus='Online' update viewstat];
            system.debug(f);            
            updated = 'SUCCESSFULLY UPDATED PUBLIC VIEW COUNT OF '+f.Title+' -- '+f.KnowledgeArticleId;
        } 
        catch(Exception e) {
            updated='FAIL';
        }
    }

}