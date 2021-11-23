/**************************************************
Type:       |
Purpose:    |
Used By:
History:
--------------------------------------------------
2017-09-17  nathan.franklin@auspost.com.au add clear values for left and right details lists incase the component is repopulated
**************************************************/

public class TIBCOTrackingResultComponentCont
{
	public List<FieldValueDisplay> leftDetailsList {get;set;}
	public List<FieldValueDisplay> rightDetailsList {get;set;}
	TIBCOTrackingResultWrapper boundTracking;
	public Contact consignmentReceiver {get;set;}
	public Contact consignmentSender {get;set;}
	public string lodgementDateString {get;set;}
	
	public TIBCOTrackingResultWrapper getboundTracking() 
	{
		return boundTracking;
	}	
	
	public void setboundTracking(TIBCOTrackingResultWrapper value) 
	{
		boundTracking = value;
		leftDetailsList.clear();
		rightDetailsList.clear();
		setFieldValueDisplays();
	}
	
	void setFieldValueDisplays()
	{
		if (boundTracking != null && boundTracking.consignmentDetails != null && leftDetailsList.size() == 0 && rightDetailsList.size() == 0)
		{
			lodgementDateString = '';			
			
			if (boundTracking.consignmentDetails.proxyConsignment.ArticleLodgementDate__c != null)
			{
				Datetime lodgementDate = Datetime.newInstance(boundTracking.consignmentDetails.proxyConsignment.ArticleLodgementDate__c, Time.newInstance(1, 0, 0, 0));
				lodgementDateString = lodgementDate.format('yyyy-MM-dd');
			}
			
			ID receiverContactID = Util.contactIDForNameAndEmail(boundTracking.consignmentDetails.proxyConsignment.ReceiverName__c, boundTracking.consignmentDetails.proxyConsignment.ReceiverEmail__c);
			if (receiverContactID != null)
			{
				system.debug('############## receiverContactID: ' + receiverContactID);
				consignmentReceiver = [select Name from Contact where id =:receiverContactID limit 1];
			}
			
			ID senderContactID = Util.contactIDForNameAndEmail(boundTracking.consignmentDetails.proxyConsignment.SenderName__c, boundTracking.consignmentDetails.proxyConsignment.SenderEmail__c);
			if (senderContactID != null)
			{
				system.debug('############## senderContactID: ' + senderContactID);
				consignmentSender = [select Name from Contact where id =:senderContactID limit 1];
			}
			
			List<FieldValueDisplay> l = new List<FieldValueDisplay>();
			if (boundTracking.consignmentDetails.proxyConsignment.ArticleID__c != null)
			{
				l.add(new FieldValueDisplay('ConsignmentID','Consignment ID', boundTracking.consignmentDetails.proxyConsignment.ArticleID__c));
			}
			
			if (boundTracking.consignmentDetails.proxyConsignment.ArticleLodgementDate__c != null){
				l.add(new FieldValueDisplay('ConsignmentDateTime', 'Consignment Date/Time', boundTracking.consignmentDetails.proxyConsignment.ArticleLodgementDate__c.format()));
			}
			
			if (boundTracking.consignmentDetails.proxyConsignment.ActualWeight__c != null){
				l.add(new FieldValueDisplay('TotalWeight','Total Weight', boundTracking.consignmentDetails.proxyConsignment.ActualWeight__c));
			}
			
			for (Schema.FieldSetMember fm : SObjectType.Article__c.FieldSets.SAP_EM_Panel_Consignment_View.getFields()) 
			{
				Object o = boundTracking.consignmentDetails.proxyConsignment.get(fm.getFieldPath());
				if (canDisplayField(fm.getFieldPath(), o)){
					l.add(new FieldValueDisplay(fm.getFieldPath(), fm.getLabel(), o));
				}
			}		
			
			integer index = 0;
			for (FieldValueDisplay d : l)
			{
				if (Math.mod(index,2) == 0)
				{
					leftDetailsList.add(d);
				}
				else
				{
					rightDetailsList.add(d);
				}
				index++;
			}
		}
	}
	
	private Boolean canDisplayField(String fieldName, Object value) 
	{
		if (fieldName == 'SignatureRequiredFlag__c')
		{
			return value == true;
		}
		else
		{
			return value != null;
		}
	}
	
	public TIBCOTrackingResultComponentCont()
	{
		leftDetailsList = new List<FieldValueDisplay>();
		rightDetailsList = new List<FieldValueDisplay>();		
	}
}