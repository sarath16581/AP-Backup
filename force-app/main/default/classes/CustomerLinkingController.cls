// later without sharing should be replaced with sharing
public without sharing class CustomerLinkingController {

    @AuraEnabled
	public static Map<String, Object> identifyCustomer(String searchkey) {
		Map<String, Object> resp = new Map<String, Object>();
		// later the query should be moved to the selector
		List<Account> acclist = [SELECT id, APCN__c, ACN__c, Name, Phone, Website
								FROM Account
								WHERE APCN__c=:searchkey
								OR ACN__c=:searchkey];
		if(acclist.size()>0){
			List<AccountWrapper> accwrapList = new List<AccountWrapper>();
			for(Account acc:acclist){
				AccountWrapper accwrap = new AccountWrapper();
				accwrap.accrec = acc;
				accwrap.classname = 'tile nonselectedtile';
				accwrapList.add(accwrap);
			}
			resp.put('accwrapList', accwrapList);
		}else{
			resp.put('noAccountFound', true);
		}
		return resp;
	}

	@AuraEnabled
	public static Map<String, Object> customerLinkingFormSubmit(String physicalAddress, String website, String phone, Account customer, String userId, Boolean isAllValidated) {
		Map<String, Object> resp = new Map<String, Object>();
		DSRWrapper dswrap = new DSRWrapper();
		dswrap.physicalAddress=physicalAddress;
		dswrap.website=website;
		dswrap.phone=phone;
		dswrap.legalEntityId=customer.Id;
		dswrap.originatingOutletId=userId;
		if(isAllValidated){
			Deal_Support_Request__c customerLinkingDsr = frameDSR(dswrap);
			System.enqueueJob(new customerLinkingQueueable(customer, userId, customerLinkingDsr));
			resp.put('success', true);
		}else{
			// map extra dsr fields here like failures 
			Deal_Support_Request__c customerLinkingDsr = frameDSR(dswrap);
			// insert customerLinkingDsr here -- as this is for physical address failure
			// pass the DSr number back to UI ::  resp.put('dsrnumber', customerLinkingDsr.Name);
			resp.put('dsrcreated', true);
		}
		return resp;
	}

	public static Deal_Support_Request__c frameDSR(DSRWrapper dsrdata){
		Deal_Support_Request__c customerLinkingDSR = new Deal_Support_Request__c();
		Id customerLinkingDSRID = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Customer_linking').getRecordTypeId();
		customerLinkingDSR.ownerId = 'customerLinkingDSR'; // Create this queue and query this queue
		// assign the rest of the fields with the actual fields
		return customerLinkingDSR;
	}

	public class DSRWrapper{
		@AuraEnabled
		public String physicalAddress {get; set;}
		@AuraEnabled
		public String website {get; set;}
		@AuraEnabled
		public String phone {get; set;}
		@AuraEnabled
		public String legalEntityId {get; set;}
		@AuraEnabled
		public String originatingOutletId {get; set;}
		@AuraEnabled
		public String dsrStatus {get; set;}
		@AuraEnabled
		public String dsrStage {get; set;}
		@AuraEnabled
		public String customerLinkingOutcome {get; set;}
		@AuraEnabled
		public String comments {get; set;}
		@AuraEnabled
		public String description {get; set;}
	} 

	public class AccountWrapper{
		@AuraEnabled
		public Account accrec {get; set;}
		@AuraEnabled
		public String classname {get; set;}
	}
}