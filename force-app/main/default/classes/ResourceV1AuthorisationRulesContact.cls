/**************************************************
Description:    Web service to expose AuthRules table
Usage:          Intended purpose is for external systems to retrieve a list of Application access records relating to their specific application
History:
--------------------------------------------------
2018-03-20  dilshan.egodawela@auspost.com.au  Created
2018-04-11  nathan.franklin@auspost.com.au  Updated
2018-05-24	dilshan.egodawela@auspost.com.au Added Caching
**************************************************/
@RestResource(urlMapping='/v1.0/authorisation/rules/contact/*')
global without sharing class ResourceV1AuthorisationRulesContact {

	//wrapper classes to hold fields that are being exposed via the rest service

	//Contact block of the response
	class AuthContact {
		private String firstName { get;set; }
		private String lastName { get;set; }
		private String oidId { get;set; }
		private String id { get;set; }
	}
	//Organization block of the response
	class AuthOrganization	{
		private String id { get;set; }
		private String name { get;set; }
		private String apbcn { get;set; }
	}
	//Billing Account section of the response
	class AuthBillingAccount	{
		private String id { get;set; }
		private String name { get;set; }
		private String billingAccountNumber { get;set; }
		private String type { get;set; }
		private String sourceSystem {get; set; }
	}
	//Location section of the response
	class AuthLocation {
		private String id { get;set; }
		private String name { get;set; }
		private String locationId { get;set; }
		private List<linkedBillingAccount> linkedBillingAccounts { get; set;}
	}
	//linkedBillingAccounts
	class linkedBillingAccount {
		private string billingAccountNumber { get; set; }
		private string id { get; set; }
	}
	//auth rules section of the response
	class AuthRule {
		private String id { get;set; }
		private String locationId { get;set; }
		private String accountId { get;set; }
		private String billingAccountId { get;set; }
		private String billingAccountNumber { get;set; }
	}
	//single record that is retured by the response
	//most of the Lists were maps originally but converted to lists by request
	class AuthRulesResponseRecord {
		private AuthContact contact;
		private List<AuthOrganization> organizations;
		private List<AuthBillingAccount> billingAccounts;
		private List<AuthLocation> locations;
		private List<AuthRule> authRules;

		private AuthRulesResponseRecord() {
			this.contact = new AuthContact();
			this.organizations = new List<AuthOrganization>();
			this.billingAccounts = new List<AuthBillingAccount>();
			this.locations = new List<AuthLocation>();
			this.authRules = new List<AuthRule>();
		}
	}

	@HttpGet
	global static void get() {
		try {
			RestRequest request = RestContext.request;
	
			// grab the OID parameter from the request
			System.Debug('Request URI: ' + request.requestURI);
			String OID = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
	
			// accepts a list of access roles to retrieve records for
			// example ('Send a Parcel UI User','Contract UI User')
			String accessType = (String.isEmpty(request.params.get('accessType')) ? '' : request.params.get('accessType'));
			
			//check org cache with OID as a parameter
			Map<String,List<AuthRulesResponseRecord>> responseRecordsMap = (Map<String,List<AuthRulesResponseRecord>>)CacheManager.get('AUTHORIZATIONRULES_RESPONSE',OID);
			System.debug('responseRecordsMap : '+responseRecordsMap);
			//if cache is not a hit or cache does not have a value for the queried accesstype, continue to query the database
			if(responseRecordsMap == null || !(responseRecordsMap.containsKey(accessType))) {				
				List<String> accessTypes = accessType.split(',');		
				//query contact with the passed in OID with the relevent Auth Rules.
				//      NOTE:
				//          As a temporary fix Status__c = 'Active' (for contact) has been removed
				//          There are currently contacts that were made inactive or do not have any status.
				//          Other systems need to be updated before the active flag can go back in.
				//             This change is being led by Eric Lui from MPB
				List<Contact> contactList = [SELECT Id, FirstName, LastName, OID_ID__c, Email, LEGACY_ID__c, IsPersonAccount, Account.Id, Account.Name, Account.LEGACY_ID__c,
											(Select Id, AccessRole__c,Account__c,Account__r.Name, Account__r.LEGACY_ID__c,Status__c, Account__r.AccountNumber,
													Billing_Account__r.LEGACY_ID__c,Billing_Account__c, Billing_Account__r.Name,Billing_Account__r.Type__c,Billing_Account__r.Organisation__c,
													Billing_Account__r.Source_System__c,Location__c, Location__r.Name,Location__r.Organisation__c,Location__r.Location_ID__c
												From Authorization_Rules__r
												Where Status__c = 'Active' AND AccessRole__c in :accessTypes)
											From Contact
											Where OID_ID__c = :OID
											And IsPersonAccount=false];
		
				System.Debug('>> contacts: ' + contactList);
		
				//Map to store Account Ids(organizations) per Contact to be used to query All Locations and all Billing Accounts for that Account ID.
				Map<Id,Id> accountIDs = new Map<Id,Id>();
		
				//populate Account Ids(organizations) per Contact map
				for(Contact cc : contactList) {
					accountIDs.put(cc.Id,cc.Account.Id);
				}
				//Craete new response object
				List<AuthRulesResponseRecord> responseRecordList = new List<AuthRulesResponseRecord>();
		
				//map to store Accounts with Billing Accounts and Locations vs Account Id
				Map<Id,Account> accMap = new Map<Id,Account>();
				accMap.putAll([Select Id, Name, (Select Id, Name, LEGACY_ID__c, Type__c,Source_System__c from Billing_Accounts__r), (Select Id, Name, Location_ID__c from Locations__r)
								From Account Where Id In :accountIDs.values()]);
		
				//all location ids queried by the request
				set<Id> locationIds = new set<Id>();
				for(Account abc : accMap.values()) {
					for(Schema.Location ll : abc.Locations__r) {
						locationIds.add(ll.Id);
					}
				}
				//query billing account rule table by location
				List<Billing_Account_Location__c> billingAccountRules = new List<Billing_Account_Location__c>([Select Id, Name, Billing_Account_Id__c, Billing_Account_Id__r.LEGACY_ID__c, Location__c, Location__r.Location_ID__c
																						From Billing_Account_Location__c Where Location__c In :locationIds]);
				System.debug('billingAccountRules :'+billingAccountRules);
				
				Map<Id,List<Billing_Account_Location__c>> billingAccountRulesbyLocationMap = new Map<Id,List<Billing_Account_Location__c>>();
				
				//set up the map of billing accounts by location.
				//this is used to get all billing account rules for each location for each organisation
				for(Billing_Account_Location__c billingAccountRule : billingAccountRules) {
					//if the location already exists in map add the billing account rule to that location key
					if(billingAccountRulesbyLocationMap.containsKey(billingAccountRule.Location__c)) {
						billingAccountRulesbyLocationMap.get(billingAccountRule.Location__c).add(billingAccountRule);
					}
					//if location key is not available in the map, put the key with a new instance of Billing_Account_Location__c list
					else {
						billingAccountRulesbyLocationMap.put(billingAccountRule.Location__c, new List<Billing_Account_Location__c>{billingAccountRule});
					}
				}
				// for all the contacts returned for the OID, genarate the response
				for(Contact c : contactList) {
					//create new Auth Rule Response record.
					AuthRulesResponseRecord responseRecord = new AuthRulesResponseRecord();
		
					//Create the contact section
					AuthContact ac = new AuthContact();
					ac.firstName = c.FirstName;
					ac.lastName = c.LastName;
					ac.oidId = c.OID_ID__c;
					ac.id = c.Id;
		
					//add contact section to the Auth Rule response record
					responseRecord.contact = ac;
		
					//create the organizations section
					AuthOrganization ao = new AuthOrganization();
					ao.id = c.Account.Id;
					ao.name = c.Account.Name;
					ao.apbcn = c.Account.LEGACY_ID__c;
		
					//add organization section to the auth rule response
					if(ao.apbcn != null) {
						responseRecord.organizations.add(ao);
					}
					//create the billing accounts section and add all billing accounts for that organization to that section
					for(Billing_Account__c bac : accMap.get(c.Account.Id).Billing_Accounts__r) {
						AuthBillingAccount aba = new AuthBillingAccount();
						aba.id = bac.Id;
						aba.name = bac.Name;
						aba.billingAccountNumber = bac.LEGACY_ID__c;
						aba.type = bac.Type__c;
						aba.sourceSystem = bac.Source_System__c;
						
						//add billing accounts section to the Auth Rule Response record
						if(aba.billingAccountNumber != null) {
							responseRecord.billingAccounts.add(aba);
						}
					}
					//Create the Locations section and add all locations associated with the organization to that section
					for(Schema.Location loc : accMap.get(c.Account.Id).Locations__r) {
						AuthLocation alo = new AuthLocation();
						alo.id = loc.Id;
						alo.name = loc.Name;
						alo.locationId = loc.Location_ID__c;
						alo.linkedBillingAccounts = new List<linkedBillingAccount>();
		
						//add linked billing accounts related to the location
						if(billingAccountRulesbyLocationMap.get(loc.Id) != null) {
							for(Billing_Account_Location__c rule : billingAccountRulesbyLocationMap.get(loc.Id)) {
								linkedBillingAccount lba = new linkedBillingAccount();
								lba.billingAccountNumber = rule.Billing_Account_Id__r.LEGACY_ID__c;
								lba.id = rule.Id;
							
								alo.linkedBillingAccounts.add(lba);
							}
						}
						//add locations section to the Auth rule response
						if(alo.locationId != null) {
							responseRecord.locations.add(alo);
						}
					}
					// we use a map to store each authrule record incase we produce duplicate records with the same information in them
					// this may happen when we are compiling a list of all possible auth rules for the different business rules.
					Map<String, AuthRule> authRules = new Map<String, AuthRule>();
		
					//for all the auth rules retunred for the passed OID
					for(Authorization_Rule__c ar : c.Authorization_Rules__r) {
						//Records where contacts with locations that are related to the primary customer record of the contact
						// or Records where contacts with billing accounts/accounts are related to the primary customer record of the contact
						if((ar.Account__r != null && c.Account.Id == ar.Account__r.Id) || (ar.Billing_Account__r != null && c.Account.Id == ar.Billing_Account__r.Organisation__c)) {
							//create auth rules section with a billing account rules list
							// we only accomodate for either
							AuthRule aRule = new authRule();
							aRule.id = ar.Id;
							aRule.accountId = ar.Account__c;
							aRule.billingAccountId = ar.Billing_Account__c;
							aRule.billingAccountNumber = (ar.Billing_Account__r != null ? ar.Billing_Account__r.LEGACY_ID__c : null);
							aRule.locationId = (ar.Location__r != null ? ar.Location__r.Location_ID__c : null);
							//System.Debug('>> auth rule key: ' + String.valueOf(ar.Account__c) + String.valueOf(ar.Billing_Account__c) + String.valueOf(ar.Location__c));
							authRules.put(String.valueOf(ar.Account__c) + String.valueOf(ar.Billing_Account__c) + String.valueOf(ar.Location__c), aRule);
						}
					}
					// when an auth rule references a location without a billing account
					// we need to find all the links between a Location and a Billing Account
					// this is represented as junction (many to many) between Location and Billing_Account__c (Billing_Account_Location__c)
					// we return a separate auth rule for each of these associations
					for(Authorization_Rule__c ar : c.Authorization_Rules__r) {
						// we are only concerned with records where a location has been specificed and a billing account has not.
						if((ar.Location__r != null && c.Account.Id == ar.Location__r.Organisation__c) && ar.Billing_Account__r == null) {
							//get the billing account rule records associated with the auth rule and add that to the billing account rules section
							for(Billing_Account_Location__c bb : billingAccountRules) {
								if(ar.Location__c == bb.Location__c) {
									AuthRule aRule = new authRule();
									aRule.id = ar.Id;
									aRule.locationId = bb.Location__r.Location_ID__c;
									aRule.billingAccountId = bb.Billing_Account_Id__c;
									aRule.billingAccountNumber = bb.Billing_Account_Id__r.LEGACY_ID__c;
		
									//add billing accounts to the relevent section.
									//System.Debug('>> auth rule key2: ' + String.valueOf(ar.Account__c) + String.valueOf(bb.Billing_Account_Id__c) + String.valueOf(bb.Location__r.Location_ID__c));
									authRules.put(String.valueOf(ar.Account__c) + String.valueOf(bb.Billing_Account_Id__c) + String.valueOf(bb.Location__r.Location_ID__c), aRule);
								}
							}
						}
					}
					responseRecord.authRules.addAll(authRules.values());
					//add auth response record to the response
					responseRecordList.add(responseRecord);
				}
				//if cache is a miss, craete new map to store responses for each accesstype queried.
				if(responseRecordsMap == null) {
					responseRecordsMap = new Map<String,List<AuthRulesResponseRecord>>();
				}
				//if cache is a hit but did not have a value for the passed accesstype, put accesstype with the response records to the cache
				responseRecordsMap.put(accessType,new List<AuthRulesResponseRecord>(responseRecordList));
				CacheManager.put('AUTHORIZATIONRULES_RESPONSE',OID, responseRecordsMap);
			}	
			//return success response
			ResourceAPIService.serializeResponse(new ResourceAPIService.ResourceResponse(true, null, responseRecordsMap.get(accessType)), 200);
		}
		//log the errors and return error response
		catch(Exception e) {
			UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'Lodgement API',
				ResourceV1AuthorisationRulesContact.class.getName(), 'Get Auth Rules by Contact',
				null, LoggingLevel.ERROR);
			ResourceAPIService.serializeResponse(new ResourceAPIService.ResourceResponse(false, e.getMessage(), null), 500);
		}
	}

}