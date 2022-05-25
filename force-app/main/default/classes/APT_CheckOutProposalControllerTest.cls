/**
 * @description       : This test class is written for APT_CheckOutProposalController
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 05-25-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   05-25-2021   Mansi Shah   Initial Version
**/
@isTest
public class APT_CheckOutProposalControllerTest {
    /**
    * @description: This method will set up the test data for test methods 
    * @author Mansi Shah | 05-25-2021 
    **/
    @TestSetup
    static void makeData(){
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        
        System.runAs(testuser) {
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.type = 'New Customer';
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Product2 product1 = APT_TestUtils.createInternationalProduct(APT_Constants.PARAM_APPC_PRODUCT,'APPC','APPC');
            product1.Non_contracted__c = false;
            insert product1 ;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli = APT_TestUtils.createPriceListItem(priceList.ID,product1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert proposal;
            
            //Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                    //proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
            //insert prodconfig;
            
            Apttus_Config2__ProductConfiguration__c config =new  Apttus_Config2__ProductConfiguration__c(Name='Australia Post Parcel Contract',Apttus_QPConfig__Proposald__c=proposal.id,Apttus_Config2__PriceListId__c=priceList.id,Apttus_Config2__Status__c = APT_Constants.CONFIGURATION_STATUS_FINALIZED);
            insert config;
            
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(config.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                    1, 'Product/Service', null, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                    null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
                                                                    'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
                                                                    'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                    true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
                                                                    5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                                                                    bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
                                                                    bundleLine.Apttus_Config2__NetPrice__c = 5225;
                                                                    bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
                                                                    bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert bundleLine; 
            
            
            
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
    }
    
    /**
    * @description: Positive scenario - Opportunity is present on Proposal 
    * @author Mansi Shah | 05-25-2021 
    **/
    @isTest
    public static void testOpportunityPresent(){
        Apttus_Config2__ProductConfiguration__c prodconfig = [SELECT ID,Apttus_QPConfig__Proposald__c 
                                                              FROM Apttus_Config2__ProductConfiguration__c
                                                              LIMIT 1];
                                                              
            Apttus_Proposal__Proposal_Line_Item__c lineitm=[select id,Apttus_QPConfig__ConfigurationId__c,Apttus_QPConfig__AttributeValueId__c,Apttus_QPConfig__AttributeValueId__r.Applied_PSR__c,Apttus_QPConfig__AttributeValueId__r.Applied_PSR__r.Quote_Validity_End_Date__c,Apttus_QPConfig__LineNumber__c,Apttus_QPConfig__ItemSequence__c,Apttus_QPConfig__LineType__c,Apttus_Proposal__Proposal__c from 
                                          Apttus_Proposal__Proposal_Line_Item__c  limit 1 ]; 
                                          
            Apttus_Proposal__Proposal__c proposal=[select id from Apttus_Proposal__Proposal__c where id=:lineitm.Apttus_Proposal__Proposal__c];                                                 

            Deal_Support_Request__c dsReq=[select id from Deal_Support_Request__c limit 1];   
            
            Apttus_QPConfig__ProposalProductAttributeValue__c av=[select id from Apttus_QPConfig__ProposalProductAttributeValue__c limit 1] ;                          

            String instanceURL = URL.getSalesforceBaseUrl().toExternalForm()+'APT_CheckOut_RedirectToOpportunity';
            ApexPages.currentPage().getHeaders().put('Referer', instanceURL);
            Apexpages.currentpage().getparameters().put('Id', lineitm.Apttus_QPConfig__ConfigurationId__c);
            Apexpages.currentpage().getparameters().put(APT_Constants.URL_BUSINESS_OBJECT_ID, prodconfig.Apttus_QPConfig__Proposald__c);
            
            APT_CheckOutProposalController controller = new APT_CheckOutProposalController();
            /*
            APT_Dealsupportobjectselector obj = new APT_Dealsupportobjectselector();
            APT_Dealsupportobjectselector mockSelector = (APT_Dealsupportobjectselector) MockUtility.mockSelector(APT_Dealsupportobjectselector.class);
            MockUtility.Mocks.startStubbing();
            MockUtility.Mocks.when(mockSelector.selectByConfigId((Set<Id>)fflib_Match.eq(new Set<Id>{lineitm.Apttus_QPConfig__AttributeValueId__r.Applied_PSR__c}))).thenReturn(
                new Map<Id,Deal_Support_Request__c>(new List<Deal_Support_Request__c>{dsReq}));
            MockUtility.Mocks.stopStubbing();
            
            APT_Proposalproductobjectselector obj1 = new APT_Proposalproductobjectselector();
            APT_Proposalproductobjectselector mockSelector1 = (APT_Proposalproductobjectselector) MockUtility.mockSelector(APT_Proposalproductobjectselector.class);
            MockUtility.Mocks.startStubbing();
            MockUtility.Mocks.when(mockSelector1.selectByConfigId((Set<Id>)fflib_Match.eq(new Set<Id>{lineitm.Apttus_QPConfig__AttributeValueId__c}))).thenReturn(
                new Map<Id,Apttus_QPConfig__ProposalProductAttributeValue__c>(new List<Apttus_QPConfig__ProposalProductAttributeValue__c >{av}));
            MockUtility.Mocks.stopStubbing();
            
            
            APT_ProposalObjectsSelector obj2 = new APT_ProposalObjectsSelector();
            APT_ProposalObjectsSelector mockSelector2 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
            MockUtility.Mocks.startStubbing();
            MockUtility.Mocks.when(mockSelector2.selectByConfigId((Set<Id>)fflib_Match.eq(new Set<Id>{lineitm.Apttus_Proposal__Proposal__c}))).thenReturn(
                new Map<Id,Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{proposal}));
            MockUtility.Mocks.stopStubbing();
            
            
            APT_ProposalLineItemSelector obj3 = new APT_ProposalLineItemSelector();
            APT_ProposalLineItemSelector mockSelector3 = (APT_ProposalLineItemSelector) MockUtility.mockSelector(APT_ProposalLineItemSelector.class);
            MockUtility.Mocks.startStubbing();
          //  MockUtility.Mocks.when(mockSelector3.selectByConfigId((Set<Id>)fflib_Match.eq(new Set<Id>{lineitm.Apttus_QPConfig__ConfigurationId__c}))).thenReturn(
          //  new Map<Id,Apttus_Proposal__Proposal_Line_Item__c>(new List<Apttus_Proposal__Proposal_Line_Item__c>{lineitm}));
           
    

      Map<Id, Apttus_Proposal__Proposal_Line_Item__c> mockDsrMap = new Map<Id, Apttus_Proposal__Proposal_Line_Item__c>{lineitm.Id => lineitm};


         // MockUtility.Mocks.when(mockSelector3.selectByConfigId(mockDsrMap.keyset(), new Set<object>{APT_ProposalLineItemSelector.Options.WITH_PROPOSAL, APT_ProposalLineItemSelector.Options.WITH_APTTUS_CONFIG_ATTRIBUTE_VALUE})).thenReturn(mockDsrMap);
            MockUtility.Mocks.when(mockSelector3.selectByConfigId(mockDsrMap.keyset(), 
            new Set<object>{APT_ProposalLineItemSelector.Options.WITH_PROPOSAL, 
            APT_ProposalLineItemSelector.Options.WITH_APTTUS_CONFIG_ATTRIBUTE_VALUE})).thenReturn(mockDsrMap);

         // MockUtility.Mocks.when(holdingRoleSelector.selectByName((String)fflib_Match.anyObject())).thenReturn(holdingRoleMap);


            MockUtility.Mocks.stopStubbing();
            
            */
            
            PageReference pgRef = controller.checkOpportunity();
            system.assert(pgRef != null);
    }
    /**
    * @description: Negative scenario - Opportunity is not present on Proposal  
    * @author Mansi Shah | 05-25-2021 
    **/
     @isTest
    public static void testOpportunityNotPresent(){
           Apttus_Config2__ProductConfiguration__c prodconfig = [SELECT ID,Apttus_QPConfig__Proposald__c 
                                                              FROM Apttus_Config2__ProductConfiguration__c
                                                              LIMIT 1];

            Apttus_Proposal__Proposal__c oProposal = [SELECT ID,Name,Apttus_Proposal__Opportunity__c
                                                      FROM Apttus_Proposal__Proposal__c LIMIT 1];
            
            oProposal.Apttus_Proposal__Opportunity__c = null;
            update oProposal;                                          

            String instanceURL = URL.getSalesforceBaseUrl().toExternalForm()+'APT_CheckOut_RedirectToOpportunity';
            ApexPages.currentPage().getHeaders().put('Referer', instanceURL);
            Apexpages.currentpage().getparameters().put('Id', prodconfig.id);
            Apexpages.currentpage().getparameters().put(APT_Constants.URL_BUSINESS_OBJECT_ID, prodconfig.Apttus_QPConfig__Proposald__c);
            
            APT_CheckOutProposalController controller = new APT_CheckOutProposalController();
            PageReference pgRef = controller.checkOpportunity();
            system.assert(pgRef == null);
    }
}