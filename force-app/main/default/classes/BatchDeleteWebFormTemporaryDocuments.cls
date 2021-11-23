/**
* Author: 		Angelo Rivera
* Name: 		BatchDeleteWebFormTemporaryDocuments
* Description: 	Extracts and deletes temporary documents uploaded from I2C Web form
*					This should be scheduled to run every end of day (11PM).
* Revision History
* 07-12-2017 	1.0		AP.Rivera		Created
**/

global without sharing class BatchDeleteWebFormTemporaryDocuments implements Database.Batchable<sObject> {
	
	String query;
	List<I2C_Web_Form_Profiles__c> lstWebFormProfiles = new List<I2C_Web_Form_Profiles__c>();
	Set<String> setProfileNames = new Set<String>();
    Set<Id> setProfileId = new Set<Id>();
	
	global BatchDeleteWebFormTemporaryDocuments() {
		System.debug('###DEBUG: Batch Process BatchDeleteWebFormTemporaryDocuments Initiated');

		lstWebFormProfiles = I2C_Web_Form_Profiles__c.getall().values();
        if(!lstWebFormProfiles.isEmpty()){
            for(I2C_Web_Form_Profiles__c wfProfile : lstWebFormProfiles){
                setProfileNames.add(wfProfile.Profile_Name__c);
            }
            System.debug('###DEBUG: ' + setProfileNames);

			for( User u : [select Id, Profile.Name, IsActive FROM User
										where IsActive = true and profile.name in: setProfileNames]){
				setProfileId.add(u.Id);
			}
        }else{
        	System.debug('###DEBUG: I2C_Web_Form_Profiles__c does not contain any profile name.');
        }

        if(!Test.isRunningTest()){query = 'select Id, Name, Description, CreatedDate, AuthorId from Document where Name like \'TemporaryDocument_%\'' +
							' and Description like \'TemporaryDocument_%\' and CreatedDate < TODAY and AuthorId in: setProfileId';
		}else{query = 'select Id, Name, Description, CreatedDate, AuthorId from Document where Name like \'TemporaryDocument_%\'' +
							' and Description like \'TemporaryDocument_%\' and CreatedDate <= TODAY and AuthorId in: setProfileId';}
        System.debug(query);

	}
	
	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext bc, List<Document> lstDocumentsToBeDeleted) {
   		System.debug('###DEBUG: Batch Process BatchDeleteWebFormTemporaryDocuments Process Started');
		
		Savepoint sp = Database.setSavepoint(); 
		try{
			if(!lstDocumentsToBeDeleted.isEmpty()){
				Delete lstDocumentsToBeDeleted;
				System.debug('###DEBUG: Batch Process Deleted ' + lstDocumentsToBeDeleted.size() + ' Documents');
			}
		} catch (exception e){
			System.debug('###DEBUG: ERROR while processing batch! | ' + e.getMessage());
            Database.rollback(sp);
		}
	}
	
	global void finish(Database.BatchableContext bc) {
		System.debug('###DEBUG: Batch Process BatchDeleteWebFormTemporaryDocuments Completed');
	}
	
}