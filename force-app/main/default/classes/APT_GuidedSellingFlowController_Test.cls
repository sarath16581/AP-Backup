/**
Description: Test class for Apex Class-APT_GetRenewalRatesController.
Created By - Drashtee Shah
Created Date - 22nd Feb, 2016
Last Modified By -
Last Modified Date -
**/
@isTest
private class APT_GuidedSellingFlowController_Test {
    /**
        Creating test data
    **/  
    private static TestMethod void APT_GuidedSellingFlowController1() {
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
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','APOST001','Postal Services');
            bundle1.Apttus_Config2__ConfigurationType__c = 'bundle';
            bundle1.Apttus_Config2__HasOptions__c = true;
            bundle1.Apttus_Config2__HasAttributes__c = true;
            //bundle1.Apttus_Config2__HasSearchAttributes__c = true;
            
            insert bundle1;
            
            Product2 option = APT_TestUtils.createInternationalProduct('International Bundle','InternationalBundle','Postal Services');
             option.Apttus_Config2__ConfigurationType__c='Option';
             option.APT_Sync_with_Opportunity__c=true;
             option.APT_International_Pricing__c = false;
             option.APT_Sync_with_Opportunity__c = true;
             insert option;
             
             
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Apttus_Config2__ClassificationName__c
            Apttus_Config2__ClassificationName__c cn = new Apttus_Config2__ClassificationName__c();
            cn.Name = 'test';
            cn.Apttus_Config2__Type__c = 'Option Group';
            cn.Apttus_Config2__HierarchyLabel__c = 'Pricing Products';
            insert cn;
            
            //Apttus_Config2__ClassificationHierarchy__c
            Apttus_Config2__ClassificationHierarchy__c cHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
            cHierarchy.Name = 'test';
            cHierarchy.Apttus_Config2__Label__c = 'Pricing Products';
            cHierarchy.Apttus_Config2__HierarchyId__c = cn.Id;
            insert cHierarchy;
            
            //Apttus_Config2__ProductOptionGroupId__c
            Apttus_Config2__ProductOptionGroup__c pog = new Apttus_Config2__ProductOptionGroup__c();
            pog.Apttus_Config2__Sequence__c = 1;
            pog.Apttus_Config2__ProductId__c = bundle1.ID;
            pog.Apttus_Config2__OptionGroupId__c = cHierarchy.ID;
            pog.Apttus_Config2__RootOptionGroupId__c = cHierarchy.ID;
            pog.Apttus_Config2__MinOptions__c = 1;
            pog.Apttus_Config2__MaxOptions__c = 1;
            pog.Apttus_Config2__RootSequence__c =1;
            pog.Apttus_Config2__IsLeaf__c = true;
            insert pog;
            
            //Apttus_Config2__ProductOptionComponent__c
            Apttus_Config2__ProductOptionComponent__c poc = new Apttus_Config2__ProductOptionComponent__c();
            poc.Apttus_Config2__Sequence__c = 1;
            poc.Apttus_Config2__ComponentProductId__c = option.ID;
            poc.Apttus_Config2__ProductOptionGroupId__c = pog.Id;
            poc.Apttus_Config2__RelationshipType__c = 'Option';
            poc.Apttus_Config2__Sequence__c =1;
            poc.Apttus_Config2__ParentProductId__c = bundle1.ID;
            poc.Apttus_Config2__DefaultQuantity__c = 1;
            insert poc;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, 'Proposal',
            'Ad Hoc',priceList.Id, null,
            'Finalized',
            null, Datetime.now(), true);
            insert prodconfig;
            
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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
            
            Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c(Name='Australia Post - All Categories',Apttus_Config2__Active__c=true,
                                                                Apttus_Config2__HierarchyLabel__c='Australia Post - All Categories',Apttus_Config2__Type__c='Offering',Apttus_Config2__GuidePage__c='APT_GuidedSellingFlow');
            insert category;
            Apttus_Config2__ClassificationHierarchy__c classHierarchy = new Apttus_Config2__ClassificationHierarchy__c(Apttus_Config2__HierarchyId__c=category.id, Apttus_Config2__Label__c='Australia Post - All Categories');
            insert classHierarchy ;
            
            /*Apttus_Config2__GuidedQuestion__c guidedQuestion = new Apttus_Config2__GuidedQuestion__c();
            guidedQuestion.Name = 'test1';
            guidedQuestion.Apttus_Config2__Description__c = 'Product2';
            guidedQuestion.Apttus_Config2__Datasource__c = 'Product2';
            guidedQuestion.Apttus_Config2__InterviewName__c = 'test1iInterview';
            insert guidedQuestion;*/
            
