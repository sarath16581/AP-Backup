/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @description Represents request payload of the external interface for provisioning new billing accounts for StarTrack.
 *			  Please refer API spec for more details:
 *			  https://australiapost.jira.com/wiki/spaces/ISS/pages/1472954644/API+Specification+-+customer+v1+billingaccounts
 *			  Request field mapping (Salesforce):
 *			  https://australiapost.jira.com/wiki/spaces/STP/pages/2814837533/Design+OB010+Request+JSON+Mapping+Salesforce+Camunda+-+TEAM
 * @changelog
 * 2021-03-10 - shashwat.nath@auspost.com.au - Created
 * 2021-03-15 - dheeraj.mandavilli@auspost.com.au - Updated the structure based upon Teams API Spec.
 * 2023-10-30 - Ranjeewa Silva - Refactored and added new payload structure for sub accounts.
 */
public with sharing class BillingAccountWrapperForTeams {

	// identifier string to include in payload when customer organisation's ACN is blank (Account.ACN__c)
	@TestVisible private static final String REQUEST_PAYLOAD_BLANK_ACN_IDENTIFIER = '000000000';

	@AuraEnabled public String orgRecordId {get; set;}
	@AuraEnabled public String processType {get; set;}
	@AuraEnabled public String requestObjId {get; set;}
	@AuraEnabled public String targetSystem {get; set;}
	@AuraEnabled public TeamSystem team {get; set;}
	@AuraEnabled public String transactionId {get; set;}

	// no argument constructor is necessary to enable passing into an AuraEnabled method as a method parameter (LWC to Apex).
	// refer - https://salesforce.stackexchange.com/questions/354110/passing-object-from-lwc-to-apex-not-working-as-expected-class-does-not-have-no
	public BillingAccountWrapperForTeams() {
	}

	public BillingAccountWrapperForTeams(String requestObjectId, String processType) {
		this.requestObjId = requestObjectId;
		this.processType = processType;
		this.targetSystem = 'TEAM';
		this.team = new TeamSystem();
	}

	public class TeamSystem {
		@AuraEnabled public CreditDetails creditDetails {get; set;}
		@AuraEnabled public Organisations organisations {get; set;}
		@AuraEnabled public List<String> service {get; set;}
		@AuraEnabled public List<StarTrackSubAccount> followerOffspringList {get; set;}

		// no argument constructor is necessary to enable passing into an AuraEnabled method as a method parameter (LWC to Apex).
		// refer - https://salesforce.stackexchange.com/questions/354110/passing-object-from-lwc-to-apex-not-working-as-expected-class-does-not-have-no
		public TeamSystem() {
			this.followerOffspringList = new List<StarTrackSubAccount>();
		}

		public Set<Id> getSubAccountRequestIds() {
			Set<Id> subAccountRequestIds = new Set<Id>();
			for (StarTrackSubAccount subAccountRequest: this.followerOffspringList) {
				subAccountRequestIds.add(subAccountRequest.followerOffspringRequestId);
			}
			return subAccountRequestIds;
		}
	}

	public class CreditDetails{
		@AuraEnabled public String authoriser {get; set;}
		@AuraEnabled public Integer creditLimit {get; set;}
		@AuraEnabled public Integer estimatedMonthlyRevenue {get; set;}
		@AuraEnabled public Date nextRevenueDueDate {get; set;}
		@AuraEnabled public String creditOfficer {get; set;}
		@AuraEnabled public String creditAssessNo {get; set;}
	}

	public class Organisations {
		@AuraEnabled public String abn {get; set;}
		@AuraEnabled public String phone {get; set;}
		@AuraEnabled public String accountName1 {get; set;}
		@AuraEnabled public String accountName2 {get; set;}
		@AuraEnabled public String acn {get; set;}
		@AuraEnabled public Address billingAddress {get; set;}
		@AuraEnabled public Address mailingAddress {get; set;}
		@AuraEnabled public Contact primaryContact {get; set;}
		@AuraEnabled public Contact secondaryContact {get; set;}
		@AuraEnabled public Id leaderAccountRequestId {get; set;}
		@AuraEnabled public String billingAccountNo {get; set;}

		// no argument constructor is necessary to enable passing into an AuraEnabled method as a method parameter (LWC to Apex).
		// refer - https://salesforce.stackexchange.com/questions/354110/passing-object-from-lwc-to-apex-not-working-as-expected-class-does-not-have-no
		public Organisations() {
		}
		public Organisations(String abn, String acn, String accountName) {
			this.abn = abn;
			this.acn = (String.isNotBlank(acn) ? acn : REQUEST_PAYLOAD_BLANK_ACN_IDENTIFIER);
			if (String.isNotBlank(accountName)) {
				this.accountName1 = accountName;
				if (accountName.length() > 25) {
					this.accountName1 = accountName.substring(0, 25);
					this.accountName2 = accountName.substring(25);
				}
			}
		}
	}

	public class Address {
		@AuraEnabled public String addressLine1 {get; set;}
		@AuraEnabled public String addressLine2 {get; set;}
		@AuraEnabled public String suburb {get; set;}
		@AuraEnabled public Integer postcode {get; set;}

		// no argument constructor is necessary to enable passing into an AuraEnabled method as a method parameter (LWC to Apex).
		// refer - https://salesforce.stackexchange.com/questions/354110/passing-object-from-lwc-to-apex-not-working-as-expected-class-does-not-have-no
		public Address() {
		}

		public Address(String streetAddress, String suburb, String postcode, Boolean truncateStreetAddress) {
			this.addressLine1 = streetAddress;
			if (truncateStreetAddress && streetAddress != null && streetAddress.length() > 25) {
				this.addressLine1 = streetAddress.substring(0, 25);
				this.addressLine2 = streetAddress.substring(25);
			}
			this.suburb = suburb;
			this.postcode = (String.isNotBlank(postcode) ? Integer.valueOf(postcode) : null);
		}
	}

	public class Contact {
		@AuraEnabled public String email {get; set;}
		@AuraEnabled public String firstName {get; set;}
		@AuraEnabled public String jobTitle {get; set;}
		@AuraEnabled public String lastName {get; set;}
		@AuraEnabled public String phone {get; set;}
		@AuraEnabled public String salutation {get; set;}

		// no argument constructor is necessary to enable passing into an AuraEnabled method as a method parameter (LWC to Apex).
		// refer - https://salesforce.stackexchange.com/questions/354110/passing-object-from-lwc-to-apex-not-working-as-expected-class-does-not-have-no
		public Contact() {
		}

		public Contact(Schema.Contact c) {
			this.email = c.Email;
			this.firstName = c.FirstName;
			this.lastName = c.LastName;
			this.salutation = c.Salutation;
			this.jobTitle = c.Title;
			this.phone = (String.isNotBlank(c.Phone) ? c.Phone : c.MobilePhone);
		}
	}

	public class StarTrackSubAccount {
		@AuraEnabled public String accountName1 {get; set;}
		@AuraEnabled public String accountName2 {get; set;}
		@AuraEnabled public Contact primaryContact {get; set;}
		@AuraEnabled public Contact secondaryContact {get; set;}
		@AuraEnabled public String phone {get; set;}
		@AuraEnabled public Address billingAddress {get; set;}
		@AuraEnabled public Address mailingAddress {get; set;}
		@AuraEnabled public Id followerOffspringRequestId {get; set;}
		@AuraEnabled public String parentBillingAccountNo {get; set;}
		@AuraEnabled public Id parentObjectId {get; set;}

		// no argument constructor is necessary to enable passing into an AuraEnabled method as a method parameter (LWC to Apex).
		// refer - https://salesforce.stackexchange.com/questions/354110/passing-object-from-lwc-to-apex-not-working-as-expected-class-does-not-have-no
		public StarTrackSubAccount() {
		}

		public StarTrackSubAccount(Id followerOffspringRequestId, String accountName) {
			this.followerOffspringRequestId = followerOffspringRequestId;
			this.accountName1 = accountName;
			if (accountName != null && accountName.length() > 25) {
				this.accountName1 = accountName.substring(0, 25);
				this.accountName2 = accountName.substring(25);
			}
		}
	}
}