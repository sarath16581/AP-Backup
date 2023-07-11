/**
*Description: This apex class is handler class for apex trigger - APT_DocuSignRecipientTrigger.
*Created By - Mahesh Patel
*Created Date - 8th Dec, 2020
*ChangeLog : 2023-05-15 - Nasir Jawed - Added logic to populated the Fields for APT_Name on insert and update
**/
public with sharing class APT_DocuSignRecipientTriggerHandler
{
	/**
	* before insert update trigger event
	*/
	public static String beforeInsertUpdateEvent(List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> listDocuSignRecipient, Map<Id,Apttus_DocuApi__DocuSignDefaultRecipient2__c>  oldMapDocuSignRecipient)
	{
		try
		{
			//Get recordtype ids
			Contact con;
			User ur;
			string contactName;
			string userName;
			string conEmail;
			string userEmail;
			string keyContact;
			string oppDriver;
			Map<ID,RecordType> contactRecordTypeMap = new Map<ID, RecordType>();
			Map<ID,RecordType> userRecordTypeMap = new Map<ID, RecordType>();
			Map<ID,RecordType> emailRecordTypeMap = new Map<ID, RecordType>();
			contactRecordTypeMap = RecordTypesSelector.newInstance().selectByDeveloperName('Apttus_DocuApi__DocuSignDefaultRecipient2__c', new Set<String>{APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_CONTACT});
			userRecordTypeMap = RecordTypesSelector.newInstance().selectByDeveloperName('Apttus_DocuApi__DocuSignDefaultRecipient2__c', new Set<String>{APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_USER});
			emailRecordTypeMap = RecordTypesSelector.newInstance().selectByDeveloperName('Apttus_DocuApi__DocuSignDefaultRecipient2__c', new Set<String>{APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_EMAIL});

			string contactRecordTypeId = contactRecordTypeMap.values()?.get(0)?.Id;
			string userRecordTypeId = userRecordTypeMap.values()?.get(0)?.Id;
			string emailRecordTypeId = emailRecordTypeMap.values()?.get(0)?.Id;

			//List of agreement Ids
			List<string> agreementIds = new List<string>();
			for(Apttus_DocuApi__DocuSignDefaultRecipient2__c docuSignRecipient : listDocuSignRecipient)
			{
				agreementIds.add(docuSignRecipient.Apttus_CMDSign__AgreementId__c);
			}

			//Get existing docusign recipients
			List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> existingDocuSignRecipients = [SELECT Apttus_CMDSign__AgreementId__c, RecordTypeId, Apttus_DocuApi__Email__c, APT_Count_of_Contact_Records__c, APT_Count_of_User_Records__c,Apttus_DocuApi__ContactId__c,Apttus_DocuApi__UserId__c
																							FROM Apttus_DocuApi__DocuSignDefaultRecipient2__c
																							WHERE Apttus_CMDSign__AgreementId__c IN :agreementIds
																							ORDER BY CreatedDate DESC];
			//Storing the value for KeyContact and Opportunity driver
			for(Apttus_DocuApi__DocuSignDefaultRecipient2__c docSign: listDocuSignRecipient){
				if(docSign.Apttus_DocuApi__ContactId__c !=null){
					keyContact =docSign.Apttus_DocuApi__ContactId__c ;
				}
				if(docSign.Apttus_DocuApi__UserId__c!=null){
					oppDriver = docSign.Apttus_DocuApi__UserId__c;
				}
			}
			//Querying the contact record
			if(keyContact != null){
				con = ContactsSelector.newInstance().selectById(new Set<Id>{keyContact}).values();
			}
			//Querying the user record
			if(oppDriver != null){
				ur = UsersSelector.newInstance().selectById(new Set<Id>{oppDriver}).values();
			}
			//Populating the value for field APT_Name__c and Apttus_DocuApi__Email__c for User, Contact and Carboncopy
			for(Apttus_DocuApi__DocuSignDefaultRecipient2__c docSign:listDocuSignRecipient){

				if(docSign.Apttus_DocuApi__ContactId__c!=null){
					contactName = con.FirstName +' '+con.LastName;
					conEmail = con.Email;
					docSign.APT_Name__c = contactName;
					docSign.Apttus_DocuApi__Email__c = conEmail;

				}
				if(docSign.Apttus_DocuApi__UserId__c!=null){

					userName = ur.FirstName +' '+ur.LastName;
					userEmail = ur.Email;
					docSign.APT_Name__c = userName;
					docSign.Apttus_DocuApi__Email__c = userEmail;
				}
				if(docSign.Apttus_DocuApi__RecipientType__c == APT_Constants.APT_CARBON_COPY){
					if(docSign.Apttus_DocuApi__FirstName__c != null && docSign.Apttus_DocuApi__LastName__c != null){
						docSign.APT_Name__c = docSign.Apttus_DocuApi__FirstName__c +' '+ docSign.Apttus_DocuApi__LastName__c;
					}

					if(docSign.APT_Docusign_Recipient_Type__c == APT_Constants.APT_DOCUSIGN_RECIPIENTS_TYPE_SALES_USER && ur != null && docSign.Apttus_DocuApi__FirstName__c == null){
						docSign.APT_Name__c = ur.FirstName +' '+ur.LastName;
					}
					if(docSign.APT_Docusign_Recipient_Type__c == APT_Constants.APT_DOCUSIGN_RECIPIENTS_TYPE_CUSTOMER && con != null && docSign.Apttus_DocuApi__FirstName__c == null){
						docSign.APT_Name__c = con.FirstName +' '+con.LastName;
					}
				}
			}



			for(Apttus_DocuApi__DocuSignDefaultRecipient2__c docuSignRecipient : listDocuSignRecipient)
			{
				Apttus_DocuApi__DocuSignDefaultRecipient2__c oldDocuSignRecipient = oldMapDocuSignRecipient != null? oldMapDocuSignRecipient.get(docuSignRecipient.id):null;
				Decimal countOfContactRecords;
				Decimal countOfUserRecords;

				if(oldDocuSignRecipient == null || (oldDocuSignRecipient != null && oldDocuSignRecipient.Apttus_DocuApi__Email__c != docuSignRecipient.Apttus_DocuApi__Email__c))
				{
					//Increment ‘Count of Contact Records’ field when new Docusign Recipients record of record type ('Contact' is created) or
					//(‘Email' is created AND ‘Recipient Email Address’ does not contain ‘auspost’) for an Agreement
					if(docuSignRecipient.RecordTypeId == contactRecordTypeId ||
					  (docuSignRecipient.RecordTypeId == emailRecordTypeId && docuSignRecipient.Apttus_DocuApi__Email__c != null && !docuSignRecipient.Apttus_DocuApi__Email__c.toLowerCase().contains(APT_Constants.AUSPOST_EMAIL)))
					{
						for(Apttus_DocuApi__DocuSignDefaultRecipient2__c existingDocuSignRecipient: existingDocuSignRecipients)
						{
							if(existingDocuSignRecipient.Apttus_CMDSign__AgreementId__c == docuSignRecipient.Apttus_CMDSign__AgreementId__c &&
							  (existingDocuSignRecipient.RecordTypeId == contactRecordTypeId || (existingDocuSignRecipient.RecordTypeId == emailRecordTypeId && !existingDocuSignRecipient.Apttus_DocuApi__Email__c.toLowerCase().contains(APT_Constants.AUSPOST_EMAIL))) &&
							  (oldDocuSignRecipient == null || (oldDocuSignRecipient != null && oldDocuSignRecipient.Apttus_DocuApi__Email__c != null && oldDocuSignRecipient.Apttus_DocuApi__Email__c.toLowerCase().contains(APT_Constants.AUSPOST_EMAIL))))
							{
								countOfContactRecords = existingDocuSignRecipient.APT_Count_of_Contact_Records__c;
								break;
							}
						}

						//Increment count of contact record by 1
						if(countOfContactRecords != null)
						{
							docuSignRecipient.APT_Count_of_Contact_Records__c = countOfContactRecords + 1;
						}
						else
						{
							docuSignRecipient.APT_Count_of_Contact_Records__c = 1;
						}
						docuSignRecipient.APT_Count_of_User_Records__c = 0;
					}
					//Increment ‘Count of User Records’ field when new Docusign Recipients record of record type (‘User is created) or
					//(‘Email' is created AND ‘Recipient Email Address’ contains ‘auspost’) for an Agreement
					else if(docuSignRecipient.RecordTypeId == userRecordTypeId ||
						   (docuSignRecipient.RecordTypeId == emailRecordTypeId && docuSignRecipient.Apttus_DocuApi__Email__c != null && docuSignRecipient.Apttus_DocuApi__Email__c.toLowerCase().contains(APT_Constants.AUSPOST_EMAIL)))
					{
						for(Apttus_DocuApi__DocuSignDefaultRecipient2__c existingDocuSignRecipient: existingDocuSignRecipients)
						{
							if(existingDocuSignRecipient.Apttus_CMDSign__AgreementId__c == docuSignRecipient.Apttus_CMDSign__AgreementId__c &&
							  (existingDocuSignRecipient.RecordTypeId == userRecordTypeId || (existingDocuSignRecipient.RecordTypeId == emailRecordTypeId && existingDocuSignRecipient.Apttus_DocuApi__Email__c.toLowerCase().contains(APT_Constants.AUSPOST_EMAIL))) &&
							  (oldDocuSignRecipient == null || (oldDocuSignRecipient != null && !oldDocuSignRecipient.Apttus_DocuApi__Email__c.toLowerCase().contains(APT_Constants.AUSPOST_EMAIL))))
							{
								countOfUserRecords = existingDocuSignRecipient.APT_Count_of_User_Records__c;
								break;
							}
						}

						//Increment count of user record by 1
						if(countOfUserRecords != null)
						{
							docuSignRecipient.APT_Count_of_User_Records__c = countOfUserRecords + 1;
						}
						else
						{
							docuSignRecipient.APT_Count_of_User_Records__c = 1;
						}
						docuSignRecipient.APT_Count_of_Contact_Records__c = 0;
					}
				}
			}

			return APT_Constants.SUCCESS_LABEL;
		}
		catch(Exception ex)
		{
			system.debug('docuSignRecipienttrigger.Error: ' + ex.getLineNumber() + ' ' + ex.getStackTraceString()+' '+ex.getMessage());
			return ex.getMessage();
		}
	}
}