            // create Apttus_Config2__GuidedSearchRule__c
            Apttus_Config2__GuidedSearchRule__c gsr = new Apttus_Config2__GuidedSearchRule__c();
            gsr.Name = 'Australia Post - All Categories';
            gsr.Apttus_Config2__Sequence__c = 1;
            gsr.Apttus_Config2__RuleType__c = 'Filter Set';
            gsr.Apttus_Config2__BusinessObject__c = 'Product2';
            gsr.Apttus_Config2__Active__c = true;
            gsr.Apttus_Config2__InterviewName__c = 'Australia Post - All Categories';
            gsr.Apttus_Config2__CategoryId__c = category.ID;
            gsr.Apttus_Config2__ClassificationId__c = classHierarchy.ID;
            //gsr.Apttus_Config2__GuidedQuestion1Id__c = guidedQuestion.ID;
            insert gsr;
            
            Apttus_Config2__GuidedSearchRuleEntry__c searchRuleEntry = new Apttus_Config2__GuidedSearchRuleEntry__c();
            //searchRuleEntry.Apttus_Config2__GuidedAnswer1__c = 'No';
            searchRuleEntry.Apttus_Config2__GuidedSearchRuleId__c = gsr.ID;
            searchRuleEntry.Apttus_Config2__Sequence__c = 1;
            insert searchRuleEntry;
            
            Apttus_Config2__GuidedSearchRuleFilter__c ruleFilter = new Apttus_Config2__GuidedSearchRuleFilter__c();
            ruleFilter.Apttus_Config2__FieldName__c = 'APT_Creatively_Shaped_Samples_Articles__c';
            ruleFilter.Apttus_Config2__Sequence__c = 1;
            ruleFilter.Apttus_Config2__MapTo__c = 'Value';
            ruleFilter.Apttus_Config2__CompOper__c = 'equal to';
            ruleFilter.Apttus_Config2__FieldValue__c = 'Yes Samples';
            ruleFilter.Apttus_Config2__RuleEntryId__c = searchRuleEntry.ID;
            insert ruleFilter;
            
            //create interview Apttus_Config2__SearchAttributeValue__c
            Apttus_Config2__SearchAttributeValue__c sav = new Apttus_Config2__SearchAttributeValue__c();
            sav.Name = 'Australia Post - All Categories';
            sav.Apttus_Config2__InterviewName__c = 'Australia Post - All Categories';
            sav.Apttus_Config2__ConfigurationId__c = prodconfig.ID;
            insert sav;
            
            Apttus_Approval__Approval_Process__c approvalProcess = new Apttus_Approval__Approval_Process__c();
            //approvalProcess.Name = 'Test';
            approvalProcess.Apttus_Approval__Object_Name__c = 'Apttus_Config2__ProductConfiguration__c';
            approvalProcess.Apttus_Approval__Object_Type__c = 'Apttus_Config2__ProductConfiguration__c';
            approvalProcess.Apttus_Approval__Sequence__c = 1;
            approvalProcess.Apttus_Approval__Active__c = true;
            insert approvalProcess;
            
            
            Apttus_Approval__Approval_Request__c approvalReq = new Apttus_Approval__Approval_Request__c();
            approvalReq.Apttus_CQApprov__CartId__c = prodconfig.ID;
            approvalReq.Apttus_Approval__Object_Id__c = prodconfig.ID;
            approvalReq.Apttus_Approval__Object_Type__c = 'Apttus_Config2__ProductConfiguration__c';
            approvalReq.Apttus_Approval__Initial_Submitter__c = UserInfo.getUserId();
            approvalReq.Apttus_Approval__Actual_Approver__c = UserInfo.getUserId();
            approvalReq.Apttus_Approval__Assigned_To_Type__c = 'Related User';
            approvalReq.Apttus_Approval__Assigned_To_Id__c = UserInfo.getUserId();
            approvalReq.Apttus_Approval__Active__c = true;
            approvalReq.Apttus_Approval__Approval_Status__c = 'Not Submitted';
            insert approvalReq;
            
            Apttus_Approval__Approval_Request__c approvalReq1 = new Apttus_Approval__Approval_Request__c();
            approvalReq1.Apttus_CQApprov__CartId__c = prodconfig.ID;
            approvalReq1.Apttus_Approval__Object_Id__c = prodconfig.ID;
            approvalReq1.Apttus_Approval__Object_Type__c = 'Apttus_Config2__ProductConfiguration__c';
            approvalReq1.Apttus_Approval__Initial_Submitter__c = UserInfo.getUserId();
            approvalReq1.Apttus_Approval__Actual_Approver__c = UserInfo.getUserId();    
            approvalReq1.Apttus_Approval__Assigned_To_Type__c = 'Related User';
            approvalReq1.Apttus_Approval__Assigned_To_Id__c = UserInfo.getUserId();
            approvalReq1.Apttus_Approval__Active__c = true;
            approvalReq1.Apttus_Approval__Approval_Status__c = 'Not Submitted';
            insert approvalReq1;
            
