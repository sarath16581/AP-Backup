/**************************************************************************************
Description:    Test class to cover CreateChildCaseController functionality
History:
---------------------------------------------------------------------------------------
18/12/2018  Rahul Kapoor  Created
***************************************************************************************/
@IsTest
public class CreateChildCaseControllerTest {

    /*********************************************************************************
    *  Scenario:
    *      Setup method to create test data.
    **********************************************************************************/
    @testSetup
    static void setup() {
        //Fetch the profile.
        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        //Create a user.
        User testUser = new User(Alias = 'testusr', Email='testusr@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = stdUserProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='testusr@testorg.com', Work_Center_Code__c='123456');

        insert testUser;
        //Get Account Record Type
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        //Insert Account
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);
        //Insert Contact
        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        con.MailingState = 'Vic';
        Database.insert(con);

        //Fetch the record type.
        Id sourceRecordTypeId = 
                Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Delivery').getRecordTypeId();

        //Set values and create a new case.
        Case testCase = new Case(Subject = 'Subject for inserting Service Delivery Case', OwnerId = testUser.Id, 
                Description = 'Description for inserting Service Delivery Case', RecordTypeId= sourceRecordTypeId, 
                ReferenceID__c = '1234597', AccountId = acc.Id, ContactId = con.Id);
        insert testCase;

        Attachment attach = new Attachment(Name = 'Attachment', ParentId = testCase.Id, 
                Body = blob.valueOf('AttachmentBody'));
        insert attach;

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = EncodingUtil.base64Decode('base64Data');
        cv.Title = 'Document';   
        cv.PathOnClient = 'PathClient';   
        insert cv;

        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId = testCase.Id, 
                ContentDocumentId = contentDocId, ShareType = 'V');
        insert cdl;
    }

    /*********************************************************************************
    *  Scenario:
    *      Test to insert and create a child case
    **********************************************************************************/
    static testMethod void testCreateChildCase() {

        //Retrieve the parent case Id.
        Case inCase = [SELECT Id, RecordTypeId, RecordType.Name, parent.ownerid, ownerId, 
                ContactId, Description, Subject, CaseNumber FROM Case LIMIT 1];

        //Prepare the record fields to save.
        String fields = '{"Subject":"Test Trading Statement invoice","Requestor__c":"'+UserInfo.getUserId()+'",'
                        +'"Report_Purpose__c":"Internal Analysis","Origin":"Salesforce User",'
                        +'"Description":"Test Trading Statement invoice"}';
        Id targetRecordTypeId = schema.sobjecttype.case.getRecordTypeInfosByName().get(Constants.RECORDTYPE_NAME_DELIVERY_ENQUIRY).getRecordTypeId();
        Id targetRecordTypeCustomerData = schema.sobjecttype.case.getRecordTypeInfosByName().get(Constants.RECORDTYPE_NAME_CUSTOMER_DATA_REQUEST).getRecordTypeId();
        //REQ3448199 remove refrence of report request record type
        //Id targetRecordTypeReportRequest = schema.sobjecttype.case.getRecordTypeInfosByName().get(Constants.RECORDTYPE_NAME_REPORT_REQUEST).getRecordTypeId();
        Id targetRecordTypeCreditDisputeClaim = schema.sobjecttype.case.getRecordTypeInfosByName().get(Constants.RECORDTYPE_NAME_CREDIT_DISPUTE_CLAIM).getRecordTypeId();
        List<Id> fileAndAttachmentIds = new List<Id>();
        fileAndAttachmentIds.addAll(new Map<Id,Attachment>([SELECT Id FROM Attachment]).keyset());
        fileAndAttachmentIds.addAll(new Map<Id,ContentDocument>([SELECT Id FROM ContentDocument]).keyset());
        Test.startTest();

        //Call the createChildCase method in Controller.
         String caseNum = CreateChildCaseController.createChildCase(fields, string.valueOf(inCase.RecordTypeId), 
                 string.valueOf(targetRecordTypeId), inCase.Id, fileAndAttachmentIds);
        
        //Call the getFieldset method in Controller.
        List<CreateChildCaseController.FieldSetMember> fieldSetMember = 
                CreateChildCaseController.getFieldSet(inCase.RecordTypeId, targetRecordTypeCustomerData, 
                inCase.Id);
        //call with Report Request record type
        //REQ3448199 remove refrence of report request record type
        //List<CreateChildCaseController.FieldSetMember> fieldSetMember2 = 
          //      CreateChildCaseController.getFieldSet(inCase.RecordTypeId, targetRecordTypeReportRequest, 
          //     inCase.Id);
        //call with Credit dispute claim record type
        List<CreateChildCaseController.FieldSetMember> fieldSetMember3 = 
                CreateChildCaseController.getFieldSet(inCase.RecordTypeId, targetRecordTypeCreditDisputeClaim, 
                inCase.Id);
        //Call child record types method
        List<CreateChildCaseController.PickListValue> picklistValues = 
                CreateChildCaseController.getChildRecordTypes(inCase.RecordTypeId);
        //get attachment List
        List<Attachment> attachList = CreateChildCaseController.getAttachmentList(inCase.Id);
        //get document List
        List<ContentDocument> docList = CreateChildCaseController.getDocumentList(inCase.Id);
        //get case record
        Case cs = CreateChildCaseController.getCaseRecord(inCase.Id);
        //get attachment Ids to share
        List<Id> attachmentIdList = new List<Id>();
        for(Attachment attach :attachList){
                attachmentIdList.add(attach.Id);
        }
        //CreateChildCaseController.creatAttachmentsforChildCase(attachmentIdList, inCase.Id);
        CreateChildCaseController.convertAttachmentToFileAndShare(attachmentIdList, inCase);
        //get document Ids to share
        List<Id> docIdList = new List<Id>();
        for(ContentDocument doc :docList){
                docIdList.add(doc.Id);
        }
        // CreateChildCaseController.shareDocsforChildCase(docIdList, inCase.Id);
        CreateChildCaseController.convertFileToAttachmentAndShare(docIdList,[SELECT Id FROM Case WHERE CaseNumber = :caseNum]);
        
        //check if files sharing is enabled for parent and target record type combination
        CreateChildCaseController.checkFileAndAttachmentSharing(inCase.RecordTypeId, targetRecordTypeId);
        Test.stopTest();

        //Retrieve the case with reference id.
        Case csRec = [SELECT Id,CaseNumber,Description,Subject,ReferenceID__c
                      FROM Case
                      WHERE ReferenceID__c = '1234597'
                      LIMIT 1];

        //Retrieve the case with caseNumber.
        //  Case csRec1 = [SELECT Id,CaseNumber,Description,Subject,ReferenceID__c,ParentId
        //                FROM Case
        //                WHERE caseNumber =: caseNum
        //                LIMIT 1];

        // System.assertNotEquals(null, caseNum,
        //         'CreateChildCaseControllerTest_testCreateChildCase : Child case should be created');

        // System.assertEquals(csRec.Id, csRec1.ParentId,
        //         'CreateChildCaseControllerTest_testCreateChildCase : Child case should be created');
        System.assertNotEquals(null,fieldSetMember,'Field set member is not null');
        System.assertNotEquals(null,picklistValues,'Found child record type options for Customer onboarding');

    }
}