/**
* @author Shashwat Nath
* @date 2017-04-10
* @group SecurePay Project
* @tag SendWelcome Pack Controller
* @tag APMS Application
* @domain SecurePay Project
* @description Controller class to fectch job records from Application__c object.
* NOTE: This class is used by SendWelcomePack VF Page upon clicking "Send Welcome Pack" from APMS Application Detail Page. 
* 2017-04-10 - Shashwat Nath - Created
* 2021-01-27 - Dheeraj Mandavilli - Updated logic to related to multicurrency feature enablement in SecurePay Project.
*/
public with sharing class SendWelcomePackController {
    // Getter Setter
    public String recordId{get;set;}
    // Constructor
    public SendWelcomePackController(ApexPages.StandardController controller){
        recordId = controller.getRecord().id;
        
    }
    /**
*  This Method is called When user clicks on Send Welcome Pack button on APMS Application Detail Record Page
*  It retrieves the current application record and checks id Welcome Pack Sent field is checked then unchecks it.
*  If Welcome Pack field is not checked then sets the Welcome Pack Email to current user email and sets the welcome pack sent time to current time.
*/
    @remoteaction
    public static void updateApplication(String recordId){
        List<Application__c> apmsApplicationList = new List<Application__c>();
        // Retrieving the current Application record
        apmsApplicationList = [SELECT ID , IsWelcomePackSent__c, WelcomePackBcc__c, WelcomePackSentTime__c, Opt_for_Multicurrency__c,
                               Existing_Customer_Adding_Multicurrency__c,Are_Multicurrency_Details_Sent__c 
                               FROM Application__c WHERE ID=:recordId LIMIT 1];
        // Checking if welcome pack has already been sent
        if(!apmsApplicationList.isEmpty() && apmsApplicationList[0].IsWelcomePackSent__c && apmsApplicationList[0].Existing_Customer_Adding_Multicurrency__c == false){
            //Logic to throw error message
            string errAccId=system.label.welcomePackEmailSent;
            AuraHandledException ex = new AuraHandledException(errAccId);
            ex.setMessage(errAccId);
            throw ex;
        }
        else{
            // If welcome Pack is not sent then setting the field values
            if(!apmsApplicationList.isEmpty()) {
                if(apmsApplicationList[0].IsWelcomePackSent__c == false){
                    apmsApplicationList[0].WelcomePackBcc__c = UserInfo.getUserEmail();
                    apmsApplicationList[0].IsWelcomePackSent__c = true;
                    apmsApplicationList[0].WelcomePackSentTime__c = system.now();
                }
                if(apmsApplicationList[0].Opt_for_Multicurrency__c == 'Yes'){
                    apmsApplicationList[0].Are_Multicurrency_Details_Sent__c = true;
                }
                
            }
            
        }
        //Logic to handle existing cutomer opting for multi currency starts here
        if(!apmsApplicationList.isEmpty() && apmsApplicationList[0].Existing_Customer_Adding_Multicurrency__c && apmsApplicationList[0].Are_Multicurrency_Details_Sent__c){
            if(apmsApplicationList[0].Existing_Customer_Adding_Multicurrency__c == true){
                apmsApplicationList[0].IsWelcomePackSent__c = false;
                //Logic to throw error message 
                string errAccId = system.label.multicurrencyDetailsSent;
                AuraHandledException ex = new AuraHandledException(errAccId);
                ex.setMessage(errAccId);
                throw ex;                     
            }
        }
        else{
            // If welcome Pack is not sent then setting the field values
            if(!apmsApplicationList.isEmpty()) {
                if(apmsApplicationList[0].Existing_Customer_Adding_Multicurrency__c == true){
                    apmsApplicationList[0].Are_Multicurrency_Details_Sent__c = true;
                }
            }
        }
        // Updating the application record
        database.update(apmsApplicationList);
    }
    
}