            Test.StartTest();
            
            PageReference pageRef = Page.APT_GuidedSellingFlow;
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('interviewName', sav.Apttus_Config2__InterviewName__c);
            ApexPages.currentPage().getParameters().put('callerPage', 'APT_GuidedSellingFlow');
            ApexPages.currentPage().getParameters().put('interviewId', sav.ID );
            ApexPages.currentPage().getParameters().put('configRequestId', prodconfig.ID );
            ApexPages.currentPage().getParameters().put('step', 'Option' );
            ApexPages.currentPage().getParameters().put('opportunityId', opty.ID);  
            ApexPages.currentPage().getParameters().put('productId', bundle1.ID);
            
            APT_Utils.getApproversList(prodconfig.ID, UserInfo.getName());
            APT_Utils.submitForApprovals(prodconfig.ID, 'Test');
            
            ApexPages.StandardController sc = new ApexPages.StandardController(prodconfig);
            APT_GuidedSellingFlowController gfc = new APT_GuidedSellingFlowController(sc);
            gfc.lookupHoverDetailUrl = 'Test URL.com';
            gfc.base = new Apttus_Config2.GuidePageController(sc);
            gfc.bundles = new List<APT_GuidedSellingFlowController.BundleInfo>();
            APT_GuidedSellingFlowController.BundleInfo bundle = new APT_GuidedSellingFlowController.BundleInfo(bundle1);
            bundle.isSelected = true;
            bundle.getIconStyleCSS();
            bundle.getIsShowSelect();
            bundle.getIsShowConfigure();
            bundle.addOptions(new List<Apttus_Config2__ProductOptionComponent__c>{poc});
            
            gfc.bundles.add(bundle);
            //gfc.doInit();
            gfc.getConfigId();
            gfc.getRequestId();
            //gfc.getInterviewId();
            gfc.getBase();
            gfc.getopportunityId();
            gfc.getBundleProducts();
            gfc.getHasBundleProducts();
            gfc.getFinishPage();
            gfc.getIsOptionStep();
            gfc.getIsResultStep();
            gfc.redirectToCallerPage();
            gfc.doSearchStep();
            gfc.doSelect();
            gfc.doCartSelected();
            gfc.doSelectAll();
            //gfc.getInterviewStepSO();
            //gfc.setCurrentStep(new gfc.Step.OPTION);
            
            //APT_Utils.deleteApprovalRequests(new List<Apttus_Approval__Approval_Request__c>{approvalReq});
            Test.StopTest();
            system.assert(bundle!=null);
            }
        }
    /**
        Creating test data
    **/ 
    private static TestMethod void APT_GuidedSellingFlowController2() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            Test.StartTest();
            try
            {
                Account acc;
                //system.assert(acc!=null);
                Double test = Double.ValueOf(acc.ID);
            }
            catch(Exception e)
            {
                APT_Utils.getErrorMessage(e);
            }
            
            Test.StopTest();
        }
    }
    /**
        Creating test data
    **/ 
    private static TestMethod void APT_GuidedSellingFlowController3() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            Test.StartTest();
            try
            {
                APT_Utils.getVFPageUrlPrefix();
                Set<String> customerUserTypes = new Set<String> {'PowerPartner'};
                Account acc1 = new Account (
                Name = 'newAcc1'
                );  
                insert acc1;
                Contact conCase = new Contact (
                AccountId = acc1.id,
                LastName = 'portalTestUserv1',Firstname = 'Test',Email = 'Test@abc.com', MailingStreet = 'Test', Phone='1234568790', HomePhone = '12345674890', MobilePhone = '1235467890',OtherPhone ='12345687490'
                );
                insert conCase;
                //Create user
        
                Profile prfile = [select Id,name from Profile where UserType in :customerUserTypes limit 1];
        
                User newUser1 = new User(
                profileId = prfile.id,
                username = 'newUser@yahoo.com',
                email = 'pb@f.com',
                emailencodingkey = 'UTF-8',
                localesidkey = 'en_US',
                languagelocalekey = 'en_US',
                timezonesidkey = 'America/Los_Angeles',
                alias='nuser',
                lastname='lastname',
                contactId = conCase.id
                );
                insert newUser1;  
                
                System.RunAs(newUser1) {
                APT_Utils.getVFPageUrlPrefix();
                APT_Utils.isPartnerUser();
                }
                insert new Lead();
            }
            catch(Exception e)
            {
                APT_Utils.getErrorMessage(e);
            }
            
            Test.StopTest();
            
        }
    }
    /**
        Creating test data
    **/ 
    private static TestMethod void APT_GuidedSellingFlowController4() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            Test.StartTest();
                APT_Utils.submitForApprovals(null, 'Test');
            Test.StopTest();
        }
    }
}