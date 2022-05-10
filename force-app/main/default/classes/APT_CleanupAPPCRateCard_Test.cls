/**
 * Created by: Sautul Mehta
 * Description: Class to have the cleanup of the generated documents for APPC View Rate Card.
 * @changelog
 * 2021-10-05 - Sautul Mehta - Class Created as part of CI-8
 */
@isTest
public class APT_CleanupAPPCRateCard_Test {

    @TestSetup
    static void makeData(){
        List<ContentDocument> contentDocuments = new List<ContentDocument>();
         Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 

        ContentVersion contentVersion_1 = new ContentVersion(
                Title='APPC Ratecard', 
                PathOnClient ='APPC Ratecard.Doc',
                VersionData = bodyBlob, 
                APT_Template_Name__c =APT_Constants.METADATTYPERECORD_TEMPLATE_APPC_RATE_CARD
            );
        insert contentVersion_1;        
    }
static testMethod void testMethod1() 
    {
        Test.startTest();

            APT_CleanupAPPCRateCard obj = new APT_CleanupAPPCRateCard();
            DataBase.executeBatch(obj); 
            
        Test.stopTest();

        List<ContentDocument> listContentDocument = [Select Id from ContentDocument];
        System.assert(listContentDocument.size() == 0);
    }
}