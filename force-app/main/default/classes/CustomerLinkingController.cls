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

	public class AccountWrapper{
		@AuraEnabled
		public Account accrec {get; set;}
		@AuraEnabled
		public String classname {get; set;}
	}
}