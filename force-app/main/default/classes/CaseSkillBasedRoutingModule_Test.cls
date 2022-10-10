/***
 * @author Noel Lim
 * @date 2022-09-23
 * @group Domain
 * @domain Routing 
 * @description Test class for CaseSkillBasedRoutingModule
 * @changelog
 * 2022-09-23 - Noel Lim - Created
 */
@IsTest
private class CaseSkillBasedRoutingModule_Test {
    /*
    * Check that the Case field values are updated based on Account field values
    * Check that Case fields values are updated only when the Case Account changes
    */
    @IsTest
    static void checkCaseSLABasedOnAccount() { 
        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


        //Generate Accounts with different SLA values
        List<Account> accounts = ApplicationTestDataFactory.getAccounts(3, true);

        Account accountNoServiceSLA = accounts[0];
        accountNoServiceSLA.ServiceSLA__c = null;

        Account accountWithServiceSLASMB = accounts[1];
        accountWithServiceSLASMB.ServiceSLA__c = 'SMB';

        Account accountWithServiceSLAGold = accounts[2];
        accountWithServiceSLAGold.ServiceSLA__c = 'Gold';

        //Generate Cases with Account data
        List<Case> cases = ApplicationTestDataFactory.getCases(6, true);        

        Case c1 = cases[0]; 
        c1.AccountId = null; 
        
        Case c2 = cases[1];
        c2.AccountId = accountNoServiceSLA.Id; 
        
        Case c3 = cases[2];
        c3.AccountId = accountWithServiceSLASMB.Id; 
        
        Case c4 = cases[3];
        c4.AccountId = accountWithServiceSLAGold.Id; 
        
        Case c5 = cases[4];
        c5.AccountId = accountWithServiceSLASMB.Id; 

        Case c6 = null;

        Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
        if(ssswRecTypes.size()>0){
            Id recTypeId = ssswRecTypes.iterator().next(); 
            c1.recordTypeId = recTypeId;
            c2.recordTypeId = recTypeId;
            c3.recordTypeId = recTypeId;
            c4.recordTypeId = recTypeId;
            c5.recordTypeId = recTypeId;
        }

        List<Case> casesInsert = new List<Case>();
        casesInsert.add(c1);
        casesInsert.add(c2);
        casesInsert.add(c3);

        
        Set<Id> nonSSSWRecTypes = Utility.searchRecordTypes(String.valueOf(Case.getsObjectType()),'StarTrack','DeveloperName');
        if(nonSSSWRecTypes.size()>0){ //Case with non-SSSW recordtype
            c6 = cases[5];
            c6.RecordTypeId = nonSSSWRecTypes.iterator().next(); 
            casesInsert.add(c6);
        }


        //Clone to simulate existing Case records to test Case Update 
        List<Case> oldCases = new List<Case>{
            cases[0].clone(true),
            cases[1].clone(true),
            cases[2].clone(true),
            cases[3].clone(true),
            cases[4].clone(true) 
        };

        oldCases[0].AccountId = accountWithServiceSLASMB.Id; //Account change: blanked
        oldCases[1].AccountId = accountWithServiceSLASMB.Id; //Account change: With SLA > No SLA
        oldCases[2].AccountId = accountNoServiceSLA.Id; //Account change: No SLA > With SLA
        oldCases[3].AccountId = accountNoServiceSLA.Id; //Account change: With SLA > With different SLA
        oldCases[4].AccountId = accountWithServiceSLASMB.Id; //Account NOT changed


        // =====================================
        // Stubbing
        // =====================================
        

        AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>(accounts));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        CaseSkillBasedRoutingModule module = CaseSkillBasedRoutingModule.newInstance();

        module.onBeforeInsert((List<SObject>) casesInsert, mockUow);
        module.onBeforeUpdate((List<SObject>) cases, new Map<Id, SObject>(oldCases), mockUow);

        Test.stopTest();

        //Asserts for Insert  
        System.assertEquals(CaseSkillBasedRoutingModule.SERVICESLA_CONSUMER, c1.CustomerQueueType__c, 'The expected CustomerQueueType for Cases without an Account is incorrect');
        System.assertEquals(CaseSkillBasedRoutingModule.SERVICESLA_CONSUMER, c2.CustomerQueueType__c, 'The expected CustomerQueueType for Cases with an Account without ServiceSLA is incorrect');
        System.assertEquals('SMB', c3.CustomerQueueType__c, 'The expected CustomerQueueType for Cases with an Account with ServiceSLA is incorrect');
        if(c6 != null){
            System.assertEquals(null, c6.CustomerQueueType__c, 'The expected CustomerQueueType for non-SSSW Cases is incorrect');
        }

        //Asserts for Update        
        System.assertEquals('Consumer',c1.CustomerQueueType__c,  'The expected CustomerQueueType for Cases without an Account is incorrect');
        System.assertEquals('Consumer',c2.CustomerQueueType__c, 'The expected CustomerQueueType for Cases with an Account without ServiceSLA is incorrect');
        System.assertEquals('SMB',c3.CustomerQueueType__c, 'The expected CustomerQueueType for Cases updated to an Account with ServiceSLA is incorrect');
        System.assertEquals('Gold',c4.CustomerQueueType__c,'The expected CustomerQueueType for Cases updated to an Account with different ServiceSLA is incorrect');
        System.assertEquals(null,c5.CustomerQueueType__c, 'Cases where AccountId does not change should have no change to its CustomerQueueType');

    }      


    @isTest
	static void testExceptionHandling(){

        // =====================================
        // Data Preparation
        // =====================================
        LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;

        // =====================================
        // Stubbing
        // =====================================
        ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

         // =====================================
        // Testing
        // =====================================
		Test.startTest();

		CaseSkillBasedRoutingModule module = CaseSkillBasedRoutingModule.newInstance();
		module.onBeforeInsert(null,null);
        module.onBeforeUpdate(null,null,null);

		Test.stopTest();

		//An exception should be created when thre are invalid parameters in the onBeforeInsert and onBeforeUpdate
        ((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 2)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
        
        // PMD warning
		System.assert(true);
	}

}