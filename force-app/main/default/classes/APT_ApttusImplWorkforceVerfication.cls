/**************************************************
Description: Class Which Implements APT_IApttusCaseAutomation Interface
History    : 2019-08-05 Neha - Define methos for all the customization required for Workflow verification
**************************************************/
public class APT_ApttusImplWorkforceVerfication implements APT_IApttusCaseAutomation {

    private String refProductType;
    private String recordTypeName;
    //find Record Id to assign
    private RecordType acicRecordType;

   /*This is method is used to Create Case on Proposal
   * @param List<Apttus_Proposal__Proposal__c> will get List of Proposal
   * @param Map<Id, Apttus_Proposal__Proposal__c> will get Map of Old Proposal
   */
    public void caseCreate(List<Apttus_Proposal__Proposal__c> listProposal, Map<Id, Apttus_Proposal__Proposal__c> mapProposalOld) {
        try {
            //Call to all the other related methods to get Proposal,Proposal Line Item and Custom Meta data setting.
            List<Apttus_Proposal__Proposal__c> approvedProposals = getApprovedProposal(listProposal, mapProposalOld);
            List<Apttus_Proposal__Proposal_Line_Item__c> proposalLineItemList = getApprovedProposalLineItemsPerProposal(approvedProposals);
            Boolean validateCustomMetaDataBoolean = getValidateCustomMetaDataSetting(proposalLineItemList);
            //Exist Code if Boolean value which matches the Custom metadata setting does not match
            if (validateCustomMetaDataBoolean == false) {
                return;
            }

            //Create Case Define variable
            List<Case> casesToCreate = new List<Case>();
            Group ownerQueue;

            //Loop to find the Product Name 'Workforce Verification' in Proposal Line Item
            for (Apttus_Proposal__Proposal_Line_Item__c pli : proposalLineItemList) {

                //Fetching the active assignment rules on case
                AssignmentRule AR = new AssignmentRule();
                AR = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = TRUE LIMIT 1];

                //Creating the DMLOptions for "Assign using active assignment rules" checkbox
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = AR.Id;
                dmlOpts.emailHeader.triggerUserEmail = true;

                //Check if the Custom Meta Information matches the ProductLineItem Information
                if ((refProductType != null && refProductType.equalsIgnoreCase(pli.Apttus_Proposal__Product__r.APT_Product_type__c))) {
                    //Auto Case Create with record type ACIC Case
                    System.debug('--------Inside Create Case -----------');
                    Case acicCase = new Case();
                    acicCase.RecordTypeId = acicRecordType.Id;
                    acicCase.setOptions(dmlOpts);
                    acicCase.Proposal__c = pli.Apttus_Proposal__Proposal__c;
                    acicCase.APT_Approved_Entities__c = pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__r.Name;
                    acicCase.APT_Approved_ABN__c = pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__r.ABN__c;
                    acicCase.Subject = 'ACIC Case: ' + pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__r.Name;
                    acicCase.AccountId=pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__c;
                    acicCase.APT_ABN__c=pli.Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__r.ABN__c;
                    acicCase.Requestor__c=UserInfo.getUserId();
                    casesToCreate.add(acicCase);

                }
            }

            System.debug('--------List to be inserted --------' + casesToCreate);
            //Check if ACIC case already created
            if (!casesToCreate.isEmpty()) {
                insert casesToCreate;
            }
            System.debug('--------inserted cases--------' + casesToCreate);
        }
        //Logic to Catch Exception
        catch (Exception ex) {
            System.debug(ex);
            System.debug('Error in APT_ApttusImplWorkforceVerfication caseCreate' + ex.getLineNumber() + ' ' + ex.getStackTraceString()+' '+ex.getMessage());
        }
    }

    /*This is method is get the Proposal details
    * @param List<Apttus_Proposal__Proposal__c> will get List of Proposal
    * @param Map<Id, Apttus_Proposal__Proposal__c> will get Map of Old Proposal
    */
    public list<Apttus_Proposal__Proposal__c> getApprovedProposal(List<Apttus_Proposal__Proposal__c> listProposal, Map<Id, Apttus_Proposal__Proposal__c> mapProposalOld) {
        System.debug('---- createCaseOnProposalUpdate ----');
        List<Apttus_Proposal__Proposal__c> approvedProposals = new List<Apttus_Proposal__Proposal__c>();
        // create a case only for approved proposals
        for (Apttus_Proposal__Proposal__c proposal : listProposal) {
            Apttus_Proposal__Proposal__c oldProposal = mapProposalOld.get(proposal.Id);
            //Check for Proposal Stage Accepted
            if (oldProposal.Apttus_Proposal__Approval_Stage__c != APT_Constants.APPROVAL_STAGE_ACCEPTED
                    && proposal.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_ACCEPTED) {
                approvedProposals.add(proposal);
            }
        }
        System.debug('---- createCaseOnProposalUpdate approvedProposals----' + approvedProposals);
        return approvedProposals;


    }

    /*This is method is get the Proposal Line Item
    * @param List<Apttus_Proposal__Proposal__c>  List of Proposal for which we need to get Proposal Line Item
    */
    public List<Apttus_Proposal__Proposal_Line_Item__c> getApprovedProposalLineItemsPerProposal(List<Apttus_Proposal__Proposal__c> approvedProposals) {
        // This list should have one product Line Item per proposal
        List<Apttus_Proposal__Proposal_Line_Item__c> subProposalLineItems = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        try {
            //Get the list of Proposal Line item from the Proposal
            List<Apttus_Proposal__Proposal_Line_Item__c> proposalLineItems = new List<Apttus_Proposal__Proposal_Line_Item__c>();
            proposalLineItems = [
                    SELECT Id, Apttus_Proposal__Proposal__c,Apttus_Proposal__Product__r.APT_Product_type__c
                    FROM Apttus_Proposal__Proposal_Line_Item__c
                    WHERE Apttus_Proposal__Proposal__c
                            IN :approvedProposals
            ];

            // Only one case to be created per proposal
            // map of ProposalId and PropsalLineItemId
            Map<Id, Id> propPropLiIdMap = new Map<Id, Id>();
            for (Apttus_Proposal__Proposal_Line_Item__c pli : proposalLineItems) {
                propPropLiIdMap.put(pli.Apttus_Proposal__Proposal__c, pli.Id);
            }
            System.debug('---- createCaseOnProposalUpdate propPropLiIdMap----' + propPropLiIdMap);


            subProposalLineItems = [
                    SELECT Id, Apttus_Proposal__Proposal__c,Apttus_Proposal__Product__r.APT_Product_type__c,Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__r.ABN__c,
                            Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__r.Name
                    FROM Apttus_Proposal__Proposal_Line_Item__c
                    WHERE Id
                            IN :propPropLiIdMap.values()
            ];
            System.debug('-------Apttus_Proposal_Automation listProposalLineItems subProposalLineItems-------' + subProposalLineItems);
            // New logic end

        } catch (Exception ex) {
            System.debug('Query Exception for proposalLineItem ' + ex.getLineNumber() + ' ' + ex.getStackTraceString());
        }
        return subProposalLineItems;


    }

    /*This is method will match the custom meta data setting value with Product Line item's detail and return boolean value
    * @param List<Apttus_Proposal__Proposal_Line_Item__c>  List of Proposal Line Item
    */
    public Boolean getValidateCustomMetaDataSetting(List<Apttus_Proposal__Proposal_Line_Item__c> subProposalLineItems) {

        try {
            //Run Query to get Custom Meta Details
            Apttus_Proposal_Automation__mdt settings = [
                    SELECT MasterLabel,QualifiedApiName,Product_Type__c, Queue_Name__c,Record_Type__c
                    FROM Apttus_Proposal_Automation__mdt
                    LIMIT 1
            ];
            System.debug('-------Apttus_Proposal_Automation Custom metadata record Setting-------' + settings);

            //Run Query to get Product Line Item information
            List<Apttus_Proposal__Proposal_Line_Item__c> proposalLineItemList = [
                    SELECT Id,Apttus_Proposal__Proposal__c, Apttus_Proposal__Product__r.APT_Product_type__c,Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__r.Name,
                            Apttus_Proposal__Proposal__r.Apttus_Proposal__Account__r.ABN__c
                    FROM Apttus_Proposal__Proposal_Line_Item__c
                    WHERE Id
                            IN :subProposalLineItems
            ];
            System.debug('-------Query to get Proposal Line Item proposalLineItemList-------' + proposalLineItemList);
            //Get the Information related to RecordType and ProductTyoe from Custom Metadata

            refProductType = (settings != null && settings.Product_Type__c != null) ? settings.Product_Type__c : null;
            recordTypeName = (settings != null && settings.Record_Type__c != null) ? settings.Record_Type__c : null;


            if (recordTypeName != null) {
                acicRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypeName LIMIT 1];
                return true;
            }


        } catch (Exception ex) {
            System.debug('Query Exception for getValidateCustomMetaDataSetting: ' + ex.getLineNumber() + ' ' + ex.getStackTraceString());
        }
        return false;

    }

}