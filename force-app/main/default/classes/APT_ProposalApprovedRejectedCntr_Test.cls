/**
Description: Test class for Apex Class- APT_ProposalApprovedRejectedController.
Created By - Jetha Ram
Created Date - 28th July, 2016
Last Modified By -
Last Modified Date -
**/
@isTest
private class APT_ProposalApprovedRejectedCntr_Test 
{
    private static TestMethod void TestProposalApprovedRejected() 
    {
        Profile p = [SELECT Id FROM Profile WHERE Name =: APT_Constants.STRING_SYSTEM_ADMINISTRATOR];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) 
        {   
            //Create Contact
            Contact con = APT_TestUtils.createContact();
            insert con;
            
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = APT_Constants.TEST_ACCOUNT_TYPE;
            acc.ACN__c = APT_Constants.TEST_ACCOUNT_ACN;
            acc.LEGACY_ID__c = APT_Constants.TEST_ACCOUNT_LEGACY_ID;
            insert acc;
            
            acc.LEGACY_ID__c = APT_Constants.TEST_ACCOUNT_LEGACY_ID;
            update acc;
            
            APT_Cash_Account__c ca = new APT_Cash_Account__c();
            ca.APT_Organisation__c = acc.Id;
            ca.APT_Cust_Name__c = APT_Constants.TEST_Cust_NAME;
            ca.APT_Cust_Email__c = APT_Constants.EMAIL_TEST_USER;
            ca.APT_Cust_State__c = APT_Constants.TEST_Cust_STATE;
            ca.APT_ABN__c = APT_Constants.TEST_ACCOUNT_ABN;
            ca.APT_ACN__c = APT_Constants.TEST_ACCOUNT_ACN;
            ca.APT_Selected__c = APT_Constants.BOOL_TRUE ;
            insert ca;
            
            APT_Charge_Account__c chargeAccount = new APT_Charge_Account__c();
            chargeAccount.APT_Organisation__c = acc.Id;
            chargeAccount.APT_Street_Address_State__c = APT_Constants.TEST_Cust_STATE;
            chargeAccount.APT_Business_name__c = APT_Constants.TEST_BUSINESS_NAME;
            chargeAccount.APT_ABN__c = APT_Constants.TEST_ACCOUNT_ABN;
            chargeAccount.APT_Applicant1_Date_of_Birth__c = System.today().addMonths(-1000);
            chargeAccount.APT_Holding_Company__c = APT_Constants.BOOL_TRUE;
            chargeAccount.APT_Selected__c = APT_Constants.BOOL_TRUE;
            insert chargeAccount;
            
            APT_Sub_Account__c sa = new APT_Sub_Account__c();
            sa.APT_Organisation__c = acc.Id;
            sa.APT_Charge_Account__c = chargeAccount.Id;
            sa.APT_Street_Address_State__c = APT_Constants.TEST_Cust_STATE;
            sa.APT_Postal_Address_State__c = APT_Constants.TEST_Cust_STATE;
            sa.APT_Branch__c = APT_Constants.TEST_BRANCH;
            sa.APT_Street_Address_Country_Code__c = APT_Constants.TEST_COUNTRY_CODE;
            sa.APT_Postal_Address_Country_Code__c = APT_Constants.TEST_COUNTRY_CODE;
            sa.APT_Selected__c = APT_Constants.BOOL_TRUE;
            insert sa;
        
            List<Account> accs = [SELECT Id, LEGACY_ID__c FROM Account];
            RecordType aptNwkRecordType = [SELECT Id, Name FROM RecordType WHERE DeveloperName =: APT_Constants.DEVELOPER_NAME_DELIVERY_1 AND sObjectType =: APT_Constants.NETWORK_SOBJECT_TYPE limit 1];

        
            //Create Network
            Network__c aptNwk = APT_TestUtils.createNetwork();
            aptNwk.Post_Code__c = APT_Constants.STRING_5000;
            aptNwk.Status__c = APT_Constants.TEST_STATUS_OPEN;

            // Adrian Recio, 22/5/2017, Test class population for APT Business Unit field
            aptNwk.APT_Business_Unit__c = APT_Constants.STRING_5000;
            aptNwk.Business_Unit__c = APT_Constants.STRING_5000;
            aptNwk.RecordTypeID = aptNwkRecordType.ID; 
            insert aptNwk;
                
            String idd = aptNwk.ID;

            // Adrian Recio, 22/5/2017, Test class population for APT Business Unit field
            aptNwk = [Select id,Org_ID__c,Name,APT_DWS_ID__c,Post_Code__c,Status__c,State__c,
                             APT_eParcel_Enabled__c,APT_Business_Unit__c,RecordTypeID,APT_Transport_Capability__c,
                             APT_MCAT__c,APT_Threshold_Categories__c,APT_Comments__c from Network__c where id =: idd];
        
            //Create Agreement
            Apttus__APTS_Agreement__c agID = APT_TestUtils.createAgreement(con.id);
            agID.Name = APT_Constants.STRING_TEST1;
            insert agID;
            
            APT_Promo_Post_allowed_Lodgements__c objPromo = new  APT_Promo_Post_allowed_Lodgements__c();
            objPromo.Name = APT_Constants.STRING_TEST1;
            objPromo.APT_Post_code__c = APT_Constants.STRING_5000;
            insert objPromo;
            
            APT_Default_Billing_Account_Products__c objBAP = new APT_Default_Billing_Account_Products__c();
            objBAP.Name = APT_Constants.STRING_TEST1;
            insert objBAP;
            
            //Create Lodgement Zone
            APT_Lodgement_Zone__c lodZone= APT_TestUtils.getLodgementZone(APT_Constants.STRING_LOGGEMENT ,APT_Constants.STRING_TEST1 );
            lodZone.APT_Post_Code_Start__c = APT_Constants.NUMBER_1;
            lodZone.APT_Post_Code_End__c = APT_Constants.NUMBER_9999;
            insert lodZone;
            
            //Create Billing Account 
            Billing_Account__c bacct = new Billing_Account__c();
            bacct.Legacy_Id__c = APT_Constants.TEST_ACCOUNT_LEGACY_ID;
            bacct.Organisation__c = acc.Id;
            insert bacct; 
            
            //Create Agreement Lodgement Point
            APT_Agreement_Lodgement_Point__c objALP1 = APT_TestUtils.createLodgementPoint(acc.id,agID.id,aptNwk.id,lodZone.id,'Promo Post',bacct.id);
            objALP1.APT_Status__c = APT_Constants.ACTIVE;
            objALP1.APT_Charge_Account__c = chargeAccount.ID;
            objALP1.APT_Cash_Account__c = ca.ID;
            objALP1.APT_Sub_Account__c = sa.ID;
            insert objALP1;
            
            Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
            opp.KeyContact__c = con.Id;
            insert opp;
            
            User u = [SELECT Id, Name, ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: APT_Constants.STRING_SYSTEM_ADMINISTRATOR limit 1];
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createDomesticProduct('Promo Post','eParcelStandard','Postal Services','CAT1', 'Standard');
            bundle1.APT_Sync_with_Opportunity__c = APT_Constants.BOOL_TRUE;
            bundle1.APT_Is_Charge_Account_Product__c = APT_Constants.BOOL_TRUE;
            bundle1.APT_Is_Cash_Account_Product__c = APT_Constants.BOOL_FALSE;
            bundle1.APT_Consolidated_Usage_Price_Tiers__c = APT_Constants.BOOL_TRUE;
            insert bundle1;
                 
            //Create Option product
            Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
            option.Apttus_Config2__ConfigurationType__c = APT_Constants.LABEL_LINE_TYPE_OPTION ;
            option.APT_Sync_with_Opportunity__c = APT_Constants.BOOL_TRUE;
            option.APT_International_Pricing__c = APT_Constants.BOOL_FALSE;
            option.APT_Consolidated_Usage_Price_Tiers__c = APT_Constants.BOOL_TRUE;
            insert option;
                 
            //Create PriceBookEntry
            Id pricebookId = Test.getStandardPricebookId();             
            PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);            
            insert standardPrice;
                 
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
                 
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opp.ID,APT_Constants.RECORD_TYPE_PROPOSAL ,APT_Constants.URL_QUOTE, priceList.ID);
            //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
            Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
            Proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;
            Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
            insert Proposal;
                 
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, APT_Constants.RECORD_TYPE_PROPOSAL ,
            'Ad Hoc',priceList.Id, null,
            APT_Constants.CONFIGURATION_STATUS_FINALIZED,
            null, Datetime.now(), true);
            prodconfig.Apttus_Config2__Status__c = APT_Constants.CONFIGURATION_STATUS_FINALIZED ;
            insert prodconfig;
            
            Apttus_Config2__LineItem__c lineItem = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
                                                        1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
                                                        null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
                                                        'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
                                                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
                                                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            lineItem.Apttus_Config2__AllowManualAdjustment__c = true;
            lineItem.Apttus_Config2__NetPrice__c = 5225;
            lineItem.Apttus_Config2__PrimaryLineNumber__c = APT_Constants.NUMBER_1;
            lineItem.Apttus_Config2__NetAdjustmentPercent__c = APT_Constants.NUMBER_10;
            lineItem.Apttus_Config2__ParentBundleNumber__c = APT_Constants.NUMBER_1;
            lineItem.Apttus_Config2__ProductId__c = option.ID;
            insert lineItem;  
            
            Apttus_Approval__Approval_Request__c parentApprovalReq = new Apttus_Approval__Approval_Request__c();
            parentApprovalReq.Apttus_Approval__ChildObjectId__c = lineItem.ID;
            parentApprovalReq.Apttus_Approval__Actual_Approver__c = u.Id;
            parentApprovalReq.Apttus_Approval__Approver_Comments__c = APT_Constants.STRING_TEST1;
            parentApprovalReq.Apttus_Approval__Approval_Status__c = APT_Constants.APPROVAL_STATUS_SUBMITTED;
            insert parentApprovalReq;
            
            Apttus_Approval__Approval_Request__c childApprovalReq = new Apttus_Approval__Approval_Request__c();
            childApprovalReq.Apttus_Approval__ChildObjectId__c = lineItem.ID;
            childApprovalReq.Apttus_Approval__Actual_Approver__c = u.Id;
            childApprovalReq.Apttus_Approval__Approver_Comments__c = APT_Constants.STRING_TEST1;
            childApprovalReq.Apttus_Approval__Approval_Status__c = APT_Constants.APPROVAL_STATUS_SUBMITTED;
            childApprovalReq.Apttus_Approval__ParentRequestId__c = parentApprovalReq.Id;
            childApprovalReq.Apttus_CQApprov__CartId__c = prodconfig.Id;
            insert childApprovalReq; 
            
            Test.StartTest();
            
            ApexPages.currentPage().getParameters().put(APT_Constants.PARAM_ID, acc.Id);
            
            APT_ProposalApprovedRejectedController par = new APT_ProposalApprovedRejectedController();
            par.setproposalID(proposal.Id);
        }
    }
    
    private static TestMethod void TestgetProposalURL() 
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) 
        {   
            //Create Contact
            Contact con = APT_TestUtils.createContact();
            insert con;
            
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = APT_Constants.TEST_ACCOUNT_TYPE;
            acc.ACN__c = APT_Constants.TEST_ACCOUNT_ACN;
            acc.LEGACY_ID__c = APT_Constants.TEST_ACCOUNT_LEGACY_ID;
            insert acc;
            
            acc.LEGACY_ID__c = APT_Constants.TEST_ACCOUNT_LEGACY_ID;
            update acc;
            
            Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
            opp.KeyContact__c = con.Id;
            insert opp;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opp.ID,APT_Constants.RECORD_TYPE_PROPOSAL ,APT_Constants.URL_QUOTE, priceList.ID);
            //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
            Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
            Proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;
            Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
            insert Proposal;
            
            Apttus_Config2__ConfigSystemProperties__c sysProp = new Apttus_Config2__ConfigSystemProperties__c();
            sysProp.Name = APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES;
            sysProp.Apttus_Config2__InstanceUrl__c = APT_Constants.PARAM_RETURN_URL ;
            insert sysProp;
            
            Test.StartTest();
            
            ApexPages.currentPage().getParameters().put(APT_Constants.PARAM_ID, acc.Id);
            
            APT_ProposalApprovedRejectedController par = new APT_ProposalApprovedRejectedController();
            par.proposalSO = Proposal;
            String proposalURL = par.getProposalURL();
            ID proposalID = par.getproposalID();
            Test.StopTest();
            
            System.assert(proposalURL != null);
        }
    }
}