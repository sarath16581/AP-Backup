/**************************************************
Type:       Visualforce controller
Purpose:    Provides logic to create the related lists to show on the Interaction view
Used By:    ContactInteractionViewComponent.component         
History:
--------------------------------------------------
22.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

public with sharing class ContactInteractionViewComponentCont {
	
	public Id contId 
	{
		get;
		set
		{
			if (value != null) 
			{
				contId = value;
				setIsPersonAccount();
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
	
	public Id persAccId 
	{
		get; 
		private set;
	}
	
	public Boolean isPersonAccount
	{
		get;
		private set;
	}
	
	public ContactInteractionViewComponentCont() 
	{
		recId = ApexPages.currentPage().getParameters().get('id');
	}
	
	public Component.Apex.OutputPanel getRelatedLists()
	{		
		List<InteractionViewRelatedListSettings__c> listSettings = sortList(InteractionViewRelatedListSettings__c.getAll().values());
		
		Component.Apex.OutputPanel op = new Component.Apex.OutputPanel();
		
		Id subject = isPersonAccount != null && isPersonAccount ? persAccId : contId;
		
		for (InteractionViewRelatedListSettings__c s : listSettings) {
			if (!s.HideList__c) {
				op.childComponents.add(RelatedListComponent.getRelatedList(subject, contId, s));
			}
		}
		
		return op;
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
		List<Account> accList = [SELECT Id FROM Account WHERE PersonContactId = :contId];
		if (accList.size() > 0) 
		{
			isPersonAccount = true;
			persAccId = accList[0].Id;	
		}
		else
		{
			isPersonAccount = false;
		}
	}
	
	private List<InteractionViewRelatedListSettings__c> sortList(List<InteractionViewRelatedListSettings__c> listSettings) {
		List<ComparableSObjectWrapper> wrapperList = new List<ComparableSObjectWrapper>();
		for (InteractionViewRelatedListSettings__c s : listSettings) {
			wrapperList.add(new ComparableSObjectWrapper(s, 'DisplayOrder__c'));
		}
		wrapperList.sort();
		
		List<InteractionViewRelatedListSettings__c> sortedList = new List<InteractionViewRelatedListSettings__c>();
		for (ComparableSObjectWrapper w : wrapperList) {
			sortedList.add((InteractionViewRelatedListSettings__c)w.sObj);
		}
		return sortedList;
	}
}