/**************************************************
Type:       Utility Class for Opportunity Object
Purpose:    The updateAccountPlan method rolls up Opportunity Amounts
            to the corresponding Account Plan Opportunity Value             
History:
--------------------------------------------------
15.09.2011      Richard Enojas(Salesforce.com)      Created
22.09.2011      Prakash Varsani                     Added code to create an Opportunity Assessment record automatically
05.06.2012      Joseph Barrameda (Cloud Sherpas)    Added code to update Owner_Employee_Number__c (S2)
19.06.2012      Joseph Barrameda (Cloud Sherpas)    Added code to assign Sales Representative to an Opportunity (S2)
25.07.2012      M. Isidro (Cloud Sherpas)           Added checkContractDates method to check on Contract dates
08.08.2012      M. Isidro (Cloud Sherpas)           Added filter in the query of Accounts in the assignOpportunityOwner method to avoid governor limits 
14.08.2012      Richard Enojas (Salesforce.com)     Modified logic for Opportunity Assignment based on Postal Code and Opportunity Initial Estimate
15.08.2012      Richard Enojas (Salesforce.com)     Added code to update Hidden Close Date
05.09.2012      M. Isidro (Cloud Sherpas)           Commented out codes not in use and increased test coverage 
15.01.2014      Louis Wang (Bluewolf)               Update test class code such that it no longer referring to out-of-date page LeadConvert1
09.07.2015      Eric Shen(Auspost)                  update    opp.StageName= 'Identify';
22.09.2016      Davey Yu (Accenture)                Updated: MPB Known Acccount Management - Territory based assignment for known accounts
17.10.2017      Adrian Recio (Accenture)            Updated: Product check added in Territory Assignment Matrix which is part of Lead Convert Minor works
23.03.2018      Adrian Recio (Accenture)            Updated: Added additional condition to increase range of rate coverage for territory assignment
03.06.2019      Jeoffrey Palmero (Accenture)        Updated: Added methods for creation of Team Member and Split, and Profile Validation
28.01.2020      Jansi                               Commented out Opportunity  Territory Assignment Matrix rules
28/05/2020      Lija Jawahar                        SOQL Error fix update - only update if the value has changed
2020-08-02 - Nathan Franklin - Refactoring. Removing the need for updateOwnerEmployeeNumber
2020-08-10 - Ranjeewa Silva  - Optimised checkIfAllowedToCloseWin method to check for closed won opportunities before proceeding.
2020-09-08      Seth Heang                          STP-2226: Added validation to check for duplicate opportunity line items upon closing as "Close Won"
2020-09-09      arjun.singh@auspost.com.au          Modified the checkIfAllowedToCloseWin method to capture all the possible validation rules
2020-30-11		seth.heang@auspost.com.au			Update the checkIfAllowedToCloseWin method to auto-populate opportunity's close date to Today prior to Opportunity Closure
**************************************************/
public with sharing class OpportunityUtility {
    public static final String CLASSNAME = 'OpportunityUtility';
    public static final String ORGID = UserInfo.getOrganizationId();
    public static final String triggerName = 'opportunityTrigger_16112011';
    public static final String STRING_YES = 'Yes';
    public static final String STRING_COMPLETED = 'Completed';

    public static void updateAccountPlan (Set<Id> planIds){
        // 28/05/2020 LJ only update if the value has changed
        List<Account_Plan__c> accontPlanToUpdate = new List<Account_Plan__c>();
        Map<Id,Account_Plan__c> acctplansToUpdate = new Map<Id,Account_Plan__c> ([
                SELECT Id, Opportunity_Value__c,(SELECT Id, Amount FROM Opportunities__r)
                FROM Account_Plan__c
                WHERE Id IN : planIds]);

        //Loop through plans
        for (Account_Plan__c plan : acctplansToUpdate.values()){

            //to compare this later
            Double initialOppvalue  = plan.Opportunity_Value__c;
            //Initialize
            Double sumAmount = 0;
            //Loop through associated opportunities
            for (Opportunity oppty: plan.Opportunities__r){
                if (oppty.Amount!=null){
                    sumAmount += oppty.Amount;
                }
            }

            //Set the rollup sum
            plan.Opportunity_Value__c = sumAmount;
            if(initialOppvalue != plan.Opportunity_Value__c){
                accontPlanToUpdate.add(plan);
            }
        }

        update accontPlanToUpdate;
    }

//    public static void updateOwnerEmployeeNumber(List<Opportunity> oppList){
//        List <Id> oppOwnerIdList = new List <Id>();
//        List <User> userList = new List <User>();
//        Map <Id,String> oppOwnerIDMap = new Map <Id,String>();
//
//        if (oppList!=null){
//            for (Opportunity tmp: oppList){
//                oppOwnerIdList.add (tmp.OwnerId);
//            }
//            userList = [Select Id, EmployeeNumber from User where ID in: oppOwnerIdList];
//            for (User uLst : userList){
//                oppOwnerIDMap.put( uLst.Id, uLst.EmployeeNumber);
//            }
//            for (Opportunity tmpOpp: oppList){
//                tmpOpp.Owner_Employee_Number__c= oppOwnerIDMap.get(tmpOpp.OwnerId);
//            }
//        }
//    }

/*
    //Phase 2 - Update Hidden Close Date with Today's date. Field is used by SAP for snapshot filtering.
    public static void updateHiddenCloseDate (List<Opportunity> oppList){
        if (oppList!=null){
            for (Opportunity opp: oppList){
                opp.Hidden_Close_Date__c=date.today();
            }
        }
    }
*/

    public static void assignSalesRep (List <Opportunity> oppList ){
        List <Opportunity> oppList1 = new List <Opportunity>();
        List <Opportunity> oppList2 = new List <Opportunity>();
        List <Opportunity> oppUpdate = new List <Opportunity>();
        List <String> oppIdList = new List <String>();
        List <String> postCodeList = new List<String>();
        Boolean isFound = false ;

        Id hUserId = new HoldingUserFetcher().getUserId();

        for (Opportunity tmpOpp: oppList){
            oppIdList.add(tmpOpp.Id);
        }

        //Scenario 1: Opportunity (via Lead Conversion) is for Prospect or Account is owned by Holding User, do territory-based assignment
        //Scenario 2: Opportunity (via Lead Conversion or direct) is for a Customer not owned by Holding User, assign to Account Owner
        for (Opportunity tmpOpp: [SELECT Name, Account.Role_Type_Roll_Up__c, Account.BillingPostalCode, Account.OwnerId,
                Lead_ID__c, Opportunity_Initial_Estimate__c, OwnerId, Product__c // Added by Adrian Recio, Part of lead convert minor works
        FROM Opportunity  WHERE Id IN: oppIdList]){

            System.debug ('### tmpOpp Lead: ' + tmpOpp.Lead_ID__c);
            System.debug ('### tmpOpp Account Role: ' + tmpOpp.Account.Role_Type_Roll_Up__c);
            System.debug ('### tmpOpp Account Owner Id: ' + tmpOpp.Account.OwnerId);
            System.debug ('### hUserId: ' + hUserId);
            System.debug ('### tmpOpp Account Postal Code: ' + tmpOpp.Account.BillingPostalCode);

            // START OF UPDATE DY 22.09.2016 MPB - Include type known to do a territory based assignment
            if (tmpOpp.Lead_ID__c!=null && (tmpOpp.Account.Role_Type_Roll_Up__c =='Prospect' ||
                    tmpOpp.Account.Role_Type_Roll_Up__c =='Known' ||
                    tmpOpp.Account.OwnerId == hUserId)){
                System.debug('### Scenario 1 ###');
                oppList1.add(tmpOpp);
                //oppIdList.add(tmpOpp.id);
                postCodeList.add(tmpOpp.Account.BillingPostalCode);
            }
            // END OF UPDATE DY 22.09.2016 MPB - Include type known to do a territory based assignment

            else if (tmpOpp.Account.Role_Type_Roll_Up__c == 'Customer' &&
                    tmpOpp.Account.OwnerId != hUserId){
                System.debug('### Scenario 2 ###');
                tmpOpp.OwnerId = tmpOpp.Account.OwnerId;
                oppList2.add(tmpOpp);
            }

        }
        System.debug ('#### OPP LIST-Scenario 1: ' + oppList1);
        System.debug ('#### OPP LIST-Scenario 2: ' + oppList2);


        if (!oppList2.isEmpty()) {
            oppUpdate.addAll(oppList2);
        }
        //-- [Jansi]: Commented below block for US - STP-108
        /*if (!oppList1.isEmpty()){
            System.debug ('############# SALES REP ###############');

            List <Territory_Assignment_Matrix__c> territoryList = [SELECT Post_Code__c, Sales_Team__c, Sales_Team_Member__c,
                    High_Threshold_amount__c, Low_Threshold_Amount__c, Product__c // Added by Adrian Recio, Part of lead convert minor works
            FROM Territory_Assignment_Matrix__c
            WHERE Post_Code__c IN : postCodeList];
            String defaultSalesRep = ConfigSetting__c.getInstance().OpportunityDriverDefaultUserId__c;

            for (Opportunity tmpOpp: oppList1){
                for (Territory_Assignment_Matrix__c tmpTerritory : territoryList){
                    if(tmpTerritory.Post_Code__c == tmpOpp.Account.BillingPostalCode){

                        //Assumption here is that Low and High reference values will be set up correctly, eg
                        //Low - 0, High - 40000.99
                        //Low - 40001, High - 80000.99
                        //Low - 80001, High - null
                        //Increased coverage of threshold amount. Added >= and <= condition.
                        if (tmpOpp.Opportunity_Initial_Estimate__c >= tmpTerritory.Low_Threshold_Amount__c &&
                                (tmpOpp.Opportunity_Initial_Estimate__c <= tmpTerritory.High_Threshold_amount__c ||
                                        tmpTerritory.High_Threshold_amount__c == null) && tmpOpp.Product__c == tmpTerritory.Product__c){ // Added by Adrian Recio, Part of lead convert minor works

                            System.debug('*****LOW: ' + tmpTerritory.Low_Threshold_Amount__c);
                            System.debug('*****HIGH: ' + tmpTerritory.High_Threshold_amount__c);

                            tmpOpp.OwnerId= tmpTerritory.Sales_Team_Member__c ;
                            oppUpdate.add(tmpOpp);
                            isFound=true;
                            break;
                        }
                    }
                }

                if (isFound<>true){
                    tmpOpp.OwnerId= defaultSalesRep;
                    oppUpdate.add (tmpOpp);
                }
                isFound=false;
            }

            System.debug('####### TERRITORY LIST #######' + oppUpdate);

            if (!oppUpdate.isEmpty())
                update oppUpdate;
        }*/
    }

    /**
     * Description: A tactical fix to the issue where Guest Users of SecurePay community try to create Opportunities. Since OpportunityUtility is 'with sharing', Guest user cannot access Users. As a workaround, this 'without sharing' class was created to fetch Users.
     *
     * History
     * 27/02/2020   gunith.devasurendra@auspost.com.au Created (REQ2115474)
     */
    without sharing class HoldingUserFetcher{
        /**
         * Gets the ID from the Holding User
         *
         * @return
         */
        public Id getUserId() {
            return [SELECT ID from User where Name = 'Holding User' LIMIT 1].Id;
        }
    }


/*
    public static void assignOpportunityOwner (List <Opportunity> oppList ){
        List <Id> oppIdList =new List <Id>();
        List <Id> acctIdList = new List <Id>();
        List <Opportunity> oppUpdate = new List < Opportunity>();

        for (Opportunity tmpOpp: oppList){
                if ((tmpOpp.Lead_ID__c !=null )){
                     oppIdList.add (tmpOpp.id);
                     acctIdList.add (tmpOpp.Account.Id);
                }
        }

        if (oppIdList !=null){
          System.debug ('+++++++++++ SALES REP +++++++++++');
            List <Opportunity> oppLst = [SELECT Id, Account.Id, Account.Name, Account.OwnerId FROM Opportunity WHERE Id in: oppIdList ];
            List <Account> acctList = [SELECT Id, Name, Role_Type_Roll_Up__c, OwnerId FROM Account where id in : acctIdList];
            List <User> holdingUserId = [SELECT ID from User where Name='Holding User' LIMIT 1];

            for (Opportunity tmpOpp : oppLst) {
                for (Account tmpAcct :acctList ){
                    system.debug('*****tmpOpp Accout Name: ' + tmpOpp.Account.Name);
                    if (tmpAcct.Role_Type_Roll_Up__c =='Customer' && tmpOpp.Account.Name == tmpAcct.Name){
                        if (tmpAcct.OwnerId != holdingUserId[0].id ){
                            System.debug ('##### FOUND: ' + tmpAcct.OwnerId);
                            tmpOpp.OwnerId=tmpAcct.OwnerId;
                            oppUpdate.add (tmpOpp);
                            break;
                        }
                    }
                }
            }
            if (oppUpdate !=null){
                update oppUpdate;
            }
            System.debug ('###### OPPORTUNITY : ' + oppUpdate);
        }
    }
*/

/*
    public static void checkContractDates(List<Opportunity> opptyList, Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap){
        system.debug('***opptyList: ' + opptyList);
        system.debug('***oldMap: ' + oldMap);
        system.debug('***newMap: ' + newMap);

        List<String> opptyIdList = new List<String>();

        for(Opportunity oppty : opptyList){
            Opportunity oldOpp = oldMap.get(oppty.Id);
            Opportunity newOpp = newMap.get(oppty.Id);

            system.debug('***oldOpp: ' + oldOpp);
            system.debug('***newOpp: ' + newOpp);

            Date oldContractStart = oldOpp.Contract_Start_Date__c;
            Date newContractStart = newOpp.Contract_Start_Date__c;
            Date oldContractEnd = oldOpp.Contract_End_Date__c;
            Date newContractEnd = newOpp.Contract_End_Date__c;

            system.debug('***oldContractStart: ' + oldContractStart);
            system.debug('***newContractStart: ' + newContractStart);
            system.debug('***oldContractEnd: ' + oldContractEnd);
            system.debug('***newContractEnd: ' + newContractEnd);

            system.debug('***oldOpp.StageName: ' + oldOpp.StageName);
            system.debug('***newOpp.StageName: ' + newOpp.StageName);

            if( (oldContractStart != newContractStart) || (oldContractEnd != newContractEnd) && (newContractStart != null) && (newContractEnd != null) && (oppty.StageName == 'Closed Won') ) {
                if(oldOpp.Modified_Contract_Start_Date__c == newOpp.Modified_Contract_Start_Date__c) {
                    system.debug('***TO GENERATE');
                    opptyIdList.add(oppty.Id);
                }
            }
        }

        system.debug('***opptyIdList: ' + opptyIdList);
        if (!opptyIdList.isEmpty()) {
            List<OpportunityLineItem> oliList = [SELECT Id, OpportunityId, PricebookEntryId, TotalPrice, Classification__c FROM OpportunityLineItem Where OpportunityId in :opptyIdList];
            if (!oliList.isEmpty()) {
                OpportunityProductClassificationUtil.generateRevenueSchedule(oliList);
            }
        }
    }
*/
    /*********************************
     * Description: Checks if the Opportunity is allowed to be Closed-Won based on business conditions
     * Author: Prince Encina
     * History:
     * 07/10/2019       Created
     * 07/25/2019       Added logic for CWG-1/CWG-5
     * 08/16/2019       Included checking for Close Date, from VR logic
     * 08/22/2019       Bugfix for updating Pre-Entry and Close Date
     * 08/27/2019       Added logic for 'Offline Contract Received' field
     * 08/09/2020       Added Validation for duplicate opportunity line item with exception that 
     * 30/11/2020		Added logic to auto-populate opportunity's close date to Today if close date is empty or not today prior to closing opportunity
     ********************************/
    public static void checkIfAllowedToCloseWin(List<Opportunity> newOppList, Map<Id,Opportunity> oldRecMap) {
        Opportunity oldRec = new Opportunity();
        Set<Id> oppIdSet = new Set<Id>();
        Map<Id, List<String>> oppErrorMap = new Map<Id, List<String>>();
        Map<Id, List<OpportunityLineItem>> oppToProductsMap = new Map<Id, List<OpportunityLineItem>>();
        Map<Id, Boolean> oppToPreEntryValueMap = new Map<Id, Boolean>();
        Map<Id, Date> oppToCloseDateValueMap = new Map<Id, Date>();                 // added 08/16/19
        Map<Id, Boolean> oppToOfflineContractValueMap = new Map<Id, Boolean>();     // added 08/27/19
        Map<Id, List<Apttus__APTS_Agreement__c>> oppToApttusContractsMap = new Map<Id, List<Apttus__APTS_Agreement__c>>();  // added 08/22/19
        // STP-2226 Classification pairing of Growth and Renewal, can be exempted from duplicate validation on opportunity products
        Set<String> exemptDupProductByClass = new Set<String>();
        exemptDupProductByClass.add(APT_Constants.CLASSIFICATION_GROWTH);
        exemptDupProductByClass.add(APT_Constants.CLASSIFICATION_RENEWAL);
        Set<Id> oppIdClosedLost = new Set<Id>();

        try {
            // Create A Save Point prior to updating the 'Close Date' to Today's Date
            Savepoint savePoint = Database.setSavepoint();

            // Check #1: Check if Opportunity has Opportunity Products
            for (Opportunity opp: newOppList) {
                oldRec = oldRecMap != NULL && oldRecMap.containsKey(opp.Id) ? oldRecMap.get(opp.Id) : NULL;
                if(Constants.CLOSED_WON.equalsIgnoreCase(opp.StageName) && !Constants.CLOSED_WON.equalsIgnoreCase(oldRec.StageName)){
                    oppIdSet.add(opp.Id);       // add to Set only if changed to Closed-Won from a different stage
                    oppToPreEntryValueMap.put(opp.Id, opp.Pre_Entry__c);            // 08/22/19: repositioned Maps as a bugfix
                    oppToCloseDateValueMap.put(opp.Id, opp.CloseDate);              // 08/22/19: repositioned Maps as a bugfix
                    oppToOfflineContractValueMap.put(opp.Id, opp.Offline_Contract_Received__c);     // 08/27/19: added along with Map
                }
                // Adds Lost Opportunities that are closed into a set
                else if(!Constants.CLOSED_WON.equalsIgnoreCase(opp.StageName) && opp.StageName.contains('Closed') && !oldRec.StageName.contains('Closed')){
                    oppIdClosedLost.add(opp.Id);
                }
            }
            
            // Update 'Close Date' for Opportunity that are closed (i.e. 'Closed-Won', 'Closed-Lost', 'Closed-Duplicate'...etc) if there is no errors
            if(!oppIdClosedLost.isEmpty() || (!oppIdSet.isEmpty())){
                // autopopulate the close date to today's date
                for(Opportunity opp: newOppList){
                    if(opp.CloseDate == null || opp.CloseDate != System.today()){
                        opp.CloseDate = System.today();
                        // Update the Close Date map, for the existing validation to process the updated 'Close Date' value
                        oppToCloseDateValueMap.put(opp.Id, opp.CloseDate);
                    }
                }
            }

            System.debug('2222###'+Limits.getQueries());

            //Only proceed if there are opportunities getting Closed Won.
            if (!oppIdSet.isEmpty()) {
                // re-query: tried merging the codes into one loop......
                for (Opportunity oppRec : [SELECT Id,
                                            (SELECT Id, Name, Classification__c, Contract_Product__c, Contract_Start_Date__c FROM OpportunityLineItems),
                                            (SELECT Id, Apttus_CMDSign__DocuSignEnvelopeId__c, Docusign_Envelope_Status__c,
                                                Is_Document_Signed__c FROM R00N50000001Xl0FEAS)
                                            FROM Opportunity
                                            WHERE Id IN :oppIdSet]) {

                    if (oppRec.OpportunityLineItems.isEmpty()) {
                         oppErrorMap = addOpportunityErrorsMap(oppErrorMap, oppRec.Id, Label.Opportunity_Cannot_Be_Closed_Won);
						 oppToProductsMap.put(oppRec.Id, oppRec.OpportunityLineItems); 
                    } else {
                        oppToProductsMap.put(oppRec.Id, oppRec.OpportunityLineItems);
                    }

                    // added 08/22/2019; list of Apttus Contract associated with the Opportunity
                    if (!oppRec.R00N50000001Xl0FEAS.isEmpty()) {
                        oppToApttusContractsMap.put(oppRec.Id, oppRec.R00N50000001Xl0FEAS);
                    }
                }

                // Check #2: Check for Pre-Entry Scenario
                Set<Id> passedOppIdSet = new Set<Id>();

                if (!oppToProductsMap.isEmpty()) {
                    for (Id oppId : oppToProductsMap.keySet()) {
                        List<OpportunityLineItem> oppProdList = new List<OpportunityLineItem>();    // intentionally placed initialization inside the loop; will check later -P
                        oppProdList = oppToProductsMap.get(oppId);

                        // map used to detect opportunity line item duplicates, and exception logic for those with classification: 'Growth' and 'Renewal' 
                        Map<String,String> oppNameToClassificationMap = new Map<String,String>();
                        // flag to track if the exception pairing is completed for the duplicate opportunity line items
                        Map<String,Boolean> growthRenewalPairingCompleted = new Map<String,Boolean>();

                        for (OpportunityLineItem oli : oppProdList) {
                            // 08/16/19: Modified error formula to accommodate deactivated Opportunity Product VR
                            if (!oppToPreEntryValueMap.get(oppId) && (oli.Contract_Start_Date__c < Date.today() || oli.Contract_Start_Date__c < oppToCloseDateValueMap.get(oppId))) {
                                oppErrorMap = addOpportunityErrorsMap(oppErrorMap, oppId, Label.Opportunity_Confirm_Pre_Entry_Scenario);
								if (STRING_YES.equalsIgnoreCase(oli.Contract_Product__c)) {
                                    // the Opportunity SHOULD SAVE and not proceed to further checks if Contract_Product__c = 'No'
                                    passedOppIdSet.add(oppId);
                                }
                            }

                            // Check #3 begins here!
                            else {
                                if (STRING_YES.equalsIgnoreCase(oli.Contract_Product__c)) {
                                    // the Opportunity SHOULD SAVE and not proceed to further checks if Contract_Product__c = 'No'
                                    passedOppIdSet.add(oppId);
                                }
                            }

                            //  STP-2226 Added Validation for duplicate opportunity line item with exception that
                            if(oppNameToClassificationMap.containsKey(oli.Name) == FALSE){
                                // is Unique Opportunity Line item
                                oppNameToClassificationMap.put(oli.Name, oli.Classification__c);
                                growthRenewalPairingCompleted.put(oli.Name, False);
                            }else if(oppNameToClassificationMap.containsKey(oli.Name) == TRUE &&
                                exemptDupProductByClass.contains(oli.Classification__c) &&
                                exemptDupProductByClass.contains(oppNameToClassificationMap.get(oli.Name)) &&
                                oli.Classification__c != oppNameToClassificationMap.get(oli.Name) &&
                                growthRenewalPairingCompleted.get(oli.Name) == FALSE){
                                // check duplicate opportunity line items for a pairing classification between 'Growth' and 'Renewal'
                            
                                // is Valid scenario, Set Pairing complete as TRUE for that product
                                growthRenewalPairingCompleted.put(oli.Name, TRUE);
                            }else if(oppNameToClassificationMap.containsKey(oli.Name) == TRUE &&
                                    exemptDupProductByClass.contains(oli.Classification__c) &&
                                    growthRenewalPairingCompleted.get(oli.Name) == TRUE){
                                // There is already a classification pairing for the same duplicate opportunity line items, thus invalid scenario
								oppErrorMap = addOpportunityErrorsMap(oppErrorMap, oppId, Label.Opportunity_Has_Duplicate_Product_Lines);
                            }else{
                                // throw duplicate error
								oppErrorMap = addOpportunityErrorsMap(oppErrorMap, oppId, Label.Opportunity_Has_Duplicate_Product_Lines);
                            }
                        }
                    }
                }

                // Check #4: Check if Apttus Contract was received
                if (!passedOppIdSet.isEmpty()) {

                    for (Id oppId : passedOppIdSet) {
                        Boolean offlineContract = oppToOfflineContractValueMap.get(oppId);  // added 08/27/19
                        List<Apttus__APTS_Agreement__c> apttusContractList = new List<Apttus__APTS_Agreement__c>();

                        if (oppToApttusContractsMap != null && !oppToApttusContractsMap.isEmpty()) {
                            apttusContractList = oppToApttusContractsMap.get(oppId);
                        }

                        if (apttusContractList == null || apttusContractList.isEmpty()) {
                            // if there are no Apttus Contracts associated with the Opportunity, check then for the Offline Contract Received? field
                            if (!offlineContract) {
								 oppErrorMap = addOpportunityErrorsMap(oppErrorMap, oppId, Label.Opportunity_Send_Contract_to_Deal_Enablement);     // call the error if field is unchecked
                            }
                        } else {
                            // at least one Apttus Contract exists
                            for (Apttus__APTS_Agreement__c aptContract : apttusContractList) {
                                if (aptContract.Apttus_CMDSign__DocuSignEnvelopeId__c == NULL || !STRING_COMPLETED.equalsIgnoreCase(aptContract.Docusign_Envelope_Status__c)) {
                                    // Check #5: Check if Document is Manually Signed
                                    if (!aptContract.Is_Document_Signed__c && !offlineContract) {
										oppErrorMap = addOpportunityErrorsMap(oppErrorMap, oppId, Label.Opportunity_Send_Contract_to_Deal_Enablement);
                                    }
                                }
                            }
                        }
                        // end Opportunity loop
                    }
                }

                if (!oppErrorMap.isEmpty()) {
                    // Finally-- get all Opportunity IDs in the error map and call addError() on them
                    for (Opportunity oppty : newOppList) {
                        if (oppErrorMap.containsKey(oppty.Id)) {
                            for(String errMessage : oppErrorMap.get(oppty.Id)){
								oppty.StageName.addError(errMessage);
							}
                        }
                    }
                    // Roll back the 'Close Date' update, due to validation error
                    Database.rollback(savePoint);
                }
            }
        } catch (exception excp) {
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'checkIfAllowedToCloseWin', triggerName, LoggingLevel.ERROR);
        }
    }
		/**
     * @Description : Geneate a Map<Id,List<string>> for Opportunity with List of error messages
     */
	private static Map<Id,List<String>> addOpportunityErrorsMap(Map<Id,List<String>> oppErrorMap, Id OpprotunityId, String errMsg){
		if(oppErrorMap.containsKey(OpprotunityId)){
			list<string> errMsgList = new list<string>();
			errMsgList = oppErrorMap.get(OpprotunityId);
			errMsgList.add(errMsg);
		}else{
			list<string> errMsgList = new list<string>();
			errMsgList.add(errMsg);
			oppErrorMap.put(OpprotunityId, errMsgList);
		}
		return oppErrorMap;
	}

    /*********************************
     * Description: Populates the Opportunity product's Classification field
     * Author: Prince Encina
     * History:
     * 08/20/19         Created
     ********************************/
    public static void populateClassification(List<Opportunity> newOptyList, Map<Id, Opportunity> oldRecMap){
        Integer barMonth;
        Integer barCYear;
        Integer barPYear;
        Integer startMonth;
        Decimal orgRev;
        Decimal prodRev;
        Decimal totalRevenue;
        Decimal totalOutsideRevenue;
        OpportunityLineItem oldRec = new OpportunityLineItem();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> tradedAcctSet = new Set<Id>();
        Set<Id> tradedProductSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> optyIdSet = new Set<Id>();
        Set<Id> proposalIdSet = new Set<Id>();
        List<Opportunity> filteredOptyList = new List<Opportunity>();
        List<OpportunityLineItem> newOptyProdList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> optyLIToUpdate = new List<OpportunityLineItem>();
        List<OpportunityLineItem> optyLineItemList = new List<OpportunityLineItem>();
        List<APT_Opportunity_Product_Line_Item__c> aptOptyLIList = new List<APT_Opportunity_Product_Line_Item__c>();
        Map<Id, Id> optyOrgMap = new Map<Id, Id>();
        Map<Id, String> acctRevenueMap = new Map<Id, String>();
        Map<Id, String> orgProductMap = new Map<Id, String>();
        Map<Id, Decimal> productTotalRevMap = new Map<Id, Decimal>();
        Map<String, Decimal> fyProductMap = new Map<String, Decimal>();
        Map<String, Decimal> barTotalRevMap = new Map<String, Decimal>();
        NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
        Opportunity oldOptyRec = new Opportunity();


        try{
            for(Opportunity optyObj : newOptyList){
                oldOptyRec = oldRecMap != NULL && oldRecMap.containsKey(optyObj.Id) ? oldRecMap.get(optyObj.Id) : NULL;
                if(Constants.CLOSED_WON.equalsIgnoreCase(optyObj.StageName) && !Constants.CLOSED_WON.equalsIgnoreCase(oldOptyRec.StageName)){
                    optyIdSet.add(optyObj.Id);
                }
                optyOrgMap.put(optyObj.Id, optyObj.AccountId);
                accountIdSet.add(optyObj.AccountId);//gets the opportunity's account id
            }

            if(optyIdSet != NULL){
                for(OpportunityLineItem optyLine : [SELECT Id, Product2Id, Contract_Start_Date__c, OpportunityId, Classification__c, Opportunity.AccountId,
                        Contract_End_Date__c, APT_Is_Apttus_Opportunity_Line_item__c, Change_Classification__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN : optyIdSet
                LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())])
                {
                    if(!optyLine.APT_Is_Apttus_Opportunity_Line_item__c){
                        optyLineItemList.add(optyLine);
                    }
                }
            }

            for(OpportunityLineItem optyLine : optyLineItemList){
                productIdSet.add(optyLine.Product2Id);//saves the product Id to the list
                optyIdSet.add(optyLine.OpportunityId);
                newOptyProdList.add(optyLine);
            }

            if(accountIdSet != NULL){//get all T&R records under the organisation
                for (Budget_and_Revenue__c bar : [SELECT Organisation__c, Product__c, Financial_Year__c,
                        Jan_Revenue_Amount__c, Feb_Revenue_Amount__c, Mar_Revenue_Amount__c,
                        Apr_Revenue_Amount__c, May_Revenue_Amount__c, Jun_Revenue_Amount__c,
                        Jul_Revenue_Amount__c, Aug_Revenue_Amount__c, Sep_Revenue_Amount__c,
                        Oct_Revenue_Amount__c, Nov_Revenue_Amount__c, Dec_Revenue_Amount__c,
                        Total_Revenue_Amount__c
                FROM Budget_and_Revenue__c
                WHERE Organisation__c IN : accountIdSet
                AND Financial_Year__c != NULL
                LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())])
                {
                    tradedProductSet.add(bar.Product__c);//products that have been traded with AuPost
                    tradedAcctSet.add(bar.Organisation__c);//accounts in this set have traded any product
                    // January
                    if(bar.Jan_Revenue_Amount__c > 0){//saves the monthly revenue of a product for the current and previous fiscal year
                        fyProductMap.put(String.valueOf(bar.Product__c) + '1' + String.valueOf(bar.Financial_Year__c), bar.Jan_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '1' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // February
                    if(bar.Feb_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '2' + String.valueOf(bar.Financial_Year__c), bar.Feb_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '2' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // March
                    if(bar.Mar_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '3' + String.valueOf(bar.Financial_Year__c), bar.Mar_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '3' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // April
                    if(bar.Apr_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '4' + String.valueOf(bar.Financial_Year__c), bar.Apr_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '4' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // May
                    if(bar.May_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '5' + String.valueOf(bar.Financial_Year__c), bar.May_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '5' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // June
                    if(bar.Jun_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '6' + String.valueOf(bar.Financial_Year__c), bar.Jun_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '6' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // July
                    if(bar.Jul_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '7' + String.valueOf(bar.Financial_Year__c), bar.Jul_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '7' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // August
                    if(bar.Aug_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '8' + String.valueOf(bar.Financial_Year__c), bar.Aug_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '8' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // September
                    if(bar.Sep_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '9' + String.valueOf(bar.Financial_Year__c), bar.Sep_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '9' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // October
                    if(bar.Oct_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '10' + String.valueOf(bar.Financial_Year__c), bar.Oct_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '10' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // November
                    if(bar.Nov_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '11' + String.valueOf(bar.Financial_Year__c), bar.Nov_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '11' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // December

                    if(bar.Total_Revenue_Amount__c > ntAmount.Amount__c){//if the total revenue exceeds the NTA, save the ID
                        barTotalRevMap.put(bar.Organisation__c, bar.Total_Revenue_Amount__c);
                        productTotalRevMap.put(bar.Product__c, bar.Total_Revenue_Amount__c);
                        orgProductMap.put(bar.Organisation__c, bar.Product__c);
                    }
                }//end BaR for
                accountIdSet.clear();
            }

            for(OpportunityLineItem optyLine : optyLineItemList){
                if(!Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                    startMonth = optyLine.Contract_Start_Date__c.MONTH();
                    barCYear = optyLine.Contract_Start_Date__c.YEAR();
                    //if there hasn't been any trade or the total revenue is <NTA
                    if(!tradedAcctSet.contains(optyOrgMap.get(optyLine.OpportunityId)) || !barTotalRevMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                        optyLine.Classification__c = Constants.CLSS_NEWBUSINESS;
                    }

                    //if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
                    else if(tradedProductSet.contains(optyLine.Product2Id) && !productTotalRevMap.containsKey(optyLine.Product2Id) && !orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                        optyLine.Classification__c = Constants.CLSS_NEWBUSINESS;
                    }

                    //if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
                    else if(tradedProductSet.contains(optyLine.Product2Id) && !productTotalRevMap.containsKey(optyLine.Product2Id) && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                        optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                    }

                    //if the product has never been traded and the org has traded other product with Total Revenue > NTA
                    else if(!tradedProductSet.contains(optyLine.Product2Id) && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                        optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                    }

                    else if(startMonth > 6){
                        //outside the 12 months of trade
                        for(Integer countRev = startMonth; countRev > 6 ; countRev--){
                            if(countRev == startMonth){//Start is AUG2019
                                //AUG2019 to JUL2019
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalOutsideRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, sets it to 0
                                    totalOutsideRevenue = 0;
                                }
                            }
                            else{
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, adds 0
                                    totalOutsideRevenue += 0;
                                }
                            }
                        }

                        //Example: Gets revenue for June back to January FY2018
                        for(Integer countRev = 6; countRev > 0; countRev--){//computes from January to June of the PFY
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalOutsideRevenue += 0;
                            }
                        }

                        //Example: Gets revenue for AUG to December FY2018
                        for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalOutsideRevenue += 0;
                            }
                        }

                        //within the 12 months of trade
                        for(Integer countRev = startMonth; countRev > 6 ; countRev--){
                            if(countRev == startMonth){//Start month to July for the Next FY
                                //Example: Start Date: 08/2019
                                //Gets the revenue for August back to July FY2020
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1))){
                                    totalRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1));
                                }
                                else{//if there are no values to be retrieved, sets it to 0
                                    totalRevenue = 0;
                                }
                            }
                            else{
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1))){
                                    totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1));
                                }
                                else{//if there are no values to be retrieved, adds 0
                                    totalRevenue += 0;
                                }
                            }
                        }

                        //Example: Gets revenue for June back to January FY2019
                        for(Integer countRev = 6; countRev > 0; countRev--){//computes from January to June of the CFY
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalRevenue += 0;
                            }
                        }

                        //Example: Gets revenue for July to December FY2019
                        for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalRevenue += 0;
                            }
                        }
                        //Example: Gets revenue for July to December FY2019
                        for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalRevenue += 0;
                            }
                        }
                        if(totalRevenue == 0 && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){//if the 12 months has no revenue and the org has other valid T&Rs
                            if(!productTotalRevMap.containsKey(optyLine.Product2Id)){//if the product has no valid T&R
                                optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                            }
                            else{//if the product has valid T&R from other FYs
                                optyLine.Classification__c = Constants.CLSS_WINBACK;
                            }
                        }
                        else if(ntAmount.Amount__c > totalRevenue){//if the total revenue is lesser than the NTA...
                            if(totalOutsideRevenue > ntAmount.Amount__c){//...but the total revenue outside the 12 months exceeds the NTA
                                optyLine.Classification__c = Constants.CLSS_WINBACK;
                            }
                            else if(totalOutsideRevenue < ntAmount.Amount__c && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                                //...but the total revenue outside is less than the NTA and the org has other valid T&Rs
                                optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                            }
                        }
                        else if(ntAmount.Amount__c < totalRevenue){//if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
                            if(Constants.NO_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                                optyLine.Classification__c = Constants.CLSS_RENEWAL;
                            }
                            else if(Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                                optyLine.Classification__c = Constants.CLSS_GROWTH;
                            }
                        }
                    }

                    else if(startMonth < 7){
                        for(Integer countRev = startMonth; countRev > 0 ; countRev--){//within 12 months of trade
                            if(countRev == startMonth){
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalOutsideRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, set it to 0
                                    totalOutsideRevenue = 0;
                                }
                            }
                            else{
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalOutsideRevenue += 0;
                                }
                            }
                        }

                        //Example: Gets the revenue from July to December FY2019
                        for(Integer countRev = 7; countRev < 13; countRev++){
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                            }
                            else{//if there are no values to be retrieved, add 0
                                totalOutsideRevenue += 0;
                            }
                        }

                        //Example: Gets the revenue from April to June FY2018
                        for(Integer countRev = startMonth; countRev < 7; countRev++){
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-2))){
                                totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-2));
                            }
                            else{//if there are no values to be retrieved, add 0
                                totalOutsideRevenue += 0;
                            }
                        }

                        //Example Start Date: 04/2019
                        //Gets the revenue for Apr back to January FY2019
                        for(Integer countRev = startMonth; countRev > 0 ; countRev--){//within 12 months of trade
                            if(countRev == startMonth){
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, set it to 0
                                    totalRevenue = 0;
                                }
                            }
                            else{
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalRevenue += 0;
                                }
                            }
                        }

                        //Example: Gets the revenue from July to December FY2019
                        for(Integer countRev = 7; countRev < 13; countRev++){
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, add 0
                                totalRevenue += 0;
                            }
                        }

                        //Example: Gets the revenue from April to June FY2018
                        for(Integer countRev = startMonth; countRev < 7; countRev++){
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                            }
                            else{//if there are no values to be retrieved, add 0
                                totalRevenue += 0;
                            }
                        }
                        //Example: Gets revenue for July to December FY2019
                        for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalRevenue += 0;
                            }
                        }
                        if(totalRevenue == 0 && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){//if the 12 months has no revenue and the org has other valid T&Rs
                            if(!productTotalRevMap.containsKey(optyLine.Product2Id)){//if the product has no valid T&R
                                optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                            }
                            else{//if the product has valid T&R from other FYs
                                optyLine.Classification__c = Constants.CLSS_WINBACK;
                            }
                        }
                        else if(ntAmount.Amount__c > totalRevenue){//if the total revenue is lesser than the NTA...
                            if(totalOutsideRevenue > ntAmount.Amount__c){//...but the total revenue outside the 12 months exceeds the NTA
                                optyLine.Classification__c = Constants.CLSS_WINBACK;
                            }
                            else if(totalOutsideRevenue < ntAmount.Amount__c && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                                //...but the total revenue outside is less than the NTA and the org has other valid T&Rs
                                optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                            }
                        }
                        else if(ntAmount.Amount__c < totalRevenue){//if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
                            if(Constants.NO_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                                optyLine.Classification__c = Constants.CLSS_RENEWAL;
                            }
                            else if(Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                                optyLine.Classification__c = Constants.CLSS_GROWTH;
                            }
                        }
                    }
                    optyLIToUpdate.add(optyLine);
                }
            }

            if(optyLIToUpdate != NULL){
                Database.update(optyLIToUpdate, TRUE);
            }

        }catch(exception excp){
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'populateClassification', triggerName, LoggingLevel.ERROR);
        }
    }

    /*********************************
    * Description: Populates the Apttus product's Classification field
    * Author: Prince Encina
    * History:
    * 08/20/19         Created
    ********************************/
    public static void populateAPTClassification(List<Opportunity> newOptyList, Map<Id, Opportunity> oldRecMap){
        Integer barMonth;
        Integer barCYear;
        Integer barPYear;
        Integer startMonth;
        Decimal prodRev;
        Decimal totalRevenue;
        Decimal totalOutsideRevenue;
        String orgString;
        Set<Id> tradedAcctSet = new Set<Id>();
        Set<Id> tradedProductSet = new Set<Id>();
        Set<Id> proposalIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> optyIdSet = new Set<Id>();
        List<APT_Opportunity_Product_Line_Item__c> filteredAPTOLIList = new List<APT_Opportunity_Product_Line_Item__c>();
        List<APT_Opportunity_Product_Line_Item__c> APTOLIToUpdate = new List<APT_Opportunity_Product_Line_Item__c>();
        List<APT_Opportunity_Product_Line_Item__c> aptOptyLIList = new List<APT_Opportunity_Product_Line_Item__c>();
        Map<Id, Id> proposalAcctMap = new Map<Id, Id>();
        Map<Id, String> acctRevenueMap = new Map<Id, String>();
        Map<Id, String> orgProductMap = new Map<Id, String>();
        Map<Id, Decimal> productTotalRevMap = new Map<Id, Decimal>();
        Map<String, Decimal> fyProductMap = new Map<String, Decimal>();
        Map<String, Decimal> barTotalRevMap = new Map<String, Decimal>();
        NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
        Opportunity oldOptyRec = new Opportunity();
        APT_Opportunity_Product_Line_Item__c oldRec = new APT_Opportunity_Product_Line_Item__c();

        try{
            for(Opportunity optyObj : newOptyList){
                oldOptyRec = oldRecMap != NULL && oldRecMap.containsKey(optyObj.Id) ? oldRecMap.get(optyObj.Id) : NULL;
                if(Constants.CLOSED_WON.equalsIgnoreCase(optyObj.StageName) && !Constants.CLOSED_WON.equalsIgnoreCase(oldOptyRec.StageName)){
                    optyIdSet.add(optyObj.Id);
                }
                accountIdSet.add(optyObj.AccountId);//gets the opportunity's account id
            }

            for(Apttus_Proposal__Proposal__c proposal : [SELECT Id, Apttus_Proposal__Account__c
            FROM Apttus_Proposal__Proposal__c
            WHERE  Apttus_Proposal__Opportunity__c IN : optyIdSet
            LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())])//get all proposal records under the opportunity
            {
                proposalAcctMap.put(proposal.Id, proposal.Apttus_Proposal__Account__c);
                proposalIdSet.add(proposal.Id);
            }
            for(APT_Opportunity_Product_Line_Item__c aptPLI : [SELECT Id, APT_Quote_Proposal__c, APT_Revenue_Start_Date__c, APT_Product__c,
                    APT_Classification__c, APT_Change_Classification__c
            FROM APT_Opportunity_Product_Line_Item__c
            WHERE APT_Quote_Proposal__c IN : proposalIdSet
            AND APT_Product__c != NULL
            LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())])//get all APT Opty Line Item under each proposal
            {
                aptOptyLIList.add(aptPLI);
            }

            if(accountIdSet != NULL){//get all T&R records under the organisation
                for (Budget_and_Revenue__c bar : [SELECT Organisation__c, Product__c, Financial_Year__c,
                        Jan_Revenue_Amount__c, Feb_Revenue_Amount__c, Mar_Revenue_Amount__c,
                        Apr_Revenue_Amount__c, May_Revenue_Amount__c, Jun_Revenue_Amount__c,
                        Jul_Revenue_Amount__c, Aug_Revenue_Amount__c, Sep_Revenue_Amount__c,
                        Oct_Revenue_Amount__c, Nov_Revenue_Amount__c, Dec_Revenue_Amount__c,
                        Total_Revenue_Amount__c
                FROM Budget_and_Revenue__c
                WHERE Organisation__c IN : accountIdSet
                AND Financial_Year__c != NULL
                LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())])
                {
                    tradedProductSet.add(bar.Product__c);//products that have a been traded with AuPost before
                    tradedAcctSet.add(bar.Organisation__c);//accounts in this set have traded any product
                    barTotalRevMap.put(String.valueOf(bar.Organisation__c) + String.valueOf(bar.Financial_Year__c), bar.Total_Revenue_Amount__c);
                    //barTotalRevMap - computes the total amount of revenue earned for a certain product grouped by FY
                    // January
                    if(bar.Jan_Revenue_Amount__c > 0){//saves the monthly revenue of a product for the current and previous fiscal year
                        fyProductMap.put(String.valueOf(bar.Product__c) + '1' + String.valueOf(bar.Financial_Year__c), bar.Jan_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '1' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // February
                    if(bar.Feb_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '2' + String.valueOf(bar.Financial_Year__c), bar.Feb_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '2' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // March
                    if(bar.Mar_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '3' + String.valueOf(bar.Financial_Year__c), bar.Mar_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '3' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // April
                    if(bar.Apr_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '4' + String.valueOf(bar.Financial_Year__c), bar.Apr_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '4' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // May
                    if(bar.May_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '5' + String.valueOf(bar.Financial_Year__c), bar.May_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '5' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // June
                    if(bar.Jun_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '6' + String.valueOf(bar.Financial_Year__c), bar.Jun_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '6' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // July
                    if(bar.Jul_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '7' + String.valueOf(bar.Financial_Year__c), bar.Jul_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '7' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // August
                    if(bar.Aug_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '8' + String.valueOf(bar.Financial_Year__c), bar.Aug_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '8' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // September
                    if(bar.Sep_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '9' + String.valueOf(bar.Financial_Year__c), bar.Sep_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '9' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // October
                    if(bar.Oct_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '10' + String.valueOf(bar.Financial_Year__c), bar.Oct_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '10' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // November
                    if(bar.Nov_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '11' + String.valueOf(bar.Financial_Year__c), bar.Nov_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '11' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // December
                    if(bar.Dec_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '12' + String.valueOf(bar.Financial_Year__c), bar.Dec_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '12' + String.valueOf(bar.Financial_Year__c), 0);
                    }

                    if(bar.Total_Revenue_Amount__c > ntAmount.Amount__c){//if total revenue exceeds the NTA, save the id
                        barTotalRevMap.put(bar.Organisation__c, bar.Total_Revenue_Amount__c);
                        productTotalRevMap.put(bar.Product__c, bar.Total_Revenue_Amount__c);
                        orgProductMap.put(bar.Organisation__c, bar.Product__c);
                    }

                }//end BaR for loop
            }
            for(APT_Opportunity_Product_Line_Item__c newAPTObj : aptOptyLIList){
                if(!Constants.YES_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                    startMonth = newAPTObj.APT_Revenue_Start_Date__c.MONTH();
                    barCYear = newAPTObj.APT_Revenue_Start_Date__c.YEAR();
                    orgString = proposalAcctMap.get(newAPTObj.APT_Quote_Proposal__c);//if there hasn't been any trade or the total revenue is <100

                    //if there hasn't been any trade or the total revenue is <NTA
                    if(!tradedAcctSet.contains(orgString) || !barTotalRevMap.containsKey(orgString)){
                        newAPTObj.APT_Classification__c = Constants.CLSS_NEWBUSINESS;
                    }

                    //if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
                    else if(tradedProductSet.contains(newAPTObj.APT_Product__c) && !productTotalRevMap.containsKey(newAPTObj.APT_Product__c) && !orgProductMap.containsKey(orgString)){
                        newAPTObj.APT_Classification__c = Constants.CLSS_NEWBUSINESS;
                    }

                    //if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
                    else if(tradedProductSet.contains(newAPTObj.APT_Product__c) && !productTotalRevMap.containsKey(newAPTObj.APT_Product__c) && orgProductMap.containsKey(orgString)){
                        newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                    }

                    //if the product has never been traded and the org has traded other product with Total Revenue > NTA
                    else if(!tradedProductSet.contains(newAPTObj.APT_Product__c) && orgProductMap.containsKey(orgString)){
                        newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                    }

                    else if(startMonth > 6){
                        //after the 12 months of trade
                        for(Integer countRev = startMonth; countRev > 6 ; countRev--){
                            if(countRev == startMonth){//Start month to July for the Next FY
                                //Example: Start Date: 08/2019
                                //Gets the revenue for August back to July FY2020
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalOutsideRevenue = fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, sets it to 0
                                    totalOutsideRevenue = 0;
                                }
                            }
                            else{
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, adds 0
                                    totalOutsideRevenue += 0;
                                }
                            }
                        }

                        //Example: Gets revenue for June back to January FY2019
                        for(Integer countRev = 6; countRev > 0; countRev--){//computes from January to June of the CFY
                            if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalOutsideRevenue += 0;
                            }
                        }

                        //Example: Gets revenue for July to December FY2019
                        for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                            if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalOutsideRevenue += 0;
                            }
                        }

                        //within the 12 months of trade
                        for(Integer countRev = startMonth; countRev > 6 ; countRev--){
                            if(countRev == startMonth){//Start month to July for the Next FY
                                //Example: Start Date: 08/2019
                                //Gets the revenue for August back to July FY2020
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear+1))){
                                    totalRevenue = fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear+1));
                                }
                                else{//if there are no values to be retrieved, sets it to 0
                                    totalRevenue = 0;
                                }
                            }
                            else{
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear+1))){
                                    totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear+1));
                                }
                                else{//if there are no values to be retrieved, adds 0
                                    totalRevenue += 0;
                                }
                            }
                        }

                        //Example: Gets revenue for June back to January FY2019
                        for(Integer countRev = 6; countRev > 0; countRev--){//computes from January to June of the CFY
                            if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalRevenue += 0;
                            }
                        }

                        //Example: Gets revenue for July to December FY2019
                        for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                            if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalRevenue += 0;
                            }
                        }
                        if(totalRevenue == 0 && orgProductMap.containsKey(orgString) && !productTotalRevMap.containsKey(newAPTObj.APT_Product__c)){
                            newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                        }
                        else if(totalRevenue == 0 && productTotalRevMap.containsKey(newAPTObj.APT_Product__c)){
                            newAPTObj.APT_Classification__c = Constants.CLSS_WINBACK;
                        }
                        //if the Total Revenue is less than the NTA and the Total Revenue outside the 12 months is greater than the NTA
                        else if(ntAmount.Amount__c > totalRevenue && totalOutsideRevenue > ntAmount.Amount__c){
                            newAPTObj.APT_Classification__c = Constants.CLSS_WINBACK;
                        }
                        else if(ntAmount.Amount__c > totalRevenue && ntAmount.Amount__c > totalOutsideRevenue && orgProductMap.containsKey(orgString)){//total 12 months revenue && outside revenue is less than NTA
                            newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                        }
                        else if(ntAmount.Amount__c < totalRevenue){//if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
                            if(Constants.NO_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                                newAPTObj.APT_Classification__c = Constants.CLSS_RENEWAL;
                            }
                            else if(Constants.YES_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                                newAPTObj.APT_Classification__c = Constants.CLSS_GROWTH;
                            }
                        }
                    }

                    else if(startMonth < 7){
                        //after 12 months
                        for(Integer countRev = startMonth; countRev > 0 ; countRev--){
                            if(countRev == startMonth){
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalOutsideRevenue = fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, set it to 0
                                    totalOutsideRevenue = 0;
                                }
                            }
                            else{
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalOutsideRevenue += 0;
                                }
                            }
                        }

                        //Example: Gets the revenue from July to December FY2019
                        for(Integer countRev = 7; countRev < 13; countRev++){
                            if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                            }
                            else{//if there are no values to be retrieved, add 0
                                totalOutsideRevenue += 0;
                            }
                        }

                        //Example: Gets the revenue from April to June FY2018
                        for(Integer countRev = startMonth; countRev < 7; countRev++){
                            if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-2))){
                                totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-2));
                            }
                            else{//if there are no values to be retrieved, add 0
                                totalOutsideRevenue += 0;
                            }
                        }

                        //Example Start Date: 04/2019
                        //Gets the revenue for Apr back to January FY2019
                        for(Integer countRev = startMonth; countRev > 0 ; countRev--){//within 12 months of trade
                            if(countRev == startMonth){
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalRevenue = fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, set it to 0
                                    totalRevenue = 0;
                                }
                            }
                            else{
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalRevenue += 0;
                                }
                            }
                        }

                        //Example: Gets the revenue from July to December FY2019
                        for(Integer countRev = 7; countRev < 13; countRev++){
                            if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, add 0
                                totalRevenue += 0;
                            }
                        }

                        //Example: Gets the revenue from April to June FY2018
                        for(Integer countRev = startMonth; countRev < 7; countRev++){
                            if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                            }
                            else{//if there are no values to be retrieved, add 0
                                totalRevenue += 0;
                            }
                        }

                        if(totalRevenue == 0 && orgProductMap.containsKey(orgString) && !productTotalRevMap.containsKey(newAPTObj.APT_Product__c)){
                            newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                        }
                        else if(totalRevenue == 0 && productTotalRevMap.containsKey(newAPTObj.APT_Product__c)){
                            newAPTObj.APT_Classification__c = Constants.CLSS_WINBACK;
                        }
                        //if the Total Revenue is less than the NTA and the Total Revenue outside the 12 months is greater than the NTA
                        else if(ntAmount.Amount__c > totalRevenue && totalOutsideRevenue > ntAmount.Amount__c){
                            newAPTObj.APT_Classification__c = Constants.CLSS_WINBACK;
                        }
                        else if(ntAmount.Amount__c > totalRevenue && ntAmount.Amount__c > totalOutsideRevenue && orgProductMap.containsKey(orgString)){//total 12 months revenue && outside revenue is less than NTA
                            newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                        }
                        else if(ntAmount.Amount__c < totalRevenue){//if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
                            if(Constants.NO_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                                newAPTObj.APT_Classification__c = Constants.CLSS_RENEWAL;
                            }
                            else if(Constants.YES_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                                newAPTObj.APT_Classification__c = Constants.CLSS_GROWTH;
                            }
                        }

                    }

                    APTOLIToUpdate.add(newAPTObj);
                }
            }

            if(APTOLIToUpdate != NULL){
                Database.update(APTOLIToUpdate, TRUE);
            }
            if(proposalIdSet != NULL){
               // APT_ConfigurationTriggerHandler.sycWithOpportunity(proposalIdSet);
            }
        }catch(exception excp){
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'populateAPTClassification', triggerName, LoggingLevel.ERROR);
        }
    }
}