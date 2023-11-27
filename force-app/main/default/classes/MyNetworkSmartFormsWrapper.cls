/**
  * @author       : Rajesh Punjabi
  * @date         : 01/06/2019
  * @description  : Wrapper class for the MyNetwork SmartForms

--------------------------------------- History --------------------------------------------------
01.06.2019    Rajesh Punjabi(Mav3rik)    Created
07.02.2020    Gunith Devasurendra        REQ2086450: Add PhotoId field
22.03.2021    Suman Gunaganti            added wine damages instructions fields
26.03.2021    Madhuri Awasthi            REQ2447384 - Adding new Wine damages fields
**/

public class MyNetworkSmartFormsWrapper {
	//..
	public String formId;
	public String articleId;
	public Id caseRecordTypeId;
	public String caseType;
	public String enquiryLinkedArticle;
	
	//.. eParcel Fields
	public String senderCompany;
	public String senderEmail;
	public String senderName;
	
	public String cartonInadequecyDetails;
	
	public String damageDetails{
		get{
			if(String.isBlank(damageDetails)){return '';}
			return damageDetails;}
		set;}
	
	public String damageLocation;
	public String dividerInadequecyDetails;
	public String doesContainWine;
	public String facilityId;
	public String facilityName;
	public String howDamageOccured;
	public String howDamageOccuredOptionalOther;
	public String isCartonAdequate;
	public String isDividerAdequate;
	public String isPartOfConsignment;
	public String noOfCapsDamaged;
	public String noOfLabelsDamaged;
	public String totalArticlesInConsignment;
	public String totalBottlesDamaged;
	public String totalBottlesInCarton;
	public String addresseeEmail;
	public String addresseeName;
	//wine damage instructions
	public String isArticleInsured;
	public String damageInstructions;
	public String actionTaken;
	public String additionalInformation;
	//wine damages new fields 
	public String sustainedDamage;
	public String totalItemInParcel;
	public String sustainedDamageDetails;
	
	public AddressWrapper customerAddress;
	public AddressWrapper senderAddress;
	public AddressWrapper addresseeAddress;
	
	public String networkId;
	public String caseOriginator;
	public String caseLocality;
	public String damagedOrMissing;
	public String contactId;  //..contact Id
	public String FirstName;
	public String LastName;
	public String Name;
	public String MobilePhone;
	public String Email;
	public Boolean IsPersonAccount;
	public String AccountId;
	//.. Customer Referrence Number (CRN__c)
	public String custRefID;
  
	public String productCategory;
	public String productSubCategory;
	public string enquirySubType;
	

	public String typeOfDamage;
	public String contents;
	public String valueOfContents;
	public String adequatelyPackaged;
	public String isarticleonhand;
	public String compensationBeingPaid;
	public String compensationAmount;
	public String postagevalue;
	public String comments{
		get{
			if(String.isBlank(comments)){return '';}
			return comments;}
		set;}
	
	// Mail Redirection/hold fields
	public String mailRedirectOrHold;
	public String hasPhotoId;

	public String redirectComments{
		get{
			if(String.isBlank(redirectComments)){return '';}
			return redirectComments;}
		set;}
	public String mailholdComments{
		get{
			if(String.isBlank(mailholdComments)){return '';}
			return mailholdComments;}
		set;}
	
	public class AddressWrapper {
		public String addressLine1;
		public String addressLine2;
		public String city;
		public String state;
		public String postcode;
		public String countrycode;
	}
}