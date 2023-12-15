/**************************************************
    Type:         Controller for visualforce component ssswRecentCustomerEmailMessage
    History:
    NOTE:         N/A
    --------------------------------------------------
    2014-09-24    Louis Wang (Bluewolf)        Created Network / Carmelo cloned for Customer.
    2023-10-18    Swati Mogadala               INC2198494: Updated fetchRecentEmail() to check emList.size() > 0 and commentList> 0 seperately to resolve 'List out of bounds error'.
 **************************************************/

public class ssswRecentCustomerEmailMessage
{
    public Id caseId 
    {    
        get;
        set
        {
            // component will only load the AssignTo into class variable after the constructor is executed
            // so need to execute the code here
            caseId = value;   
            if(caseId != null)
            {
                fetchRecentEmail();     
            }      
        }
    }
    
    public class myMessage {
        public String htmlBody {get; set;}
        public String textBody {get; set;}
        public Boolean isComment {get; set;}
    }
    
    public Boolean IsText
    {
        get;
        set;
    }

    public myMessage em {get;set;}

    public ssswRecentCustomerEmailMessage() {}
        
    private void fetchRecentEmail()
    {
        system.debug('xxx caseId = ' + caseId);    
        // fetch From Address from Custom Setting
        QM__c configSetting = QM__c.getInstance();
        string fromAddress = configSetting.CusEmail__c;
        em = new myMessage();
        em.HTMLBody = '';
        em.TextBody = '';
        em.isComment = false;
        if(fromAddress != null)
        {
            // fetch the most recent email message sent by AusPost network (as per defined in custom setting)
            list<EmailMessage> emList = [SELECT Id, FromAddress, ToAddress, CreatedDate,
                                            TextBody, Subject, HtmlBody 
                                            FROM EmailMessage
                                            WHERE FromAddress = : fromAddress
                                            AND ParentId = : caseId
                                            ORDER BY CreatedDate DESC
                                            LIMIT 1];
            list<CaseComment> commentList = [SELECT commentbody, createddate from CaseComment where 
                                             IsPublished = true
                                             AND ParentId = : caseId
                                             ORDER BY CreatedDate DESC
                                             LIMIT 1];
            if(emList.size() > 0 )
            {
                if(commentList.size()==0 || (commentList.size()>0 && emList[0].createdDate>commentList[0].createdDate)) {
                
                    em.HTMLBody = emList[0].HTMLBody;
                    string html = em.HTMLBody;
                     //first replace all <BR> tags with \n to support new lines
                    string result = html.replaceAll('<br/>', '\n');
                    result = result.replaceAll('<br />', '\n');
                    result = result.replaceAll('<br>', '');
                    //regular expression to match all HTML/XML tags
                    string HTML_TAG_PATTERN = '<.*?>';
                    string CSS_PATTERN = '(?ims)(<style.*?>)(.+?)(</style>)';
                    string NEWLINE_PATTERN = '(\\n\\s*)';
                    //string CSS_PATTERN = '^[^<>={]*\\{([^}]+)\\}';
                    
                    // compile the pattern     
                    pattern myPattern = pattern.compile(CSS_PATTERN);
                    
                    
                    // get your matcher instance
                    matcher myMatcher = myPattern.matcher(result);
                   
                    //remove the tags     
                    em.TextBody = myMatcher.replaceAll('');
                    pattern myPattern1 = pattern.compile(HTML_TAG_PATTERN);
                    matcher myMatcher1 = myPattern1.matcher(em.TextBody);
                    em.TextBody = myMatcher1.replaceAll('');
                    
                    myPattern1 = pattern.compile(NEWLINE_PATTERN);
                    myMatcher1 = myPattern1.matcher(em.TextBody);
                    em.TextBody = myMatcher1.replaceAll('\n');
                    
                    em.TextBody = em.TextBody.replaceAll('&amp;','&');
                    em.TextBody = em.TextBody.replaceAll('&nbsp;','');
                    em.isComment = false;
                    }
                
               } 
               
            if(commentList.size()>0){
               
                 if(emList.size()==0 || (emList.size()>0 && emList[0].createdDate<commentList[0].createdDate)) {
                    
                    em.TextBody  = commentList[0].commentBody;
                    em.HTMLBody  = commentList[0].commentBody;
                    em.isComment = true;
                }
            }
        }
    }
}