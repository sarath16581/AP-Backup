/*------------------------------------------------------------
Author:        Adrian Recio (adrian.recio@auspost.com.au)
Description:   Main handler class for membershiptrigger
Test Class:    MembershipTriggerHandler_Test
History
15/5/2018     Adrian Recio (adrian.recio@auspost.com.au)         Created main handler class methods and expireSibling method
27/6/2018     Daric Dava (daric.antoni.a.dava@accenture.com)     Implemented trigger validation rules
4/5/2018      Adrian Recio (adrian.recio@auspost.com.au)         Added parent account license activation
11/7/2018	  Chester Borbon (conrad.c.v.borbon@accenture.com)   Added code to validate and change the APLAC Member checkbox in the related Account/License. Added the checkAPLACMember method.
05/05/2020    Disha Kariya      Added record Type check
15/05/2020    Paul Perry		Austrac S75 process, tracking status updates in date fields
------------------------------------------------------------*/


public with sharing class MembershipTriggerHandler {
	//    public static Boolean isRecursive = false;
	//    public static Boolean workFlowRecursive = false;
		/**
		 * Return the APLAC record type Id
		*/
		public static Id aplacRecordTypeId {
			get{
				if(aplacRecordTypeId == null){
					aplacRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Membership__c', new Set<String>{Membership_Constants.APLAC_RECORD_TYPE}).values()[0].Id;
				}
				return aplacRecordTypeId;
			}set;
		}
	
		/* Trigger Handler Methods */
		public static void beforeInsertTriggerHandler(List<Membership__c> triggerNewList){
			MembershipTriggerHandler.handlerSetBuilder(triggerNewList, true);
			MembershipTriggerHandler.validateMembershipRecords(triggerNewList, null, true);
			MembershipTriggerHandler.austracHistoryTracking(triggerNewList, null);
		}
	
		public static void beforeUpdateTriggerHandler(List<Membership__c> triggerNewList, Map<Id, Membership__c> oldMap){
	//        if(MembershipTriggerHandler.isRecursive==false) {
				MembershipTriggerHandler.handlerSetBuilder(triggerNewList, false);
				MembershipTriggerHandler.validateMembershipRecords(triggerNewList, oldMap, false);
				MembershipTriggerHandler.austracHistoryTracking(triggerNewList, oldMap);
	//        }
		}
	
		public static void afterInsertTriggerHandler(List<Membership__c> triggerNewList){
			MembershipTriggerHandler.expireSibling(triggerNewList);
			MembershipTriggerHandler.checkAPLACMember(triggerNewList);			
		}
	
		public static void afterUpdateTriggerHandler(List<Membership__c> triggerNewList){
	//        if(MembershipTriggerHandler.isRecursive==false) {
				MembershipTriggerHandler.expireSibling(triggerNewList);
	//        }
	
	//        if(MembershipTriggerHandler.workFlowRecursive == false){
				MembershipTriggerHandler.checkAPLACMember(triggerNewList);
	//        }
		}
		/* End of Trigger Handler Methods */
	
		//Commented below as memIdSet was never used
	//    public static Set<Id> memIdSet = new Set<Id>();
		public static Set<Id> licenseeSet = new Set<Id>();
		public static Set<Id> licenseeSetToCompare = new Set<Id>();
		public static Map<Id, Account> accLicenseMap = new Map<Id, Account>();
	
		/**
	* Build sets used for list query
	* @author adrian.a.recio 11/07/2018
	* @param triggerNewList List of trigger new membership records subject for validation.
	*/
		public static void handlerSetBuilder(List<Membership__c> memList, Boolean beforeInsert){
			// Pull parent account Id in a set only when inserting or when the update is
			licenseeSetToCompare.addAll(licenseeSet);
				for (Membership__c memVar : (!(beforeInsert) ? ((List<Membership__c>) RecursionUtility.getUnprocessedRecords('handlerSetBuilder', memList)) : memList)) {
					System.debug('memVar.RecordTypeId--->' + memVar.RecordTypeId);
	
					//Added check for APLAC record type
					if (memVar.Status__c == 'Active' && (memVar.RecordTypeId == null || memVar.RecordTypeId.equals(MembershipTriggerHandler.aplacRecordTypeId))) {
						//Commented below as memIdSet is not used.
	//                    memIdSet.add(memVar.Id);
						licenseeSet.add(memVar.Account__c);
					}
				}
	
				// Pull parent account and child active membership records
	//        accLicenseMap = new Map<Id, Account>([SELECT Id, APLAC_Member__c,
	//                                                (SELECT Id, Status__c FROM Memberships__r
	//                                                WHERE Status__c = 'Active')
	//                                                FROM Account WHERE Id IN :licenseeSet]);
			//Added below if to avoid retrieving recently created Active Membership
			if(!licenseeSetToCompare.containsAll(licenseeSet) || beforeInsert) {
				//Used AccountSelector as it can be used to mock in test class
				accLicenseMap = AccountsSelector.newInstance().selectById(licenseeSet, new Set<Object>{
						AccountsSelector.Options.WITH_ACTIVE_MEMBERSHIPS
				});
			}
			System.debug('after accLicenseMap--->'+accLicenseMap);
		}
	
		/**
	* Expire all sibling memberships and activate account license as APLAC Member
	* @author adrian.a.recio 15/5/2018
	* @param triggerNewList List of trigger new membership records subject for validation.
	*/
		public static void expireSibling(List<Membership__c> triggerNewList){
			try {
	
				System.debug('Expire Execution');
				Set<Membership__c> setMemberships = new Set<Membership__c>();
				setMemberships.addAll(triggerNewList);
				System.debug('licenseeSet size:' + licenseeSet.size());
				//No need to add record type check here as we already added this check when adding licence to licenseeSet
				// Update active sibling membership to expired
				if (licenseeSet.size() > 0) {
					List<Membership__c> memExpireList = new List<Membership__c>();
					Map<Id, Membership__c> memTempMap = new Map<Id, Membership__c>();
					for(Membership__c pmemVar : (List<Membership__c>) RecursionUtility.getUnprocessedRecords('expireSibling',triggerNewList)) {
						List<Membership__c> memTempList = accLicenseMap.get(pmemVar.Account__c).Memberships__r;
						System.debug('child member size:' + memTempList.size());
	
						for(Membership__c memVar: memTempList) {
							//Added condition before updating the field
							if(memVar.Status__c != 'Expired') {
								memVar.Status__c = 'Expired';
								memTempMap.put(memVar.Id, memVar);
							}
						}
					}
					memExpireList.addAll(memTempMap.values());
	
					System.debug('memExpireList size:' + memExpireList.size());
	//                MembershipTriggerHandler.isRecursive = true;
					if(memExpireList.size()>0) {
						update memExpireList;
					}
				}
	
			} catch(Exception e){
				UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), Membership_Constants.APLICATION_NAME, MembershipTriggerHandler.class.getName(), 'expireSibling',null, LoggingLevel.ERROR);
			}
		}
		
	
		/**
	* Throw an error if application has a License Type of “Update Membership” and matching organisation based on ABN doesn’t have existing membership.
	* @author daric.antoni.a.dava 22/06/2018
	* @param triggerNewList List of trigger new membership records subject for validation.
	*/
		public static void validateMembershipRecords(List<Membership__c> triggerNewList, Map<Id, Membership__c> oldMap, Boolean beforeInsert){
			try {
				for(Membership__c memVar : (!(beforeInsert) ? ((List<Membership__c>)RecursionUtility.getUnprocessedRecords('validateMembershipRecords',triggerNewList, new Set<String>{'Licensee_Type__c'})) : triggerNewList)) {
					//Check for APLAC record type if record type exist. ALso check if Licensee Type has been updated or if status changed to Active .
					if (memVar.RecordTypeId == null || memVar.RecordTypeId.equals(MembershipTriggerHandler.aplacRecordTypeId) && (oldMap==null || (oldMap.containsKey(memVar.Id) && oldMap.get(memVar.Id).Licensee_Type__c != memVar.Licensee_Type__c) || (oldMap.containsKey(memVar.Id) && memVar.Status__c.equalsIgnoreCase('Active') && oldMap.get(memVar.Id).Status__c != memVar.Status__c))){
						//New Membership License Type validation
						//Check if Map has Licence details
						if (accLicenseMap.containsKey(memVar.Account__c) && accLicenseMap.get(memVar.Account__c).Memberships__r.size() > 0 &&
								memVar.Licensee_Type__c == 'New Membership') {
							memVar.Licensee_Type__c.addError('Membership is already active. Select Licensee Type of Update Membership.');
						} else if (accLicenseMap.containsKey(memVar.Account__c) && accLicenseMap.get(memVar.Account__c).Memberships__r.size() == 0 &&
								memVar.Licensee_Type__c == 'Update Membership') {
							memVar.Licensee_Type__c.addError('Licensee doesn’t have an existing membership. Select Licensee Type of New Membership.');
						}
					}
				}
	
			}catch(Exception e){
				UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), Membership_Constants.APLICATION_NAME, MembershipTriggerHandler.class.getName(), 'validateMembershipRecords',null, LoggingLevel.ERROR);
			}
		}
	
		/**
	* Check if the hidden field to check if the Email has already been sent to the Member. If yes,  change the value of the APLAC Member in the related Account/License to true.
	* @author conrad.c.v.borbon July 11, 2018
	*/
		
		public static void checkAPLACMember(List<Membership__c> triggerNewList) {
			try{
	
				List<Account>accLicUpdateList = new List<Account>();
	
				// Pull contact and licensee information from active membership
				for (Membership__c memVar : triggerNewList) {
					//Added check for APLAC record type
					if (memVar.Status__c == 'Active' &&
						memVar.APLAC_Welcome_Email_Sent__c == true && (memVar.RecordTypeId == null || memVar.RecordTypeId.equals(MembershipTriggerHandler.aplacRecordTypeId))) {
					   Account accVar = accLicenseMap.get(memVar.Account__c);
					   if(!accVar.APLAC_Member__c) {
						   accVar.APLAC_Member__c = true;
						   accLicUpdateList.add(accVar);
					   }
					}
				}
	
				if(accLicUpdateList.size()>0) {
	//                MembershipTriggerHandler.workFlowRecursive = true;
					update accLicUpdateList;
				}
			}catch(Exception e){
				UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), Membership_Constants.APLICATION_NAME, MembershipTriggerHandler.class.getName(), 'checkAPLACMember',null, LoggingLevel.ERROR);
			}
		}
	
		/**
		 * Execute Austrac S75 Logic: Apply Date Stamp for S75_Status__c changes using HistoryTracking Framework
		 * Capture update Date upon S75 Status field updates (Jira: SMWD-405)
		 */
		public static void austracHistoryTracking(List<Membership__c> triggerNewList, Map<Id, Membership__c> oldMap) {
			HistoryTracking.run(Membership__c.SObjectType, triggerNewList, oldMap);
		}
	}