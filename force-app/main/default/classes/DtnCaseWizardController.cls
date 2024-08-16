/**
 * @author Ranjeewa Silva
 * @date 2020-10-21
 * @group DirectToNetworkCaseCreation
 * @tag Case
 * @description Controller for Direct to Network Case Lightning wizard.
 * @changelog
 * 2020-10-21 - Ranjeewa Silva - Created
 * 2020-11-09 - Ranjeewa Silva - Populate 'Sent to Netowrk Date' field on Direct to Network Case created.
 * 2021-08-17 - Alex Volkov - Set "Bypass Routing Rules on Creation" flag
 * 2021-10-10 - Nathan Franklin - Refactor attach safe drop to new DeliveryProofService class
 */
public with sharing class DtnCaseWizardController {

    // Queue to assign the Direct to Network Case
    private static final String SSSW_NETWORK_QUEUE = 'SSSWNetworkQueue';

    // Case status to set on Direct to Network Case
    private static final String STATUS_AWAITING_NETWORK_RESPONSE = 'Awaiting Network Response';

    // Parameters related to Case duplicate check
    @TestVisible private static final Set<String> DUPLICATE_CHECK_EXCLUDED_PRODUCT_CATEGORIES = new Set<String>{ 'Money & Insurance', 'Post Office & Business Hub Services', 'Travel & ID', 'Web & Apps'};
    @TestVisible private static final String DUPLICATE_CHECK_EXCLUDED_CASE_TYPE = 'General Enquiry';
    @TestVisible private static final String DUPLICATE_CHECK_EXCLUDED_PRODUCT_SUB_CATEGORY = 'Unaddressed Mail';

    /**
	 * Determines whether or not the agent is an HLC agent or not
	 * This is used to enable the user to bypass the duplicate check on case creation
	 */
    @TestVisible
    private static Boolean isHLCUser {
        get {
            if(isHLCUser == null) {
                isHLCUser = (GroupMembersSelector.newInstance().countByMyGroups(new List<String>{'SSSW High Level Complaints', 'SSSW Customer Recovery'}) > 0);
            }
            return isHLCUser;
        }
        private set;
    }

    /**
     * Create case and assign direct to network.
     *
     * @param newCase new case record to insert.
     * @param ignoreDuplicates By-pass duplicate check for HLC users if set to true.
     * @param attachSafedrop Attach safedrop image to case if set to true. Safedrop image is attached asynchronously.
     * @return DTN Case Save results
     */
    @AuraEnabled
    public static DTNCaseSaveResult createCaseDirectToNetwork(Case newCase, Boolean ignoreDuplicates, Boolean attachSafedrop) {

        System.debug('newCase = ' + newCase);
        System.debug('ignoreDuplicates = ' + ignoreDuplicates);

        DTNCaseSaveResult dtnCaseSaveResult = new DTNCaseSaveResult();

        try {
            // Duplicate check is not required for HLC users if the user has elected to create the case ignoring
            // duplicates. Duplicate check must be done for all other scenarios.
            if ((ignoreDuplicates == true && isHLCUser) || !isDuplicate(newCase)) {
                newCase.Status = STATUS_AWAITING_NETWORK_RESPONSE;
                newCase.Automated_Network_Assignment__c = true;
                newCase.ByPassRoutingRulesOnCreation__c = true;

                // Case must be assigned to queue - 'SSSWNetworkQueue'
                Map<Id, Group> groups = GroupsSelector.newInstance().selectByDeveloperName(new Set<String>{SSSW_NETWORK_QUEUE});
                if (!groups.isEmpty()) {
                    newCase.OwnerId = groups.values()[0].id;
                    newCase.Sent_To_Network_Date__c = System.now();
                }

                // insert new case
                ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{newCase});

                dtnCaseSaveResult.status = Status.SUCCESSFUL.name();
                dtnCaseSaveResult.caseId = newCase.Id;

                if (attachSafedrop == true) {
                    // attach the pdf delivery proof to the case in an async process
                    DeliveryProofService.getInstance().enqueueAttachAPDeliveryProof(new Set<Id>{newCase.Id});
                }
            } else {
                //Case failed the duplicate check. Return error.
                dtnCaseSaveResult.status = Status.DUPLICATE.name();
                dtnCaseSaveResult.canIgnoreDuplicate = isHLCUser;
                dtnCaseSaveResult.errorMessage = (isHLCUser ? System.Label.DirectToNetworkDuplicateCaseWarningMessage : System.Label.DirectToNetworkDuplicateCaseErrorMessage);
            }

        } catch (Exception ex) {
            //handle error
            dtnCaseSaveResult.status = Status.ERROR.name();
            dtnCaseSaveResult.errorMessage = ex.getMessage();
        } finally {
            System.debug('dtnCaseSaveResult' + dtnCaseSaveResult);
        }

        return dtnCaseSaveResult;
    }

    /**
     * Perform duplicate check on the case.
     * @param newCase new case record to check for duplicates
     * @return true if duplicates are found, false otherwise.
     */
    @AuraEnabled
    public static DuplicateCheckResult doDuplicateCheck(Case newCase) {
        DuplicateCheckResult duplicateCheckResult = new DuplicateCheckResult();
        duplicateCheckResult.isDuplicate = isDuplicate(newCase);
        if (duplicateCheckResult.isDuplicate) {
            // If duplicates are found, check if the current user can ignore duplicates and proceed
            duplicateCheckResult.canIgnoreDuplicate = isHLCUser;
            // Error/Warning message to display.
            duplicateCheckResult.errorMessage = (isHLCUser ? System.Label.DirectToNetworkDuplicateCaseWarningMessage : System.Label.DirectToNetworkDuplicateCaseErrorMessage);
        }
        return duplicateCheckResult;
    }

    /**
     * Determine default case description based on the description rules configured in SSSWRouting__c (Record Type = SSSWDescription)
     * @param newCase case record to evaluate description rules
     * @return the case description
     */
    @AuraEnabled
    public static String getCaseDescriptionDefaultValue(Case newCase) {
        SSSW_Routing.populateCaseDescriptionFromDescriptionRules(new List<Case>{newCase}, null);
        //Return the case description
        return newCase.Description;
    }

    /**
     * Check if case is an duplicate.
     * @param newCase the case record
     * @return true if duplicates are found. false otherwise.
     */
    private static Boolean isDuplicate(Case newCase) {
        if (!String.isBlank(newCase.ReferenceID__c) &&
                !DUPLICATE_CHECK_EXCLUDED_PRODUCT_CATEGORIES.contains(newCase.ProductCategory__c) &&
                !DUPLICATE_CHECK_EXCLUDED_PRODUCT_SUB_CATEGORY.equalsIgnoreCase(newCase.ProductSubCategory__c) &&
                !DUPLICATE_CHECK_EXCLUDED_CASE_TYPE.equalsIgnoreCase(newCase.Type)) {

            Integer duplicateCaseCount = SSSWCasesSelector.newInstance().countOpenCasesByReferenceId(new Set<String>{newCase.ReferenceID__c});
            if (duplicateCaseCount > 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * Status of create Case operation.
     */
    public enum Status {
        SUCCESSFUL,
        DUPLICATE,
        ERROR
    }

    /**
     * Outcome of the Direct to Network Case creation.
     * If successful, status is set to 'SUCCESSFUL' and 'caseId' is populated.
     * If duplicate check failed, status is set to 'DUPLICATE' and error details are populated in 'errorMessage'
     * If any unexpected error, status is set to 'ERROR' and error details are populated in 'errorMessage'
     */
    public class DTNCaseSaveResult {
        @AuraEnabled public Id caseId {get; private set;}
        @AuraEnabled public String errorMessage {get; private set;}
        @AuraEnabled public String status {get; private set;}
        @AuraEnabled public Boolean canIgnoreDuplicate {get; private set;}
    }

    /**
     * Outcome of the duplicate check.
     */
    public class DuplicateCheckResult {
        // true if duplicates are found
        @AuraEnabled public Boolean isDuplicate {get; private set;}
        // can current user ignore duplicates and proceed. Only set if duplicates are found.
        @AuraEnabled public Boolean canIgnoreDuplicate {get; private set;}
        // error message to display
        @AuraEnabled public String errorMessage {get; private set;}
    }
}