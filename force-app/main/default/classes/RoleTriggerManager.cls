/**
 * @description Class that manages trigger on Organisation_Role object
 * @author Cloud Sherpas SH
 * @date 17.May.2012
 * History:
--------------------------------------------------
 17.05.2012  SH (Cloud Sherpas)     Created
 22.09.2016  Davey Yu (Accenture)	Updated: MPB Known Account Management populate organisation legacy id for known
 03.02.2021  SaiSwetha Pingali      INC1727549 - Moved the logic to update accounts from PopulateLegacyIdOnAccount to a inner class without sharing as guest users doesn't have access to accounts.
*/
public with sharing class RoleTriggerManager {

	public static void PopulateLegacyIdOnAccount(List<Organisation_Role__c> orgRole){
        
		Set<Id> accId = new Set<Id>();
		AccessAccountData qAcc = new AccessAccountData();
		Map<String,String> orgMap = new Map<String,String>();
		
		try{
			//put all new values into map to hold account id and name of the organisation role
			for(Organisation_Role__c orc: orgRole){
				// validate first if organisation role has a prospect or customer role type
				// START OF UPDATE DY 22.09.2016 MPB - Include role type of known to set the legacy id
				if(orc.Role_Type__c=='Prospect' || orc.Role_Type__c=='Customer' || orc.Role_Type__c =='Known'){
				orgMap.put(orc.Organisation__c, orc.Name);
				accId.add(orc.Organisation__c);//ids of account to filter query
				}
				// END OF UPDATE DY 22.09.2016 MPB - Include role type of know to set the legacy id
			}
			if(accId!=null){
                // spingali - Soql and DML is handled in a inner class without sharing as guest user doesn't have access to the account record.
				qAcc.UpdateAccounts(accId,orgMap);
			}
		}
		catch(Exception e){
				System.debug(e.getMessage());
		}
	}
    
    /* spingali - added a new inner class as guest users doesn't have access to Accounts */
	public without sharing class AccessAccountData
	{
		public void UpdateAccounts(Set<Id> AccountIds,Map<String,String> OrgMap){
			List<Account> accList = new List<Account>();
			List<Account> accUpdate = new List<Account>();
		    try{
			 if(AccountIds!=null){//validate that accId is not empty
					// Soql is handled in a inner class without sharing as guest user doesn't have access to the account record.
					accList= [Select Id from Account where Id IN: AccountIds];
					for(Account acc: accList){
						if(OrgMap.containsKey(acc.Id)){//put Name of organisation role to account field legacy id
							acc.LEGACY_ID__c = OrgMap.get(acc.Id);
							system.debug('LEGACY_ID__c'+acc.LEGACY_ID__c);
							accUpdate.add(acc);//add to list of account
						}
					}
					update accUpdate;// update account list
				}
			}
			catch(Exception e){
					System.debug(e.getMessage());
			}
		}
	}
 
    private static testMethod void myUnitTest() {
    	Test.startTest();//determine recordtype of account
    	RecordType orgRecType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        List<Account> accList = new List<Account>();
        Account acc;
        integer x = 0;
       	for(x=1;x<200;x++){
       		acc = new Account();
       		acc.RecordTypeId =orgRecType.Id;
       		acc.Name = 'Philip Stein';
       		accList.add(acc);
       	}
       	insert accList;
       	List<Organisation_Role__c> orList = new List<Organisation_Role__c>();
       	Organisation_Role__c orc;
       	for(Account a: accList){
       		orc = new Organisation_Role__c();
       		orc.Organisation__c = a.Id;
       		orc.Role_Type__c = 'Prospect';
       		orList.add(orc);
       	}
       	insert orList;
       
       	Test.stopTest();

       	List<Account> accAll = [Select Name,LEGACY_ID__c from Account Where Id IN:accList];
       	List<Organisation_Role__c> orAll = [Select Name,Role_Type__c,Organisation__c from Organisation_Role__c where Id IN: orList];
		for (Account acct : accAll){
			System.assertEquals(acct.Name,'Philip Stein');
			for (Organisation_Role__c o : orAll){
				if(acct.Id==o.Organisation__c){
					System.assertEquals(o.Role_Type__c,'Prospect');
		            System.assertEquals(o.Name,acct.LEGACY_ID__c);
	          	}
			}
		}
    }
}