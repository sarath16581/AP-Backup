/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description Helper for createBillingAccount component and used for creating the billing account request
 * @changelog
 * 2020-11-23 - arjun.singh@auspost.com.au - Created
 * 2021-04-12 - seth.heang@auspost.com.au - updated wrapper class to reflect the latest request payload structure
 * 2021-05-2021 - avula.jansirani@auspost.com.au - added 'bankAccounts', 'industryId','entityType' in 'CustomerDetail' class 
 * 2022-08-04 - Seth Heang - Update wrapper with additional rating plan payload definition
 */
public with sharing class BillingAccountWrapper {

    @AuraEnabled
    public String orgRecordId;
    @AuraEnabled
    public String requestObjId;
    @AuraEnabled
    public String transactionId; 
    @AuraEnabled
    public String processType; 
    @AuraEnabled
    public String processTypeDesc;
    @AuraEnabled
    public String targetSystem;
    @AuraEnabled
    public SAPsystem sap;
    @AuraEnabled
    public CompassContractActivation ratingPlanActivation;
    @AuraEnabled
    public String customerId;

    public class communicationInfoDetail{
        @AuraEnabled
        public String email;
        @AuraEnabled
        public String mobile;
        @AuraEnabled
        public String phone;
    }

    public class lodgementPointsDetail{
        @AuraEnabled
        public String lodgementPointId;
    }

    public class creditControlsDetail{
        @AuraEnabled
        public String creditAssessNo;
        @AuraEnabled
        public String creditGroup;
        @AuraEnabled
        public String creditLimit;
        @AuraEnabled
        public String creditRepCode;
        @AuraEnabled
        public String creditRepName;
    }
 
    //Characteristics Details
    public class CharacteristicsDetail{        
        @AuraEnabled
        public Boolean elmsFlag;
        @AuraEnabled
        public Boolean pcmsCustManif;
        @AuraEnabled
        public Boolean pcmsDelPartCons;
        @AuraEnabled
        public Boolean pcmsFlag;
        @AuraEnabled
        public Boolean pcmsMerchBarcode;
    }
    
    public class childAccountDetail{
        @AuraEnabled
        public String name1;
        @AuraEnabled
        public String name2;
        @AuraEnabled
        public String objectId;
        @AuraEnabled
        public String objectType;
        @AuraEnabled
        public CharacteristicsDetail characteristics;
        @AuraEnabled
        public addressInfoDetail addressInfo;
        @AuraEnabled
        public communicationInfoDetail communicationInfo;
        @AuraEnabled
        public List<lodgementPointsDetail> lodgementPoints;
        @AuraEnabled
        public List<ContactDetail> contactPersons;
    }

    //Contact Details
    public class ContactDetail{
        @AuraEnabled
        public communicationInfoDetail communicationInfo;
        @AuraEnabled
        public String contactPersonId;
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String lastName;
    }
    
    public class addressInfoDetail{
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String country;
        @AuraEnabled
        public String postcode;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String street;
    }

    public class CustomerDetail {
        @AuraEnabled    
        public String abn;
        @AuraEnabled
        public String accountGroup;
        @AuraEnabled
        public String acn;
        @AuraEnabled
        public String customerId;
        @AuraEnabled
        public String parentBillingAccNo;
        @AuraEnabled
        public addressInfoDetail addressInfo;
        @AuraEnabled
        public CharacteristicsDetail characteristics;
        @AuraEnabled
        public communicationInfoDetail communicationInfo;
        @AuraEnabled
        public List<childAccountDetail> childAccount;
        @AuraEnabled
        public creditControlsDetail creditControls;
        @AuraEnabled
        public List<lodgementPointsDetail> lodgementPoints;
        @AuraEnabled
        public List<ContactDetail> contactPersons;
        @AuraEnabled
        public String name1;
        @AuraEnabled
        public String name2;
        @AuraEnabled
        public String name3;
        @AuraEnabled
        public String name4;
        @AuraEnabled
        public String objectId;
        @AuraEnabled
        public String objectType;
        @AuraEnabled                              
        public List<BankAccount> bankAccounts;
        @AuraEnabled   
        public String industryId;
        @AuraEnabled   
        public String entityType;
    }
    
    public class BankAccount{    
        public String accountHolderName; 
        public String bankAccountNo;
        public String bankStateBranch;
    }

    // SAP layer
    public class SAPsystem{
        @AuraEnabled
        public CustomerDetail customer;
    }

    public BillingAccountWrapper(){
        sap = new SAPsystem();
        sap.customer = new CustomerDetail();
        sap.customer.addressInfo = new addressInfoDetail();
        sap.customer.characteristics = new CharacteristicsDetail();
        sap.customer.creditControls = new creditControlsDetail();
        sap.customer.lodgementPoints = null;
        sap.customer.contactPersons = new List<ContactDetail>();
        sap.customer.communicationInfo = new communicationInfoDetail();
        sap.customer.childAccount = new List<childAccountDetail>();
        ratingPlanActivation = new CompassContractActivation();
    }

	public class CompassContractActivation{
		@AuraEnabled
		public String quoteId;
		@AuraEnabled
		public List<ratingPlanCustomer> customer;
		@AuraEnabled
		public List<eventData> eventData;
	}

	public class ratingPlanCustomer{
		@AuraEnabled
		public String objectType;
		@AuraEnabled
		public String objectId;
		@AuraEnabled
		public String ratingPlanId;
		@AuraEnabled
		public String requestObjId;
	}

	public class eventData{
		@AuraEnabled
		public String action;
		@AuraEnabled
		public String actionId;
		@AuraEnabled
		public data data;
	}

	public class data{
		@AuraEnabled
		public String ratingPlanId;
		@AuraEnabled
		public String customer;
		@AuraEnabled
		public String validFrom;
		@AuraEnabled
		public String validTo;
		@AuraEnabled
		public String newValidTo;
		@AuraEnabled
		public String ratingModel;
		@AuraEnabled
		public String ratingGroup;
		@AuraEnabled
		public String contractRef;
		@AuraEnabled
		public String weightRounding;
		@AuraEnabled
		public String status;
		@AuraEnabled
		public String description;
		@AuraEnabled
		public String cubingFlag;
		@AuraEnabled
		public String cubicConvFac;
		@AuraEnabled
		public String cubicDWTConvFac;
		@AuraEnabled
		public List<item> item;
	}

	public class item{
		@AuraEnabled
		public String ratingPlanItemId;
		@AuraEnabled
		public String rateCardCategory;
		@AuraEnabled
		public String lodgementZoneType;
		@AuraEnabled
		public String destinationZoneType;
		@AuraEnabled
		public String customerTier;
		@AuraEnabled
		public String customRef;
		@AuraEnabled
		public List<feature> features;
    }

	public class feature{
		@AuraEnabled
		public String pricePoint;
		@AuraEnabled
		public Integer totDeclaredCover;
	}

    public BillingAccountWrapper(boolean subAccount){
        if(subAccount){
            sap = new SAPsystem();
            sap.customer = new CustomerDetail();
            sap.customer.childAccount = new List<childAccountDetail>();
        }
    }
}