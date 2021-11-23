/*
@Description        : Test class for APT_ContractFileShareScheduler and APT_ContractFilesQueueClass 
                      which links the apttus contract file/s to the related sf contract when an apttus 
                      contract is activated or a file is added under apttus contract.
================================ Modification Log =============================== 
Developer Name  Date            Comments
Ramtej          15/05/2019      Created
*/
@isTest
public class APT_ContractFileShareSchedulerTest {
    
    // Test variable declaration
    public static final string MSA_RECORTYPE = 'MSA & Service Schedule';
    public static final string INAUTHOR_STATUS_CATEGORY = 'In Authoring';
    public static final string AUTHORCONTRACT_STATUS = 'Author Contract';
    
    @testSetup static void setup() {
        // Create test organisation
        Account accVar = APT_TestUtil2.createOrganisation();
        insert accVar;

        // Create test contact
        Contact conVar = APT_TestUtil2.createContact();
        conVar.AccountId = accVar.Id;
        insert conVar;

        // Create test opportunity
        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);
        
        //Create Docusign Envelope Record
        Apttus_DocuApi__DocuSignEnvelope__c docuEnv = new Apttus_DocuApi__DocuSignEnvelope__c();
        docuEnv.Apttus_DocuApi__Status__c = 'completed';
        insert docuEnv;
        // Create test agreement
        Apttus__APTS_Agreement__c aptContract = APT_TestUtil2.createAgreement(accVar,
                                                                              conVar,
                                                                              oppVar,
                                                                              new Apttus_Proposal__Proposal__c(),
                                                                              AUTHORCONTRACT_STATUS,
                                                                              INAUTHOR_STATUS_CATEGORY,
                                                                              MSA_RECORTYPE);

        aptContract.APT_Product__c = 'eParcel';
        aptContract.Apttus_CMDSign__DocuSignEnvelopeId__c = docuEnv.id;
        insert aptContract;
                 

    }
    
    static testMethod void testLinkingFiles(){        
        test.startTest();        
        Apttus__APTS_Agreement__c aptContract = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Account accVar = [SELECT Id FROM Account LIMIT 1];                                
        //Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        
        //create sf contract under apttus contract
        Contract con = new Contract(Parent_Agreement__c = aptContract.Id, AccountId = accVar.id);
        insert con;
        // Create test content documents more than 5 to test APT_ShareFilesQueueClass
        List<ContentVersion> ContentVersionList = new List<ContentVersion>();
        ContentVersion contentVersion0 = APT_TestUtil2.createContentVersion();
        ContentVersionList.add(contentVersion0);
        ContentVersion contentVersion1 = APT_TestUtil2.createContentVersion();
        ContentVersionList.add(contentVersion1);
        ContentVersion contentVersion2 = APT_TestUtil2.createContentVersion();
        ContentVersionList.add(contentVersion2);
        contentVersion2.title = 'Test__signed';
        ContentVersion contentVersion3 = APT_TestUtil2.createContentVersion();
        ContentVersionList.add(contentVersion3);
        ContentVersion contentVersion4 = APT_TestUtil2.createContentVersion();
        //ContentVersionList.add(contentVersion4);
        ContentVersion contentVersion5 = APT_TestUtil2.createContentVersion();
        //ContentVersionList.add(contentVersion5);
        ContentVersion contentVersion6 = APT_TestUtil2.createContentVersion();
        
        //ContentVersionList.add(contentVersion6);
        insert ContentVersionList;
        
        List<Id> contentversionIds = new List<Id>();
        for(ContentVersion cv :ContentVersionList){
            contentversionIds.add(cv.Id);            
        }

        // Create ContentDocumentLink  records
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for(ContentVersion cv  :[SELECT Id, contentdocumentId FROM ContentVersion WHERE Id IN :contentversionIds]){
            cdlList.add(APT_TestUtil2.createContentDocumentLink (aptContract.id, cv.contentdocumentId));
        } 
        insert cdlList;
        //schedule class to link files
        APT_ContractFileShareScheduler schedulerClass = new APT_ContractFileShareScheduler();
        schedulerClass.contractList = new List<Contract>{con};
        schedulerClass.linkFiles();        
        test.stopTest();
        //test the number of files under sf contract
        system.assertEquals(4, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :con.Id].size());
    }
}