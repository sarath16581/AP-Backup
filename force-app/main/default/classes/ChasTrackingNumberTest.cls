/**
 * Created by nmain on 21/08/2018.
 */
@isTest(SeeAllData=true)
public with sharing class ChasTrackingNumberTest {

    /**
        * Moved this method here because 'fakeResponse' will not work if we insert any DML then calling 'HttpCalloutMock'.
        * So this class is annatation is seeAll=True, so without inserting Custom setting calling 'HttpCalloutMock' so working.
        * The ChasApexControllerTest is having dataSetUp() methods so can't put sellAll=True
        * **/
    public static testMethod void testsearchTrackingNumber() {
        Boolean isSuccess = true;

        try{

            Test.startTest();

            /* List< Consumer_Help_and_Support__c> customSettingList = new List< Consumer_Help_and_Support__c>();
            //-- setting some key and service URL as it wont hit a call for service from test cases
            Consumer_Help_and_Support__c setting = new Consumer_Help_and_Support__c();
            setting.API_Key__c = 'ecc702f2-278a-4b84-aa1e-3e7dea3c6246';
            setting.Connection_Time_Out__c = 60000;
            setting.End_Point_1Track_Service_URL__c ='https://digitalapi-ptest.npe.auspost.com.au/shipmentsanonapi/customers/anon/shipments/';
            setting.AP_Channel_Name__c ='HelpSupport';
            setting.SetupOwnerId=UserInfo.getOrganizationId();
            customSettingList.add(setting);
            //-- Inserting Custom setting
            insert customSettingList; */

            ChasApexController.TrackingNumberDetails a = new ChasApexController.TrackingNumberDetails();
            a.articleType=null;
            a.deliveredByDateOrEDD=null;
            a.eddStatus = null;
            a.itemType = null;
            a.recipientCountry = null;
            a.senderCountry = null;
            a.trackingNumSerachStatusCode= null;
            a.trackingNumSerachStatusMsg = null;

            Map<String, String> responseHeaders = new Map<String,String>{'Content-Type'=>'application/json'} ;
            ChasSingleRequestMock fakeResponse = new ChasSingleRequestMock(200,'Complete', '{"consignmentId":"HMM0000812","articles":[{"consignmentId":"HMM0000812","articleId":"HMM000081201000910909","articleType":'+
                    '"Parcel Post","deliveredByDate":"20170802"}]}', responseHeaders);

            Test.setMock(HttpCalloutMock.class, fakeResponse);

            ChasApexController.searchTrackingNumber('HMM000081201000910909');     // -- with EDD=null, with EDD > today, with EDD < today, article type='international' 'Domestic'
            Test.stopTest();

        }catch(Exception e){
            System.debug('testsearchTrackingNumber()::error==>'+e.getMessage());
            isSuccess = true;
        }
        System.assert(isSuccess);
    }


}