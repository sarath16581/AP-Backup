/**
 * @author Phap Mai
 * @date 2021-07-12
 * @group Controller
 * @tag CompensationController
 * @tag Compensation
 * @description Compensation form controller
 * @changelog
 * 2021-07-12 - Phap Mai - Init
 * 2021-07-28 - Phap Mai - Added updateBankDetails()
 * 2021-09-10 - hara.sahoo@auspost.com.au - Added compensation status to updateBankDetails()
 * 2021-09-20 - phapmai@auspost.com.au - Modified updateToken() to send compensation email right after token updated
 * 2021-09-30 - phapmai@auspost.com.au - Added custom exception
 * 2021-10-03 - phapmai@auspost.com.au - Added method to send confirmation email and modified updateBankDetails() to send confirmation email
 * 2021-10-14 - phapmai@auspost.com.au - Expose generateToken() from private to public so that in can be invoked from trigger
 * 2021-10-14 - phapmai@auspost.com.au - Added createCaseCommentAboutEmailSent to create comment on parent case when compensation email sent out
 * 2021-10-21 - phap.mai@auspot.com.au - Modified case comment on out of attemps to be a private one
 */
public with sharing class CHAS_CompensationFormController
{
    /**
     * Generate & update token to record
     * @param Id: target record Id
     * @param urlEncode: option to encode the token
     * @param sendCompensationEmail: option to send out compensation email after token generated
     * @param resetAttemps: option to reset attemps after token generated
     */
    @AuraEnabled
    public static void updateToken(Id recordId, Boolean urlEncode, Boolean sendCompensationEmail, Boolean resetAttemps)
    {
        List<Compensation__c> compensations = getCompensationById(recordId);

        if (compensations.size() == 0)
        {
            throw new CompensationException('Found no compensation with this record Id');
        }
            
        // query by Id ensure either 0 or 1 record
        Compensation__c compensation = compensations[0];

        // make sure compensation have valid recipient
        if (sendCompensationEmail)
        {
            validateEmailRecipientOf(compensation);
        }
        
        // make sure compensation is valid for compensation form before sending
        validate(compensation);

        // generate token and assign to record, URL encode for browser-friendly browsing
        if (urlEncode)
        {
            compensation.Compensation_Form_Token__c = EncodingUtil.urlEncode(generateToken(compensation), 'UTF-8');
        }
        else
        {
            compensation.Compensation_Form_Token__c = generateToken(compensation);
        }

        if (resetAttemps == null)
        {
            resetAttemps = false;
        }

        if (resetAttemps)
        {
            compensation.Compensation_Form_Attemps__c = 0;
        }
            
        // commit token to DB
        try
        {
            update compensation;
        } catch (Exception e)
        {
            throw new CompensationException('Failed committing token to record with error: ' + e.getMessage());
        }

        // send email to customer, the error is handled in this method separately
        if (sendCompensationEmail)
        {
            sendCompensationEmail(compensation);
        }
    }

    /**
     * send compensation email to case's contact email and create case comment on sent out email
     * @param compensation: target compensation record
     */
    @AuraEnabled
    public static void sendCompensationEmail(Compensation__c compensation)
    {
        // get OWD email
        List<OrgWideEmailAddress> owes = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :SSSWConstants.ORGWIDEEMAIL];

        // safe escape
        if (owes.size() == 0)
        {
            throw new CompensationException('Found no Org Wide Email with address: ' + SSSWConstants.ORGWIDEEMAIL);
        }

        // get email template
        List<EmailTemplate> templates = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'SSSW_Compensation_Form_Email'];

        // safe escape
        if (templates.size() == 0)
        {
            throw new CompensationException('Found no email template with name SSSW_Compensation_Form_Email');
        }

        // draft the email
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTargetObjectId(compensation.Case__r.ContactId);
        message.setOrgWideEmailAddressId(owes[0].Id);
        message.setTemplateId(templates[0].Id);
        message.setWhatId(compensation.Id);

        // send email
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

        // process sending result
        for (Messaging.SendEmailResult res : results)
        {
            if (!res.isSuccess())
            {
                throw new CompensationException('Failed sending compensation email with error: ' + compileEmailError(res.getErrors()));
            }
        }

        // DDS-8012: create a case comment for compensation email sent out
        // non-critical function, wrap in try catch to not hinder sending email process
        try
        {
            createCaseCommentAboutEmailSent(new List<Compensation__c> {compensation});
        }
        catch (Exception caseCommentExp)
        {
            // try to log error for audit
            UTIL_LoggingService.logHandledException(caseCommentExp, UserInfo.getOrganizationId(), 'CHAS_Compensation', 'CHAS_CompensationFormController', 'sendCompensationEmail', '', LoggingLevel.ERROR);
        }
    }

    /**
     * invoked by compensation form to get the compensation with @token and validate if record is valid for compensation form before returning
     * @param token: compensation token
     */
    @AuraEnabled
    public static CompensationPackage getCompensationByToken(String token)
    {
        // url encode to match the token field
        token = EncodingUtil.urlEncode(token, 'UTF-8');

        // get via helper since community don't have access to compensation record
        Invoker helper = new Invoker();
        List<Compensation__c> compensations = helper.getCompensationByToken(token);

        if (compensations.size() == 0)
        {
            throw new CompensationException('Invalid token');
        }
        else if (compensations.size() > 1)
        {
            throw new CompensationException('Duplicate token');
        }

        // token suppose to be unique
        Compensation__c compensation = compensations[0];

        // check if compensation is validate
        validate(compensation);

        // return compensation as part of package
        CompensationPackage result = new CompensationPackage();
        result.compensation = compensation;
        result.maxAttemps = getMaxAttemps();

        return result;
    }

    /**
     * get next steps metadata for thank you page
     * @param mtdGroup: metadata group to get
     */
    @AuraEnabled(cacheable = true)
    public static List<CHAS_ThankYouPageNextSteps__mdt> getNextStepsMetadata(String mtdGroup){
        return ChasApexController.getNextStepMetadata(mtdGroup);
    }

    /**
     * invoked by compensation form to update failed attemp counter in compensation record. The new value is equal current value plus 1
     * @param recordId: target record Id
     */
    @AuraEnabled
    public static void increaseAttempsCounter(String recordId)
    {
        Invoker helper = new Invoker();
        Compensation__c compensation = helper.updateCompensationAttemps(recordId);

        // add case comment if compensation is out of attemp
        if (compensation.Compensation_Form_Attemps__c >= getMaxAttemps())
        {
            // non-critical function, wrap in try catch to prevent the attemp counter being rolled back if exception happen
            try
            {
                helper.createCaseCommentWithPublishOption(compensation.Case__c, 'All attempts for compensation has been exhausted', false, true);
            }
            catch (Exception caseCommentExp)
            {
                // try to log error for audit
                UTIL_LoggingService.logHandledException(caseCommentExp, UserInfo.getOrganizationId(), 'CHAS_Compensation', 'CHAS_CompensationFormController', 'increaseAttempsCounter', '', LoggingLevel.ERROR);
            }
        }
    }

    /**
     * invoked by compensation form to update bank details provided by customer
     * @param compensationId: target compensation Id
     * @param accountName: account name to update
     * @param BSB: BSB number to update
     * @param accountNumber: account number to update
     */
    @AuraEnabled
    public static Compensation__c updateBankDetails(String compensationId, String accountName, String BSB, String accountNumber)
    {
        Invoker helper = new Invoker();
        Compensation__c compensation = helper.updateBankDetails(compensationId, accountName, BSB, accountNumber);
        return compensation;
    }

    /**
     * validate if compensation record is fit for compensation form
     * @param compensation: target compensation record
     */
    private static void validate(Compensation__c compensation)
    {
        checkRecordTypeOf(compensation);
        checkLeftAttempOf(compensation);
        checkOpenStatusOf(compensation);
        checkNeedBankDetailsOf(compensation);
        checkFlaggedForCompensationEmailOf(compensation);
    }

    /**
     * check if compensation record type is EFT
     * @param compensation: target compensation record
     */
    private static void checkRecordTypeOf(Compensation__c compensation)
    {
        if (compensation.RecordType.DeveloperName != 'EFT')
        {
            throw new CompensationException('Invalid compensation record type');
        }
    }

    /**
     * check if compensation's failed attempt exceed maximum failed attempts
     * @param compensation: target compensation record
     */
    private static void checkLeftAttempOf(Compensation__c compensation)
    {
        final Integer MAX_ATTEMPS = getMaxAttemps();

        Integer attemp = compensation.Compensation_Form_Attemps__c == null? 0 : Integer.valueOf(compensation.Compensation_Form_Attemps__c);
        
        if (attemp >= MAX_ATTEMPS)
        {
            throw new CompensationException('This compensation is out of attempts');
        }
    }

    /**
     * check if status is equals to 'Approved Awaiting Customer'
     * @param compensation: target compensation record
     */
    private static void checkOpenStatusOf(Compensation__c compensation)
    {
        if (compensation.Status__c != SSSWConstants.STATUS_APPROVED_AWAITING_CUSTOMER)
        {
            throw new CompensationException('This compensation is not open');
        }
    }

    /**
     * check if the bank details is empty
     * @param compensation: target compensation record
     */
    private static void checkNeedBankDetailsOf(Compensation__c compensation)
    {
        if (String.isNotEmpty(compensation.Account_Name__c) || String.isNotEmpty(compensation.Account_Number__c) || String.isNotEmpty(compensation.BSB__c))
        {
            throw new CompensationException('We\'re unable to complete your request online. Please contact us to continue.');
        }
    }

    /**
     * check if the compensation is flagged for customer provide bank details
     * @param compensation: target compensation records
     */
    public static void checkFlaggedForCompensationEmailOf(Compensation__c compensation)
    {
        if (!compensation.Bank_Detail_Provided_By_Customer__c)
        {
            throw new CompensationException('This compensation record is not flagged for customer-provided bank details');
        }
    }

    /**
     * generate compensation token from record Id & Name
     * @param compensation: target compensation record
     */
    public static String generateToken(Compensation__c compensation)
    {
        return encryptData(gatherParameters(compensation));
    }

    /**
     * check if compensation having valid email recipient
     * @param compensation: target compensation record
     */
    private static void validateEmailRecipientOf(Compensation__c compensation)
    {
        if (compensation.Case__c == null)
        {
            throw new CompensationException('This compensation record is not linked to a case');
        }
            
        if (compensation.Case__r.ContactId == null)
        {
            throw new CompensationException('This compensation\'s case is not linked to a contact');
        }
            
        if (String.isEmpty(compensation.Case__r.ContactEmail))
        {
            throw new CompensationException('This compensation\'s contact does not have an email');
        }
    }

    /**
     * aggregate error message from a list of email sending errors
     * @param errors: sending email errors
     */
    private static String compileEmailError(List<Messaging.SendEmailError> errors)
    {
        try
        {
            String compiledMessage = '';
            for (Messaging.SendEmailError error : errors)
                compiledMessage += error.getMessage() + '.\n';

            return compiledMessage;
        }
        catch (Exception e)
        {
            return 'Unknow Error';
        }
    }

    /**
     * encrypt @input data using crypto key from custom setting
     * @param input: data to encrypt
     */
    private static String encryptData(String input)
    {
        // safe escape
        if (String.isEmpty(input))
        {
            return input;
        }
        
        // get custom settings
        Consumer_Help_and_Support__c CHAS_SETTINGS = Consumer_Help_and_Support__c.getOrgDefaults();

        // decode the encoded key
        Blob cryptoKey = EncodingUtil.base64Decode(CHAS_SETTINGS.Encoded_Crypto_Key__c);
        
        // encrypt input
        Blob encryptedInput = Crypto.encryptWithManagedIV('AES256', cryptoKey, Blob.valueOf(input));

        // encode back to human-readable format
        String output = EncodingUtil.base64Encode(encryptedInput);

        return output;
    }

    /**
     * gather parameter as raw string for encrypting
     * @param compensation: target compensation record
     */
    private static String gatherParameters(Compensation__c compensation)
    {
        List<String> parameters = new List<String>();

        parameters.add('recordId=' + compensation.Id);
        parameters.add('recordName=' + compensation.Name);
        
        return String.join(parameters, '&');
    }

    /**
     * get compensation record by Id
     * @param recordId: target record Id
     */
    private static List<Compensation__c> getCompensationById(String recordId)
    {
        CompensationSelector selector = new CompensationSelector();

        Set<Object> options = new Set<Object>{
            CompensationSelector.Options.WITH_OVERRIDE_CASE, 
            CompensationSelector.Options.WITH_OVERRIDE_RECORD_TYPE
        };

        return selector.getById(recordId, options);
    }

    /**
     * return max attemps from setting
     */
    private static Integer getMaxAttemps()
    {
        // H&S settings
        Consumer_Help_and_Support__c HELP_AND_SUPPORT = Consumer_Help_and_Support__c.getOrgDefaults();

        // get max attemps
        final Integer MAX_ATTEMPS = Integer.valueOf(HELP_AND_SUPPORT.Compensation_Max_Attemps__c);

        return MAX_ATTEMPS;
    }

    /**
     * create comment on related cases about the compensation email has been sent out
     * @param compensations : target compensation records
     */
    public static void createCaseCommentAboutEmailSent(List<Compensation__c> compensations)
    {
        List<CaseComment> comments = new List<CaseComment>();
        for (Compensation__c compensation : compensations)
        {
            comments.add(new CaseComment(
                                            CommentBody = 'Compensation number: ' + compensation.Name + '.\nCompensation email has been sent to customer.',
                                            isPublished = false,
                                            ParentId = compensation.Case__c
                                        )
                        );
        }
        insert comments;
    }

    /**
     * private internal class for getting compensation record without exposing the object
     */
    private without sharing class Invoker
    {
        private List<Compensation__c> getCompensationByToken(String token)
        {
            CompensationSelector selector = new CompensationSelector();

            Set<Object> options = new Set<Object>{
                CompensationSelector.Options.WITH_OVERRIDE_CASE, 
                CompensationSelector.Options.WITH_OVERRIDE_RECORD_TYPE
            };

            return selector.getByToken(token, options);
        }

        private List<Compensation__c> getCompensationById(String recordId)
        {
            CompensationSelector selector = new CompensationSelector();

            Set<Object> options = new Set<Object>{
                CompensationSelector.Options.WITH_OVERRIDE_CASE, 
                CompensationSelector.Options.WITH_OVERRIDE_RECORD_TYPE
            };

            return selector.getById(recordId, options);
        }

        private Compensation__c updateCompensationAttemps(String recordId)
        {
            List<Compensation__c> compensations = this.getCompensationById(recordId);

            if (compensations.size() == 0)
            {
                throw new CompensationException('Found no compensation record to increase attempts');
            }

            Compensation__c compensation = compensations[0];

            compensation.Compensation_Form_Attemps__c = compensation.Compensation_Form_Attemps__c == null? 1 : compensation.Compensation_Form_Attemps__c + 1;

            try
            {
                update compensation;
            } catch (Exception e)
            {
                throw new CompensationException('Updating attempt failed with error: ' + e.getMessage());
            }

            return compensation;
        }

        private Compensation__c updateBankDetails(String compensationId, String accountName, String BSB, String accountNumber)
        {
            List<Compensation__c> compensations = this.getCompensationById(compensationId);

            if (compensations.size() == 0)
            {
                throw new CompensationException('Found no compensation record to update');
            }

            Compensation__c compensation = compensations[0];

            compensation.Account_Name__c = accountName;
            compensation.Account_Number__c = accountNumber;
            compensation.BSB__c = BSB;
            // Update status to Approved
            // Additionally check if the status was Approved Awaiting Customer previously
            // To prevent accidental overwriting
            compensation.Status__c = (compensation.Status__c == SSSWConstants.STATUS_APPROVED_AWAITING_CUSTOMER ? SSSWConstants.STATUS_APPROVED : compensation.Status__c);

            // update email field in compensation for email alert to use
            compensation.Compensation_Email__c = compensation.Case__r.ContactEmail;

            try {
                update compensation;
            }
            catch (Exception e)
            {
                throw new CompensationException('Updating bank details failed with error: ' + e.getMessage());
            }

            return compensation;
        }

        /**
         * Create case comment with option to publish/private
         * @param caseId: target case Id
         * @param commentBody: comment to create
         * @param isPublished: flag for public comment
         * @param doCommit: flag for comment insert
         */
        public CaseComment createCaseCommentWithPublishOption(String caseId, String commentBody, Boolean isPublished, Boolean doCommit)
        {
            CaseComment comment = new CaseComment(CommentBody = commentBody, isPublished = isPublished, ParentId = caseId);

            if (doCommit)
            {
                insert comment;
            }

            return comment;
        }
    }

    /**
     * compensation together with other information to return by retrieving method
     */
    public class CompensationPackage
    {
        @AuraEnabled public Compensation__c compensation {get; set;}
        @AuraEnabled public Integer maxAttemps {get; set;}
    }

    public class CompensationException extends Exception{}
}