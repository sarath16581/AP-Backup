/**
 * Created by hasantha on 7/01/2019.
 */
@IsTest
private class stp_ConsignmentSearch_Test {

    @testSetup
    static void setup() {
        // Create consignment
        Article__c consignment = new Article__c(
                Last_Update_Type__c = StarTrack_Constants.CON_LASTUP_TYPE,
                Source_System__c = 'TEAM',
                CID__c = '20160405',
                RecordTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId()
        );
        insert consignment;

        // Create article
        Article__c article = new Article__c(
                Last_Update_Type__c = StarTrack_Constants.CON_LASTUP_TYPE,
                Source_System__c = 'TEAM',
                CID__c = '20160405',
                Consignment__c = consignment.Id,
                RecordTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Article').getRecordTypeId()
        );
        insert article;

        //add a POD
        Proof_of_Delivery__c pod = new Proof_of_Delivery__c();
        pod.Consignment__c = consignment.id;
        insert pod;

        // create related event messages
        List < EventMessage__c > messages = TestDataProvider.createEventMessages(2, consignment, 'DD-ER15');

        // create related event messages for article
        messages.addAll(TestDataProvider.createEventMessages(2, article, 'DD-ER15'));
        insert messages;
    }

    /**
     * getPOD : retrieve the PODs related to the consignment
     */
    @IsTest
    static void getPODSuccess() {
        Proof_of_Delivery__c pod = [SELECT id, Consignment__c FROM Proof_of_Delivery__c LIMIT 1];

        // create an attachment for POD
        TestDataProvider.createAndSaveAttachment('att1', pod.Id, Blob.valueOf('body1'));

        // get POD
        list < stp_ConsignmentSearch.ProofOfDeliveryDTO > pods = stp_ConsignmentSearch.getPOD(pod.Consignment__c);

        // expects pods to be returned
        system.assertNotEquals(0, pods.size(), 'stp_ConsignmentSearch_Test.getPODSuccess() : PODs must be returned');
    }

    /**
     * getConsignmentEvents: return the events by consignments, scan events section
     */
    @IsTest
    static void getConsignmentEventsSuccess() {
        // we need a consignment id
        Article__c Consignment = [SELECT id FROM Article__c WHERE RecordTypeId =: Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId() LIMIT 1];
        // call the method to test
        List < EventMessage__c > eventMessages = stp_ConsignmentSearch.getConsignmentEvents(Consignment.Id);

        // expects event messages to be returned
        system.assertNotEquals(0, eventMessages.size(), 'stp_ConsignmentSearch_Test.getConsignmentEventsSuccess() : Events must be returned');
    }


    /**
     * getArticleEvents: scan events section events related to all the articles
     */
    @IsTest
    static void getArticleEventsSuccess() {
        // we need a consignment id
        Article__c Consignment = [SELECT id FROM Article__c WHERE RecordTypeId =: Schema.SObjectType.Article__c.getRecordTypeInfosByName().get('Consignment').getRecordTypeId() LIMIT 1];

        // call the method to test
        List < EventMessage__c > eventMessages = stp_ConsignmentSearch.getArticleEvents(Consignment.Id);

        // expects event messages to be returned
        system.assertNotEquals(0, eventMessages.size(), 'stp_ConsignmentSearch_Test.getArticleEvents() : Events must be returned');
    }

    /**
     * read the field set by fields set name and object name
     */
    @IsTest
    static void readFieldSetSuccess() {

        // call the method to test
        Object fieldset = stp_ConsignmentSearch.readFieldSet('StarTrack_Consignment_Summary', 'Article__c', false);

        // expects event messages to be returned
        system.assertNotEquals(null, fieldset,
                'stp_ConsignmentSearch_Test.getArticleEvents() : Feildset returned cannot be null');

        // call the method to test get standard fieldset
        fieldset = stp_ConsignmentSearch.readFieldSet('StarTrack_Consignment_Summary', 'Article__c', true);

        // expects event messages to be returned
        system.assertNotEquals(null, fieldset,
                'stp_ConsignmentSearch_Test.getArticleEvents() : Feildset returned cannot be null');
    }




}