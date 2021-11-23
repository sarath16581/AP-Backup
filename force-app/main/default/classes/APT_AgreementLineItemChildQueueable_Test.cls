/**
Description - 
Created By - Aakash Khatri
Created Date - 4th July, 2016
Last Modified By -
Last Modified Date - 
 */
 
@isTest
private class APT_AgreementLineItemChildQueueable_Test {
    
    private static testMethod void TestMethod1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            try{
            
            Contact con= APT_TestUtils.createContact();
            insert con;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            tempacct.Legacy_Id__c = '60000000';
            insert tempacct;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            insert opp;
            
            Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
            insert product;
            
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            insert priceListItem;
            
            Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
            insert quote;
            
            Apttus_Config2__ProductConfiguration__c config =new  Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=quote.id,Apttus_Config2__PriceListId__c=priceList.id);
            insert config;
            
            Apttus_Config2__SummaryGroup__c summaryGroup = new Apttus_Config2__SummaryGroup__c (Apttus_Config2__ConfigurationId__c=config.id, Apttus_Config2__ItemSequence__c=78, Apttus_Config2__LineNumber__c=45);
            insert summaryGroup ;
            
            Apttus_Config2__ProductOptionComponent__c prodOptionComponent = new Apttus_Config2__ProductOptionComponent__c(Apttus_Config2__Sequence__c=2);
            insert prodOptionComponent;
            
            Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c(Name='Test',Apttus_Config2__Active__c=true,
                                                                Apttus_Config2__HierarchyLabel__c='High',Apttus_Config2__Type__c='Offering',Apttus_Config2__GuidePage__c='Sample');
            insert category;
            
            Apttus_Config2__ClassificationHierarchy__c classHierarchy = new Apttus_Config2__ClassificationHierarchy__c(Apttus_Config2__HierarchyId__c=category.id, Apttus_Config2__Label__c='Sample');
            insert classHierarchy ;
            
            Apttus_Config2__LineItem__c lineItem = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id  ,1,true,2,'',product.id,false,prodOptionComponent.id,
                                                                                   product.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem.Id,'','','','',
                                                                                   false,false,22.00,24.00,'',34.00,23.00,33.50,'');
            insert lineItem;
            
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
            
            test.startTest();
            
            Apttus__AgreementLineItem__c agrmntLineItem = new Apttus__AgreementLineItem__c (Apttus__ProductId__c=product.Id,Apttus_CMConfig__LineNumber__c=1,
                                                            Apttus_CMConfig__ItemSequence__c=1,Apttus__AgreementId__c=agreement.Id,Apttus_CMConfig__BaseProductId__c=product.Id,Apttus_CMConfig__BillToAccountId__c=tempacct.Id,
                                                            Apttus_CMConfig__ClassificationId__c=classHierarchy.Id,Apttus_CMConfig__DerivedFromId__c=lineItem.Id);
            insert agrmntLineItem;
            
            set<Id> agreementIDList = new set<Id>();
            agreementIDList.add(agreement.ID);
            
            APT_AgreementLineItemChildQueueable ccb = new APT_AgreementLineItemChildQueueable(agreementIDList);
            System.enqueueJob(ccb);
            
            test.stopTest();
            }catch(exception ex){
                System.debug('Ex.getMessage:' + ex.getMessage());
            }
        }
    }
    
}