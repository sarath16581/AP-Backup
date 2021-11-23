/**
 * @author Louis Wang (Bluewolf)
 * @date 2014-05-27
 * @group BSP
 * @tag BSP
 * @tag Controller
 * @tag Cases
 * @domain BSP
 * @description Controller for visualforce page bspEnquiryDetail
 * @changelog
 * 2016-04-21    Nathan Main (Salesforce)     Updated to support MyPostBUsiness.
 * 2017-02-02    David Catindoy (Accenture)   Added additional method to track item related to the current case.
 * 2017-02-16    David Catindoy (Accenture)   Added the logic to hide SSCR5 UI changes.
 * 2017-03-03    Without sharing is required to allow BSP users to close case owned by other users.
 * 2019-04-19    nathan.franklin1@auspost.com.au - Large refactor to support the onboarding of BAM Self service portal
 * 2019-05-04    hasantha.liyanage@auspost.com.au embedded drag and drop component and the billing account dropdown changes on top of refactored changes
 * 2019-06-24    gnana.muruganantham@auspost.com.au modified submitEnquiryFileUpload method to merge classic (mpb user) and drag & drop (bsp and other users) attachment functionality
 * 2020-04-20 - Nathan Franklin - refactor commHistory class
 * 2020-06-22 - Nathan Franklin - Added a without sharing inner class to select from User since external User sharing model is Private
 */
