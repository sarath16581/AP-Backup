/*
 * Created: Andrew Judd 27 May 2019.
 * AJ 2019-08-07 - Extended time diff between EOR update in test validateProvision5 from -1 to -1000
 * AJ 2019-08-12  ajudd@salesforce.com Added BAM Record Type Id conditions
 */
@isTest
public with sharing class BAMProvision_Test {

    testmethod static void validateProvision1(){
               
        /*Test initial provision with no eobr records.
         *Confirm that payloadMap returns a provision payload and no deprovision payload
		*/
        Map<String, Id> recordIdMap = new  Map<String,Id>();
        Map<String,String> payloadMap = new  Map<String,String>();
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;
        
        //Create test data
        recordIdMap = BAMTestUtility.createBamBasicRecords();
		
        //Get contact Id
        Id contactId = recordIdMap.get('con'); 
        Id conAppId = recordIdMap.get('conapp');
        
        //Call provision
        payloadMap = BAMProvision.provision(contactId);
        
        //Get Pending External Onboarding request record
        BAMExternalOnboardingRequest__c[] objEOBR = [
            Select Id FROM BAMExternalOnboardingRequest__c 
            WHERE Contact__c = :contactId AND
            Contact_Application__c = :conAppId AND 
            Type__c = 'Provision' AND 
            Status__c = 'Pending' AND
            RecordTypeId = :bamExtObRTId 
            LIMIT 1]; 
       
        //confirm provision returned - due to access being set up and no eobr record; and deprovision not returned - due to no app in pending delete or pending deactivation
        System.assertNotEquals(null, payloadMap.get('provision'));
        System.assertEquals(null, payloadMap.get('deprovision'));
        
        //Confirm one external onboarding request record created for the contact app with status = Pending
		System.assertNotEquals(null, objEOBR);

    }
    
    testMethod static void validateProvision2() {

        /*Test deprovision
         *Confirm that payloadMap returns a deprovision payload and no provision payload
		*/
        Map<String, Id> recordIdMap = new  Map<String,Id>();
        Map<String,String> payloadMap = new  Map<String,String>();
        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;
        
        //Create test data
        recordIdMap = BAMTestUtility.createBamBasicRecords();
        
        //Get contact Id
        Id contactId = recordIdMap.get('con'); 
        Id conAppId = recordIdMap.get('conapp');
        
        //Set Contact Application to Pending Delete - i.e. deprovision
        BAMContactApplication__c[] objConApp = [Select Id, Pending_Delete__c FROM BAMContactApplication__c WHERE Contact__c = :contactId LIMIT 1];
        objConApp[0].Pending_Delete__c = true;
        update objConApp[0];
        
        //Call provision
        payloadMap = BAMProvision.provision(contactId);
        
        //Get Pending External Onboarding request record
        BAMExternalOnboardingRequest__c[] objEOBR = [
            Select Id FROM BAMExternalOnboardingRequest__c 
            WHERE Contact__c = :contactId AND
            Contact_Application__c = :conAppId AND 
            Type__c = 'Deprovision' AND 
            Status__c = 'Pending' AND
            RecordTypeId = :bamExtObRTId 
            LIMIT 1]; 
       
        //confirm no provision returned - due to app being set as pending delete; and deprovision returned - due app in pending delete state
        System.assertEquals(null, payloadMap.get('provision'));
        System.assertNotEquals(null, payloadMap.get('deprovision'));
        
        //Confirm one external onboarding request record created for the contact app with status = Pending
		System.assertNotEquals(null, objEOBR);

    }    
    testmethod static void validateProvision3(){
               
        /*Test provision with Pending eobr records.
         *Create a 'Pending' external onboarding request
		 *Then call provision and confirm that no provision payload is returned due to Pending request for contact application
		*/
        Map<String, Id> recordIdMap = new  Map<String,Id>();
        Map<String,String> payloadMap = new  Map<String,String>();
        
        //Create test data
        recordIdMap = BAMTestUtility.createBamBasicRecords();
        
        //Get Ids
        Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp'); 
        
        Datetime responseDateTime = System.now();
        
        //Create external onboarding request Pending
        BAMExternalOnboardingRequest__c eobr = BAMTestUtility.createExternalOnboardingRequest(contactId, conAppId, 'Pending', responseDateTime);
        insert eobr;	
        
        //Call provision
        payloadMap = BAMProvision.provision(contactId);
       
        //confirm no provision returned - due to pending eobr; and no deprovision returned - due to no pending delete or deactivation
        System.assertEquals(null, payloadMap.get('provision'));
        System.assertEquals(null, payloadMap.get('deprovision'));
    }
    testmethod static void validateProvision4(){
               
        /*Test provision with Success eobr records and NO changes made to access since success
         *Create a 'Success' external onboarding request with response date after to the change in access (set up of data)
		 *Then call provision and confirm that the provision payload is NOT returned due to no changes in access for contact application made after the response date of the success eobr
		*/
        Map<String, Id> recordIdMap = new  Map<String,Id>();
        Map<String,String> payloadMap = new  Map<String,String>();
        
        //Create test data
		recordIdMap = BAMTestUtility.createBamBasicRecords();

        //Get Ids
        Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp'); 
        
        //Create external onboarding request Success
        Datetime responseDateTime = System.now();
        BAMExternalOnboardingRequest__c eobr = BAMTestUtility.createExternalOnboardingRequest(contactId, conAppId, 'Success', responseDateTime);
        insert eobr;	
       
        //Call provision
        payloadMap = BAMProvision.provision(contactId);
       
        //confirm no provision returned - due to no change in access since success eobr; and no deprovision returned - due to no pending delete or deactivation
        System.assertEquals(null, payloadMap.get('provision'));
        System.assertEquals(null, payloadMap.get('deprovision'));
    }
    testmethod static void validateProvision5(){
               
        /*Test provision with Success eobr records and WITH changes made to access since success
         *Create a 'Success' external onboarding request 
		 *Add a new LE to the Role after the success
		 *Then call provision and confirm that the provision payload is IS returned due to changes in access for contact application made after the response date of the success eobr
		*/
        Map<String, Id> recordIdMap = new  Map<String,Id>();
        Map<String,String> payloadMap = new  Map<String,String>();
        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;
        
        //Create test data
		recordIdMap = BAMTestUtility.createBamBasicRecords();

        //Get Ids
        Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp'); 
        Id accId = recordIdMap.get('acc'); 
        Id conRoleId = recordIdMap.get('conrole'); 
        
        //Create external onboarding request Success (remove some time to ensure it prior to the change applied below)
        Datetime responseDateTime = System.now().addSeconds(-1000);
        BAMExternalOnboardingRequest__c eobr = BAMTestUtility.createExternalOnboardingRequest(contactId, conAppId, 'Success', responseDateTime);
        insert eobr;	
       
        //Add a new linked entity to the role
        //Create new BA and LE with that BA against the role
        Billing_Account__c ba = BAMTestUtility.createTestBillingAccount(accId, 'BA678');
        insert ba;
        BAMLinkedEntity__c le = BAMTestUtility.createTestLinkedEntity(conRoleId, ba.Id, 'ba');
        insert le;

        //Call provision
        payloadMap = BAMProvision.provision(contactId); 
        
        //Get Pending External Onboarding request record
        BAMExternalOnboardingRequest__c[] objEOBR = [
            Select Id FROM BAMExternalOnboardingRequest__c 
            WHERE Contact__c = :contactId AND
            Contact_Application__c = :conAppId AND 
            Type__c = 'Provision' AND 
            Status__c = 'Pending' AND
            RecordTypeId = :bamExtObRTId 
            LIMIT 1]; 
       
        //confirm provision returned - due to change in access since success eobr; and no deprovision returned - due to no pending delete or deactivation
        System.debug('AJJ payloadMap provision = ' + payloadMap.get('provision'));
        System.debug('AJJ payloadMap deprovision = ' + payloadMap.get('deprovision'));
        System.assertNotEquals(null, payloadMap.get('provision'));
        System.assertEquals(null, payloadMap.get('deprovision'));
        
        //Confirm one external onboarding request record created for the contact app with status = Pending
		System.assertNotEquals(null, objEOBR);
    }
}