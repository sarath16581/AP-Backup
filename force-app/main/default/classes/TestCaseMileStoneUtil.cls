@isTest
private class TestCaseMileStoneUtil {
    //No more Needed as all methods in CaseMileStoneUtil is commented
    // @testSetup static void testDataCreate() {
    //     Group g1 = new Group(Name='SSSW Child Cases', type='Queue');
    //     insert g1;
    //     QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
    //     insert q1;
    // }

    // static testMethod void MethodTestChunk1() {
    //     Id rtId ;
    //     for(Id ssswid : Utility.getRecordTypeIds('Case', 'SSSW')) {
    //         rtId = ssswid;
    //         break;
    //     }

    //     buildCaseEntitlement();

    //     Group g1 = [Select Id, Name from Group where Type = 'Queue' AND Name='SSSW Child Cases' limit 1];
    //     QueueSObject q1 = [select QueueId from QueueSObject where QueueId =: g1.id];

    //     Network__c network = new Network__c(Name='test', Email_1__c='test@test.com');
    //     insert network;

    //     Id contactId = createTestContact().Id;

    //     map<Id, Case> map_newCase = new map<Id, Case>();
    //     map<Id, Case> map_oldCase = new map<Id, Case>();

    //     TestDataProvider.preventTrigger = true;

    //     Case c1 = buildCase('Email', rtId, network.Id, contactId, 'In Progress,Awaiting Information', q1.QueueId, null);
    //     map_oldCase.put(c1.Id, c1);

    //     Case c1_new = c1.clone(true, true);
    //     c1_new.Facility_Milestones_Violated__c = 2;
    //     map_newCase.put(c1_new.Id, c1_new);

    //     Case c2 = buildCase('SMS', rtId, network.Id, contactId, 'Awaiting Network Response', g1.Id, c1.Id);
    //     map_oldCase.put(c2.Id, c2);

    //     Case c2_new = c2.clone(true, true);
    //     c2_new.Customer_Milestones_Violated__c = 2;
    //     map_newCase.put(c2_new.Id, c2_new);
            
    //     List<Case> newCases = map_newCase.values();

    //     Test.startTest();
    //     map_newCase.remove(c1.Id);
    //     CaseChildQueueManagement.updateParentCase(map_newCase);

    //     Test.stopTest();
    //     System.assertEquals(True, c2_new.Bypass_Data_enforcement__c);
    //     System.assertEquals('test@test.com', c1_new.Facility_Tier_Escalation_Email__c);
    // } 

    // static testMethod void MethodTestChunk2() {
    //     Id rtId ;
    //     for(Id ssswid : Utility.getRecordTypeIds('Case', 'SSSW')) {
    //     rtId = ssswid;
    //     break;
    //     }

    //     buildCaseEntitlement();

    //     Group g1 = [Select Id, Name from Group where Type = 'Queue'  AND Name='SSSW Child Cases' limit 1];
    //     QueueSObject q1 = [select QueueId from QueueSObject where QueueId =: g1.id];

    //     Network__c network = new Network__c(Name='test', Email_1__c='test@test.com');
    //     insert network;

    //     Id contactId = createTestContact().Id;

    //     map<Id, Case> map_newCase = new map<Id, Case>();
    //     map<Id, Case> map_oldCase = new map<Id, Case>();

    //     TestDataProvider.preventTrigger = true;

            
    //     Case c3 = buildCase(null, rtId, network.Id, contactId, 'Awaiting Customer Response', q1.queueId, null);  
    //     map_oldCase.put(c3.Id, c3);

    //     Case c3_new = c3.clone(true, true);
    //     c3_new.Internal_Milestones_Violated__c = 2;
    //     map_newCase.put(c3_new.Id, c3_new);

    //     Case c4 = c3.clone(true, true);
    //     c4.Internal_Milestones_Violated__c = null;

    //     List<Case> newCases = map_newCase.values();
    //     newCases.add(c4);

    //     Test.startTest();
            
    //     Test.stopTest();
    //     // System.assertEquals(True, c4.Bypass_Data_enforcement__c);
    //     // System.assertEquals('test@test.com', c3_new.Facility_Tier_Escalation_Email__c);
    // } 

    // public static Case buildCase(String pcm, id rtid, id networkId, id contactId, string status, Id queueId, Id parentId) {
    //     Case c = new Case();
    //     c.Status = status;
    //     c.OwnerId = queueId;
    //     c.ParentId = parentId;
    //     c.AllocateToQueue__c = true;
    //     c.Subject = 'test subject';
    //     c.Description = 'test description';
    //     c.Type = 'Fax';
    //     c.RecordTypeId = rtid;
    //     c.Network__c = networkId;
    //     c.Preferred_Communication_Method__c = pcm;
    //     c.Facility_Milestones_Violated__c = 1;
    //     c.Customer_Milestones_Violated__c = 1;
    //     c.Internal_Milestones_Violated__c = 1;
    //     c.ContactId = contactId;
    //     insert c;
    //     return c;
    // }

    // public static void buildCaseEntitlement() {
    // // Requires population, used in CaseTrigger
    //     list<Case_Entitlement_Status__c> list_ces = [SELECT Id 
    //                             FROM Case_Entitlement_Status__c 
    //                             WHERE Internal__c='In Progress,Awaiting Information'
    //                             OR Facility__c='Awaiting Facility Response'
    //                             OR Customer__c='Awaiting Customer Response'];
    //     if(list_ces != null && list_ces.size() == 0) {
    //         Case_Entitlement_Status__c ces = new Case_Entitlement_Status__c(name='test',
    //                                         Internal__c='In Progress,Awaiting Information',
    //                                         Facility__c='Awaiting Facility Response',
    //                                         Customer__c='Awaiting Customer Response');
    //         insert ces;
    //     }
    // }

    // public static Contact createTestContact() {
    //     Contact con = new Contact(); 
    //     con.LastName = 'dsf';
    //     con.Function_Group__c = 'Accountant';
    //     con.MailingCity = 'de';
    //     con.MailingState = '1';
    //     con.MailingStreet = '21';
    //     con.MailingPostalCode = '32';
    //     con.Email = 'dsf@df.com';
    //     con.FirstName = 's';
    //     insert con;
    //     return con;
    // }  
}