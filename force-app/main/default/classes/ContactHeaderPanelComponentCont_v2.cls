/**************************************************
Type:       Visualforce controller
Purpose:    Provides the controller logic to create the five column header panel for the Contact/Person Account records in the console.
			Also calculates the AverageCallTime for the Contact/Person Account.
Used By:    ContactHeaderPanelComponent_v2.component         
History:
--------------------------------------------------
29.04.2014  Amy.Tran@bluewolf.com  Created
May-2015:  scherukuwada@salesforce.com  Added LIMIT 100
22.07.2015 nandan.narasappa@auspost.com.au Added VIP field in contact query
17/08/2017 dilshan.egodawela@auspost.com Added Method to calculate minimum loa value
12/09/2017 nathan.franklin@auspost.com.au Replaced calcHistory with select count() rather than selecting all cases
									& prevented contId/recId set method being fired twice unless the id changes
2020-04-19 snigdha.sahu@auspost.com.au - REQ2140009 : Updated Phone number to be fetched
2020-06-11 Disha.Kariya@auspost.com.au - MW0003891  : Updated to use response from maritz for business contacts and from NPS Survey for consumers
2021-05-12	Madhuri.awasthi@auspost.com.au			: Add a preferred name field in contact areas of Salesforce (REQ2476162)
2023-08-18    Boris Bachovski 						: Add Closed Account info (Flag, Reason and Date) for closed accounts.
2023-10-02    Boris Bachovski    					: Refactor to use IsInactiveCustomer__c instead of is_Inactive_Customer__c
**************************************************/

