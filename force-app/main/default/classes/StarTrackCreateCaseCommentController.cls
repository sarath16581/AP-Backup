/**
 ** Description: Controller for StarTrackCreateCaseComment PA(Publisher Action)
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: March 15, 2016
 ** History:--------------------------------------------
 **         March 15, 2016 David Catindoy - Created
 **/

global class StarTrackCreateCaseCommentController {
    public Case existingCase {get; set;}
    public Integer charCount {get; set;}

    public StarTrackCreateCaseCommentController(){
        existingCase = [SELECT Id, Status, RecordType.Name FROM Case WHERE Id =: ApexPages.CurrentPage().getParameters().get('Id')];
        charCount = 0;
    }
    
    @RemoteAction
    global static Case refreshCase(String recordId) {
        return [SELECT Id, Status, RecordType.Name FROM Case WHERE Id =: recordId];
    }
}