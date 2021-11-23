@isTest
public with sharing class APT_ApprovalRequestTriggerHelper_Test {
    private static testMethod void testMethod1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            //create international product
            Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
            bundle1.APT_Sync_with_Opportunity__c=true;
            bundle1.APT_Is_Charge_Account_Product__c = true;
            bundle1.APT_Is_Cash_Account_Product__c = false;
            insert bundle1;
            //Create Option product
            Product2 option = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
            option.Apttus_Config2__ConfigurationType__c='Option';
            option.APT_Sync_with_Opportunity__c=true;
            option.APT_International_Pricing__c = false;
            insert option;
            //Create PriceBookEntry
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);
            insert standardPrice;
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
            proposal.APT_Domestic_Overweight_Flag__c = true;
            proposal.APT_International_Overweight_Flag__c = true;
            proposal.APT_Overweight_Approval_Status__c = 'Approved';
            proposal.APT_Tier_Adjustment_Type__c = '1 Tier Up';
            insert Proposal;
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
                                                                                                       Proposal.id, 'Proposal',
                                                                                                       'Ad Hoc',priceList.id, null,
                                                                                                       'New',
                                                                                                       null, null, true);
            insert prodconfig;
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
                                                                                     1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
                                                                                     null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable
                                                                                     'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
                                                                                     'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                                     true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                                                                                     5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            insert bundleLine;
            APT_ApprovalCommentsFieldMapping__c appfieldmap = new APT_ApprovalCommentsFieldMapping__c();
            appfieldmap.Name = 'RK Code';
            appfieldmap.APT_Field_Data_Type__c = 'Text';
            appfieldmap.APT_Line_Item_Field_Name__c = 'APT_Rate_Card_Key__c';
            insert appfieldmap;
            Test.StartTest();
            // create approval request
            Apttus_Approval__Approval_Request__c approvalReq = new Apttus_Approval__Approval_Request__c();
            approvalReq.Apttus_Approval__Approval_Status__c = 'Not Submitted';
            approvalReq.Apttus_Approval__ChildObjectId__c = bundleLine.Id;
            approvalReq.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
            insert approvalReq;
            approvalReq.Apttus_Approval__Approval_Status__c = 'Rejected';
            approvalReq.Apttus_Approval__Approver_Comments__c = 'RK Code - 678 ';
            approvalReq.Apttus_Approval__StepLabel__c = 'Dangerous Goods';
            approvalReq.Apttus_QPApprov__ProposalId__c = proposal.Id;
            update approvalReq;
            /*
            try{
                approvalReq.Apttus_Approval__Approval_Status__c = 'Rejected';
                approvalReq.Apttus_Approval__Approver_Comments__c = 'Rejected - test';
                update approvalReq;
            }catch(Exception e) {
                System.debug('e.getMessage():'+ e.getMessage());
            }
			*/
            Apttus_Approval__Approval_Request__c approvalReq2 = new Apttus_Approval__Approval_Request__c();
            approvalReq2.Apttus_Approval__Approval_Status__c = 'Not Submitted';
            approvalReq2.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
            insert approvalReq2;
            approvalReq2.Apttus_Approval__Approval_Status__c = 'Rejected';
            approvalReq2.Apttus_Approval__Approver_Comments__c = 'Rejected test';
            approvalReq2.Apttus_Approval__StepLabel__c = 'Overweight items';
            approvalReq2.Apttus_QPApprov__ProposalId__c = proposal.Id;
            update approvalReq2;
            Apttus_Approval__Approval_Request__c approvalReq3 = new Apttus_Approval__Approval_Request__c();
            approvalReq3.Apttus_Approval__Approval_Status__c = 'Not Submitted';
            approvalReq3.Apttus_Approval__Object_Type__c = APT_Constants.PRODUCT_CONFIGURATION_OBJECT;
            insert approvalReq3;
            approvalReq3.Apttus_Approval__Approval_Status__c = 'Approved';
            approvalReq3.Apttus_Approval__Approver_Comments__c = 'Rejected test';
            approvalReq3.Apttus_Approval__StepLabel__c = 'International Items';
            approvalReq3.Apttus_QPApprov__ProposalId__c = proposal.Id;
            update approvalReq3;
            Contact con= APT_TestUtils.createContact();
            insert con;
            Apttus__APTS_Agreement__c agreement = APT_TestUtils.createAgreement(con.Id);
            agreement.Apttus_QPComply__RelatedProposalId__c=proposal.Id;
            insert agreement;
            Apttus_Config2__ConfigSystemProperties__c objSett = new Apttus_Config2__ConfigSystemProperties__c(Name= 'System Properties');
            insert objSett;
            APT_TermAndConditionController tempObj = new APT_TermAndConditionController();
            tempObj.setcontractID(agreement.ID);
            ID testVar = tempObj.getcontractID();
            tempObj.approvalRequestSO = approvalReq3;
            tempObj.agreementSO = agreement;
            tempObj.getContractURL();
            Test.StopTest();
            system.assert(approvalReq!=null);
            system.assert(approvalReq2!=null);
            system.assert(approvalReq3!=null);
        }
    }
}