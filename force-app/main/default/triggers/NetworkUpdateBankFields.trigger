/**************************************************
Type:       Trigger for Network__c Object
Purpose:    To perform all action in Insert, Update & Delete of network record
History:
--------------------------------------------------
27.09.2012  BlueWolf   Created
2019-05-01  disha.kariya@auspost.com.au  Added a call to a method to update Network Manager and/or State Admin
**************************************************/
trigger NetworkUpdateBankFields on Network__c (before insert, before update)
{
	if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) 
	{
		NetworkUtil.updateBankFields(Trigger.new);
		//Update Network Manager & State Admin on Licence when changes on Facility.Network.Parent.
		if(Trigger.isUpdate) {
			NetworkUtil.updateNetworkManagerOnLicence(Trigger.New, (Map<Id, Network__c>) trigger.oldMap);
		}
	}
}