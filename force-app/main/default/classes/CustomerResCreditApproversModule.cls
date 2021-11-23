/**
 * @description
 * Domain Module to populate approvers on Credit Approvals in Customer Resolutions domain. Credit approvers are configured
 * in Credit Approval Matrix and this module is responsible for looking up the matrix to determine appropriate
 * credit approvers.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 *
 * @author Ranjeewa Silva
 * @date 2021-05-13
 * @group Domain
 * @domain Customer Resolutions
 * @changelog
 * 2021-05-13 - Ranjeewa Silva - Created.
 */

public with sharing class CustomerResCreditApproversModule extends ApplicationDomain.Module {

    // credit approver role name for 'Sales Director'. attempts to set the approver dynamically based on sales team.
    // sets the approver configured in credit approval matrix, if the approver cannot be found based on sales team.
    @TestVisible private static String DYNAMIC_APPROVER_ROLE_SALES_DIRECTOR = 'Sales Director';

    // credit approver role name for 'GM of Sales'. attempts to set the approver dynamically based on sales team.
    // sets the approver configured in credit approval matrix, if the approver cannot be found based on sales team.
    @TestVisible private static String DYNAMIC_APPROVER_ROLE_GM_OF_SALES = 'GM of Sales';

    public static CustomerResCreditApproversModule newInstance() {
        return (CustomerResCreditApproversModule)Application.Utilities.newInstance(CustomerResCreditApproversModule.class);
    }

    // Setup which triggers this module should respond to
    public CustomerResCreditApproversModule() {
        getTriggerEvents().enableBeforeUpdate();
    }

    /**
	 * Called when a Credit Approval is being updated.
	 */
    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {

        List<Credit_Approval__c> creditApprovalsToPopulateApprovers = new List<Credit_Approval__c>();

        Map<Id, Set<SObjectField>> changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{Credit_Approval__c.Type__c, Credit_Approval__c.Credit_Amount__c,
                Credit_Approval__c.Product_Family__c, Credit_Approval__c.Product_Sub_Category__c, Credit_Approval__c.Ready_For_Approval__c,
                Credit_Approval__c.Approver1Complete__c, Credit_Approval__c.Approver2Complete__c, Credit_Approval__c.Approver3Complete__c,
                Credit_Approval__c.Approver4Complete__c, Credit_Approval__c.Approver5Complete__c, Credit_Approval__c.Approver6Complete__c});

        // loop through our records to figure out what actions need to be taken
        for(Credit_Approval__c creditApproval : (List<Credit_Approval__c>)records) {
            Set<SObjectField> changed = changedRecords.get(creditApproval.Id);
            if (changed == null) changed = new Set<SObjectField>();

            if (creditApproval.Ready_For_Approval__c
                    && (changed.contains(Credit_Approval__c.Ready_For_Approval__c) || changed.contains(Credit_Approval__c.Credit_Amount__c)
                        || changed.contains(Credit_Approval__c.Type__c) || changed.contains(Credit_Approval__c.Product_Family__c)
                        || changed.contains(Credit_Approval__c.Product_Sub_Category__c))
                    && (creditApproval.Status__c == Label.I2C_New || creditApproval.Status__c == Label.I2C_Pending_Approval_Decision || creditApproval.Status__c == Label.I2C_Rejected)) {

                // populate approvers from approval matrix only when Ready_For_Approval__c = true and if any of
                // Ready_For_Approval__c, Credit_Amount__c, Type__c, Product_Family__c or Product_Sub_Category__c are changing.
                creditApprovalsToPopulateApprovers.add(creditApproval);
            }

            if (changed.contains(Credit_Approval__c.Approver1Complete__c) || changed.contains(Credit_Approval__c.Approver2Complete__c)
                    || changed.contains(Credit_Approval__c.Approver3Complete__c) || changed.contains(Credit_Approval__c.Approver4Complete__c)
                    || changed.contains(Credit_Approval__c.Approver5Complete__c) || changed.contains(Credit_Approval__c.Approver6Complete__c)) {

                // populate actual approver user when any of Approver[n]Complete__c fields are changing.
                populateActualApproverOnCompletedApproval(creditApproval, changed);
            }
        }

        if (!creditApprovalsToPopulateApprovers.isEmpty()) {

            // populate approvers for credit approvals.
            populateApprovers(creditApprovalsToPopulateApprovers);
        }
    }

    /**
     * Check if Approver[x]Complete__c field has changed and set corresponding ActualApprover[x]User__c field to
     * currently logged in user. If current step is approved, set next approver user as the current approver.
     * @param creditApproval Credit Approval to populate actual approval users.
     * @param changed Changed fields
     */
    private void populateActualApproverOnCompletedApproval(Credit_Approval__c creditApproval, Set<SObjectField> changed) {
        setActualApproverAndNextApproverUser(creditApproval, changed, Credit_Approval__c.Approver1Complete__c, Credit_Approval__c.ActualApprover1User__c, Credit_Approval__c.Approver_2__c);
        setActualApproverAndNextApproverUser(creditApproval, changed, Credit_Approval__c.Approver2Complete__c, Credit_Approval__c.ActualApprover2User__c, Credit_Approval__c.Approver_3__c);
        setActualApproverAndNextApproverUser(creditApproval, changed, Credit_Approval__c.Approver3Complete__c, Credit_Approval__c.ActualApprover3User__c, Credit_Approval__c.Approver_4__c);
        setActualApproverAndNextApproverUser(creditApproval, changed, Credit_Approval__c.Approver4Complete__c, Credit_Approval__c.ActualApprover4User__c, Credit_Approval__c.Approver_5__c);
        setActualApproverAndNextApproverUser(creditApproval, changed, Credit_Approval__c.Approver5Complete__c, Credit_Approval__c.ActualApprover5User__c, Credit_Approval__c.Approver_6__c);
        setActualApproverAndNextApproverUser(creditApproval, changed, Credit_Approval__c.Approver6Complete__c, Credit_Approval__c.ActualApprover6User__c, null);
    }

    /**
     * Inspect if the field 'approverCompleteField' passed in has changed and populate the actual approver user for the
     * this step. If  current step is approved, set next approver user as the current approver.
     *
     * @param creditApproval Credit approval to populate actual approver user
     * @param changed changed fields in credit approval record
     * @param approverCompleteField  Field to check if approver has completed the approval
     * @param actualApproverUserField Field representing actual approver user.
     * @param nextApproverUserField Field representing the approver for the next approval step.
     */
    private void setActualApproverAndNextApproverUser(Credit_Approval__c creditApproval, Set<SObjectField> changed, SObjectField approverCompleteField, SObjectField actualApproverUserField, SObjectField nextApproverUserField) {

        if (changed.contains(approverCompleteField)) {
            // approval completion status has changed. if it is null or 'Pending' set actual approver user to null.
            // else, set actual approver user to cussrent user.
            String approvalCompleted = (String) creditApproval.get(approverCompleteField);
            if (String.isBlank(approvalCompleted) || approvalCompleted.equalsIgnoreCase(CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_PENDING)) {
                creditApproval.put(actualApproverUserField, null);
            } else {
                creditApproval.put(actualApproverUserField, UserInfo.getUserId());

                // if current step is approved, set next approver user as the current approver.
                if (approvalCompleted.equalsIgnoreCase(CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_APPROVED)
                        && nextApproverUserField != null && creditApproval.get(nextApproverUserField) != null) {

                    creditApproval.Current_Approver_Name__c = (Id) creditApproval.get(nextApproverUserField);
                }
            }
        }
    }

    /**
     * Populate approvers on Credit Approvals passed in. Lookuop approvers configured in Credit Approval Matrix based on
     * Credit Type (i.e. Discretionary Credit, Non-Discretionary), Product Family, Product Sub-Category and the Credit Amount.
     *
     * For Sales Team roles 'Sales Director' and 'GM of Sales', dynamically determine approver based on the Sales Team
     * assigned to the organisation.
     *
     * @param creditApprovals list of credit approvals to set approvers.
     */
    private void populateApprovers(List<Credit_Approval__c> creditApprovals) {

        // set of product families to lookup Credit Approval Matrix records.
        // include 'default' product family.
        Set<String> productFamilies = new Set<String>();
        productFamilies.add(CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_FAMILY);

        // set of product sub categories to lookup Credit Approval Matrix records.
        // include 'default' product family.
        Set<String> productSubcategories = new Set<String>();
        productSubcategories.add(CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_SUB_CATEGORY);

        // set of credit types to lookup Credit Approval Matrix records.
        Set<String> creditTypes = new Set<String>();

        // set of sales teams to lookup approvers for dynamic sales team roles.
        Set<String> salesTeamNames = new Set<String>();

        // default 'Holding User' sales team names used in the org. If credit approval is assigned to one of these sales teams
        // populate approvers based on Credit Approval matrix even for the dynamic sales team roles.
        Set<String> defaultSalesTeamNames = getDefaultSalesTeams();

        for (Credit_Approval__c creditApproval: creditApprovals) {
            productFamilies.add(creditApproval.Product_Family__c);
            productSubcategories.add(creditApproval.Product_Sub_Category__c);
            creditTypes.add(creditApproval.Type__c);

            if (String.isNotBlank(creditApproval.Sales_Team__c) && !defaultSalesTeamNames.contains(creditApproval.Sales_Team__c)) {
                salesTeamNames.add(creditApproval.Sales_Team__c);
            }
        }

        // retrieve credit approval matrix based on credit types, product families and product sub categories collected above.
        Map<String, List<CreditApprovalMatrix__c>> approvalMatrixRecordsMap = selectCreditApprovalMatrixRecords(creditTypes, productFamilies, productSubcategories);

        // retrieve sales team hierarchy for the sales teams collected above
        Map<String, Sales_Segment_Reference__c> salesTeams = selectSalesTeamHierarchy(salesTeamNames);

        for (Credit_Approval__c creditApproval: creditApprovals) {

            // locate the credit approval matrix records applicable to credit approval
            CreditApprovalMatrix__c applicableApprovalMatrix = findCreditApprovalMatrix(creditApproval, approvalMatrixRecordsMap);

            // locate the sales team hierarchy applicable to credit approval
            Sales_Segment_Reference__c salesTeam = salesTeams.get(creditApproval.Sales_Team__c);

            if (applicableApprovalMatrix != null) {

                // credit approval matrix record has been found. set approvers based on this record.
                creditApproval.AutoApprove__c = applicableApprovalMatrix.AutoApprove__c;
                // populate approver fields for each of the approval steps. currently 6 approval steps are supported.
                populateApproverForApprovalStep(creditApproval, Credit_Approval__c.Approver_1__c, Credit_Approval__c.Approver1Role__c, Credit_Approval__c.Approver1Complete__c, Credit_Approval__c.ActualApprover1User__c, applicableApprovalMatrix.Approver_1__c, applicableApprovalMatrix.Approver1Role__c, salesTeam);
                populateApproverForApprovalStep(creditApproval, Credit_Approval__c.Approver_2__c, Credit_Approval__c.Approver2Role__c, Credit_Approval__c.Approver2Complete__c, Credit_Approval__c.ActualApprover2User__c, applicableApprovalMatrix.Approver_2__c, applicableApprovalMatrix.Approver2Role__c, salesTeam);
                populateApproverForApprovalStep(creditApproval, Credit_Approval__c.Approver_3__c, Credit_Approval__c.Approver3Role__c, Credit_Approval__c.Approver3Complete__c, Credit_Approval__c.ActualApprover3User__c, applicableApprovalMatrix.Approver_3__c, applicableApprovalMatrix.Approver3Role__c, salesTeam);
                populateApproverForApprovalStep(creditApproval, Credit_Approval__c.Approver_4__c, Credit_Approval__c.Approver4Role__c, Credit_Approval__c.Approver4Complete__c, Credit_Approval__c.ActualApprover4User__c, applicableApprovalMatrix.Approver_4__c, applicableApprovalMatrix.Approver4Role__c, salesTeam);
                populateApproverForApprovalStep(creditApproval, Credit_Approval__c.Approver_5__c, Credit_Approval__c.Approver5Role__c, Credit_Approval__c.Approver5Complete__c, Credit_Approval__c.ActualApprover5User__c, applicableApprovalMatrix.Approver_5__c, applicableApprovalMatrix.Approver5Role__c, salesTeam);
                populateApproverForApprovalStep(creditApproval, Credit_Approval__c.Approver_6__c, Credit_Approval__c.Approver6Role__c, Credit_Approval__c.Approver6Complete__c, Credit_Approval__c.ActualApprover6User__c, applicableApprovalMatrix.Approver_6__c, applicableApprovalMatrix.Approver6Role__c, salesTeam);

                creditApproval.CreditApprovalMatrix__c = applicableApprovalMatrix.Id;

            } else {
                // no matching credit approval matrix record found. force credit approval save operation to fail with an error
                creditApproval.addError(Label.CustomerResCreditApprovalMatrixRecordNotFoundErrorMessage);
            }
        }
    }

    /**
     * Populate approver details for an approval step.
     *
     * @param creditApproval Credit Approval record
     * @param approverField SObject field containing approver id for this step
     * @param approverRoleField SObject field containing approver role for this step
     * @param approverCompleteField SObject field indicating approval completion for this step
     * @param actualApproverField SObject field containing actual approver id for this step
     * @param configuredApprover Approver configured in credit approval matrix
     * @param configuredApproverRole Approver role configured in credit approval matrix
     * @param salesTeam Sales Team applicable for this credit approval
     */
    private void populateApproverForApprovalStep(Credit_Approval__c creditApproval, SObjectField approverField, SObjectField approverRoleField, SObjectField approverCompleteField, SObjectField actualApproverField, Id configuredApprover, String configuredApproverRole, Sales_Segment_Reference__c salesTeam) {
        if (String.isNotBlank(configuredApproverRole) && configuredApprover != null) {
            // approver and role is configured in credit approval matrix for this step.
            creditApproval.put(approverField, getApprover(configuredApproverRole, configuredApprover, salesTeam));
            creditApproval.put(approverRoleField, configuredApproverRole);
            creditApproval.put(approverCompleteField, CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_PENDING);
        } else {
            // approver is not configured in credit approval matrix for this step.
            // set approver, approver role and approver complete fields to null - this ensures the approver fields are reset
            // based on current credit approval matrix in the case of resubmission.
            creditApproval.put(approverField, null);
            creditApproval.put(approverRoleField, null);
            creditApproval.put(approverCompleteField, null);
        }
        creditApproval.put(actualApproverField, null);
    }

    /**
     * Determine the credit approver based on approver role.
     * If approver role is one of the sales roles where approver is determined dynamically, attempt to locate the approver
     * based on sales team hierarchy. Else assign the configuredApproverId passed in.
     *
     * @param approverRole Credit Approver role such as Customer Resolutions Manager, Sales Director
     * @param configuredApproverId Approver Id as per Credit Approval Matrix
     * @param salesTeam Sales Team hierarchy
     *
     * @return Approver Id
     */
    private Id getApprover(String approverRole, Id configuredApproverId, Sales_Segment_Reference__c salesTeam) {

        // check if the approver role is one of sales team roles where the approver should be determined dynamically
        if (!(DYNAMIC_APPROVER_ROLE_SALES_DIRECTOR.equalsIgnoreCase(approverRole) || DYNAMIC_APPROVER_ROLE_GM_OF_SALES.equalsIgnoreCase(approverRole))) {
            // approver role is not a sales team role. return the configured approver.
            return configuredApproverId;
        }

        // approver role is one of sales team roles. check if the sales team owner is valid and the sales team is not assigned
        // to 'Holding User'.
        if (!isSalesTeamOwnerAvailable(salesTeam)) {
            // sales team owner is not available. return the configured approver.
            return configuredApproverId;
        }

        //Determine approver based on Sales Team
        User salesTeamApprover = null;
        if (DYNAMIC_APPROVER_ROLE_SALES_DIRECTOR.equalsIgnoreCase(approverRole)) {
            if (Label.I2C_Sales_Director == salesTeam.Sales_Team_Owner_Type__c) {
                salesTeamApprover = salesTeam.Sales_Director__r;
            } else if (Label.I2C_Sales_Manager == salesTeam.Sales_Team_Owner_Type__c) {
                salesTeamApprover = salesTeam.Sales_Director__r.Manager;
            }
        } else if (DYNAMIC_APPROVER_ROLE_GM_OF_SALES.equalsIgnoreCase(approverRole)) {
            if (Label.I2C_Sales_Director == salesTeam.Sales_Team_Owner_Type__c) {
                salesTeamApprover = salesTeam.Sales_Director__r.Manager;
            } else if (Label.I2C_Sales_Manager == salesTeam.Sales_Team_Owner_Type__c) {
                salesTeamApprover =  salesTeam.Sales_Director__r.Manager.Manager;
            }
        }

        if (salesTeamApprover != null && salesTeamApprover.IsActive) {
            return salesTeamApprover.Id;
        }

        return configuredApproverId;
    }


    /**
     * Checks if a valid sales team owner is available. 'Holding User' is considered invalid for approval purpose.
     * @param salesTeam Sales team to check
     *
     * @return true if a valid sales team owner is available. false otherwise.
     */
    private Boolean isSalesTeamOwnerAvailable(Sales_Segment_Reference__c salesTeam) {

        if (salesTeam == null || salesTeam.Sales_Director__c == null) {
            return false;
        }

        // doing a name check to identify the 'holding user' here.
        if (salesTeam.Sales_Director__r.Name == null || salesTeam.Sales_Director__r.Name.toLowerCase().contains('holding user')) {
            return false;
        }

        return true;
    }

    /**
     * Find the matching Credit Approval Matrix record.
     * Attempt to find a match based on Credit Type, Product Family, Product Sub Category and the Credit Amount. If a match
     * based on Product Family and Product Sub Category is not available, then attempt to find a matching
     * Credit Approval Matrix with 'default' product family and product sub category.
     *
     * @param creditApproval Credit Approval record where a matching credit approval matrix record needs to be found.
     * @param approvalMatrixRecordsMap Map of credit approval matrix records in the system. Key = Credit Type | Product Family | Product Sub-Category
     *
     * @return the matching Credit Approval Matrix record. returns null if a match cannot be found.
     */
    private CreditApprovalMatrix__c findCreditApprovalMatrix(Credit_Approval__c creditApproval, Map<String, List<CreditApprovalMatrix__c>> approvalMatrixRecordsMap) {

        // first find the credit approval matrix records applicable for the credit approval based on Credit Type, Product Family and Product Sub Category
        List<CreditApprovalMatrix__c> applicableApprovalMatrixRecords = findApprovalMatrixByCreditTypeProduct(creditApproval.Type__c, creditApproval.Product_Family__c, creditApproval.Product_Sub_Category__c, approvalMatrixRecordsMap);

        // now attempt to find the relevant credit approval matrix record based on credit amount.
        // approval matrix collection must be ordered by ToCreditAmount asc
        for (CreditApprovalMatrix__c approvalMatrix: applicableApprovalMatrixRecords) {
            if (approvalMatrix.FromCreditAmount__c <= creditApproval.Credit_Amount__c && approvalMatrix.ToCreditAmount__c >= creditApproval.Credit_Amount__c) {
                return approvalMatrix;
            }
        }

        return null;
    }

    List<CreditApprovalMatrix__c> findApprovalMatrixByCreditTypeProduct(String creditType, String productFamily, String productSubCategory, Map<String, List<CreditApprovalMatrix__c>> approvalMatrixRecordsMap) {

        // first attempt to find a match based on Credit type, Product Family and Product Sub-Category of the Credit approval
        String approvalMatrixLookupKey = getCreditApprovalMatrixLookupKey(creditType, productFamily, productSubCategory);
        if (approvalMatrixRecordsMap.containsKey(approvalMatrixLookupKey)) {
            return approvalMatrixRecordsMap.get(approvalMatrixLookupKey);
        }

        // No match found. Now attempt to find a match based on Credit Type, Product Family and no specific
        // product sub category (i.e. Product Sub-Category set to 'default')
        approvalMatrixLookupKey = getCreditApprovalMatrixLookupKey(creditType, productFamily, CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_SUB_CATEGORY);
        if (approvalMatrixRecordsMap.containsKey(approvalMatrixLookupKey)) {
            return approvalMatrixRecordsMap.get(approvalMatrixLookupKey);
        }

        // No match found. Now attempt to find a match based on Credit Type and with no specific product family
        // and product sub category (i.e. Product Family and Product Sub-Category set to 'default')
        approvalMatrixLookupKey = getCreditApprovalMatrixLookupKey(creditType, CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_FAMILY, CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_SUB_CATEGORY);
        if (approvalMatrixRecordsMap.containsKey(approvalMatrixLookupKey)) {
            return approvalMatrixRecordsMap.get(approvalMatrixLookupKey);
        }

        // no match found. return an empty list.
        return new List<CreditApprovalMatrix__c>();
    }

    /**
     * Select credit approval matrix records based on credit types, product families and product sub categories passed in.
     *
     * @param creditTypes credit types to filter credit approval matrix records
     * @param productFamilies product families to filter credit approval matrix records
     * @param productSubCategories product sub-categories to filter credit approval matrix records
     *
     * @return Credit Approval Matrix records indexed by "Credit Type | Product Family | Product Sub-Category"
     */
    public Map<String, List<CreditApprovalMatrix__c>> selectCreditApprovalMatrixRecords(Set<String> creditTypes, Set<String> productFamilies, Set<String> productSubCategories) {

        Map<String, List<CreditApprovalMatrix__c>> creditApprovalMatrixRecordsByCreditTypeAndProduct = new Map<String, List<CreditApprovalMatrix__c>>();

        List<CreditApprovalMatrix__c> creditApprovalMatrixRecords = CreditApprovalMatrixSelector.newInstance().selectByCreditTypeAndProductInOrder(creditTypes, productFamilies, productSubCategories, new Set<Object>());

        for (CreditApprovalMatrix__c creditApprovalMatrix: creditApprovalMatrixRecords) {
            String approvalMatrixKey = getCreditApprovalMatrixLookupKey(creditApprovalMatrix.CreditType__c, creditApprovalMatrix.Product_Family__c, creditApprovalMatrix.Product_Sub_Category__c);
            List<CreditApprovalMatrix__c> approvalMatrixList = creditApprovalMatrixRecordsByCreditTypeAndProduct.get(approvalMatrixKey);
            if (approvalMatrixList == null) {
                approvalMatrixList = new List<CreditApprovalMatrix__c>();
                creditApprovalMatrixRecordsByCreditTypeAndProduct.put(approvalMatrixKey, approvalMatrixList);
            }
            approvalMatrixList.add(creditApprovalMatrix);
        }

        return creditApprovalMatrixRecordsByCreditTypeAndProduct;
    }

    /**
     * Return the key to use for looking up credit approval matrix.
     *
     * @param creditType Credit Type - i.e. Discretionary Credit or Non-Discretionary
     * @param productFamily Product Family
     * @param productSubCategory Product Sub Category
     *
     * @return key for looking up credit approval matrix
     */
    private String getCreditApprovalMatrixLookupKey(String creditType, String productFamily, String productSubCategory) {
        String lookupKey = '';
        if (String.isNotBlank(creditType)) {
            lookupKey += creditType.trim();
        }

        lookupKey += '|';

        if (String.isNotBlank(productFamily)) {
            lookupKey += productFamily.trim();
        }

        lookupKey += '|';

        if (String.isNotBlank(productSubCategory)) {
            lookupKey += productSubCategory.trim();
        }

        return lookupKey;
    }

    /**
     * Get the list of default sales teams (e.g. 'Holding User') used in the org. Default sales teams are used
     * when the Organisation is not allocated to a specific sales team.
     *
     * @return the default sales teams
     */
    private Set<String> getDefaultSalesTeams() {
        Set<String> defaultSalesTeams = new Set<String>();

        //TODO evaluate the need for having a custom setting
        for(Default_Sales_Teams__c defST : Default_Sales_Teams__c.getall().values()){
            defaultSalesTeams.add(defST.Name);
        }

        return defaultSalesTeams;
    }

    /**
     * Retrieve Sales Team Hierarchy records for the sales teams passed in.
     *
     * @param salesTeamNames sales team names to retrieve the sales team hierarchy
     *
     * @return sales team hierarchy
     */
    private Map<String, Sales_Segment_Reference__c> selectSalesTeamHierarchy(Set<String> salesTeamNames) {

        Map<String, Sales_Segment_Reference__c> salesTeamHierarchy = new Map<String, Sales_Segment_Reference__c>();
        for (Sales_Segment_Reference__c salesSegmentReference: [SELECT Id, Sales_Segment__c, Sales_Team_Owner_Type__c,
                                                                        Sales_Director__c, Sales_Director__r.Name, Sales_Director__r.IsActive,
                                                                        Sales_Director__r.ManagerId, Sales_Director__r.Manager.IsActive,
                                                                        Sales_Director__r.Manager.ManagerId, Sales_Director__r.Manager.Manager.IsActive
                                                                    FROM Sales_Segment_Reference__c
                                                                    Where Sales_Segment__c IN :salesTeamNames]) {

            salesTeamHierarchy.put(salesSegmentReference.Sales_Segment__c, salesSegmentReference);
        }
        return salesTeamHierarchy;
    }


    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
    public class Constructor implements ApplicationDomain.IConstructableModule {
        public ApplicationDomain.Module construct() {
            return (ApplicationDomain.Module)CustomerResCreditApproversModule.newInstance();
        }
    }

}