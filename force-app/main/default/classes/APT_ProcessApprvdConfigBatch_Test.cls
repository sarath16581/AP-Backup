/**
 * @description       : This is the test class for APT_ProcessApprovedConfigurationBatch
 * @author            : Darshan Chauhan
 * @group             : 
 * @last modified on  : 06-29-2021
 * @last modified by  : Darshan Chauhan
 * Modifications Log 
 2022- 05-15 Nasir Jawed Changed Tier
**/
@isTest
public with sharing class APT_ProcessApprvdConfigBatch_Test {

    @isTest
    static void validatTest() {
       
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER, EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {

            set<Id> setprodconfigId = new set<Id>();
            Apttus_Config2__ProductConfiguration__c prodconfig = [SELECT Id, name, Apttus_QPConfig__Proposald__c, Apttus_QPConfig__Proposald__r.Is_Startrack_Proposal__c from Apttus_Config2__ProductConfiguration__c];
            prodconfig.Apttus_CQApprov__Approval_Status__c = APT_Constants.APPROVAL_STATUS_PROCESSING_APPROVAL;
            update prodconfig;


            for(Apttus_Config2__ProductConfiguration__c prod1 : [SELECT Id, name, Apttus_QPConfig__Proposald__c, Apttus_QPConfig__Proposald__r.Is_Startrack_Proposal__c from Apttus_Config2__ProductConfiguration__c]){
                System.debug('prod record>>>'+prod1);
                setprodconfigId.add(prod1.Id);
            }
            
            test.startTest();
            APT_ProcessApprovedConfigurationBatch pavConfigBatch = new APT_ProcessApprovedConfigurationBatch(setprodconfigId);
            test.stopTest();
			System.assertEquals(([SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1]).size(), 1);        			            

        }
    }

    @TestSetup
    static void createData(){
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;                          
            
        //Create Opportunity
        Opportunity opty = APT_TestUtils.createOpportunity(acc.id);
        insert opty;

        // Startrack Product
        Product2 product = APT_TestUtils.createStarTrackProduct('Road Express Tier 1', 'ExpressRoadTier1', 'Parcel Services', 'T01', 'EXP', 'Startrack');
        product.APT_Domestic_Pricing__c = true;
        insert product;
        
        //Create PriceList
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;

        Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
        insert priceListItem;
        
        APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('3000', 'AUSTRALIAN NATIONAL UNIVERSITY', 'MIL', 'VC3', 'AC3');
        insert pcm1;

        Network__c ntwk = APT_TestUtils.createNetwork();
        insert ntwk;

        Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.id,opty.id,'Proposal','Quote', priceList.id);
        Proposal.Apttus_Proposal__Approval_Stage__c='Draft';
        Proposal.Expected_Revenue_Start_Date__c = System.today();
        Proposal.Expected_Revenue_End_Date__c = System.today() +90;
        Proposal.Apttus_Proposal__Primary__c =false;
        Proposal.APT_Selected_LP__c = ntwk.id;
        Proposal.Is_Startrack_Proposal__c = APT_Constants.OPTION_YES;
        Proposal.Apttus_QPApprov__Approval_Status__c = 'Approval Required';
        Proposal.APT_Minimum_Monthly_Spend__c = 1200;
        Proposal.APT_Postcode_Suburb__c = pcm1.id;
        insert Proposal;

        //Create Product Configuration             
        Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
        Proposal.Id, 'Proposal',
        'Ad Hoc',priceList.Id, null,
        'Ready For Finalization',
        null, Datetime.now(), true);
        prodconfig.Apttus_CQApprov__Approval_Status__c = APT_Constants.PROPOSAL_APPROVAL_STATUS_PENDING_APPROVAL;
        insert prodconfig;

        Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
            1, 'Product/Service', product.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
            null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.id, priceListItem.id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;            
            bundleLine.Apttus_Config2__IsPrimaryLine__c = true;
            bundleLine.Apttus_CQApprov__Approval_Status__c = 'Approved';

            insert bundleLine;

            Apttus_Config2__ProductAttributeValue__c prntpav = APT_TestUtils.GetAttributeValue(bundleLine.Id,'High',true,true,true,'5674','Industry',true,true);            
            insert prntpav;
    }
}