public with sharing class ContactHeaderPanelComponentCont_v2 {
	//private Set<String> enterpriseTiers = new Set<String> {'Enterprise', 'Large Account', 'Business Partners'};

	public Id contId {
		get;
		set {
			if (value != null && value != contId) {
				contId = value;
				setContact();
				setIsPersonAccount();
				calcHistory();
				calcMoney();
				setNPS();
				setCreditStatus();
				setReportIds();
				//setCustomerTier();
				checkCallbackReminder(); //.. count Total number of Callback Resminder (@author: rajesh.punjabi@mav3rik.com)
			}
		}
	}

	public String recId {
		get;
		set {
			if (value != null && value != recId) {
				recId = value;
				setContactId();
			}
		}
	}

	public transient Contact contactRec { get; private set; }

	public transient Boolean isPersonAccount { get; private set; }

	public transient Integer activityCount { get; private set; }
	public transient Integer caseOpen { get; private set; }
	public transient Integer caseTotal { get; private set; }

	public transient Decimal compensationTotal { get; private set; }
	public transient Integer compensationCount { get; private set; }
	public transient Decimal revenueForCurrentFY { get; private set; }
	public transient Integer callbackCount { get; private set; }

	public transient Integer creditStatusTrueCount { get; private set; }
	public transient Integer creditStatusFalseCount { get; private set; }

	public transient String activitiesReportID { get; private set; }
	public transient String casesReportID { get; private set; }
	public transient String compensationReportID { get; private set; }
	public transient String creditStatusReportID { get; private set; }

	public transient Decimal npsResponse { get; private set; }

	public transient String customerTier { get; private set; }
	public decimal minLOA { get; set; }

	public ContactHeaderPanelComponentCont_v2() {
		setMinLOA();
	}

	private void setContactId() {
		if (recId != null) {
			if (recId.startsWith(Case.SObjectType.getDescribe().getKeyPrefix())) {
				List<Case> caseContact = [SELECT ContactId FROM Case WHERE Id = :recId];
				//Adding additional check that the Case Contact is returned, Salesforce Internal Error was detected in Summer 14.
				if (caseContact.size() > 0) {
					contId = caseContact[0].ContactId;
				}
				//Else will be null and a page message displayed
			} else {
				if (recId.startsWith(Account.SObjectType.getDescribe().getKeyPrefix())) {
					List<Account> accList = [SELECT PersonContactId FROM Account WHERE Id = :recId];
					if (accList.size() > 0) {
						contId = accList[0].PersonContactId;
					}
				} else if (recId.startsWith(Contact.SObjectType.getDescribe().getKeyPrefix())) {
					contId = recId;
				}
			}
		}
	}
	public void setMinLOA() {
		List<LOA_Settings__c> loas = LOA_Settings__c.getall().values();
		List<decimal> b = new List<decimal>();
		for (LOA_Settings__c a : loas) {
			b.add(a.LOA_Value__c);
		}
		b.sort();
		if (!b.isEmpty()) {
			minLOA = b.get(0);
		}
	}

	private void setIsPersonAccount() {
		isPersonAccount = false;
		if (contactRec != null) {
			List<Account> acctList = [SELECT isPersonAccount FROM Account WHERE PersonContactId = :contId OR Id = :contactRec.AccountId LIMIT 1];
			if (acctList.size() > 0) {
				isPersonAccount = acctList[0].isPersonAccount;
			}
		}
	}

	private void setContact() {
		/* Snigdha : Added Phone field to be fetched for Contact */
		List<Contact> contList = [
			SELECT Salutation, Name, Email,Preferred_Name__c, MobilePhone, HomePhone, Phone, Fax, MailingStreet, MailingStreet2__c, MailingCity, MailingPostalCode, MailingState,
				MailingCountry, MailingDPID__c, Individual_Number__c, Birthdate, Birth_Place__c, AccountId, Account.Name,
				Account.AccountNumber, Account.Type, Account.ServiceSLA__c, Account.Role_Type_Roll_Up__c, APCN__c, Special_Treatment_Notes__c, SpecialTreatment__c, CRMCSSOID__c,
				ServiceType__c, Account.IsPersonAccount, Account.IsVIP__c, Account.LevelOfAssurance__pc,   // Nandan N - 22/07/2015 : Added VIP fields for Icon
				IsInactiveCustomer__c, ClosedDateTime__c, ClosedReason__c
			FROM Contact
			WHERE Id = :contId
		];
		if (contList.size() > 0) {
			contactRec = contList[0];
		}
	}

	/**
	 * Grabs a list closed and opened cases and activities to be displayed in the VF page.
	 */
	private void calcHistory() {
		caseTotal = [Select COUNT() From Case Where ContactId = :contId];
		caseOpen = [Select COUNT() From Case Where ContactId = :contId And IsClosed = false];

		activityCount = [SELECT count() FROM Task WHERE WhoId = :contId];
	}

	private void calcMoney() {
		List<Compensation__c> compList = [SELECT Total_Compensation_Amount__c FROM Compensation__c WHERE Case__r.ContactId = :contId];
		compensationTotal = 0;
		compensationCount = 0;
		for (Compensation__c c : compList) {
			if (c.Total_Compensation_Amount__c != null) {
				compensationTotal += c.Total_Compensation_Amount__c;
			}
			CompensationCount++;
		}

		if (!isPersonAccount && contactRec != null) {
			List<Account> acctList = [SELECT Total_Actual_Revenue__c FROM Account WHERE Id = :contactRec.AccountId];
			if (acctList.size() > 0) {
				revenueForCurrentFY = acctList[0].Total_Actual_Revenue__c;
			}
		}
	}
	
	private void checkCallbackReminder() {
		Id SSSW_Callback_ReminderId = Utility.getRecordTypesAsIdByDevName('Callback_Request__c', 'SSSW_Callback_Reminder');
		
		List<AggregateResult> AggregateResultList = [SELECT Count(Id) ctr FROM Callback_Request__c WHERE RecordTypeId=: SSSW_Callback_ReminderId AND Status__c != 'Closed' AND CaseId__r.ContactId = :contId];
		 
		if(AggregateResultList != null && AggregateResultList.size() > 0){
			callbackCount = (integer) AggregateResultList[0].get('ctr');
		}
	}

	private void setNPS() {
		//Added below condition to display NPS score from MaritzCX for Business Contact in contact panel
		//Display average of NPS score from NPS Survey object for consumer
		if(contactRec !=null && !contactRec.Account.IsPersonAccount){
		  AggregateResult[] ar = [
			  SELECT AVG(MaritzCX__Key_Metric_1__c) avg
			  FROM MaritzCX__Survey_Response__c
			  WHERE MaritzCX__Case_Id__r.ContactId = :contId OR MaritzCX__Contact_Id__c = :contId
		  ];
		  npsResponse = (Decimal) ar[0].get('avg');
		}
		else {
			AggregateResult[] ar = [
				SELECT AVG(NPS_Score__c) avg
				FROM NPSSurvey__c
				WHERE Case__r.ContactId = :contId OR Contact__c = :contId
			];
			npsResponse = (Decimal) ar[0].get('avg');
		}
	}

	private void setCreditStatus() {
		creditStatusTrueCount = 0;
		creditStatusFalseCount = 0;
		if (contactRec != null) {
			List<Billing_Account__c> billAcctList = [SELECT Credit_Status__c FROM Billing_Account__c WHERE Organisation__c = :contactRec.AccountId AND PAYER_ACCOUNT_ID__c = null];
			for (Billing_Account__c ba : billAcctList) {
				if (ba.Credit_Status__c) {
					creditStatusFalseCount++;
				} else {
					creditStatusTrueCount++;
				}
			}
		}
	}

	private void setReportIds() {
		List<CustomerHeaderSettings__c> custHeadSettingsList = [SELECT ActivitiesReportID__c, CasesReportID__c, CompensationReportID__c, CreditStatusReportID__c FROM CustomerHeaderSettings__c LIMIT 100];
		if (custHeadSettingsList.size() > 0) {
			activitiesReportID = custHeadSettingsList[0].ActivitiesReportID__c;
			casesReportID = custHeadSettingsList[0].CasesReportID__c;
			compensationReportID = custHeadSettingsList[0].CompensationReportID__c;
			creditStatusReportID = custHeadSettingsList[0].CreditStatusReportID__c;
		}
	}
	
	/*private void setCustomerTier() {
		String customerType = contactRec.Account.Type;
		
		if (customerType == 'Consumer' || isPersonAccount) {
			customerTier = 'Consumer';
		} else if (enterpriseTiers.contains(customerType)) {
			customerTier = 'Enterprise';
		} else {
			customerTier = 'SMB';
		}
	}*/
}