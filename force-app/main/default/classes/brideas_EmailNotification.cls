public class brideas_EmailNotification {
    private List<Messaging.SingleEmailMessage> mails;
    private List<brideas_TestEmail__c> elog;

    public brideas_EmailNotification() {
        this.mails = new List<Messaging.SingleEmailMessage>();
        this.elog = new List<brideas_TestEmail__c>();
    }

    public void addIdeaCreatedNotification(String address, Idea idea, String templateName){
        Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('authorName', UserInfo.getName());
        dataMap.put('ideaTitle', idea.Title);
        dataMap.put('ideaId', idea.Id);
        dataMap.put('ideaBody', idea.Body);

        Messaging.SingleEmailMessage mail = this.createEmail(templateName, new List<String>{address}, dataMap);

        this.mails.add(mail);
    }

    public void addNewCommentNotification(String address, IdeaComment comment, String templateName) {
        Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('ideaId', comment.Idea.Id);
        dataMap.put('ideaTitle', comment.Idea.Title);
        // Use Community Nickname for all external email notifications on Communities
        //dataMap.put('authorName', UserInfo.getName());
        dataMap.put('authorName', comment.CreatorName);
        dataMap.put('commentBody', comment.CommentBody);

        Messaging.SingleEmailMessage mail = this.createEmail(templateName, new List<String>{address}, dataMap);

        this.mails.add(mail);
    }

    public void addStatusChangeNotification(List<String> addr, Idea idea, String oldStatus, String templateName) {
        Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('oldStatus', oldStatus);
        dataMap.put('newStatus', idea.Status);
        dataMap.put('ideaTitle', idea.Title);
        dataMap.put('ideaId', idea.Id);
        dataMap.put('ideaBody', idea.Body);

        Messaging.SingleEmailMessage mail = this.createEmail(templateName, addr, dataMap);

        this.mails.add(mail);
    }

    public void addIdeaModeratedNotification(Idea idea){
        List<String> moderatorEmails = this.getModeratorsEmails();

        if (moderatorEmails.isEmpty()) return;

        Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('ideaId', idea.Id);
        dataMap.put('ideaTitle', idea.Title);
        dataMap.put('ideaBody', idea.Body);

        Messaging.SingleEmailMessage mail = this.createEmail('NewIdeaModerationNotification', moderatorEmails, dataMap);

        this.mails.add(mail);
    }

    public void addIdeaCommentModeratedNotification(IdeaComment ideaComment){
        List<String> moderatorEmails = this.getModeratorsEmails();

        if (moderatorEmails.isEmpty()) return;

        Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('ideaId', ideaComment.IdeaId);
        dataMap.put('ideaTitle', ideaComment.Idea.Title);
        dataMap.put('ideaCommentBody', ideaComment.CommentBody);

        Messaging.SingleEmailMessage mail = this.createEmail('NewIdeaCommentModerationNotification', moderatorEmails, dataMap);

        this.mails.add(mail);
    }

    public void addIdeaFlaggedNotification(Idea flaggedIdea, User userFlagged){
        List<String> moderatorEmails = this.getModeratorsEmails();

        if (moderatorEmails.isEmpty()) return;

        Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('ideaLink', '/ideas/viewIdea.apexp?id=' + flaggedIdea.Id);
        dataMap.put('ideaTitle', flaggedIdea.Title);
        dataMap.put('ideaBody', flaggedIdea.Body);
        dataMap.put('username', userFlagged.Username);

        Messaging.SingleEmailMessage mail = this.createEmail('IdeaFlaggedNotification', moderatorEmails, dataMap);

        this.mails.add(mail);
    }

    public void addIdeaCommentFlaggedNotification(IdeaComment flaggedComment, User userFlagged){
        List<String> moderatorEmails = this.getModeratorsEmails();

        if (moderatorEmails.isEmpty()) return;

        Map<String, String> dataMap = new Map<String, String>();
        dataMap.put('ideaLink', '/ideas/viewIdea.apexp?id=' + flaggedComment.IdeaId);
        dataMap.put('ideaTitle', flaggedComment.Idea.Title);
        dataMap.put('ideaCommentBody', flaggedComment.CommentBody);
        dataMap.put('username', userFlagged.Username);

        Messaging.SingleEmailMessage mail = this.createEmail('IdeaCommentFlaggedNotification', moderatorEmails, dataMap);

        this.mails.add(mail);
    }

    public Messaging.SendEmailResult[] sendEmails() {
        if (Test.isRunningTest()) {
            insert this.elog;
            return null;
        }

        return Messaging.sendEmail(this.mails, false);
    }

    private Messaging.SingleEmailMessage createEmail(String tplName, List<String> addrTo, Map<String, String> dataMap){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        EmailTemplate tpl = this.getEmailTemplate(tplName);
        String emailBody = this.cleanTemplateBody(tpl.HtmlValue);
        String subject = tpl.Subject;
        // Fetch Org wide ID to set From address
        if(!Test.isRunningTest()){
            OrgWideEmailAddress owa = [select Id from OrgWideEmailAddress where Address='noreply@auspost.com.au' LIMIT 1];
            mail.setOrgWideEmailAddressId(owa.Id);
        }

        for (String keyVal : dataMap.keySet()) {
            emailBody = emailBody.replace('{!' + keyVal + '}', dataMap.get(keyVal));
            subject = subject.replace('{!' + keyVal + '}', dataMap.get(keyVal));
        }

        mail.setToAddresses(addrTo);
        mail.subject = subject;
        mail.setHtmlBody(emailBody);

        this.elog.add(new brideas_TestEmail__c(ToAddresses__c = String.join(addrTo, ','),
                Subject__c = tpl.Subject, EmailBody__c = emailBody, EmailTemplate__c = tplName));

        return mail;
    }

    private EmailTemplate getEmailTemplate(String name) {
        return [SELECT HtmlValue, Subject FROM EmailTemplate WHERE Name = :name LIMIT 1];
    }

    private String cleanTemplateBody(String emailBody) {
        return emailBody.replaceAll('<!--.*-->', '');
    }

    private List<String> getModeratorsEmails(){
        List<String> emailsList = new List<String>();
        List<User> moderators = [SELECT Name, Email FROM User
                                 WHERE IsActive = true AND UserType = 'Standard' AND IdeasModerator__c = true
                                 LIMIT 50];

        for (User moder : moderators) {
            emailsList.add(moder.Email);
        }

        if (Test.isRunningTest()) {
            emailsList = new List<String>{'moderator@test.com'};
        }

        return emailsList;
    }
}