/**************************************************
Description:    social handler class for handling all social post and threading them to correct parent and handling them correctly.

History:
--------------------------------------------------
2016-11-12  kalpita.talwadekar@auspost.com.au  Created
2018-06-06  clint.dsilva@auspost.com.au        Replace functionality of default social contact to default dummy social post
2018-07-04  clint.dsilva@auspost.com.au        Added functionality for Social Business integration
2020-11-17 - Ranjeewa Silva - Populate Social Post Tags on Cases to allow social cases to be routed using SSSW Routing rules.
**************************************************/

global virtual class CustomInboundSocialPostHandlerImpl implements Social.InboundSocialPostHandler{

    final static Integer CONTENT_MAX_LENGTH = 32000;
    final static string CASE_TYPE_GENERAL_ENQUIRY = 'General Enquiry';
    @TestVisible private final static String CASE_STATUS_NEW = 'New';
    @TestVisible private final static String CASE_ORIGIN_SOCIAL = 'Social';
    final static string CASE_ORIGIN_SOCIAL_BUSINESS = 'Social Business';

    // Reopen case if it has not been closed for more than this number
    global virtual Integer getMaxNumberOfDaysClosedToReopenCase() {
        return 2;
    }

    /**
     * @description       method to get the default account to be attached to each persona
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    global string  getDefaultAccountId() {
        string accountName = system.label.socialAccountName;
        string accountId = null;

        try {
            accountId =  [select Id from account where name = :accountName limit 1].Id;
        }
        catch(exception e) {}
        return accountId;
    }

    /**
     * @description      Method to handle incoming social posts
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    global Social.InboundSocialPostResult handleInboundSocialPost(SocialPost post,SocialPersona persona, Map<String, Object> rawData) {
        Social.InboundSocialPostResult result = new Social.InboundSocialPostResult();
        result.setSuccess(true);
        matchPost(post);
        matchPersona(persona);
        //Abbreviate text in string upto max length of text is too long
        if ((post.Content != null) && (post.Content.length() > CONTENT_MAX_LENGTH)) {
            post.Content = post.Content.abbreviate(CONTENT_MAX_LENGTH);
        }

        if (post.Id != null) {
            handleExistingPost(post, persona);
            return result;
        }

        setReplyTo(post, persona);
        buildPersona(persona);
        Case parentCase = buildParentCase(post, persona, rawData);
        setRelationshipsOnPost(post, persona, parentCase);
        upsert post;
        return result;
    }

    /**
     * @description       Handling post based on new or existing
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private void handleExistingPost(SocialPost post, SocialPersona persona) {
        update post;
        if (persona.id != null)
            updatePersona(persona);
    }

    /**
     * @description       Method to set who has replied on the post
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private void setReplyTo(SocialPost post, SocialPersona persona) {
        SocialPost replyTo = findReplyTo(post, persona);
        if(replyTo.id != null) {
            post.replyToId = replyTo.id;
            post.replyTo = replyTo;
        }
    }

    /**
     * @description       Based on incoming post, method to build the person's details (new/existing)
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private SocialPersona buildPersona(SocialPersona persona) {
        if (persona.Id == null)
            createPersona(persona);
        else {
            updatePersona(persona);
        }


        return persona;
    }

    /**
     * @description       If existing persona, update the details if any
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private void updatePersona(SocialPersona persona) {
        try {
            update persona;
        } catch (exception ex){
            //do nothing
        }
    }

    /**
     * @description      Method to thread the post to right parent cases
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private Case buildParentCase(SocialPost post, SocialPersona persona, Map<String, Object> rawData){
        Case parentCase = findParentCase(post, persona);
        if (caseShouldBeReopened(parentCase)) {
            reopenCase(parentCase);
        } else if (!hasSkipCreateCaseIndicator(rawData) && (parentCase.id == null || parentCase.isClosed)) {

            parentCase = createCase(post, persona);
        }
        return parentCase;
    }

    /**
     * @description       If parent case obtained is closed method to check if its less than 2 days old, reopen the same.
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private boolean caseShouldBeReopened(Case c){
        return c.id != null && c.isClosed && System.now() <
                c.closedDate.addDays(getMaxNumberOfDaysClosedToReopenCase());
    }

    /**
     * @description       Method to set the post, persona, case relation/threading
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private void setRelationshipsOnPost(SocialPost postToUpdate, SocialPersona persona,Case parentCase) {
        if (persona.Id != null) {
            postToUpdate.PersonaId = persona.Id;
        }
        if(parentCase.id != null) {
            postToUpdate.ParentId = parentCase.Id;
        }
    }

    /**
     * @description       Method to create a new case if not threaded to existing
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private Case createCase(SocialPost post, SocialPersona persona) {
        Case newCase = new Case(subject = post.Name);
        newCase.Origin = getCaseOrigin(post);
        //SET parent id as account or contact
        if (persona != null && persona.ParentId != null) {
            if (persona.ParentId.getSObjectType() == Contact.sObjectType) {
                newCase.ContactId = persona.ParentId;
            } else if(persona.ParentId.getSObjectType() == Account.sObjectType) {
                newCase.AccountId = persona.ParentId;
            }
        }
        newCase.AllocateToQueue__c = true;
        newCase.SocialPostTags__c = post.PostTags;

        insert newCase;
        return newCase;
    }

    // get Case origin based on post Tags
    private string getCaseOrigin(SocialPost post){
        string sOrigin = CASE_ORIGIN_SOCIAL;
        if(post.postTags != null && post.postTags.contains('AusPost-Business') ) {
            sOrigin = CASE_ORIGIN_SOCIAL_BUSINESS;
        }
        return sOrigin;
    }

    /**
     * @description       Method to search for parent case based on based on origin of Post
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private Case findParentCase(SocialPost post, SocialPersona persona) {
        Case parentCase = new Case();
        parentCase.Origin = getCaseOrigin(post);
        // Find and assign appropriate parent case if it exists, either from post or persona
        if (post.ReplyTo != null && (post.IsOutbound || post.ReplyTo.PersonaId == persona.Id) &&
                (!(post.messageType == 'Direct'
                        || post.messageType == 'Direct Message'
                        || post.messageType == 'Private'
                        || post.messageType == 'Private Message' )
                )) {
                parentCase = findParentCaseFromPostReply(post);
        } else if(post.ReplyTo != null && !post.IsOutbound && post.ReplyTo.isOutbound ) {
            List<SocialPost> spost =[ Select Id, ParentId, PersonaId from SocialPost where
            ParentId=:post.ReplyTo.ParentId and PersonaId = :persona.id
            order by createdDate asc limit 1 ];
            if(!spost.isEMpty()) {
                parentCase = [SELECT Id, IsClosed, Status, ClosedDate, Origin from Case where Id = :sPost[0].ParentId];
            }
        } else if((post.messageType == 'Direct' || post.messageType == 'Direct Message' ||
                post.messageType == 'Private' || post.messageType == 'Private Message' ) && String.isNotBlank(post.Recipient)) {
            if(post.ReplyTo != null && Persona.Id!=null && post.PersonaId != post.ReplyTo.PersonaId ){parentCase =  findParentFromReplyToPersona(post,post.ReplyTo.PersonaId); }
            else  {parentCase =  findParentCaseFromPersona(post, persona); }
        }

        return parentCase;
    }

    /**
      * @description       Based on person's response, find the parent case
      * @param             NA
      * @return            NA
      * @throws            NA
      */
    private Case findParentFromReplyToPersona (SocialPost post, Id personaId) {
        SocialPersona persona = [Select Id from SocialPersona where Id = :personaId limit 1 ];
        SocialPost lastestInboundPostWithSamePersonaAndRecipient =
                findLatestInboundPostBasedOnPersonaAndRecipient(post, persona);
        if (lastestInboundPostWithSamePersonaAndRecipient != null) {
            List<Case> cases = [SELECT Id, IsClosed, Status, ClosedDate , Origin FROM Case WHERE
                    id = :lastestInboundPostWithSamePersonaAndRecipient.parentId LIMIT 1];
            if(!cases.isEmpty()) {return cases[0]; }
        }
        Case parentCase = new Case();
        parentCase.Origin = getCaseOrigin(post);
        return parentCase;
    }


    /**
     * @description       Based on person's response, find the parent case
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private Case findParentCaseFromPersona(SocialPost post, SocialPersona persona) {
        SocialPost lastestInboundPostWithSamePersonaAndRecipient =
                findLatestInboundPostBasedOnPersonaAndRecipient(post, persona);
        if (lastestInboundPostWithSamePersonaAndRecipient != null) {
            List<Case> cases = [SELECT Id, IsClosed, Status, ClosedDate , Origin FROM Case WHERE
                    id = :lastestInboundPostWithSamePersonaAndRecipient.parentId LIMIT 1];
            if(!cases.isEmpty()) {
                string sOrigin = getCaseOrigin(post);
                if(cases[0].Origin != sOrigin ){
                    cases[0].Origin = sOrigin;
                }
                return cases[0];
            }
        }
        Case parentCase = new Case();
        parentCase.Origin = getCaseOrigin(post);
        return parentCase;
    }

    /**
     * @description       Find the latest post from the same person to get the parent case
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private SocialPost findLatestInboundPostBasedOnPersonaAndRecipient(SocialPost post,
            SocialPersona persona) {
        if (persona != null && String.isNotBlank(persona.Id) && post != null && String.isNotBlank(post.Recipient)) {
            List<String> messageTypes = new List<STring>{'Direct', 'Direct Message','Private','Private Message'};
            List<SocialPost> posts = [SELECT Id, ParentId FROM SocialPost WHERE Provider
                    = :post.provider AND Recipient = :post.Recipient AND PersonaId = :persona.id AND IsOutbound
                    = false AND  messageType IN :messageTypes ORDER BY CreatedDate DESC LIMIT 1];
            if (!posts.isEmpty()) { return posts[0];  }
        }
        return null;
    }

    /**
     * @description       If replied to, find parent case
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private Case findParentCaseFromPostReply(SocialPost post){
        List<Case> cases = [SELECT Id, IsClosed, Status, ClosedDate , Origin FROM Case WHERE Id =
                :post.ReplyTo.ParentId  LIMIT 1];
        if(!cases.isEmpty())
            return cases[0];

        Case parentCase = new Case();
        parentCase.Origin = getCaseOrigin(post);
        return parentCase;
    }

    /**
     * @description       If case is less than 2 days old and closed -  we can reopen and send to SSSW Social Team with isNewForRouting flag
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private void reopenCase(Case parentCase) {
        parentCase.Status = CASE_STATUS_NEW;
        parentCase.AllocateToQueue__c = true;
        parentCase.IsNewForRouting__c =  true;
        parentCase.Type=  CASE_TYPE_GENERAL_ENQUIRY;
        update parentCase;
    }

    /**
     * @description       Match incoming posts
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private void matchPost(SocialPost post) {
        if (post.Id != null) return;

        performR6PostIdCheck(post);

        if (post.Id == null){
            performExternalPostIdCheck(post);
        }
    }

    private void performR6PostIdCheck(SocialPost post){
        if(post.R6PostId == null) return;

        List<SocialPost> postList = [SELECT Id FROM SocialPost WHERE R6PostId = :post.R6PostId
        LIMIT 1];
        if (!postList.isEmpty()) {
            post.Id = postList[0].Id;
        }
    }

    private void performExternalPostIdCheck(SocialPost post) {
        if (post.provider == 'Facebook' && post.messageType == 'Private') return;
        if (post.provider == null || post.externalPostId == null) return;
        List<SocialPost> postList = [SELECT Id FROM SocialPost WHERE ExternalPostId = :post.ExternalPostId
        AND Provider = :post.provider LIMIT 1];
        if (!postList.isEmpty()) { post.Id = postList[0].Id; }
    }

    /**
     * @description       Method to find out whom the post was replied to - self/other
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private SocialPost findReplyTo(SocialPost post, SocialPersona persona) {
        if(post.replyToId != null && post.replyTo == null)
            return findReplyToBasedOnReplyToId(post);
        if(post.responseContextExternalId != null)
            return findReplyToBasedOnExternalPostIdAndProvider(post,post.responseContextExternalId);

        return new SocialPost();
    }

    /**
     * @description       Method to find reply to based on post id
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private SocialPost findReplyToBasedOnReplyToId(SocialPost post){
        List<SocialPost> posts = [SELECT Id, ParentId, IsOutbound, PersonaId FROM SocialPost
        WHERE id = :post.replyToId LIMIT 1];
        if(posts.isEmpty())  return new SocialPost();

        return posts[0];
    }

    private SocialPost findReplyToBasedOnExternalPostIdAndProvider(SocialPost post, String externalPostId){
        List<SocialPost> posts = [SELECT Id, ParentId, IsOutbound, PersonaId FROM SocialPost
        WHERE Provider = :post.provider AND ExternalPostId = :externalPostId LIMIT 1];
        if(posts.isEmpty())
            return new SocialPost();

        return posts[0];
    }

    /**
     * @description       Method to match the persona details
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private void matchPersona(SocialPersona persona) {
        if (persona != null) {
            List<SocialPersona> personaList = new List<SocialPersona>();
            if(persona.Provider != 'Other' && String.isNotBlank(persona.ExternalId)) {
                personaList = [SELECT Id, ParentId FROM SocialPersona WHERE
                Provider = :persona.Provider AND
                ExternalId = :persona.ExternalId LIMIT 1];
            } else if(persona.Provider == 'Other' && String.isNotBlank(persona.ExternalId)
                    && String.isNotBlank(persona.MediaProvider)) {
                personaList = [SELECT Id, ParentId FROM SocialPersona WHERE
                MediaProvider = :persona.MediaProvider AND
                ExternalId = :persona.ExternalId LIMIT 1];
            } else if(persona.Provider == 'Other' && String.isNotBlank(persona.Name) &&
                    String.isNotBlank(persona.MediaProvider)) {
                personaList = [SELECT Id, ParentId FROM SocialPersona WHERE
                MediaProvider = :persona.MediaProvider AND
                Name = :persona.Name LIMIT 1];
            }
            if (!personaList.isEmpty()) {
                persona.Id = personaList[0].Id;
                persona.ParentId = personaList[0].ParentId;
            }
        }
    }

    /**
     * @description      For new customers create a persona 1st time they perform an activity on social media
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    private void createPersona(SocialPersona persona) {
        if (persona == null || String.isNotBlank(persona.Id) ||
                !isThereEnoughInformationToCreatePersona(persona))
            return;
        SObject parent = createPersonaParent(persona);
        persona.ParentId = parent.Id;
        insert persona;
    }

    private boolean isThereEnoughInformationToCreatePersona(SocialPersona persona) {
        return String.isNotBlank(persona.Name) &&
                String.isNotBlank(persona.Provider) &&
                String.isNotBlank(persona.MediaProvider);
    }

    private boolean hasSkipCreateCaseIndicator(Map<String, Object> rawData) {
        Object skipCreateCase = rawData.get('skipCreateCase');
        return skipCreateCase != null &&
                'true'.equalsIgnoreCase(String.valueOf(skipCreateCase));
    }

    /**
     * @description       Based on persona, create parent contact and map to the persona
     * @param             NA
     * @return            NA
     * @throws            NA
     */
    global virtual SObject createPersonaParent(SocialPersona persona) {
        String name = persona.Name.trim();
        if (String.isNotBlank(persona.RealName))
            name = persona.RealName.trim();
        String firstName = '';
        String lastName = name;
        if (name.contains(' ')) {
            firstName = name.substringBeforeLast(' ');
            lastName = name.substringAfterLast(' ');
        }
        firstName = firstName.abbreviate(40);
        lastName = lastName.abbreviate(80);

        SocialPost sp = new SocialPost(name = 'DummyParent' + firstName + lastName  );
        Insert sp;
        return sp;
    }
}