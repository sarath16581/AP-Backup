/**
 * This Apex Class is test class for APT_ContractPricingQueueable.
 * Created By - Mausam Padhiyar
 * Created Date - 6th Oct, 2016
 * Last Modified By -
 * Last Modified Date -
 */
@isTest
public with sharing class APT_ContractPricingQueueable_Test {
    
    /**
     * Test Method 1.
     */
    private static testMethod void testMethod1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        
        System.runAs(testuser) {
            Contact con= APT_TestUtils.createContact();
            insert con;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            tempacct.Legacy_Id__c = '60000000';
            insert tempacct;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            insert opp;
            
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            product.APT_Contract_Pricing__c = true;
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
            insert productAttributeGroup;
            
            Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
            insert productAttribute;
            
            list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
            Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('priceDimension1', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension1);
            
            Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('priceDimension2', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Domestic_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension2);
            
            Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('priceDimension3', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension3);
            insert listPriceDimension;
            
            Apttus_Config2__PriceMatrix__c priceMatrix = APT_TestUtils.createPriceMatrix(priceListItem.Id, priceDimension1.Id, priceDimension2.Id, priceDimension3.Id);
            insert priceMatrix;
            
            /**
            list<Apttus_Config2__PriceMatrixEntry__c> listPME = new list<Apttus_Config2__PriceMatrixEntry__c>();
            Apttus_Config2__PriceMatrixEntry__c pme1 = new Apttus_Config2__PriceMatrixEntry__c();
            pme1.Apttus_Config2__Dimension1Value__c = '1';
            pme1.Apttus_Config2__Dimension2Value__c = '2';
            pme1.Apttus_Config2__Dimension3Value__c = '3';
            pme1.Apttus_Config2__PriceMatrixId__c = priceMatrix.Id;
            pme1.Apttus_Config2__Sequence__c = 1;
            pme1.Apttus_Config2__UsageRate__c = 1;
            pme1.Apttus_Config2__AdjustmentAmount__c = 1;
            pme1.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme1);
            
            Apttus_Config2__PriceMatrixEntry__c pme2 = new Apttus_Config2__PriceMatrixEntry__c();
            pme2.Apttus_Config2__Dimension1Value__c = '1';
            pme2.Apttus_Config2__Dimension2Value__c = '2';
            pme2.Apttus_Config2__Dimension3Value__c = '3';
            pme2.Apttus_Config2__PriceMatrixId__c = priceMatrix.Id;
            pme2.Apttus_Config2__Sequence__c = 1;
            pme2.Apttus_Config2__UsageRate__c = 1;
            pme2.Apttus_Config2__AdjustmentAmount__c = 1;
            pme2.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme2);
            
            insert listPME;
            **/
            
            Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
            insert quote;
            
            Apttus_Config2__ProductConfiguration__c config =new  Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=quote.id,Apttus_Config2__PriceListId__c=priceList.id);
            insert config;
            
            Apttus_Config2__LineItem__c lineItem = APT_TestUtils.getConfigLineItem(config.id, null, 1, true, 2, '', product.id, false, null,
                                                                                   product.id, null, '', 2.3, false, '', 2, priceList.id, priceListItem.Id, '', '', '', '',
                                                                                   false, false, 22.00, 24.00, '', 34.00, 23.00, 33.50, '');
            insert lineItem;
            
            list<Apttus_Config2__UsagePriceTier__c> listUPT = new list<Apttus_Config2__UsagePriceTier__c>();
            Apttus_Config2__UsagePriceTier__c upt1 = new Apttus_Config2__UsagePriceTier__c();
            upt1.Apttus_Config2__Dimension1Value__c = '1';
            upt1.Apttus_Config2__Dimension2Value__c = '2';
            upt1.Apttus_Config2__Dimension3Value__c = '3';
            upt1.Apttus_Config2__Sequence__c = 1;
            upt1.Apttus_Config2__AdjustmentAmount__c = 1;
            upt1.Apttus_Config2__PriceOverride__c = 1;
            upt1.Apttus_Config2__UsageRate__c = 1;
            upt1.Apttus_Config2__LineItemId__c = lineItem.id;
            listUPT.add(upt1);
            
            Apttus_Config2__UsagePriceTier__c upt2 = new Apttus_Config2__UsagePriceTier__c();
            upt2.Apttus_Config2__Dimension1Value__c = '1';
            upt2.Apttus_Config2__Dimension2Value__c = '2';
            upt2.Apttus_Config2__Dimension3Value__c = '3';
            upt2.Apttus_Config2__Sequence__c = 2;
            upt2.Apttus_Config2__AdjustmentAmount__c = 1;
            upt2.Apttus_Config2__PriceOverride__c = 1;
            upt2.Apttus_Config2__UsageRate__c = 1;
            upt2.Apttus_Config2__LineItemId__c = lineItem.id;
            listUPT.add(upt2);
            
            insert listUPT;
            
            
            Apttus_Proposal__Proposal_Line_Item__c propLineItem = APT_TestUtils.getProposalLineItem(quote.Id,lineItem.Id,priceListItem.Id,product.Id,product.Id);
            propLineItem.Apttus_Proposal__Product__c=product.Id;
            //propLineItem.Apttus_QPConfig__LineNumber__c =1;
            propLineItem.Apttus_QPConfig__ItemSequence__c=1;
            insert propLineItem;
            
            APT_Lodgement_Zone__c LP = APT_TestUtils.getLodgementZone('Sample','1234');
            insert LP;
            
            APT_Quote_Lodgement_Point__c quoteLP = new APT_Quote_Lodgement_Point__c(APT_Proposal_Line_Item__c=propLineItem.Id,APT_Quote_Proposal__c=quote.Id,APT_Lodgement_Zone_Lookup__c=LP.Id);
            insert quoteLP;
            
            APT_Quote_Lodgement_Point__c quoteLP2 = new APT_Quote_Lodgement_Point__c(APT_Proposal_Line_Item__c= null,APT_Quote_Proposal__c=quote.Id,APT_Lodgement_Zone_Lookup__c=LP.Id);
            insert quoteLP2;
            
            APT_Line_Item_Rate_Card__c lineRateCard = new APT_Line_Item_Rate_Card__c(APT_Proposal_Line_Item__c=propLineItem.Id,APT_Value_1__c='1',APT_Value_2__c='2',APT_Value_3__c='3');
            insert lineRateCard;
            
            Apttus__APTS_Agreement__c agreement = APT_TestUtils.createAgreement(con.Id);
            agreement.Apttus_QPComply__RelatedProposalId__c=quote.Id;
            insert agreement;
            
            Apttus__AgreementLineItem__c agrmntLineItem = new Apttus__AgreementLineItem__c (Apttus__ProductId__c=product.Id,Apttus_CMConfig__LineNumber__c=1,
                                                            Apttus_CMConfig__ItemSequence__c=1,Apttus__AgreementId__c=agreement.Id,Apttus_CMConfig__BaseProductId__c=product.Id,Apttus_CMConfig__BillToAccountId__c=tempacct.Id,
                                                            Apttus_CMConfig__DerivedFromId__c=lineItem.Id);
            insert agrmntLineItem;
            
            set<Id> agreementIDList = new set<Id>();
            agreementIDList.add(agreement.ID);
            
            test.startTest();
            
            APT_ContractPricingQueueable cpQueable = new APT_ContractPricingQueueable(agreementIDList);
            System.enqueueJob(cpQueable);
            
            test.stopTest();
            
            Apttus_Config2__PriceList__c pl = [SELECT Id FROM Apttus_Config2__PriceList__c WHERE Apttus_Config2__ContractNumber__c = :agreement.Id];
            system.assert(pl != null);
        }
    }
}