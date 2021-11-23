/**
   * Created by: Shashwat Nath
   * Description: Test class for GenerateDocumentPage class
   * Date: 07/10/2019
   */
@IsTest
public class GenerateDocumentPageControllerTest {
    /* Test Method for bulk approvals */
    @testSetup static void setup() {
        Account Acc = new Account();
        Acc.name = 'Test';
        insert Acc;

        //data setup
        Rate_List__c rtList = new Rate_List__c();
        rtList.name = 'Test';
        rtList.Status__c = 'Active';
        rtList.Licence_Type__c = 'LPO';
        insert rtList;
        
        rtList.Status__c = 'Active';
        rtList.ByPassValidation__c=true;
        update rtList;
        
        
         system.debug('Rate List after insert'+rtList);

        Agreement_Document__c agreementRec = new Agreement_Document__c();
        agreementRec.Rate_List__c = NULL;
        agreementRec.Licence__c = Acc.id;
        agreementRec.Licence_Type__c='LPO';
        insert agreementRec;

    }
    
    public static testmethod void updateAgreementDocumentRecordTest() {

        Agreement_Document__c agreementRec = [Select ID FROM Agreement_Document__c LIMIT 1];

        Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(agreementRec);
            GenerateDocumentPageController cont = new GenerateDocumentPageController(sc);
            GenerateDocumentPageController.updateAgreementDocumentRecord(agreementRec.id , 'LPO');
        Test.StopTest();
        List<Agreement_Document__c> rtlistUpdated = new List<Agreement_Document__c>();
        rtlistUpdated = [Select Id , Rate_List__c from Agreement_Document__c where ID=:agreementRec.id LIMIT 1];
        Rate_List__c rtList = [SELECT ID, Licence_Type__c , Status__c FROM Rate_List__c LIMIT 1];
        system.debug('Rate List'+rtList);
        System.AssertEquals(rtlistUpdated[0].Rate_List__c , rtList.id);

    }
}