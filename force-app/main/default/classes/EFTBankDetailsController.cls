/**
* @author Dishan Egodawela
* @date 2018-09-03
* @group Compensation
* @tag Controller
* @tag Compensation__c
* @domain Case Details Page
* @description Created to facilitate EFT compensations. this is the controller for EFTBankDetails page.
the controller runs on system mode to enable agents to enter and edit compensation bank details.
* 2018-09-03 - dilshan.egodawela@auspost.com.au Created
* 2020-08-07 - dheeraj.mandavilli@auspost.com.au Added Logic to accomodate Load & Go Record Type.
* 2020-08-21 - dheeraj.mandavilli@auspost.com.au Removed Logic associated with Load & Go Record Type.
* 2021-08-25 - phap.mai@auspost.com.au Modified the validate method to ignore checking if compensation email checkbox is ticked
* 2023-07-01 - hasantha.liyanage@auspost.com.au Modified: Compensation MW changes based on the custom permissions control the UI accessibility
*/

public without sharing class EFTBankDetailsController {
    public Compensation__c record  {get;set;}
    public Boolean showEditScreen {get;set;}
    public Boolean showEditButton {get;set;}
    public Boolean detailsProvided {get;set;}
    public ApexPages.StandardController stdCon {get;set;}
    public String accountName {get;set;}
    public String accountNumber {get;set;}
    public String accountBSB {get;set;}
    public Boolean privacyCheck {get;set;}
    public Boolean confirmDetails {get;set;}
    public Id eftRecordTypeID {get;set;}

    // DDS-6866: checkbox for sending compensation email
    public Boolean compensationEmail {get; set;}

    // DDS-6866: flag for EFTBankDetails page to show the notification that this compensation is awaiting bank details from customer
    public Boolean awaitBankDetailsFromCustomer {get; set;}

    // DDS-8012: attribute indicate the route of customer provide or agent provide bank details
    public final String BANK_DETAILS_VIA_FORM = 'CustomerProvide';
    public final String BANK_DETAILS_VIA_AGENT = 'AgentProvide';

    public static Boolean isAllowedToCreateCompensation {
        get {
            if(isAllowedToCreateCompensation == null) {
                return true;
            }
            return isAllowedToCreateCompensation;
        }
        private set;
    }

    public static Set<Id> RESTRICTED_COMPENSATION_RECORD_TYPES {
        get {
            if(RESTRICTED_COMPENSATION_RECORD_TYPES == null) {
                RESTRICTED_COMPENSATION_RECORD_TYPES = RecordTypesSelector.newInstance().selectByDeveloperName('Compensation__c', new Set<String>{'EFT','Load_and_Go','Money_Order','Money_Order_Number_Required'}).keySet();
            }
            return RESTRICTED_COMPENSATION_RECORD_TYPES;
        }
        private set;
    }

    public static Set<Id> RESTRICTED_COMPENSATION_RECORD_TYPES_WITH_BANK_DETAILS_APPLIES {
        get {
            if(RESTRICTED_COMPENSATION_RECORD_TYPES == null) {
                RESTRICTED_COMPENSATION_RECORD_TYPES = RecordTypesSelector.newInstance().selectByDeveloperName('Compensation__c', new Set<String>{'EFT','Load_and_Go'}).keySet();
            }
            return RESTRICTED_COMPENSATION_RECORD_TYPES;
        }
        private set;
    }
    public Boolean isCompensationUser {
        get {
            if(isCompensationUser == null) {
                isCompensationUser = FeatureManagement.checkPermission('Is_Compensation_User');
            }
            return isCompensationUser;
        }
        private set;
    }
    public Boolean isCompensationSupervisor {
        get {
            if(isCompensationSupervisor == null) {
                isCompensationSupervisor = FeatureManagement.checkPermission('Is_Compensation_Supervisor');
            }
            return isCompensationSupervisor;
        }
        private set;
    }
    
    public EFTBankDetailsController(ApexPages.StandardController stdController) {
        showEditButton = true;
        stdCon = stdController;
        eftRecordTypeID = [select Id,Name from RecordType where SobjectType='Compensation__c' and RecordType.DeveloperName = 'EFT'].Id;

        //if standard controller id is null create new compensation. this occurs when creating new records.
        if(stdController.getId() == null) {
            record = new Compensation__c();

        }
        else {
            //quary the compensation record passed in through the std controller
            record = [SELECT Id, Case__c, Case__r.ArticleTest__c, CostCentreCode__c,Status__c, Compensation_Amount__c, Proof_of_Value__c, Service_Value__c,
                      Other__c, Discretionary_Compensation__c, Account_Name__c, Account_Number__c, BSB__c, Privacy_Check__c ,
                      Cover_Type__c , Contact__c, Legal_Entity_Name__c , Business_Account_Number__c, HasExtraCover__c, Bank_Detail_Provided_By_Customer__c, RecordTypeId
                      FROM Compensation__c
                      WHERE Id = :stdController.getId()];
        }
        // DDS-6866: checkbox for sending compensation email
        this.compensationEmail = record.Bank_Detail_Provided_By_Customer__c;
        
        //set the details provided flag if banks details are present
        if(record.Account_Number__c != null) {
            detailsProvided = true;
        }
        else
        {
            // DDS-6866: display a message on EFTBankDetails that this record is awaiting bank details from customer
            if(record.Bank_Detail_Provided_By_Customer__c)
            {
                this.awaitBankDetailsFromCustomer = true;
            }
        }
        //hide edit button if the status is processing.
        if(record.Status__c == 'Processing') {
            showEditButton = false;
        }

        // compensation restrictions
        validateOnLoad();

    }

    public PageReference editMethod() {
        //display edit screen and hide the edit button on edit button press
        showEditScreen = true;
        showEditButton = false;
        return null;
    }
    //method to create new compensations
    public PageReference insertMethod() {
        //run validation
        if(!validateDetails()) {
            try {
                //get the record passedin from stn controller.(which runs on user mode)
                record = (Compensation__c)stdCon.getRecord();
                //insert bank details captured by inputtext feilds to the compensation record
                //since this is running on system mode, users will be able to execute this even they don't have access the actual account fields.
                // DDS-6866: save bank details only if compensation email checkbox is unticked (current state)
                if (!this.compensationEmail)
                {
                    record.Account_Number__c = accountNumber;
                    record.BSB__c = accountBSB;
                    record.Account_Name__c = accountName;
                    record.Privacy_Check__c = privacyCheck;
                    record.Bank_Details_Confirmed__c = confirmDetails;
                }
                record.Bank_Detail_Provided_By_Customer__c = this.compensationEmail;

                ElevatedSharingContext context = new ElevatedSharingContext();
                context.upsertRecords(new List<SObject>{record});
                //return to the record default details page
                return new pagereference('/' + record.id);
            }
            catch(Exception e) {
                ApexPages.addMessages(e);
                return null;
            }
        }
        else {
            return null;
        }
    }
    public PageReference saveMethod()
    {

        String currentRoute = this.compensationEmail? BANK_DETAILS_VIA_FORM : BANK_DETAILS_VIA_AGENT;
        String newRoute;

        // DDS-8012: if compensation is on customer provide route and under approving, prevent agent from editting
        if (currentRoute == BANK_DETAILS_VIA_FORM && Approval.isLocked(record.Id))
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This compensation is flagged for customer provide bank details and under approval process.'));
            return null;
        }

        // DDS-8012: set the flag and route accordingly to bank details
        if (String.isNotEmpty(accountName) && String.isNotEmpty(accountNumber) && String.isNotEmpty(accountBSB))
        {
            // if agent provide bank details, set the route to agent provide and uncheck the checkbox
            record.Bank_Detail_Provided_By_Customer__c = false;
            this.compensationEmail = false;
            newRoute = BANK_DETAILS_VIA_AGENT;
        }

        // DDS-8012: update the status when route change
        if (currentRoute != newRoute)
        {
            // if compensation is at awaiting customer stage and customer update bank details via agent, update status to approved
            if (record.Status__c == SSSWConstants.STATUS_APPROVED_AWAITING_CUSTOMER && newRoute == BANK_DETAILS_VIA_AGENT)
            {
                record.Status__c = SSSWConstants.STATUS_APPROVED;
            }
        }


        //run validation
        if(!validateDetails()) {
            try {
                record.Account_Number__c = accountNumber;
                record.BSB__c = accountBSB;
                record.Account_Name__c = accountName;
                record.Privacy_Check__c = privacyCheck;
                record.Bank_Details_Confirmed__c = confirmDetails;
                ElevatedSharingContext context = new ElevatedSharingContext();
                context.upsertRecords(new List<SObject>{record});
                //show edit button and return to view screen
                showEditButton = true;
                showEditScreen = false;
                //clear properties
                accountNumber = null;
                accountBSB = null;
                accountName = null;
                privacyCheck = null;
                confirmDetails = null;
                //confirm record update
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Success! Record has been saved.');
                ApexPages.addMessage(msg);
                return null;
            }
            catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        } 
        else {
            return null;
        }
    }
    //cancel method
    public PageReference cancelMethod() {
        //clear property values
        accountNumber = null;
        accountBSB = null;
        accountName = null;
        privacyCheck = null;
        confirmDetails = null;
        //return to view screen
        showEditButton = true;
        showEditScreen = false;
        return null;
    }

    /**
     * Validate checks on load of the page
     */
    private void validateOnLoad() {
        Compensation__c record = (Compensation__c) this.stdCon.getRecord();
        // validate is required only when create record
        if(record.id != null) {
            return;
        }
        // get the related case, there must be a case as the relationship is a master detail
        Case cse = CasesSelector.newInstance(1).selectById(new Set<Id>{record.Case__c}).values()[0];
        if (RESTRICTED_COMPENSATION_RECORD_TYPES.contains(record.recordTypeId) && (!isCompensationUser && !isCompensationSupervisor)) {
            isAllowedToCreateCompensation = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CompensationMsgNoPrivilege));
        } else if (!isCompensationSupervisor) {
            // when the user is not the supervisor perform validations
            if(String.isBlank(cse.ReferenceID__c)) {
                // when the reference id is blank user should not be able to create a compensation record except supervisor
                isAllowedToCreateCompensation = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CompensationMsgCaseMustHaveReference));
            } else if (isMoreThanOneCompensationRecord(record.Case__c)) {
                // Check eligibility to create more than one Compensation record per Article, this is only allowed for Compensation Supervisor
                isAllowedToCreateCompensation = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CompensationMsgMoreThanOnePerCaseReference));
            }
        }
    }

    //used to validate the bank details entered by user
    public boolean validateDetails() {

        // DDS-6866: if user tick the send compensation email checkbox, bank details at this step is not mandatory
        if (!this.compensationEmail)
        {
            // the privacy statement have to be read to the customer before saving any bank details on the system
            if(privacyCheck == null || privacyCheck == false) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ensure that data compliance statement has been read to the customer.'));
            }
            // the privacy statement have to be read to the customer before saving any bank details on the system
            if(confirmDetails == null || confirmDetails == false) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please confirm Bank Details with the customer.'));
            }
            //cannot leave any of baking details blank
            if(String.isBlank(accountNumber) || String.isBlank(accountBSB) || String.isBlank(accountName)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Bank Details cannot be empty.'));
            }
            //number check
            if((String.isNotBlank(accountNumber) && !accountNumber.isNumeric()) || (String.isNotBlank(accountBSB) && !accountBSB.isNumeric())) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Account Number and BSB should be numbers only.'));
            }
            //bsb should only have 6 digits
            if(String.isNotBlank(accountBSB) && accountBSB.length() != 6) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'BSB should be 6 digits'));
            }
            //account bnumber should only have 9 digits
            if(String.isNotBlank(accountNumber) && accountNumber.length() > 9) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Account Number should not exceed beyond 9 digits'));
            }

            // compensation Agent permission do not have the method to manually enter the bank account details
            // and should continue using the current email method to acquire bank account details from the customer.
            // check is only against EFT and Load and Go record Types as those are the only 2 record types which accepts bank details
            Compensation__c record = (Compensation__c) this.stdCon.getRecord();
            if(RESTRICTED_COMPENSATION_RECORD_TYPES_WITH_BANK_DETAILS_APPLIES.contains(record.recordTypeId) && !isCompensationSupervisor) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CompensationMsgUserCannotUpdateBankDetails));
            }

        } else if(!isCompensationUser && !isCompensationSupervisor) {
            // User DOESN't have the system permission �CC Compensation Agent� OR,
            // the system permission �CC Compensation Supervisor� he is not allowed to send email
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CompensationMsgUserIsNotAllowedToSendEmail));
        }

        if(ApexPages.getMessages().size() > 0) {
            return true;
        }
        else {
            return false;
        }
    }

    /**
     * Checking whether If there are more than one compensation per reference ID,
     * @param caseId
     *
     * @return Boolean
     */
    public Boolean isMoreThanOneCompensationRecord(Id relatedCaseId) {
        if (String.isNotEmpty(relatedCaseId)) {
            Map<Id, List<Compensation__c>> groupedCompensationByCaseIds = CompensationService.getInstance().getCompensationRecordByCaseIds(new Set<Id>{relatedCaseId});

            if (groupedCompensationByCaseIds != null && groupedCompensationByCaseIds.containsKey(relatedCaseId)) {
                List<Compensation__c> compensationList = groupedCompensationByCaseIds.get(relatedCaseId);
                return compensationList.size() > 0;
            }
        }
        return false;
    }

    /**
	* Private inner class that elevates access/edit privileges of the current user to edit data without being limited by
	* sharing settings.
	*/
    @TestVisible
    private without sharing class ElevatedSharingContext {
        /**
		 * Insert a list of sObject records in system mode
		 * @param List<sObject>
		*/
        @TestVisible
        private void upsertRecords(List<sObject> recordList) {
            ApplicationDatabase.getInstance().dmlUpsert(recordList, Compensation__c.Id,true);
        }
    }
}