/**
* @author Sri HArsha
* @date 2022-04-27
* @group Tests
* @tag Selector
* @tag Apttus_Proposal__Proposal_Line_Item__c SObject
* @domain Apttus 
* @description Apttus_Proposal__Proposal_Line_Item__c to validate Data.
*/
@IsTest
private with sharing class APT_ProposalLineItemSelector_Test {
    
    //Test setupdata;
    @testSetup static void setup() { 
    
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;        
        
        Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
        opty.type = 'New Customer';
        insert opty; 
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        Product2 product1 = APT_TestUtils.createInternationalProduct(APT_Constants.PARAM_APPC_PRODUCT,'APPC','APPC');
        product1.Non_contracted__c = false;
        insert product1 ;  
        
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
        insert proposal;
        
        Apttus_Config2__ProductConfiguration__c config =new  Apttus_Config2__ProductConfiguration__c(Name='Australia Post Parcel Contract',Apttus_QPConfig__Proposald__c=proposal.id,Apttus_Config2__PriceListId__c=priceList.id,Apttus_Config2__Status__c = APT_Constants.CONFIGURATION_STATUS_FINALIZED);
        insert config;
        
        Apttus_Config2__ProductOptionComponent__c prodOptionComponent = new Apttus_Config2__ProductOptionComponent__c(Apttus_Config2__Sequence__c=2);
        insert prodOptionComponent;
        
        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c(Name='Test',Apttus_Config2__Active__c=true,
                                                                                               Apttus_Config2__HierarchyLabel__c='High',Apttus_Config2__Type__c='Offering',Apttus_Config2__GuidePage__c='Sample');
        insert category;
        
        Apttus_Config2__ClassificationHierarchy__c classHierarchy = new Apttus_Config2__ClassificationHierarchy__c(Apttus_Config2__HierarchyId__c=category.id, Apttus_Config2__Label__c='Sample');
        insert classHierarchy;
        
        Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id, product1.id, '', '');
        insert priceListItem;
        
        
        Apttus_Config2__SummaryGroup__c summaryGroup = new Apttus_Config2__SummaryGroup__c (Apttus_Config2__ConfigurationId__c=config.id, Apttus_Config2__ItemSequence__c=78, Apttus_Config2__LineNumber__c=45);
        insert summaryGroup ;
        Apttus_Config2__LineItem__c lineItem = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id , 1, true, 2, '', product1.id, false,prodOptionComponent.id,
                                                                           product1.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem.Id,'','','','',
                                                                           false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        insert lineItem ;
        
        Id bidDSRRecordTypeId = [Select Id from RecordType where Name='Bids Support Request' and sObjectType='Deal_Support_Request__c'].Id;
        
        Deal_Support_Request__c dsr= new Deal_Support_Request__c();
        dsr.Quote_Validity_End_Date__c=system.today();
        dsr.stage__c='New';
        dsr.Status__c='Draft';
        dsr.Start_Date__c = date.Today();
        dsr.Due_Date__c = date.Today().addDays(25); 
        dsr.Document_Type__c = 'RFP'; 
        dsr.Organisation__c=acc.id;
        dsr.Product__c='Courier';
        dsr.Work_Type__c='other';
        dsr.RecordTypeId = bidDSRRecordTypeId;
        dsr.Opportunity__c = opty.Id;
        insert dsr;  
        
        Apttus_Proposal__Proposal_Line_Item__c propLineItem = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem.Id,priceListItem.Id,product1.Id,product1.Id);
        propLineItem.Apttus_QPConfig__LineNumber__c =1;
        propLineItem.Apttus_QPConfig__ItemSequence__c=1;
        propLineItem.Apttus_QPConfig__IsPrimaryLine__c=true;
        propLineItem.Apttus_QPConfig__LineType__c = 'Product/Service';
        propLineItem.Apttus_Proposal__Proposal__c=proposal.id; 
        propLineItem.Apttus_QPConfig__ConfigurationId__c=config.id;          
        insert propLineItem ;      
        
       
        Apttus_QPConfig__ProposalProductAttributeValue__c ppav= new Apttus_QPConfig__ProposalProductAttributeValue__c();
        ppav.Applied_PSR__c=dsr.id;
        ppav.Revenue_Committment__c = '3,000 - 4,999';
        ppav.Apttus_QPConfig__LineItemId__c = propLineItem.ID;        
        ppav.APT_Volume_Data__c = 'Yes';
        ppav.APT_Minimum_Quantity__c = 0;
        insert ppav;  
        
        propLineItem.Apttus_QPConfig__AttributeValueId__c=ppav.id;
        update propLineItem ;
       
        
        
    }
    
    /**
* Test:
*  Ensures that the selectors method is returning the correct query result
*/
    @IsTest
    private static void testEnsureSelectorMethodsReturnCorrectResult() {        
        
        MockUtility.disableTriggerExecution();
        
        Apttus_Proposal__Proposal_Line_Item__c prpLineitem=[select id from Apttus_Proposal__Proposal_Line_Item__c limit 1];
        
        Test.startTest();
        
        APT_ProposalLineItemSelector selector = APT_ProposalLineItemSelector.newInstance(1);
        Map<Id, Apttus_Proposal__Proposal_Line_Item__c > results = selector.selectByConfigId(new Set<ID>{prpLineitem.id});
        Test.stopTest();
        
    }
    
}