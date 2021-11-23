/**************************************************
Type:       Visualforce controller
Purpose:    Provides the controller logic to create the five column header panel for the Contact/Person Account records in the console.
			Also calculates the AverageCallTime for the Contact/Person Account.
Used By:    ContactHeaderPanelComponent.component         
History:
--------------------------------------------------
08.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

public with sharing class ContactHeaderPanelComponentCont 
{	
	public Id contId 
	{
		get;
		set
		{
			if (value != null) 
			{
				contId = value;
				setContact();
				calcAverageCallTime();
				setIsPersonAccount();
				setLastCallProduct();
			}
		}
	}
	
	public String recId
	{
		get;
		set
		{
			if (value != null) 
			{
				recId = value;
				setContactId();
			}
		}
	}
	
	public Contact contactRec
	{
		get;
		private set;
	}
	
	public Boolean isPersonAccount
	{
		get;
		private set;
	}
	
	public String averageCallTime
	{
		get;
		private set;
	}
	
	public Integer npsResponse
	{
		get
		{
			return (Integer)(Math.random()*10);
		}
		set;
	}
	
	public String lastCallProduct
	{
		get;
		private set;
	}
	
	public ContactHeaderPanelComponentCont() 
	{		
	}
	
	private void setContactId() 
	{
		if (recId != null) 
		{
			if (recId.startsWith(Account.SObjectType.getDescribe().getKeyPrefix())) 
			{
				List<Account> accList = [SELECT PersonContactId FROM Account WHERE Id = :recId];
				if (accList.size() > 0) 
				{
					contId = accList[0].PersonContactId;
				}
			} else if (recId.startsWith(Contact.SObjectType.getDescribe().getKeyPrefix())) {
				contId = recId;
			}
		}
	}
	
	private void setIsPersonAccount()
	{
		isPersonAccount = [SELECT count() FROM Account WHERE PersonContactId = :contId] > 0;
	}
	
	private void setContact()
	{	
		List<Contact> contList = [SELECT Salutation, Name, Email, MobilePhone, Phone, Fax, MailingStreet, MailingCity, MailingPostalCode, MailingCountry, MailingDPID__c, Individual_Number__c, Birthdate, Birth_Place__c, Account.AccountNumber, APCN__c  FROM Contact WHERE Id = :contId];
		if (contList.size() > 0) 
		{
			contactRec = contList[0];
		}
	}
	
	private void calcAverageCallTime() 
	{
		AggregateResult[] ar = [SELECT AVG(CallDurationInSeconds) aveg
								FROM Task 
								WHERE WhoId = :contId AND RecordType.DeveloperName = :Constants.RECORDTYPE_NAME_TASK_SSSWCALL];
		averageCallTime = '00:00 mins';
		if (ar.size() > 0) 
		{
			Decimal avgTimeInSec = (Decimal) ar[0].get('aveg'); 
			if (avgTimeInSec != null) 
			{
				Integer mins = Integer.valueOf(avgTimeInSec/60);
				Integer secs =  Math.mod(Integer.valueOf(avgTimeInSec), 60);
				averageCallTime = mins + ':' + (secs < 10 ? '0' : '') + secs + ' mins';
			}
		}
	}
	
	private void setLastCallProduct()
	{
		lastCallProduct = '';
		List<Task> tasks = [SELECT Product_Category__c 
							FROM Task 
							WHERE WhoId = :contId 
								AND RecordType.DeveloperName = :Constants.RECORDTYPE_NAME_TASK_SSSWCALL 
								AND Product_Category__c != null 
							ORDER BY CreatedDate DESC 
							LIMIT 1];
		if (tasks.size() > 0) 
		{
			lastCallProduct = tasks[0].Product_Category__c;
		}
	}
}