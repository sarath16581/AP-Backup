/**
 * Created by hasantha on 27/5/19.
 */
@isTest
public with sharing class ServiceNow_UploadFIleControllerTest {

    @testSetup
    static void testData(){
        // insert of auspost custom setting for credentials to access serv now
        AusPostSettings__c auspostSettings = new AusPostSettings__c();
        auspostSettings.Name = 'ServiceNowCredentials';
        auspostSettings.URL__c = 'TestURL';
        auspostSettings.Username__c = 'TestUserName';
        auspostSettings.Password__c = 'TestPassword';
        insert auspostSettings;
    }

    /**
     * Upload file success
     **/
    @IsTest
    static void UploadFIleControllerTest_upload() {
        String fileName = 'name';
        String base64Data = 'b64';
        String contentType = '.pdf';
        // call the saveChunk without the field Id (first save)
        Id fileId = ServiceNow_UploadFIleController.saveTheChunk(fileName, base64Data, contentType, '');
        // this will return a field ID.
        system.assertNotEquals(
            null,
            fileId,
            'ServiceNow_UploadFIleControllerTest:UploadFIleControllerTest_upload() FiledId must not be null when the field id is not passed to the saveChunks method'
        );

        // second call will be made with a field Id from aura controller, if there are more chunks to be appended
        fileId = ServiceNow_UploadFIleController.saveTheChunk(fileName, base64Data, contentType, fileId);
        
        // once upload is completed, this will upload file to service now, notification is sent from aura
        Boolean success = ServiceNow_UploadFIleController.uploadToServNow(fileId,'test');
        
        system.assertEquals(true, success, 'ServiceNow_UploadFIleControllerTest:UploadFIleControllerTest_upload() : upload successful');
    }

}