public with sharing class bspEnquiryDetail extends bspBase {
    public Case enq { get; private set; }
    public CaseComment newCaseComment {get;set;}
    public boolean showAttachmentButtonFlag {get;set;}
    public String fromName { get; private set; }
    public String fromCompany { get; private set; }
    public String fromAddress1 { get; private set; }
    public String fromAddress2 { get; private set; }
    public String toName { get; private set; }
    public String toCompany { get; private set; }
    public String toAddress1 { get; private set; }
    public String toAddress2 { get; private set; }
    public List<commHistory> commHistoryList {get;set;}
    public List<Attachment> existingAttachments {get;set;}

    /**
	* Included so new changes can be deployed
	* If this is in prod then the vars / methods below can be removed
	*/
    public boolean hideSSCR5 {get;set;}
    /**
     * END
     */

    public String fileName {get;set;}
    public transient String fileBody {get;set;} // Hasantha changed to trasiant in order to change the upload component to a drag and drop component.
    public String fileBodyLength {get;set;} // Hasantha changed this to String from decimal as we are using an actionFunction for dropzone
    public String fileContentType {get;set;}
    public Blob fileBodyBlob {get;set;} // MPB use this for standard VF upload

    public String mpbFileName {get;set;}
    public Blob mpbFileBody {get;set;}
    public decimal mpbFileBodyLength {get;set;}
    public String mpbFileContentType {get;set;}

    // the currently loaded case passed in from the query String
    public Id enqId { get; set; }

    // determines where the user has access to view the current loaded case
    public Boolean authorised { get; set; }

    /**
	 * TODO: ?
	 */
    public static String fromAusPostAddress {
        get {
            if(fromAusPostAddress == null) {
                QM__c qmConfigSetting = QM__c.getInstance();
                fromAusPostAddress = (String.isEmpty(qmConfigSetting.CusEmail__c) ? '' : qmConfigSetting.CusEmail__c);
            }
            return fromAusPostAddress;
        }
        private set;
    }

    /**
	 * TODO: ?
	 */
    public static Id ccuProfileId {
        get {
            return CCUSettings__c.getInstance().CCUCommunityUserProfileId__c;
        }
    }

    //NM 07/04 - Added for MyPost Business
    public bspEnquiryDetail() {
        super();

        setPageHeaders();

        authorised = false;

        enq = null;
        enqId = ApexPages.currentPage().getParameters().get('id');
        System.debug('>> enqId: ' + enqId);
        if(!String.isEmpty(enqId)) {
            enq = getEnquiry(enqId);
        }

        if(enq != null) {
            authorised = true;
            initialiseCaseComment();
            initialiseAttachments();

            setAddressStrings();
            commHistoryList = new List<commHistory>();
            generateCommHistory();
        } else {
            // show a not authorised message
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, bspBase.getErrorMessage(BspConstants.ERROR_NOT_AUTHORISED_PAGE)));
        }
    }

    /**
     * Had to include for deployment to remove it
     */
    public System.PageReference bspEnquiryDetail1() {
        return null;
    }

    private void initialiseCaseComment()
    {
        newCaseComment = new CaseComment();
        newCaseComment.IsPublished = true;
        newCaseComment.ParentId = enq.Id;
    }

    public PageReference initialiseAttachments()
    {
        showAttachmentButtonFlag=false;
        existingAttachments = new List<Attachment>();
        existingAttachments = [SELECT Id, Name, BodyLength, Description, ContentType, createdById
                                FROM Attachment
                                WHERE ParentId = : enq.Id
                                AND IsPrivate = false
                                ORDER BY CreatedDate DESC];

        for(Integer i=0;i<existingAttachments.size();i++) {
            if(existingAttachments[i].Name.substring(0,5) == doNotShowFile) {
                existingAttachments.remove(i);
            }
        }

        return null;
    }

    public PageReference SF_DisplayAttachmentButton() {
        if(showAttachmentButtonFlag==true) {
            showAttachmentButtonFlag = false;
        } else {
            showAttachmentButtonFlag = true;
        }
        return null;
    }
    private void setPageHeaders()
    {
        // the following code resolved IE8/9 mis-aligned rendering issue

        // Make sure IE9 will use edge (IE9) mode - without the insertion of the following header
        // <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
        // comes too late and gives this error
        // HTML1115: X-UA-Compatible META tag ('IE=edge,chrome=1') ignored because document mode is already finalized.
        // Caused by Vf outputing tags and content prior to this meta tag
        Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge,chrome=1');

        // Add headers as advised by security review 2013-02-15
        Apexpages.currentPage().getHeaders().put('X-Frame-Options', 'SameOrigin'); // To prevent clickjacking
        Apexpages.currentPage().getHeaders().put('Cache-control', 'no-store'); // To prevent the browser to store personal information into its cache
        Apexpages.currentPage().getHeaders().put('Pragma', 'no-cache');
    }

    private Case getEnquiry(Id caseId) {
        List<Case> enqList = new List<Case>([SELECT Id, Subject, CCUServiceUsed__c, ArticleType__c, DatePosted__c, CCUYourReference__c, Permanent_Close__c,
                                                        ContactId, ReferenceID__c, CreatedDate, Status, LastModifiedDate, CCUEnquiryType__c, CCUItemContents__c,Address2__c, Enquiry_Type__c,
                                                        BSP_Sender_Name__c, BSP_Sender_Company__c, BSP_Sender_Address__c, Primary_Name__c, Primary_Company__c, Address1__c, Pickup_Booking_Reference__c,
                                                        BSP_Addressee_Name__c, BSP_Addressee_Company__c, BSP_Addressee_Address__c,Secondary_Contact__c,Secondary_Companry__c,
                                                        CaseNumber, ProductCategory__c, ProductSubcategory__c, DescriptionOfContents__c, ArticleTest__r.Name, StarTrack_RecordType__c,
                                                        Article_Receiver_Name__c, Article_Receiver_Address__c, StarTrack_Receiver_Name__c, Address4__c, Description, RecordType.DeveloperName, RecordType.Name,
                                                        AccountId, Related_Billing_Account__c, CreatedById, Contact.BillingAccount__c,
                                                        Contact.BillingAccount__r.Name, Contact.BillingAccount__r.LEGACY_ID__c, Contact.BillingAccount__r.Id, Contact.BillingAccount__r.Source_System__c,
                                                        Related_Billing_Account__r.Name, Related_Billing_Account__r.LEGACY_ID__c, Related_Billing_Account__r.Id, Related_Billing_Account__r.Source_System__c, Related_Billing_Account__r.Organisation__c
                                                FROM Case WHERE Id =: caseId]);

        if(!enqList.isEmpty()) {
            if(isMpbHspFlag) {
                return enqList[0];
            } else if(isCaseAccessible(enqList[0])) {
                System.debug('~~ enq : ' + enqList[0]);
                System.debug('~~ enq.Related_Billing_Account__r : ' + enqList[0].Related_Billing_Account__r);
                System.debug('~~ enq.ArticleTest__r : ' + enqList[0].ArticleTest__r);
                return enqList[0];
            }
        }

        return null;
    }

    private void setAddressStrings() {
        List<String> tempAdd = new List<String>();
        system.debug('###BW### Set Addresses');
        fromName = (enq.BSP_Sender_Name__c != null ? enq.BSP_Sender_Name__c : enq.Primary_Name__c);
        fromCompany = (enq.BSP_Sender_Company__c != null ? enq.BSP_Sender_Company__c : enq.Primary_Company__c);

        if(!String.isBlank(enq.BSP_Sender_Address__c))
        {
            if(enq.BSP_Sender_Address__c.contains(','))
            {
                tempAdd = enq.BSP_Sender_Address__c.split(',',2);
                fromAddress1 = (tempAdd[0] != null ? tempAdd[0] : '');
                fromAddress2 = (tempAdd[1] != null ? tempAdd[1].trim() : '');
            }
            else
            {
                fromAddress1 = enq.BSP_Sender_Address__c;
                fromAddress2 = '';
            }
        }
        if (String.isBlank(fromAddress1))
        {
            fromAddress1 = enq.Address1__c;
        }
        toName = (enq.BSP_Addressee_Name__c != null ? enq.BSP_Addressee_Name__c : enq.Secondary_Contact__c);
        toCompany = (enq.BSP_Addressee_Company__c != null ? enq.BSP_Addressee_Company__c : enq.Secondary_Companry__c);

        if(!String.isBlank(enq.BSP_Addressee_Address__c))
        {
            if(enq.BSP_Addressee_Address__c.contains(','))
            {
                tempAdd = enq.BSP_Addressee_Address__c.split(',',2);
                toAddress1 = (tempAdd[0] != null ? tempAdd[0] : '');
                toAddress2 = (tempAdd[1] != null ? tempAdd[1].trim() : '');
            }
            else
            {
                toAddress1 = enq.BSP_Addressee_Address__c;
                toAddress2 = '';
            }
        }
        if (String.isBlank(toAddress1))
        {
            toAddress1 = enq.Address2__c;
        }
    }

    //Modified by David Catindoy (Feb 10, 2017) to add the capability to close cases that are still pending for approval.
    public PageReference closeCase()
    {
        String previousStatusValue = enq.Status;
        enq.Status = BspConstants.CASE_STATUS_CLOSED;
        enq.ResolutionCode__c = 'Customer – Self service';
        Boolean inApproval = Approval.isLocked(enq.Id); //Check if case record is locked.
        try {

            Database.update(enq);

            if(inApproval){//If the record is locked, then it is still pending for approval.
                Database.insert(new CaseComment(CommentBody = 'BSP User closed this case while still pending for approval process.', ParentId = enq.Id)); //Create a comment under the case.
                Approval.UnlockResult result = Approval.unlock(enq.Id); //Unlock the case record.
            }

        } catch(Exception ex) {
            enq.Status = previousStatusValue;
            ApexPages.addMessages(ex);
            return null;
        }
        String URL = ApexPages.CurrentPage().GetURL();
        URL = URL.substring(0,URL.indexOf('?'));
        URL += '?id=' + enq.Id;
        PageReference pageRef = new PageReference(URL);
        pageRef.setRedirect(true);
        return pageRef;
    }

    public PageReference reopenCase() {
        enq.Status = 'New';
        try {
            update enq;
        } catch(Exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
        String URL = ApexPages.CurrentPage().GetURL();
        URL = URL.substring(0,URL.indexOf('?'));
        URL += '?id=' + enq.Id;
        PageReference pageRef = new PageReference(URL);
        pageRef.setRedirect(true);
        return pageRef;
    }

    public PageReference addComment() {
        if(ApexPages.hasMessages()) {
            // Salesforce would load the attachment file. If it is larger than 10MB, it will reset every attachment variables
            //    and leaves an ApexMessage. Display it!
            //    "This file exceeds the maximum size limit of 10MB."
            return null;
        }

        // TODO NEED TO CLARIFY
        // TODO GNANA TO ADD MPB FILE UPLOAD BACK IN
        submitEnquiryFileUpload();

        system.debug('xxx newCaseComment.CommentBody = ' + newCaseComment.CommentBody);
        if(newCaseComment.CommentBody.trim()!=null && newCaseComment.CommentBody.trim()!='')
        {
            try {
                insert newCaseComment;
            } catch(Exception ex) {
                ApexPages.addMessages(ex);
                return null;
            }
        }

        if(enq.RecordType.DeveloperName.startsWith('StarTrack') && (String.isNotBlank(newCaseComment.CommentBody))){
            enq.Case_Update__c = StarTrack_Constants.CASE_UPDATE_CUSTOMERRESP;
            enq.Case_Update_Time__c = System.now();

            if (StarTrack_Constants.CASE_STATUS_WAITINGONCUSTOMER.equals(enq.Status)) {
                enq.Status = StarTrack_Constants.CASE_STATUS_INVESTIGATION;
            }

            try {
                Database.update(enq);
            } catch (Exception ex) {
                ApexPages.addMessages(ex);
                return null;
            }
        }

        String URL = ApexPages.CurrentPage().GetURL();
        URL = URL.substring(0,URL.indexOf('?'));
        URL += '?id=' + enq.Id;
        PageReference pageRef = new PageReference(URL);
        pageRef.setRedirect(true);
        return pageRef;
    }

    private void generateCommHistory() {
        // this function sorted 2 types of objects (Comm) by CreatedDate DESC, and then added to a wrapper class
        //    such that Vf page can access them consistently.
        String avoidSubjects = '%'+String.valueOf(System.Label.ProdRelease1_2)+'%';
        List<SObject> comments = [SELECT Id, CommentBody, IsPublished, CreatedDate, CreatedById
                                    FROM CaseComment
                                    WHERE IsPublished = true
                                    AND ParentId = : enq.Id];
        System.debug('xxx comments.size() = ' + comments.size());

        System.debug([SELECT Id, HtmlBody, TextBody, CreatedDate, CreatedById,
                                Subject, FromAddress, ToAddress, CcAddress, FromName
                        FROM EmailMessage
                        WHERE ParentId = : enq.Id]);

        // only display EmailMessage if it has keyword matched in its FromAddress or ToAddress
        List<SObject> emailMessages = [SELECT Id, HtmlBody, TextBody, CreatedDate, CreatedById,
                                                Subject, FromAddress, ToAddress, CcAddress, FromName
                                        FROM EmailMessage
                                        WHERE ParentId = : enq.Id
                                        AND (FromAddress LIKE : emailKeyword OR ToAddress LIKE : emailKeyword)
                                        AND (NOT Subject LIKE :avoidSubjects)];
        System.debug('xxx emailMessages.size() = ' + emailMessages.size());

        // We do not display names of internal users so we need to understand what the user types are of each user involved in the updates
        // not sure why but some of these details aren't accessible with CreatedBy.x in above queries
        Set<Id> userIds = new Set<Id>();
        for(SObject comment : comments) {
            userIds.add((Id)comment.get('CreatedById'));
        }
        for(SObject emailMessage : emailMessages) {
            userIds.add((Id)emailMessage.get('CreatedById'));
        }

        // use a without sharing inner class in order to grab user details given that internal users will not be accessible
        WithoutSharingExtension extension = new WithoutSharingExtension();
        Map<Id, User> usersInUpdates = extension.getUsersTypes(userIds);
        System.debug('Users: ' + usersInUpdates);

        List<SObject> objs = new List<SObject>();
        objs.addAll(comments);
        objs.addAll(emailMessages);

        for(SObject s : objs)
        {
            commHistoryList.add(new commHistory(s, usersInUpdates.get((Id)s.get('CreatedById'))));
        }
        // sort against CreatedDate
        commHistoryList.sort();
    }

    public class commHistory implements Comparable
    {
        // this wrapper class handles sobject of EmailMessage, Task and CaseComment
        // Note: task is not visible to community user so it is no longer relevant.
        private SObject record;
        private User createdByUser;
        private String objType;

        public Integer compareTo(Object compareTo)
        {
            // make the sorting based on CreatedDate
            commHistory c = (commHistory)compareTo;
            if(getCreatedDate() == c.getCreatedDate()) {
                return 0;
            } else if(getCreatedDateTime() > c.getCreatedDateTime()) {
                return -1;
            } else {
                return 1;
            }
        }

        public Datetime getCreatedDateTime()
        {
            // make the sorting based on CreatedDate
            Datetime dt = Datetime.valueOf(record.get('CreatedDate'));
            return dt;
        }

        public commHistory(SObject record, User createdByUser)
        {
            this.record = record;
            this.createdByUser = createdByUser;

            if (record.getSObjectType() == CaseComment.SObjectType) {
                objType = 'comment';
            } else if(record.getSObjectType() == Task.SObjectType) {
                objType = 'task';
            } else if(record.getSObjectType() == EmailMessage.SObjectType) {
                objType = 'message';
            }
        }

        public String getobjType() {
            return objType;
        }

        private String getCreatedDate() {
            String output = '';
            Datetime dt = Datetime.valueOf(record.get('CreatedDate'));
            output = dt.format();
            return output;
        }

        public String getBody() {
            String output = '';
            if(objType == 'comment') {
                output = String.valueOf(record.get('CommentBody'));
            } else if(objType == 'task') {
                output = String.valueOf(record.get('Description'));
            } else if(objType == 'message') {
                //Subject, FromAddress, ToAddress, Body
                output = 'Subject: ' + String.valueOf(record.get('Subject')) + '\n';
                output += 'From: ' + String.valueOf(record.get('FromAddress')) + '\n';
                output += 'To: ' + String.valueOf(record.get('ToAddress')) + '\n';
                output += '-----------------------------------------------------------------------------------\n';
                output += String.valueOf(record.get('TextBody'));

            }
            return output;
        }

        private String getPostedBy() {
            if((new Set<String>{'comment', 'task'}).contains(objType)) {
                return createdByUser.Name;
            } else if(objType == 'message') {
                // use FromName
                return String.valueOf(record.get('FromName'));
            }

            return null;
        }

        private Boolean isCommunityUser() {
            // determine whether the record is created by 'CCU/BSP Community User' profile
            Boolean output = false;
            if((new Set<String>{'comment', 'task'}).contains(objType)) {
                // is an external user?
                return BspConstants.EXTERNAL_USER_USERTYPE.equalsIgnoreCase(createdByUser.UserType);
            } else if(objType == 'message') {
                // use FromAddress to determine whether it is Community User
                String fromAddress = String.valueOf(record.get('FromAddress'));
                fromAddress = fromAddress.toLowerCase();
                if(!fromAddress.equalsIgnoreCase(fromAusPostAddress)) {
                    output = true;
                }
            }
            return output;
        }

        private Boolean isMe() {
            return createdByUser.Id == UserInfo.getUserId();
        }

        public String getHeader() {
            // due to unique CSS structure, see sample below, this function generates the html String
            String output = '';
            if(isCommunityUser() && !getBody().contains(bspBase.getErrorMessage('CSV Error')) && !getBody().contains('Number of Cases created via Bulk Upload :')) {
                // comment from the business user
                output = '<h3 class="comm-header client">';
                output += '    <div class="title">' + (isMe() ? 'ME ' : 'BSP ') + '(' + getPostedBy() + ')</div>';
                output += '    <div class="timestamp">' + getCreatedDate() + '</div>';
                output += '</h3>';
            } else {
                // must be the comment by AusPost
                output = '<h3 class="comm-header auspost">';
                output += '    <div class="title">Update</div>';
                output += '    <div class="timestamp">' + getCreatedDate() + '</div>';
                output += '</h3>';
            }

            return output;

        }
    }

    //David Catindoy - StarTrack method to navigate to BSP Consignment search page when the BSP User clicked the 'Track item' button.
    public PageReference trackItem(){
        if(String.isNotBlank(enq.ArticleTest__r.Name) && enq.RecordType.DeveloperName.startsWith('StarTrack')){
            return new PageReference('/bsp/BSPConsignmentSearch?consignmentNumber=' + enq.ArticleTest__r.Name + '&caseRT=' + BspConstants.AUTH_SCOPE_ST);
        } else{
            return new PageReference('/bsp/BSPConsignmentSearch?consignmentNumber=' + enq.ReferenceID__c + '&caseRT=' + BspConstants.AUTH_SCOPE_AP);
        }
        return null;
    }

    /**
  * file upload support for dropzone on the VF page, this is invoked by an action function,
  * this method will be called multiple times based on the number of files drop on to the
  * drag and drop (dropzone)
  *
  * once the file is received, attachment record will be created and saved under the case
  * @author hasantha 2019-02-28
  * @modified Gnana 2019-06-24 - Merged classic and drag & drop file uploading functionality
  * @return PageReference
  */
    public PageReference submitEnquiryFileUpload() {
        if(ApexPages.hasMessages()) {
            // Salesforce would load the attachment file. If it is larger than 10MB, it will reset every attachment variables
            //    and leaves an ApexMessage. Display it!
            //    "This file exceeds the maximum size limit of 10MB."
            return null;
        }

        // for mpb users attachmnet
        if(isMpbHspFlag){
            if(mpbFileBodyLength  > 0){
                if((mpbFileBodyLength/1048576) > fileSizeLimit){
                    String msgString = 'This file exceeds the maximum size limit of ' + fileSizeLimitInteger + 'MB.';
                    apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.Error, msgString);
                    apexpages.addmessage(msg);

                    // clear fileBody to blank to avoid viewstate error
                    mpbFileBody = null;
                    mpbFileBodyLength = 0;
                    return null;
                } else {
                    Attachment att  = new Attachment();
                    att.Body = mpbFileBody;
                    att.Name = mpbFileName;
                    att.ContentType = mpbFileContentType;
                    att.OwnerId = UserInfo.getUserId();
                    att.ParentId = enq.id;
                    att.IsPrivate = false;

                    try {
                        insert att;
                        //return true;
                    } catch(Exception ex) {
                        // clear fileBody to blank to avoid viewstate error
                        mpbFileBody = null;
                        mpbFileBodyLength = 0;
                        ApexPages.addMessages(ex);
                        //return null;
                        return null;
                    }
                }
            }
        }
        // for non-mpb users attachment (drag and drop)
        else {
            Decimal fileBodyLengthDeimal = fileBodyLength != null && !String.isEmpty(fileBodyLength) ? Decimal.valueOf(fileBodyLength) : 0;
            if(fileBodyLengthDeimal > 0) {
                // cehck max file size here, this is bneing checked in clinet side as well, this is for extra safty
                if((fileBodyLengthDeimal/1048576) > fileSizeLimit) {
                    String msgString = 'This file exceeds the maximum size limit of ' + fileSizeLimitInteger + 'MB.';
                    apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.Error, msgString);
                    apexpages.addmessage(msg);

                    // clear fileBody to blank to avoid viewstate error
                    fileBody = null;
                    fileBodyLengthDeimal = 0;
                    return null;
                } else {
                    try {
                        // creating the attachment
                        Attachment att  = new Attachment();
                        att.Body = EncodingUtil.base64Decode(fileBody); // fileBody is a trasiant variable which contains a base64 file body
                        att.Name = fileName;
                        att.ContentType = fileContentType;
                        att.OwnerId = UserInfo.getUserId();
                        att.ParentId = enq.id;
                        att.IsPrivate = false;
                        insert att;
                    } catch(Exception ex) {
                        // clear fileBody to blank to avoid viewstate error
                        fileBodyBlob = null;
                        fileBodyLength = '0';
                        system.debug('bspEnquiryDetail ex.message = ' + ex);
                        ApexPages.addMessages(ex);
                    }
                }
            }
        }

        return null;
    }

    /**
     * A without sharing class here to retrieve details of users that aren't in the community (Internal users)
     * Currently, External Org Wide Default for User is Private, hence why a without sharing is required for this call.
     */
    private without sharing class WithoutSharingExtension {
        public Map<Id, User> getUsersTypes(Set<Id> userIds) {
            return new Map<Id, User>([Select Id, UserType, ProfileId, Name From User Where Id in :userIds]);
        }
    }
}