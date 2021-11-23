public class AccountPlanExCon {
	/**************************************************
	Type:         Controller for visualforce page AccountPlanSummary
	History:
	--------------------------------------------------
	02.01.2014    AusPost									Production copy as is.
	02.01.2014    Louis Wang (Bluewolf)						Removed concept of Partner / Individual, such that standard Account-Contact is reestablished
	**************************************************/
 
	private ApexPages.StandardController stdCon;
	private Id AcctPlanId;
                
	public AccountPlanExCon(ApexPages.StandardController controller) {
        stdCon = controller;
        AcctPlanId = stdCon.getRecord().Id;
    }
    
    public Account_Plan__c acctplan {
        get{
                if(acctplan == null){
                        acctplan = [SELECT Account__c, Account__r.Id FROM Account_Plan__c WHERE Id = :AcctPlanId];
                }
                return acctplan;
        }
        set;
    }
    
    private List<Opportunity> opps {
        get{
                if(opps == null){ 
                        opps = [SELECT Id FROM Opportunity WHERE Account_Plan__c = :AcctPlanId];
                        }
                return opps;
        }
        set;
    }
    
	public List<Contact> contacts {
		// LW 2/01/2014 - Replace Partners list with this Contacts list
		get{
				if(contacts == null) {
					contacts = [SELECT Id, AccountId, Name, Title, Email, Phone 
									FROM Contact 
									WHERE AccountId = : acctplan.Account__c
									ORDER BY Name];
				}
				return contacts;
		}
		set;
	}

    public List<Pain_Point__c> painpts {
		// LW 2/01/2014 - Use KeyContact__c (lookup to Contact) from original Key_Contact__c (lookup to Account)
        get{
                        if(painpts == null){
                                painpts = [SELECT Name, KeyContact__c, Internal_Stakeholder_Impact__c, Opportunity__r.Name, KeyContact__r.Name 
                                                        FROM Pain_Point__c
                                                        WHERE Opportunity__c in :opps];
                        }
                        return painpts;
        }
        set;
	}

	public List<Competitor__c> competitors {
        get{
                        if(competitors == null){
                                competitors = [SELECT AccountId__r.Name, Incumbents__c, Incumbent_Reason__c, Incumbent_Satisfaction__c, 
                                                                        Competitive_Advantage__c, OpportunityId__r.Name   
                                                                FROM Competitor__c 
                                                                WHERE OpportunityId__c in :opps];
                }
                        return competitors;
        }
        set;
	}

	public List<Event> events{
		// LW 2/01/2014 - Use AccoundId in where clause from original WhatId. 
		//					AccountId is the account of WhatId if it exists, otherwise it’s the account of WhoId if it exists, otherwise it’s set to null		
        get{
                        if(events == null){
                                events = [SELECT Subject, ActivityDateTime, Owner.FirstName, Owner.LastName, Location, Description from Event WHERE AccountId =: acctplan.Account__r.Id
                                          AND ActivityDate >: Date.Today() AND ActivityDate <=: Date.Today()+90];
                        }
                        return events;                 
        }
        set;
	}
        
	public List<Task> tasks{
		// LW 2/01/2014 - Use AccoundId in where clause from original WhatId. 
		//					AccountId is the account of WhatId if it exists, otherwise it’s the account of WhoId if it exists, otherwise it’s set to null		
        get{
                        if(tasks == null){
                                tasks = [SELECT Subject, ActivityDate, Owner.FirstName, Owner.LastName, Status, Priority from Task WHERE AccountId =: acctplan.Account__r.Id
                                          AND ActivityDate >: Date.Today() AND ActivityDate <=: Date.Today()+90];
                        }
                        return tasks;                 
        }
        set;
	}
          
        public static testmethod void TestAcctPlan(){
                
                RecordType rectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
                
                //create account
                Account ca=new Account(name='test', phone='123', email__c='test@test.com', recordtypeid=rectype.id);
                insert ca;
                
                //create account plan
                Account_Plan__c ap=new Account_Plan__c(name='test ap', account__c=ca.id);
                insert ap;
                
                Test.startTest();
                //Test coverage for the VF page
                PageReference pageRef = Page.AccountPlanSummary;
                pageRef.getParameters().put('id', ap.id); 
                Test.setCurrentPageReference(pageRef);

                //Create an instance of the controller
                Apexpages.StandardController stdController = new Apexpages.StandardController(ap);                            
                AccountPlanExCon apExCon = new AccountPlanExCon(stdController);
                
                apExCon.acctplan = null;
                apExCon.competitors = null;
                apExCon.painpts = null;
                apExCon.contacts = null;
                apExCon.tasks = null;
                apExCon.events = null;
                
                system.AssertEquals(true,apExCon.acctplan!=null);
                system.AssertEquals(true,apExCon.competitors!=null);
                system.AssertEquals(true,apExCon.painpts!=null);
                system.AssertEquals(true,apExCon.contacts!=null);
                system.AssertEquals(true,apExCon.tasks!=null);
                system.AssertEquals(true,apExCon.events!=null);
                
                Test.stopTest();
        }
}