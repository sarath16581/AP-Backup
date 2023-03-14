/**************************************************
Type:       Test class for SSSW_Routing
History:
--------------------------------------------------
2018-07-20  nathan.franklin@auspost.com.au  Updates to test class
2019-01-14  swati.mogadala@auspost.com.au Changed queue name from Click & Send to Consumer Back Office Disputed Del
2020-10-04  naseer.abbasi@auspost.com.au    Addded test class to assert case queue assignment for strategic support customers cases
2020-11-18 - Ranjeewa Silva - Added test case to verify field value matching.
2021-06-30  steve.judd6@auspost.com.au Added test class for Extra Cover to test sending to SSSW Extra Cover queue
2023-02-16	Noel Lim -	Update method createTestData to remove old queues being decommissioned
						Update method testRoutingRaw to transform old queues transforming to Omni queues
						Moved method testSortingController to new class SSSWSortingController_Test

**************************************************/
@isTest
public with sharing class SSSW_Routing_Sorting_Test {
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
    private static final String BACK_OFC_QUEUE = 'SSSW_BOH_Group_2';
    private static final String HLC_QUEUE = 'SSSW_High_Level_Complaints';
    private static final String CR_QUEUE = 'SSSW_Customer_Recovery';

    @testSetup
    private static void createTestData() {
        List<String> groupNames = new List<String>{
            'SSSW High Level Complaints',
            'SSSW Customer Recovery',
            'SSSW Snap It Inbound',
            'SSSW Snap It Back Office',
            'SSSW MyPost Business Inbound',
            'SSSW MyPost Business Back Office',
            'SSSW Damages Back Office',
            'SSSW Load & Go',
            'SSSW MyPost',
            'SSSW Consumer Back Office Disputed Del',
            'SSSW PBD Inbound Orders queue',
            'SSSW MyPost Digital Mailbox',
            'SSSW Shopmate',
            'SSSW Enterprise Inbound',
            'SSSW Business Inbound',
            'SSSW International Inbound Std Track',
            'SSSW International Inbound',
            'SSSW International ECI Back Office',
            'SSSW International Back Office',
            'SSSW Unaddressed Mail Inbound',
            'SSSW Unaddressed Mail Back Office',
            'SSSW Enterprise Back Office',
            'SSSW Business Back Office',
            'SSSW Consumer Inbound',
            'SSSW Consumer Back Office Spec Del',
            'SSSW Consumer Back Office Delivery Compl',
            'SSSW Consumer Back Office Premium',
            'SSSW Consumer Back Office Standard',
            'SSSW Consumer Back Office Fin & Trav',
            'SSSW Consumer Back Office Other',
            'SSSW Extra Cover',
			'SSSW Consumer Back Office High Priority'
        };

        Profile adminProf = [select Id from Profile where Name = 'System Administrator'];

        // use runAs to bypass the DML with Group limitations
        System.runAs(TestUtility.createUser('Admin',adminProf.id,null)) {

            //Create the related Groups
            List<Group> groupsToAdd = new List<Group>();
            for (String gn : groupNames) {
                groupsToAdd.add(new Group(Name = gn, Type = 'Queue'));
            }
            insert groupsToAdd;

            //Create the related queues
            List<QueueSobject> queuesToAdd = new List<QueueSobject>();
            for (Group g : groupsToAdd) {
                queuesToAdd.add(new QueueSobject(QueueID = g.id, SobjectType = 'Case'));
            }
            insert queuesToAdd;
        }
    }

    private static void CreateRoutingRulesForRaw()
    {	
        //Grab all the groups
        List<Group> groups = new List<Group>([Select Id, Name from Group where Type = 'Queue']);
        Map<Id,String> groupIdToName = new Map<Id,String>();
        for(Group g : groups) {
            groupIdToName.put(g.Id,g.Name);
        }

        //Grab all the queues and map them from QueueID to Name
        List<QueueSobject> queues = new List<QueueSobject>([select QueueId from QueueSobject where QueueId in: groups]);
        Map<String,Id> nameToQId = new Map<String,Id>();
        for(QueueSobject q : queues) {
            if (!nameToQId.containsKey(groupIdToName.get(q.QueueId))) {
                nameToQId.put(groupIdToName.get(q.QueueId), q.QueueId);
            }
        }

        //Routing rule for HLC
        List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();
        SSSWRouting__c routingRule = TestUtility.createSSSWRouting(null,null,null,null,null,'High Level Complaint','All',SSSWConstants.RECTYPEROUTING);
        routingRule.High_Level_Complaint_Flag__c = true;
        routingRule.IsActive__c = True;
        routingRule.Queue_ID__c = nameToQId.get('SSSW High Level Complaints');
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);

        //Routing rule for CR
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Unauthorised Hold/Redirection application',null,null,'Any',SSSWConstants.RECTYPEROUTING);
        routingRule.Customer_Recovery_Flag__c = true;
        routingRule.IsActive__c = True;
        routingRule.Queue_ID__c = nameToQId.get('SSSW Customer Recovery');
        routingRule.Sequence__c = 2;
        routesToInsert.add(routingRule);

        //Routing rule for Prod Cat, Sub Cat, Enq type, sub Type
        routingRule = TestUtility.createSSSWRouting('International Letters','eParcel- Express','General Enquiry','Item transfer',null,null,'ALL',SSSWConstants.RECTYPEROUTING);
        routingRule.IsActive__c = True;
        routingRule.Queue_ID__c = nameToQId.get('SSSW International Inbound');
        routingRule.Sequence__c = 3;
        routesToInsert.add(routingRule);

        //Routing rule for cust type Consumer
        routingRule = TestUtility.createSSSWRouting(null,'Mail redirection',null,null,'Consumer','Internal form','ALL',SSSWConstants.RECTYPEROUTING);
        routingRule.IsActive__c = True;
        routingRule.Queue_ID__c = nameToQId.get('SSSW Consumer Back Office High Priority');
        routingRule.Sequence__c = 4;
        routesToInsert.add(routingRule);

        //Routing rule for Any NPS
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Staff Complaint',null,null,'Any',SSSWConstants.RECTYPENPS);
        routingRule.IsActive__c = True;
        routingRule.NPS_criteria__c = 'Include';
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);

        //Routing rule for All NPS
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Damage to property',null,'Direct Email','All',SSSWConstants.RECTYPENPS);
        routingRule.IsActive__c = True;
        routingRule.NPS_criteria__c = 'Exclude';
        routingRule.Sequence__c = 2;
        routesToInsert.add(routingRule);

        //Routing rule for Any Escalation
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Staff Complaint',null,null,'Any',SSSWConstants.RECTYPEESCALATION);
        routingRule.IsActive__c = True;
        routingRule.AutoEscalate__c = true;
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);

        //Routing rule for All Escalation
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Damage to property',null,'Direct Email','All',SSSWConstants.RECTYPEESCALATION);
        routingRule.IsActive__c = True;
        routingRule.AutoEscalate__c = true;
        routingRule.Sequence__c = 2;
        routesToInsert.add(routingRule);

        //Routing Rule for All Description
        routingRule = TestUtility.createSSSWRouting(null,null,null,null,null,'High Level Complaint','All',SSSWConstants.RECTYPEDESCRIPTION);
        routingRule.High_Level_Complaint_Flag__c = true;
        routingRule.IsActive__c = True;
        routingRule.DefaultCaseDetails__c = 'Testing All Description';
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);

        //Routing Rule for All Description
        routingRule = TestUtility.createSSSWRouting(null,null,null,'Unauthorised Hold/Redirection application',null,null,'Any',SSSWConstants.RECTYPEDESCRIPTION);
        routingRule.Customer_Recovery_Flag__c = true;
        routingRule.IsActive__c = True;
        routingRule.DefaultCaseDetails__c = 'Testing Any Description';
        routingRule.Sequence__c = 2;
        routesToInsert.add(routingRule);

        Database.insert(routesToInsert,false);
    }
	
    @isTest
    private static void testRoutingRaw() {
        CreateRoutingRulesForRaw();
        
        List<SSSWRouting__c> routingRules = new List<SSSWRouting__c>();
        routingRules = [Select Id, RecordType.Name, Sequence__c, Origin__c, High_Level_Complaint_Flag__c , EnquirySubType__c, Customer_Recovery_Flag__c, CaseType__c,
                            Customer_Type__c, CustomerQueueType__c, ProductCategory__c, ProductSubCategory__c, Queue_ID__c, Status__c, IsNew__c, IsStrategic__c from SSSWRouting__c];
        System.debug('routingRules--->'+routingRules);

        //Grab all the groups
        List<Group> groups = new List<Group>([Select Id, Name from Group where Type = 'Queue']);
        Map<Id,String> groupIdToName = new Map<Id,String>();
        for(Group g : groups) {
            groupIdToName.put(g.Id,g.Name);
        }

        //Grab all the queues and map them from QueueID to Name
        List<QueueSobject> queues = new List<QueueSobject>([select QueueId from QueueSobject where QueueId in: groups]);
        Map<String,Id> nameToQId = new Map<String,Id>();
        for(QueueSobject q : queues) {
            if (!nameToQId.containsKey(groupIdToName.get(q.QueueId))) {
                nameToQId.put(groupIdToName.get(q.QueueId), q.QueueId);
            }
        }

        //Assign the QueueID to each routing rule and create a case with the same criteria
        //Create the relevant case
        RecordType consumerRType = [select Id from RecordType where sObjectType = 'Account' and RecordType.DeveloperName = 'PersonAccount' limit 1];
        RecordType businessRType = [select Id from RecordType where sObjectType = 'Account' and RecordType.DeveloperName = 'Business_Account' limit 1];

        //Customer_Type__c is a formula field that looks up to Account SLA, so we have to build the accounts with their SLAs before the cases
        Set<Account> accsToCreate = new Set<Account>();
        for(SSSWRouting__c rrs : routingRules) {
            if (rrs.Customer_Type__c != null && rrs.Customer_Type__c != 'Consumer'){
                Account acc = TestUtility.createBusinessAccount('testAccount',businessRType.Id);
                acc.ServiceSLA__c = rrs.Customer_Type__c;
                accsToCreate.add(acc);
            } else {
                Account acc = TestUtility.createPersonAccount('testAccount',consumerRType.Id);
                acc.Firstname = 'Test';
                acc.PersonEmail = 'test@example.com';
                accsToCreate.add(acc);
            }
        }
        List<Account> accsToInsert = new List<Account>();
        accsToInsert.addAll(accsToCreate);
        insert accsToInsert;
        //Create a map of slas to account Ids so we can match a suitable account (with correct SLA) to each case for testing.
        Map<String, Id> slaNameToAccid = new Map<String,Id>();
        for(Account accs : accsToCreate) {
            if(!slaNameToAccid.containsKey(accs.ServiceSLA__c)) {
                slaNameToAccid.put(accs.ServiceSLA__c,accs.Id);
            }
        }

        RecordType caseRecordType = [select id from RecordType where sObjectType = 'Case' and name like 'SSSW%' limit 1];

        List<Case> casesToInsert = new List<Case>();
        for(SSSWRouting__c rrs : routingRules) {
            //rrs.Queue_ID__c = nameToQId.get(rrs.Test_Queue_Name__c);

            Case c = new Case();
            c.IsNewForRouting__c = true;
            c.AccountId = slaNameToAccid.get(rrs.Customer_Type__c);
            c.RecordTypeId = caseRecordType.Id;
            c.Origin = rrs.Origin__c;
            c.IsHLC__c = rrs.High_Level_Complaint_Flag__c;
            c.EnquirySubType__c = rrs.EnquirySubType__c;
            c.IsCR__c = rrs.Customer_Recovery_Flag__c;
            c.Type = rrs.CaseType__c != null ? rrs.CaseType__c : 'Feedback';
            c.ProductCategory__c = rrs.ProductCategory__c;
            c.ProductSubCategory__c = rrs.ProductSubCategory__c;
            c.CustomerQueueType__c = rrs.CustomerQueueType__c;
            c.Description = rrs.RecordType.Name == SSSWConstants.RECTYPEROUTING ? 'Test' : 'Description Test';
            c.AllocateToQueue__c = True;
            if('New'.equals(rrs.Status__c)) {
                c.Status = rrs.Status__c;
            }
            casesToInsert.add(c);
        }

        update routingRules;

        //Debugging
        routingRules = [select Id, RecordType.Name, Sequence__c, Status__c, Origin__c, High_Level_Complaint_Flag__c , EnquirySubType__c, Customer_Recovery_Flag__c, CaseType__c,
                Customer_Type__c, CustomerQueueType__c, ProductCategory__c, ProductSubCategory__c, Queue_ID__c, IsStrategic__c from SSSWRouting__c];
        system.debug('routing rules after:>> '+routingRules);
        //TODO: assert the routing rules have assigned the cases appropriately.
        insert casesToInsert;
        List<Case> casesRouted = new List<Case>([Select Id, AccountId, RecordTypeId, Origin, IsHLC__c, EnquirySubType__c, IsCR__c, Type,
                Description, ProductCategory__c, ProductSubCategory__c, CustomerQueueType__c, Customer_Type__c, OwnerId, Status, IsNew__c, ReferenceID__c, ArticleTest__c from Case]);

        //SSSW_Routing.assignCases(casesRouted);
        for(Case cs : casesRouted){
            if(cs.IsHLC__c && cs.Description == 'Test'){
                System.debug('HLC caseOwner---->'+cs.ownerId);
                System.debug('nameToQId.get(\'SSSW High Level Complaints\')--->'+nameToQId.get('SSSW High Level Complaints'));
                System.assertEquals(nameToQId.get('SSSW High Level Complaints'), cs.ownerId, 'Expected SSSW High Level Complaints');
                //System.assertEquals('Test\nTesting All Description',cs.Description);
            }
            if(cs.IsCR__c){
                System.debug('CR caseOwner---->'+cs.ownerId);
                System.debug('nameToQId.get(\'SSSW Customer Recovery\')--->'+nameToQId.get('SSSW Customer Recovery'));
                System.assertEquals(nameToQId.get('SSSW Customer Recovery'), cs.ownerId, 'Expected SSSW Customer Recovery');
                //System.assertEquals('Test\nTesting Any Description',cs.Description);
            }
            if(cs.CustomerQueueType__c == 'Consumer' && cs.Origin == 'Internal form'){
                System.debug('Consumer caseOwner---->'+cs.ownerId);
                System.debug('nameToQId.get(\'SSSW Consumer Back Office High Priority\')--->'+nameToQId.get('SSSW Consumer Back Office High Priority'));
                System.assertEquals(nameToQId.get('SSSW Consumer Back Office High Priority'), cs.ownerId, 'Expected SSSW Consumer Back Office High Priority');
            }
            if(cs.ProductCategory__c == 'International Letters'){
                System.debug('International caseOwner---->'+cs.ownerId);
                System.debug('nameToQId.get(\'SSSW International Inbound\')--->'+nameToQId.get('SSSW International Inbound'));
                System.assertEquals(nameToQId.get('SSSW International Inbound'), cs.ownerId, 'Expected SSSW International Inbound');
            }
            if(cs.EnquirySubType__c == 'Staff Complaint' || cs.EnquirySubType__c == 'Damage to property'){
                Boolean b1 = SSSW_Routing.checkAutoEscalate(cs);
                //System.assertEquals(True, b1);
            }
        }
    }
	
    @isTest
    private static void testMultiSelectAll()
    {
        //Grab all the groups
        List<Group> groups = new List<Group>([Select Id, Name from Group where Type = 'Queue']);
        Map<Id,String> groupIdToName = new Map<Id,String>();
        for(Group g : groups) {
            groupIdToName.put(g.Id,g.Name);
        }

        //Grab all the queues and map them from QueueID to Name
        List<QueueSobject> queues = new List<QueueSobject>([select QueueId from QueueSobject where QueueId in: groups]);
        Map<String,Id> nameToQId = new Map<String,Id>();
        for(QueueSobject q : queues) {
            if (!nameToQId.containsKey(groupIdToName.get(q.QueueId))) {
                nameToQId.put(groupIdToName.get(q.QueueId), q.QueueId);
            }
        }

        RecordType caseRecordType = [select id, name from RecordType where sObjectType = 'Case' and name like 'SSSW%' limit 1];

        system.debug('recordType test multiselect::: '+caseRecordType.name);
        List<String> productValues = new List<String>{'product001', 'product002', 'product003'};

        //Routing rule with
        List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();
        SSSWRouting__c routingRule = TestUtility.createSSSWRouting(null,null,null,null,null,'High Level Complaint','All',SSSWConstants.RECTYPEROUTING);
        routingRule.ProductCategory__c = String.join(productValues, SSSWRoutingController.MULTI_SELECT_DELIM);
        routingRule.High_Level_Complaint_Flag__c = true;
        routingRule.CaseType__c = 'Feedback';
        routingRule.IsActive__c = true;
        routingRule.Queue_ID__c = nameToQId.get('SSSW High Level Complaints');
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);

        insert routesToInsert;
        system.debug('routestoInsert::: '+routesToInsert);


        Test.startTest();
        List<Case> testCases = new List<Case>();
        // create a fail case
        Case caseFail = new Case();
        caseFail.IsNewForRouting__c = true;
        caseFail.AllocateToQueue__c = true;
        caseFail.RecordtypeId = caseRecordType.Id;
        caseFail.Origin = routingRule.Origin__c;
        caseFail.IsHLC__c = true;
        caseFail.Type = routingRule.CaseType__c != null ? routingRule.CaseType__c : 'Feedback';
        caseFail.ProductCategory__c = 'Something else';
        caseFail.Description = 'fail test';
        testCases.add(caseFail);

        // create a pass case
        Case casePass = new Case();
        casePass.IsNewForRouting__c = true;
        casePass.RecordtypeId = caseRecordType.Id;
        casePass.AllocateToQueue__c = true;
        casePass.Origin = routingRule.Origin__c;
        casePass.IsHLC__c = true;
        casePass.Type = routingRule.CaseType__c != null ? routingRule.CaseType__c : 'Feedback';
        casePass.ProductCategory__c = productValues[0];
        casePass.Description = 'pass test';
        testCases.add(casePass);

        Case caseIgnoreCheck = new Case();
        caseIgnoreCheck.IsNewForRouting__c = false;
        caseIgnoreCheck.RecordtypeId = caseRecordType.Id;
        caseIgnoreCheck.AllocateToQueue__c = true;
        caseIgnoreCheck.Origin = routingRule.Origin__c;
        caseIgnoreCheck.IsHLC__c = true;
        caseIgnoreCheck.Type = routingRule.CaseType__c != null ? routingRule.CaseType__c : 'Feedback';
        caseIgnoreCheck.ProductCategory__c = productValues[0];
        caseIgnoreCheck.Description = 'pass ignore checkbox';
        testCases.add(caseIgnoreCheck);
        insert testCases;

        Test.stopTest();
        System.debug('!@#$ test cases = ' + testCases);

        // validate results
        List<Case> results = [
                SELECT Id, OwnerId, Description
                FROM Case
        ];
        for(Case result:results)
        {
            String description = result.Description;
            if(description == caseFail.Description)
            {
                System.assertNotEquals(nameToQId.get('SSSW High Level Complaints'), result.ownerId, 'Expected something else');
            }else if(description == casePass.Description || description == caseIgnoreCheck.Description)
            {
                System.assertEquals(nameToQId.get('SSSW High Level Complaints'), result.ownerId, 'Expected to pass the rule');
            }
        }
    }

    @isTest
    private static void testMultiSelectAny()
    {
        //Grab all the groups
        List<Group> groups = new List<Group>([Select Id, Name from Group where Type = 'Queue']);
        Map<Id,String> groupIdToName = new Map<Id,String>();
        for(Group g : groups) {
            groupIdToName.put(g.Id,g.Name);
        }

        //Grab all the queues and map them from QueueID to Name
        List<QueueSobject> queues = new List<QueueSobject>([select QueueId from QueueSobject where QueueId in: groups]);
        Map<String,Id> nameToQId = new Map<String,Id>();
        for(QueueSobject q : queues) {
            if (!nameToQId.containsKey(groupIdToName.get(q.QueueId))) {
                nameToQId.put(groupIdToName.get(q.QueueId), q.QueueId);
            }
        }

        RecordType caseRecordType = [select id from RecordType where sObjectType = 'Case' and name like 'SSSW%' limit 1];

        List<String> productValues = new List<String>{'product001', 'product002', 'product003'};

        //Routing rule with
        List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();
        SSSWRouting__c routingRule = TestUtility.createSSSWRouting(null,null,null,null,null,'High Level Complaint','Any',SSSWConstants.RECTYPEROUTING);
        routingRule.ProductCategory__c = String.join(productValues, SSSWRoutingController.MULTI_SELECT_DELIM);
        routingRule.High_Level_Complaint_Flag__c = true;
        routingRule.IsActive__c = true;
        routingRule.Queue_ID__c = nameToQId.get('SSSW High Level Complaints');
        routingRule.Sequence__c = 1;
        routesToInsert.add(routingRule);
        insert routesToInsert;

        Test.startTest();
        List<Case> testCases = new List<Case>();
        // create a fail case
        Case caseFail = new Case();
        caseFail.IsNewForRouting__c = true;
        caseFail.AllocateToQueue__c = true;
        caseFail.RecordtypeId = caseRecordType.Id;
        //caseFail.Origin = routingRule.Origin__c;
        //caseFail.IsHLC__c = true;
        caseFail.Type = routingRule.CaseType__c != null ? routingRule.CaseType__c : 'Feedback';
        caseFail.ProductCategory__c = 'Something else';
        caseFail.Description = 'fail test';
        testCases.add(caseFail);

        // create a pass case
        Case casePass = new Case();
        casePass.IsNewForRouting__c = true;
        casePass.RecordtypeId = caseRecordType.Id;
        casePass.AllocateToQueue__c = true;
        casePass.Origin = routingRule.Origin__c;
        casePass.IsHLC__c = true;
        casePass.Type = routingRule.CaseType__c != null ? routingRule.CaseType__c : 'Feedback';
        casePass.ProductCategory__c = productValues[2];
        casePass.Description = 'pass test';
        testCases.add(casePass);
        insert testCases;

        System.debug('!@#$ MATCH ANY test cases = ' + testCases);

        // validate results
        List<Case> results = [
                SELECT Id, OwnerId, Description
                FROM Case
        ];
        for(Case result:results)
        {
            String description = result.Description;
            if(description == caseFail.Description)
            {
                System.assertNotEquals(nameToQId.get('SSSW High Level Complaints'), result.ownerId, 'Expected something else');
            }else if(description == casePass.Description)
            {
                System.assertEquals(nameToQId.get('SSSW High Level Complaints'), result.ownerId, 'Expected to pass the rule');
            }
        }

        Test.stopTest();

    }

    /**
     * @description       Validate Case routing for the Strategic customers
     * @param             NA     
     * @return            Void
     * @throws            NA
    */
    private static testMethod void testAStrategicCustomerCase() {
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Account acc;
        Contact con;
        Article__c article;
        Billing_Account__c billAcc;
        Group strategicgroup, nonStrategicgroup;
        QueueSObject strategicQueue, nonStrategicQueue;

        System.runAs(TestUtility.createUser('admin1', adminProf.id, null)){ 
            //strategic customer queue
            strategicgroup = new Group(Name='SSSW Consumer Key Account BO', Type='Queue');
            Insert strategicgroup;

            nonStrategicgroup = new Group(Name='SSSW Admin', Type='Queue');
            Insert nonStrategicgroup;

            strategicQueue = new QueueSObject(QueueID = strategicgroup.id, SObjectType = 'Case');
            Insert strategicQueue;

            nonStrategicQueue = new QueueSObject(QueueID = nonStrategicgroup.id, SObjectType = 'Case');
            Insert nonStrategicQueue;

            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            List<Account> accList = new List<Account>();
            Account tempAcc = TestUtility.createBusinessAccount('Temporary Customer', accRecTypeMap.get('Organisation').getRecordTypeId());
            tempAcc.LEGACY_ID__c = '60000000';
            accList.add(tempAcc);

            acc = TestUtility.createBusinessAccount('Wayne Enterprises', accRecTypeMap.get('Organisation').getRecordTypeId());
            acc.LEGACY_ID__c = '12345';
            accList.add(acc);
            Insert accList;

            acc.Sales_Segment__c = 'Enterprise & Strategic VIC 1'; //makes a strategic customer
            acc.Legacy_Id__c = '60000000';
            upsert acc;
            
            billAcc = TestUtility.createBillingAccount('Bill Acc', acc.Id);
            Insert billAcc;

            con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com', acc.id);
            insert con;
            system.debug('about to insert article... ');
            article = TestUtility.createArticle('12345', 1, 'Bruce', 'Peter', 'Domestic Parcels');
            article.Billing_Account__c = billAcc.Id;
            Insert article;

            SSSWRouting__c strategicRule = TestUtility.createSSSWRouting('Domestic Parcels', 'Express', 'Investigation', null, null, 'Phone', 'All', SSSWConstants.RECTYPEROUTING);
            strategicRule.IsNew__c = true;
            strategicRule.IsActive__c = true;
            strategicRule.Queue_ID__c = strategicgroup.Id;
            strategicRule.IsStrategic__c = true;
            strategicRule.CustomerQueueType__c = 'Consumer';
            strategicRule.Sequence__c = 1;	
            Insert strategicRule;

            SSSWRouting__c nonStrategicRule = TestUtility.createSSSWRouting('Domestic Parcels', 'Express', 'Investigation', null, null, 'Phone', 'All', SSSWConstants.RECTYPEROUTING);
            nonStrategicRule.IsNew__c = true;
            nonStrategicRule.IsActive__c = true;
            nonStrategicRule.Queue_ID__c = nonStrategicgroup.Id;
            nonStrategicRule.CustomerQueueType__c = 'Consumer';
            nonStrategicRule.IsStrategic__c = false;
            nonStrategicRule.Sequence__c = 2;	
            Insert nonStrategicRule;
        }

        System.runAs(TestUtility.createUser('Wayne', prof.id, null)) { 
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
            cases[0].Type = 'Investigation';
            cases[0].AccountId = acc.Id;
            cases[0].ContactId = con.Id;
            cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
            cases[0].Origin = 'Phone';
            cases[0].ProductCategory__c = 'Domestic Parcels';
            cases[0].ProductSubCategory__c = 'Express';
            cases[0].ReferenceId__c = '12345';
            cases[0].Address2__c  = '111 Bourke Street';
            cases[0].IsNewForRouting__c  = true;
            cases[0].AllocateToQueue__c = true;
            
            Test.startTest();
                Insert cases[0];
            Test.stopTest();
        }
        Case cs = [SELECT OwnerId FROM Case LIMIT 1];
        System.assertEquals(strategicgroup.Id, cs.OwnerId);
    }

    
    /**
     * @description       Validate Bulk of Cases routing for the Strategic customers
     * @param             NA     
     * @return            Void
     * @throws            NA
    */
    private static testMethod void testBulkStrategicCustomerCases() {
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Account strategicAccount, nonStrategicAccount;
        Contact contactForSA, contactForNSA;
        Article__c article1, article2;
        Billing_Account__c strategicBillingAccount, nonStrategicBillingAccount;
        Group strategicgroup, nonStrategicgroup;
        QueueSObject strategicQueue, nonStrategicQueue;
        Integer count = 50;

        System.runAs(TestUtility.createUser('admin1', adminProf.id, null)){ 
            //strategic customer queue
            strategicgroup = new Group(Name='SSSW Consumer Key Account BO', Type='Queue');
            Insert strategicgroup;

            nonStrategicgroup = new Group(Name='SSSW Admin', Type='Queue');
            Insert nonStrategicgroup;

            strategicQueue = new QueueSObject(QueueID = strategicgroup.id, SObjectType = 'Case');
            Insert strategicQueue;

            nonStrategicQueue = new QueueSObject(QueueID = nonStrategicgroup.id, SObjectType = 'Case');
            Insert nonStrategicQueue;

            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            List<Account> accList = new List<Account>();
            Account tempAcc = TestUtility.createBusinessAccount('Temporary Customer', accRecTypeMap.get('Organisation').getRecordTypeId());
            tempAcc.LEGACY_ID__c = '60000000';
            accList.add(tempAcc);

            strategicAccount = TestUtility.createBusinessAccount('Wayne Enterprises', accRecTypeMap.get('Organisation').getRecordTypeId());
            strategicAccount.Sales_Segment__c = 'Enterprise & Strategic VIC 1'; //makes a strategic customer
            strategicAccount.LEGACY_ID__c = '123456789';
            accList.add(strategicAccount);

            nonStrategicAccount = TestUtility.createBusinessAccount('Some Enterprises', accRecTypeMap.get('Organisation').getRecordTypeId());
            nonStrategicAccount.LEGACY_ID__c = '987654321';
            nonStrategicAccount.Sales_Segment__c = 'Sales Holding User';
            accList.add(nonStrategicAccount);
            Insert accList;

            strategicAccount.Legacy_Id__c = '60000000';
            nonStrategicAccount.Legacy_Id__c = '60000000';
            update accList;
            
            List<Billing_Account__c> billingAccountList = new List<Billing_Account__c>();
            strategicBillingAccount = TestUtility.createBillingAccount('Bill Acc', strategicAccount.Id);
            billingAccountList.add(strategicBillingAccount);

            nonStrategicBillingAccount = TestUtility.createBillingAccount('Bill Acc2', nonStrategicAccount.Id);
            billingAccountList.add(nonStrategicBillingAccount);
            Insert billingAccountList;

            List<Contact> contactList = new List<Contact>();
            contactForSA = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com', strategicAccount.id);
            contactList.add(contactForSA);
            
            contactForNSA = TestUtility.createContact('Some','Wayne','Some@wayne.com', nonStrategicAccount.id);
            contactList.add(contactForNSA);
            Insert contactList;

            List<Article__c> articleList = new List<Article__c>();
            article1 = TestUtility.createArticle('12345', 1, 'Bruce', 'Peter', 'Domestic Parcels');
            article1.Billing_Account__c = strategicBillingAccount.Id;
            articleList.add(article1);

            article2 = TestUtility.createArticle('54321', 1, 'Some', 'Peter', 'Domestic Parcels');
            article2.Billing_Account__c = nonStrategicBillingAccount.Id;
            articleList.add(article2);
            Insert articleList;

            List<SSSWRouting__c> routingRuleList = new List<SSSWRouting__c>();
            SSSWRouting__c strategicRule = TestUtility.createSSSWRouting('Domestic Parcels', 'Express', 'Investigation', null, null, 'Phone', 'All', SSSWConstants.RECTYPEROUTING);
            strategicRule.IsNew__c = true;
            strategicRule.IsActive__c = true;
            strategicRule.Queue_ID__c = strategicgroup.Id;
            strategicRule.IsStrategic__c = true;
            strategicRule.CustomerQueueType__c = 'Consumer';
            strategicRule.Sequence__c = 1;	
            routingRuleList.add(strategicRule);

            SSSWRouting__c nonStrategicRule = TestUtility.createSSSWRouting('Domestic Parcels', 'Express', 'Investigation', null, null, 'Phone', 'All', SSSWConstants.RECTYPEROUTING);
            nonStrategicRule.IsNew__c = true;
            nonStrategicRule.IsActive__c = true;
            nonStrategicRule.Queue_ID__c = nonStrategicgroup.Id;
            nonStrategicRule.CustomerQueueType__c = 'Consumer';
            nonStrategicRule.IsStrategic__c = false;
            nonStrategicRule.Sequence__c = 2;	
            routingRuleList.add(nonStrategicRule);
            Insert routingRuleList;
        }

        System.runAs(TestUtility.createUser('Wayne', prof.id, null)) { 
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            List<Case> caseList = ApplicationTestDataFactory.getCases(count, false);
            Integer i = 0;
            for(Case c : caseList) {
                c.Type = 'Investigation';
                c.RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
                c.Origin = 'Phone';
                c.ProductCategory__c = 'Domestic Parcels';
                c.ProductSubCategory__c = 'Express';
                c.ReferenceId__c = '12345';
                c.Address2__c  = '111 Bourke Street';
                c.IsNewForRouting__c  = true;
                c.AllocateToQueue__c = true;
                if(i < (count/2)) {
                    c.AccountId = strategicAccount.Id;
                    c.ContactId = contactForSA.Id;
                    c.ReferenceId__c = '12345';
                }else {
                    c.AccountId = nonStrategicAccount.Id;
                    c.ContactId = contactForNSA.Id;
                    c.ReferenceId__c = '54321';
                }
                i++;
            }
            
            Test.startTest();
                Insert caseList;
            Test.stopTest();
        }
        System.assertEquals([SELECT Id FROM Case WHERE OwnerId = :strategicgroup.Id].size(), count/2);
    }

    private static testMethod void testSSSWRoutingRuleValueMatching() {

        System.assertEquals(true, SSSW_Routing.valueMatches('Origin', 'Phone', 'PHONE'), 'Expected successful match using default matcher - exact match with ignore case.');
        System.assertEquals(false, SSSW_Routing.valueMatches('Origin', 'Phone1', 'PHONE'), 'Expected unsuccessful match using default matcher.');

        System.assertEquals(true, SSSW_Routing.valueMatches('SocialPostTags__c', 'post tag1,post tag2', 'POST TAG1'), 'Expected successful match using reg ex matcher - exact phrase specified in rule match one of the phrases in case field.');
        System.assertEquals(false, SSSW_Routing.valueMatches('SocialPostTags__c', 'posttag1,post tag2', 'POST TAG1'), 'Expected unsuccessful using reg ex matcher - phrase specified in rule does not match any phrase in case field.');
        System.assertEquals(false, SSSW_Routing.valueMatches('SocialPostTags__c', 'post tag1', 'post'), 'Expected unsuccessful match using reg ex matcher - rule value does not match the exact phrase in case field value.');
    }

    /**
     * @description       Validate Case routing for the Extra Cover routing rules
     * @param             NA
     * @return            Void
     * @throws            NA
    */
    private static testMethod void testExtraCoverCase() {
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        Profile adminProf = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
        Account acc;
        Contact con;
        Article__c article;
        Billing_Account__c billAcc;
        Group extraCoverGroup, nonExtraCoverGroup;
        QueueSObject extraCoverQueue, nonExtraCoverQueue;

        System.runAs(TestUtility.createUser('admin1', adminProf.id, null)){
            //strategic customer queue
            extraCoverGroup = new Group(Name='SSSW Extra Cover', Type='Queue');
            Insert extraCoverGroup;

            nonExtraCoverGroup = new Group(Name='SSSW Admin', Type='Queue');
            Insert nonExtraCoverGroup;

            extraCoverQueue = new QueueSObject(QueueID = extraCoverGroup.id, SObjectType = 'Case');
            Insert extraCoverQueue;

            nonExtraCoverQueue = new QueueSObject(QueueID = nonExtraCoverGroup.id, SObjectType = 'Case');
            Insert nonExtraCoverQueue;

            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            List<Account> accList = new List<Account>();
            Account tempAcc = TestUtility.createBusinessAccount('Temporary Customer', accRecTypeMap.get('Organisation').getRecordTypeId());
            tempAcc.LEGACY_ID__c = '60000000';
            accList.add(tempAcc);

            acc = TestUtility.createBusinessAccount('Wayne Enterprises', accRecTypeMap.get('Organisation').getRecordTypeId());
            acc.LEGACY_ID__c = '12345';
            accList.add(acc);
            Insert accList;

            //acc.Sales_Segment__c = 'Enterprise & Strategic VIC 1'; //makes a strategic customer
            acc.Segment__c = 'Consumer';
            acc.Legacy_Id__c = '60000000';
            upsert acc;

            billAcc = TestUtility.createBillingAccount('Bill Acc', tempAcc.Id);
            Insert billAcc;

            con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com', tempAcc.id);
            insert con;
            system.debug('about to insert article... ');
            article = TestUtility.createArticle('12345', 1, 'Bruce', 'Peter', 'Domestic Parcels');
            article.Billing_Account__c = billAcc.Id;
            // Extra cover is  indicated by an amount > 0 and Blank merchant location id.
            article.InsuranceAmount__c = 200;
            Insert article;

            SSSWRouting__c extraCoverRule = TestUtility.createSSSWRouting('Domestic Parcels', 'Express', 'Investigation', null, null, 'Phone', 'All', SSSWConstants.RECTYPEROUTING);
            extraCoverRule.IsNew__c = true;
            extraCoverRule.IsActive__c = true;
            extraCoverRule.Queue_ID__c = extraCoverGroup.Id;
            extraCoverRule.HasExtraCover__c = true;
            extraCoverRule.CustomerQueueType__c = 'Consumer';
            extraCoverRule.Sequence__c = 1;
            Insert extraCoverRule;

            SSSWRouting__c nonExtraCoverRule = TestUtility.createSSSWRouting('Domestic Parcels', 'Express', 'Investigation', null, null, 'Phone', 'All', SSSWConstants.RECTYPEROUTING);
            nonExtraCoverRule.IsNew__c = true;
            nonExtraCoverRule.IsActive__c = true;
            nonExtraCoverRule.Queue_ID__c = nonExtraCoverGroup.Id;
            nonExtraCoverRule.CustomerQueueType__c = 'Consumer';
            nonExtraCoverRule.HasExtraCover__c = false;
            nonExtraCoverRule.Sequence__c = 2;
            Insert nonExtraCoverRule;
        }

        System.runAs(TestUtility.createUser('Wayne', prof.id, null)) {
            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            List<Case> cases = ApplicationTestDataFactory.getCases(3, false);
            cases[0].Type = 'Investigation';
            cases[0].AccountId = acc.Id;
            cases[0].ContactId = con.Id;
            cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
            cases[0].Origin = 'Phone';
            cases[0].ProductCategory__c = 'Domestic Parcels';
            cases[0].ProductSubCategory__c = 'Express';
            cases[0].ReferenceId__c = '12345';
            cases[0].Address2__c  = '111 Bourke Street';
            cases[0].IsNewForRouting__c  = true;
            cases[0].AllocateToQueue__c = true;

            cases[1].Type = 'Investigation';
            cases[1].AccountId = acc.Id;
            cases[1].ContactId = con.Id;
            cases[1].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
            cases[1].Origin = 'Phone';
            cases[1].ProductCategory__c = 'Domestic Parcels';
            cases[1].ProductSubCategory__c = 'Express';
            cases[1].ReferenceId__c = '12345';
            cases[1].Address2__c  = '111 Bourke Street';
            cases[1].IsNewForRouting__c  = true;
            cases[1].AllocateToQueue__c = true;


            cases[2].Type = 'Feedback'; //should not go to extra cover queue
            cases[2].AccountId = acc.Id;
            cases[2].ContactId = con.Id;
            cases[2].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
            cases[2].Origin = 'Phone';
            cases[2].ProductCategory__c = 'Domestic Parcels';
            cases[2].ProductSubCategory__c = 'Express';
            cases[2].ReferenceId__c = '12345';
            cases[2].Address2__c  = '111 Bourke Street';
            cases[2].IsNewForRouting__c  = true;
            cases[2].AllocateToQueue__c = true;

            Test.startTest();
            Insert cases;
            Test.stopTest();
        }
        List<Case> csList = [SELECT OwnerId FROM Case WHERE OwnerId =:extraCoverGroup.Id];
        System.assertEquals(csList.size(), 2);
    }

}