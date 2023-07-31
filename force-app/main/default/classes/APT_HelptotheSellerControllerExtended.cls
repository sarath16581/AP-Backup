/**
Description:This apex class is extension class for APT_HelptotheSellerExtended page
Created By:Nasir Jawed
Created Date:17-03-2023
Last Modified By:
Last Modified Date:
@changelog:
2023.04.19 Ken McGuire  Proposal field migration to opportunity
*/

public with sharing class APT_HelptotheSellerControllerExtended{
	/**
	*This method gets calling from sendForESignatureLWC lightning page and is used get Key contact and Opportunity driver record from Opportunity.
	*@param String contractId
	*@return
	*/

	@AuraEnabled
	public static map<string,List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>> getContractRecord(ID recordId){
		try{
			ID keyContact;
			ID oppDriver;
			string contactName;
			string userName;
			map<String,List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>> sobjmap=new map<String,List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>>();
			List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> recipientSalesUserList =new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
			List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> recipientContactList =new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
			List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> recipientCCList =new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
			List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> docRecipient = new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
			//getting the recordTypeId for DocusignRecipient object for record Type User and Customer
			string contactRecordTypeId =Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Customer (Contact)').getRecordTypeId();
			string userRecordTypeId =Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Sales Professional (User)').getRecordTypeId();
			//Using selector to query the agreement record by using agreement id and getting relationship field from opportunity
			Apttus__APTS_Agreement__c agreementRec =ApttusContractsSelector.newInstance().selectById(new Set<Id>{recordId},new Set<Object>{ApttusContractsSelector.Options.WITH_OPPORTUNITY}).values()[0];

			keyContact =agreementRec.Apttus__Related_Opportunity__r.KeyContact__c;
			oppDriver =agreementRec.Apttus__Related_Opportunity__r.OwnerId;

			//querying the contact record by passing key contact field from opportunity
			Contact con =ContactsSelector.newInstance().selectById(new Set<Id>{keyContact}).values();
			contactName = con.FirstName +' '+con.LastName;
			//querying the User record by passing opportunity driver field from opportunity
			User ur =UsersSelector.newInstance().selectById(new Set<Id>{oppDriver}).values();
			userName = ur.FirstName +' '+ur.LastName;
			//Using selector to query the Docusign recipients record by using agreement id
			docRecipient = APT_DocuSignDefaultRecipient2Selector.newInstance().selectByAgreementId(new Set<Id>{recordId});

			//checking if the size of the recipients record id zero,if its zero create recipients else return map
			if(docRecipient.size() == 0){
				//create recipients record for User record type
				Apttus_DocuApi__DocuSignDefaultRecipient2__c user= new Apttus_DocuApi__DocuSignDefaultRecipient2__c();
				user.Apttus_DocuApi__UserId__c =ur.id;
				user.APT_Name__c = userName;
				user.Apttus_DocuApi__RecipientType__c = APT_Constants.Signer;
				user.Apttus_DocuApi__SigningOrder__c = 1;
				user.APT_Docusign_Recipient_Type__c = APT_Constants.APT_DOCUSIGN_RECIPIENTS_TYPE_SALES_USER;
				user.Apttus_DocuApi__Email__c = ur.email;
				user.Apttus_CMDSign__AgreementId__c=recordId;
				user.recordTypeId = userRecordTypeId;
				recipientSalesUserList.add(user);
				ApplicationDatabase.getInstance().dmlInsert(recipientSalesUserList);
				sobjmap.put('user',recipientSalesUserList);

				//create recipients record for customer record type
				Apttus_DocuApi__DocuSignDefaultRecipient2__c contact= new Apttus_DocuApi__DocuSignDefaultRecipient2__c();
				contact.Apttus_DocuApi__ContactId__c = con.id;
				contact.APT_Name__c = contactName;
				contact.Apttus_DocuApi__RecipientType__c = APT_Constants.Signer;
				contact.Apttus_DocuApi__SigningOrder__c = 1;
				contact.APT_Docusign_Recipient_Type__c = APT_Constants.APT_DOCUSIGN_RECIPIENTS_TYPE_CUSTOMER;
				contact.Apttus_DocuApi__Email__c = con.email;
				contact.Apttus_CMDSign__AgreementId__c = recordId;
				contact.recordTypeId = contactRecordTypeId;
				recipientContactList.add(contact);
				ApplicationDatabase.getInstance().dmlInsert(recipientContactList);
				sobjmap.put('contact',recipientContactList);
				return sobjmap;
			}else{
				for(Apttus_DocuApi__DocuSignDefaultRecipient2__c docReci : docRecipient){

					if(docReci.Apttus_DocuApi__RecipientType__c == APT_Constants.Signer && docReci.APT_Docusign_Recipient_Type__c == APT_Constants.APT_DOCUSIGN_RECIPIENTS_TYPE_SALES_USER){
						recipientSalesUserList.add(docReci);
						sobjmap.put('user',recipientSalesUserList);
					}
					if(docReci.Apttus_DocuApi__RecipientType__c == APT_Constants.APT_CARBON_COPY && docReci.APT_Docusign_Recipient_Type__c == APT_Constants.APT_DOCUSIGN_RECIPIENTS_TYPE_SALES_USER){
						recipientCCList.add(docReci);
						sobjmap.put('cc',recipientCCList);
					}
					if(docReci.Apttus_DocuApi__RecipientType__c == APT_Constants.Signer && docReci.APT_Docusign_Recipient_Type__c == APT_Constants.APT_DOCUSIGN_RECIPIENTS_TYPE_CUSTOMER){
						recipientContactList.add(docReci);
						sobjmap.put('contact',recipientContactList);
					}
					if(docReci.Apttus_DocuApi__RecipientType__c == APT_Constants.APT_CARBON_COPY && docReci.APT_Docusign_Recipient_Type__c == APT_Constants.APT_DOCUSIGN_RECIPIENTS_TYPE_CUSTOMER){
						recipientCCList.add(docReci);
						sobjmap.put('cc',recipientCCList);
					}

				}
				return sobjmap;
			}
		}
		catch(Exception e){
			return null;
		}
	}

	/**
	*This method gets called from SendForESignatureLWC lightning page and it updated the recordtypeid for user, so a new carbon copy user can created.
	*@param recordType
	*@return id RecordTypeID
	*/
	@AuraEnabled
	public static Id addCC(string recordType){
		ID recordTypeId;
		//getting the record Type Id for record Types
		if(recordType == APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_USER){
			recordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Sales Professional (User)').getRecordTypeId();
			return recordTypeId;
		}
		if(recordType == APT_Constants.APT_Contact_RECORDTYPE){
			recordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Customer (Contact)').getRecordTypeId();
			return recordTypeId;
		}
		if(recordType == APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_EMAIL){
			recordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Email(Manually enter the customer details)').getRecordTypeId();
			return recordTypeId;
		}
		return null;

	}

	/**
	*This method gets called from SendForESignatureLWC lightning page and pass the record id for Carbon Copy user which needs to be deleted.
	*@param deleted record ID
	*@return Boolean
	*/
	@AuraEnabled
	public static boolean deleteCC(string id){
		boolean deleted = false;
		List<Database.DeleteResult> docuSignReciDelete = new List<Database.DeleteResult>();
		List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> docRecipientToDeletList = new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
		//Querying the record for deletion
		Apttus_DocuApi__DocuSignDefaultRecipient2__c docRecipientToDelete = APT_DocuSignDefaultRecipient2Selector.newInstance().selectById(new Set<Id>{id})[0];
		docRecipientToDeletList.add(docRecipientToDelete);
		//deletion of record
		docuSignReciDelete = ApplicationDatabase.getInstance().dmldelete(docRecipientToDeletList);
		for (Database.DeleteResult sr : docuSignReciDelete) {
			if (sr.isSuccess()) {
				deleted = true;
			}
		}
		return deleted;
	}

	/**
	*This method gets called from SendForESignatureLWC lightning page and pass the record id for Carbon Copy user which needs to be edited.
	*@param edited Record Id
	*@return RecordType
	*/
	@AuraEnabled
	public static string editCC(string id){
		string recordTypeName;
		//Getting the record id for each record types
		string contactRecordTypeId =Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Customer (Contact)').getRecordTypeId();
		string userRecordTypeId =Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Sales Professional (User)').getRecordTypeId();
		string emailRecordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Email(Manually enter the customer details)').getRecordTypeId();
		//Querying the record for editing for each record Type
		Apttus_DocuApi__DocuSignDefaultRecipient2__c docRecipientToEdit = APT_DocuSignDefaultRecipient2Selector.newInstance().selectById(new Set<Id>{id})[0];
		if(docRecipientToEdit.recordTypeId == emailRecordTypeId){
			recordTypeName = APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_EMAIL;
		}
		if(docRecipientToEdit.recordTypeId == userRecordTypeId){
			recordTypeName = APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_USER;
		}
		if(docRecipientToEdit.recordTypeId == contactRecordTypeId){
			recordTypeName = APT_Constants.APT_Contact_RECORDTYPE;
		}
		return recordTypeName;
	}
}