/***
 * @description
 * Methods to support the sending of the provisioning request from Salesforce to Camunda
 * Inputs: ContactId
 * Output: Map with up to two payload strings - one for Provision, another for Deprovision
 *
 * @author Andrew Judd
 * @date 2019-04-29
 * @group Merchant Portal
 * @changelog
 * 2019-05-15 - ajudd@salesforce.com - Updates following feedback
 * 2019-06-03 - ajudd@salesforce.com - Adjust payload from list (array) to records for some nodes
 * 2019-06-03 - ajudd@salesforce.com - Change EOR query to get based off contact app
 * 2019-07-11 - ajudd@salesforce.com - Added set of record type on EOR record and include in EOR record queries
 * 2019-07-11 - ajudd@salesforce.com - Added check that contact belongs to same org as the portal user
 * 2019-07-11 - ajudd@salesforce.com - Changed mapping of contact APBCN to Legacy Id field on contact org
 * 2019-09-05 - nathan.franklin@auspost.com.au - Renamed sourceSystem to source in payload
 * 2020-05-24 - Nathan Franklin - Fixed bug where EOR Application was being assigned incorrectly
 */
public class BAMProvision {

	public static final String FIELD_DEPROVISION = 'deprovision';
	public static final String FIELD_PROVISION = 'provision';

	private class AuthPayload {
		private AuthRequestor requestor { get; set; }
		private AuthContact contact { get; set; }
		private List<AuthRequest> requests { get; set; }
		private List<AuthBillingAccount> billingAccounts { get; set; }
		private List<AuthOrganization> organisations { get; set; }
		private List<AuthGroup> groups { get; set; }
	}
	private class AuthRequestor {
		private String lastName { get; set; }
		private String firstName { get; set; }
		private String emailAddress { get; set; }
	}
	private class AuthContact {
		private String id { get; set; }
		private String organisation { get; set; }
		private String lastName { get; set; }
		private String firstName { get; set; }
		private String emailAddress { get; set; }
		private string apbcn { get; set; }
		private string apcn { get; set; }
		private String cnumber { get; set; }
	}
	private class AuthRequest {
		private String id { get; set; }
		private String type { get; set; }
		private AuthContactApp application { get; set; }
	}
	private class AuthContactApp {
		private String appKey { get; set; }
		private String showAllConsignments { get; set; }
		private String primaryBillingAccount { get; set; }
		private String requesttype { get; set; }
		private String app { get; set; }
		private List<AuthContactRole> roles { get; set; }
	}
	private class AuthContactRole {
		private String role { get; set; }
		private Set<Id> billingAccounts { get; set; }
		private Set<Id> orgs { get; set; }
		private Set<Id> groups { get; set; }
	}
	private class AuthBillingAccount {
		private String id { get; set; }
		private String name { get; set; }
		private String organisation { get; set; }
		private String accountNumber { get; set; }
		private String type { get; set; }
		private String mlid { get; set; }
		private String source { get; set; }
	}
	private class AuthOrganization {
		private String id { get; set; }
		private String name { get; set; }
		private String accountNumber { get; set; }
		private String type { get; set; }
	}
	private class AuthGroup {
		private String id { get; set; }
		private String name { get; set; }
		private String organisation { get; set; }
		private Set<Id> billingAccounts { get; set; }
		private AuthLocation location { get; set; }
	}
	private class AuthLocation {
		private String id { get; set; }
		private String name { get; set; }
		private String dispatchId { get; set; }
		private AuthLocationAddress address { get; set; }
	}
	private class AuthLocationAddress {
		private String line1 { get; set; }
		private String city { get; set; }
		private String state { get; set; }
		private String postCode { get; set; }
	}

	//TODO: Will need some good code documentation here about our rules and how they work Pending_Delete__c, Status__c = 'Pending' etc...
	//TODO: It's ok if it's a long winded explanation since this is the core logic of BAM provisioning and it will be important to communicate this to other devs down the line
	public static Map<String, String> provision(Id provContactId) {

		/* This method first checks that the
			 TO DO
			1. Pending Delete logic - include condition to ignore when add LEs, Roles, and Applications
			2. Test change detection scenarios
		*/

		Map<Id, AuthBillingAccount> baMap = new Map<Id, AuthBillingAccount>();
		Map<Id, AuthOrganization> orgMap = new Map<Id, AuthOrganization>();
		Map<Id, AuthGroup> grpMap = new Map<Id, AuthGroup>();
		Map<Id, AuthContactRole> conRoleMap = new Map<Id, AuthContactRole>();
		Map<Id, AuthContactApp> conAppProvMap = new Map<Id, AuthContactApp>();
		Map<Id, AuthContactApp> conAppDeprovMap = new Map<Id, AuthContactApp>();
		Map<Id, AuthContact> conMap = new Map<Id, AuthContact>();
		Map<Id, AuthRequest> reqProvMap = new Map<Id, AuthRequest>();
		Map<Id, AuthRequest> reqDeprovMap = new Map<Id, AuthRequest>();
		Map<String, String> payloadMap = new Map<String, String>();

		Map<Id, Datetime> maxAccessModByConAppMap = new Map<Id, Datetime>();
		Map<Id, Datetime> maxEOBRSuccessByConAppMap = new Map<Id, Datetime>();
		Map<Id, Id> conRoleIdToConAppId = new Map<Id, Id>();
		Map<id, Set<id>> grpIdToBAIdSetMap = new Map<id, Set<id>>();

		List<BAMExternalOnboardingRequest__c> eobrList = new List<BAMExternalOnboardingRequest__c>();
		List<BAMContactApplication__c> conappListWithLatestEOR = new List<BAMContactApplication__c>();
		Map<Id, BAMExternalOnboardingRequest__c> eobrMap = new Map<Id, BAMExternalOnboardingRequest__c>();

		Set<String> conAppsToProvisionSet = new Set<String>();
		Set<String> conAppsToDeprovisionSet = new Set<String>();
		Set<Id> requestConAppPendingSet = new Set<Id>();
		Set<Id> conAppsEvaluatedSet = new Set<Id>();
		Set<Id> conAppsDeprovisionSet = new Set<Id>();
		Set<Id> baSet = new Set<Id>(); //to put against contact role
		Set<Id> orgSet = new Set<Id>(); //to put against contact role
		Set<Id> grpSet = new Set<Id>(); //to put against contact role
		Set<Id> grpSetAll = new Set<Id>();
		Set<Id> tempSet = new Set<Id>();
		Id conAppId;
		Id bamExtObRTId;
		String provPayloadString;
		String deprovPayloadString;
		String conAppsToProvAndDeprovString = ''; //comma separated string of all con apps prov and deprov

		//##Get details for contact
		Contact[] conRecord = [
				SELECT Id, FirstName, LastName, OID_ID__c, Email, AccountId, APCN__c, BillingAccount__c,
						BillingAccount__r.Organisation__c, BillingAccount__r.Name, BillingAccount__r.LEGACY_ID__c,
						BillingAccount__r.MLID__c, BillingAccount__r.Source_System__c,
						Account.Name, Account.Legacy_ID__c, Account.Role_Type_Roll_Up__c
				FROM Contact
				WHERE Id = :provContactId
		];

		//If contact found
		if (conRecord.size() > 0) {
			System.Debug('Contact id = ' + conRecord[0].Id);

			//#Validate contact org is the same as the portal user's org
			//Get portal user
			User[] userRecord = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()];
			System.debug('Portal User org = ' + userRecord[0].Contact.AccountId);
			System.debug('Contact org = ' + conRecord[0].AccountId);
			//Continue if user is not a portal user, or if portal user's org is the same as the contact's org
			if (userRecord[0].Contact.AccountId == null || (userRecord[0].Contact.AccountId == conRecord[0].AccountId)) {

				//Get external onboarding request BAM record type id
				bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

				//Create contact map record and add to map
				AuthContact conRecNew = new AuthContact();
				conRecNew.id = conRecord[0].Id;
				conRecNew.firstname = conRecord[0].FirstName;
				conRecNew.lastname = conRecord[0].LastName;
				conRecNew.organisation = conRecord[0].AccountId;
				conRecNew.emailAddress = conRecord[0].Email;
				conRecNew.apbcn = conRecord[0].Account.LEGACY_ID__c;
				conRecNew.apcn = conRecord[0].APCN__c;
				conRecNew.cnumber = conRecord[0].OID_ID__c;
				conMap.put(conRecord[0].Id, conRecNew);

				//Add primary ba to ba map and contact to ba map
				if (conRecord[0].BillingAccount__c != null) {
					AuthBillingAccount ba = new AuthBillingAccount();
					ba.Id = conRecord[0].BillingAccount__c;
					ba.Name = conRecord[0].BillingAccount__r.Name;
					ba.organisation = conRecord[0].BillingAccount__r.Organisation__c;
					ba.accountNumber = conRecord[0].BillingAccount__r.LEGACY_ID__c;
					ba.type = conRecord[0].Account.Role_Type_Roll_Up__c;
					ba.mlid = conRecord[0].BillingAccount__r.MLID__c;
					ba.source = conRecord[0].BillingAccount__r.Source_System__c;
					//Add to ba map
					baMap.put(conRecord[0].BillingAccount__c, ba);
				}

				//Add contact account to org map and contact to org map
				if (conRecord[0].AccountId != null) {
					AuthOrganization org = new AuthOrganization();
					org.Id = conRecord[0].AccountId;
					org.name = conRecord[0].Account.Name;
					org.accountNumber = conRecord[0].Account.Legacy_ID__c;
					org.type = conRecord[0].Account.Role_Type_Roll_Up__c;
					//Add to org map
					orgMap.put(conRecord[0].AccountId, org);
				}

				//##Get contact roles, linked entities, and other related info for contact.
				//Note that pending delete records are included to ensure delete change is detected
				List<BAMContactRole__c> accessList = new List<BAMContactRole__c>();
				accessList = [
						SELECT Id, ContactApplication__r.Contact__r.FirstName, ContactApplication__r.Contact__r.LastName, Contact_Id__c,
								ContactApplication__r.Application__c, ContactApplication__r.Contact__c, ContactApplication__c, ContactApplication__r.Application__r.AppKey__c,
								ContactApplication__r.LastModifiedDate, ContactApplication__r.Pending_Delete__c, ContactApplication__r.Pending_Deactivation__c,
								ApplicationName__c, ApplicationRole__c, Application_Role_Role__c, LastModifiedDate, Pending_Delete__c, ContactApplication__r.BSPCanViewAllConsignments__c, (
								SELECT Id, Name, BillingAccount__c, BillingAccount__r.Name, BillingAccount__r.Organisation__c, BillingAccount__r.LEGACY_ID__c,
										BillingAccount__r.MLID__c, BillingAccount__r.Source_System__c,
										Group__c, Group__r.Name, Group__r.Organisation__c, Organisation__c, Organisation__r.Name, Organisation__r.Legacy_ID__c,
										Group__r.Despatch_Location__c, Group__r.Despatch_Location__r.Street__c, Group__r.Despatch_Location__r.City__c,
										Group__r.Despatch_Location__r.State__c, Group__r.Despatch_Location__r.Post_Code__c, Group__r.Despatch_Location__r.Name,
										Group__r.Despatch_Location__r.Despatch_ID__c, Pending_Delete__c, Organisation__r.Role_Type_Roll_Up__c,
										BillingAccount__r.Organisation__r.Role_Type_Roll_Up__c, LastModifiedDate
								FROM LinkedEntities__r
						)
						FROM BAMContactRole__c
						WHERE ContactApplication__r.Contact__c = :provContactId
				];

				System.debug('Size = ' + accessList.size());

				//##Loop thru each Contact Role and LE to build map latest last modified date by Contact Application.
				//Note that accessList includes 'Pending Delete' contact role and linked entity records
				//and 'Pending Delete' or 'Pending Deactivation' contact app records to allow detection of records.

				//The latest last modified date is that for the contact app, contact role, or linked entity

				//Also note that when onboarding request records are set to Success via the platform event:
				//>All 'Pending Delete' records and child records will be physically deleted
				//>All 'Pending Deactivation' contact app records will be set to 'Inactive'
				for (BAMContactRole__c cr : accessList) {
					conAppId = cr.ContactApplication__c;

					conAppsEvaluatedSet.add(conAppId); //Set of Contact Apps evaluated

					//If the con app is Pending Delete or Deactivation then record as a con app to deprovision
					if (cr.ContactApplication__r.Pending_Delete__c || cr.ContactApplication__r.Pending_Deactivation__c) {
						conAppsDeprovisionSet.add(conAppId);
					}

					//#1 Get most recent (max) modified date-time by contact app
					//Compare the con app modified date to the most recent stored so far for the con app.  If it is more recent, or not yet set, then store this for the con app
					if (cr.ContactApplication__r.LastModifiedDate > maxAccessModByConAppMap.get(conAppId) || maxAccessModByConAppMap.get(conAppId) == null) {
						maxAccessModByConAppMap.put(conAppId, cr.ContactApplication__r.LastModifiedDate);
					}
					//#2 Get most recent (max) modified date-time by contact role
					//Compare the con role modified date to the most recent stored so far for the con app.  If it is more recent, or not yet set, then store this for the con app
					if (cr.LastModifiedDate > maxAccessModByConAppMap.get(conAppId) || maxAccessModByConAppMap.get(conAppId) == null) {
						maxAccessModByConAppMap.put(conAppId, cr.LastModifiedDate);
					}
					//#3 Get most recent (max) modified date-time by linked entity
					//Compare the le modified date to the most recent stored so far for the con app.  If it is more recent, or not yet set, then store this for the con app
					for (BAMLinkedEntity__c le : cr.LinkedEntities__r) {
						//Get linked entity modified date and record if more recent than that found against other records
						if (le.LastModifiedDate > maxAccessModByConAppMap.get(conAppId)) {
							maxAccessModByConAppMap.put(conAppId, le.LastModifiedDate);
						}
					}
				}
				System.debug('maxAccessModByConAppMap = ' + maxAccessModByConAppMap);

				//#Get latest BAM external onboarding request based on contact application for contact.
				conappListWithLatestEOR = [
						SELECT Id, (
								SELECT Id, Type__c, Contact_Application__r.Application__c, Status__c, Response_Date__c
								FROM BAM_External_Onboarding_Requests__r
								WHERE RecordTypeId = :bamExtObRTId
								ORDER BY CreatedDate DESC
								LIMIT 1
						)
						FROM BAMContactApplication__c
						WHERE Contact__c = :provContactId
				];

				//##Build map of latest successful onboarding request by Contact Application.
				//Any changes to access since a successful onboarding request will indicate that a change has been made to a user's access for that app
				for (BAMContactApplication__c conapp : conappListWithLatestEOR) {
					conAppId = conapp.Id;

					//If there is an external onboarding request record for the contact app
					if (!conapp.BAM_External_Onboarding_Requests__r.isEmpty()) {

						//For the eor record
						for (BAMExternalOnboardingRequest__c eor : conapp.BAM_External_Onboarding_Requests__r) {

							//If latest request is success, then store the response date of success by app.
							if (eor.Status__c == 'Success') {
								maxEOBRSuccessByConAppMap.put(conAppId, eor.Response_Date__c);
							}
							//If latest request is pending, then record to suppress a repeat provision or deprovision call
							//Note that the UI should prevent the update to a con app in Pending status, so this is just a safeguard.
							else if (eor.Status__c == 'Pending') {
								requestConAppPendingSet.add(conAppId);
							}
						}//end for eor record
					}//end if an eor record
				}
				System.debug('maxEOBRSuccessByConAppMap = ' + maxEOBRSuccessByConAppMap);
				System.debug('requestConAppPendingSet = ' + requestConAppPendingSet);

				//##Build Set of Contact Applications to provision and deprovision
				//For all active contact apps contact has access to, compare the latest access modified date recorded against the latest successful onboarding response date
				//If the contact app is pending delete or deactivation (i.e. in conAppsToDeprovisionSet), then deprovision, else provision.
				for (Id conApplnId : conAppsEvaluatedSet) {
					//If no pending external request for con app
					if (!requestConAppPendingSet.contains(conApplnId)) {
						//If con app set to pending delete or deactivation, then add to deprovision set
						if (conAppsDeprovisionSet.contains(conApplnId)) {
							conAppsToDeprovisionSet.add(conApplnId);
						}
						//Else if max date of successful onboarding request request is null (i.e not yet provisioned) OR
						//a role or linked entity access record has been modified after the most recent successful onboarding request (i.e. a change in access) then add to provision set
						else if (maxEOBRSuccessByConAppMap.get(conApplnId) == null || (maxAccessModByConAppMap.get(conApplnId) > maxEOBRSuccessByConAppMap.get(conApplnId))) {
							System.debug('!!!Provision!!!');
							conAppsToProvisionSet.add(conApplnId);
						}
					}//end not pending
				}

				System.debug('conAppsToProvisionSet = ' + conAppsToProvisionSet);
				System.debug('conAppsToDeprovisionSet = ' + conAppsToDeprovisionSet);

				//If there are contact apps to provision or deprovision continue to build payload, else payload map returned will be empty
				if (!conAppsToProvisionSet.isEmpty() || !conAppsToDeprovisionSet.isEmpty()) {

					//## For Provision - Loop thru each Contact Role and LE to build structure for Contact Applications to be provisioned
					//Follow this structure:
					/*Payload
						Requestor
						Contact
							Requests
								Application (contact application)
									Roles (contact role)
										1. Billing Account - ids
										2. Groups - ids
										3. Orgs - ids
						1. Billing Accounts - details (including group bas and contact primary ba)
						2. Groups - details
						3. Orgs - details (including contact org)*/

					//## For Deprovision, build this structure
					/*Payload
						Requestor
						Contact
							Requests
								Application (contact application)*/

					//Loop through contact role records, and for all apps to be provisioned, and role not pending delete:
					//>build BA, Org, and Group maps Contact Role, Contact Application
					//For all apps to be deprovisioned:
					//>build Contact Application for contact
					for (BAMContactRole__c cr : accessList) {

						conAppId = cr.ContactApplication__c;

						//If con app to be provisioned i.e. a change in contact's access has been detected
						if (conAppsToProvisionSet.contains(conAppId)) {

							//If role not 'pending delete'
							if (!cr.Pending_Delete__c) {

								//If Linked Entities on contact role
								if (!cr.LinkedEntities__r.isEmpty()) {

									//Loop through all LEs and add to applicable maps
									for (BAMLinkedEntity__c le : cr.LinkedEntities__r) {

										//If not a 'pending delete' LE record
										if (!le.Pending_Delete__c) {
											//If BA linked, then add to map and set
											if (le.BillingAccount__c != null) {
												AuthBillingAccount bacc = new AuthBillingAccount();
												bacc.Id = le.BillingAccount__r.Id;
												bacc.name = le.BillingAccount__r.Name;
												bacc.organisation = le.BillingAccount__r.Organisation__c;
												bacc.accountNumber = le.BillingAccount__r.LEGACY_ID__c;
												bacc.mlid = le.BillingAccount__r.MLID__c;
												bacc.source = le.BillingAccount__r.Source_System__c;
												bacc.type = le.BillingAccount__r.Organisation__r.Role_Type_Roll_Up__c;
												baSet.add(le.BillingAccount__r.Id);
												baMap.put(le.BillingAccount__r.Id, bacc);
											}
											//If Group linked, then add to map and set
											if (le.Group__c != null) {
												//Build Groups by Contact Role - If grp against role. Then if contact role in map, then add to existing list, else create new list and add
												AuthGroup grp = new AuthGroup();
												grp.id = le.Group__c;
												grp.name = le.Group__r.Name;
												grp.organisation = le.Group__r.Organisation__c;
												grpSet.add(le.Group__c);

												//If group not yet stored then store grp with location and address if set
												if (!grpSetAll.contains(le.Group__c)) {
													//record all groups ids for query outside loop
													grpSetAll.add(le.Group__c);
													//Set Location and Location Address
													if (le.Group__r.Despatch_Location__c != null) {
														AuthLocation loc = new AuthLocation();
														loc.id = le.Group__r.Despatch_Location__c;
														loc.name = le.Group__r.Despatch_Location__r.Name;
														loc.dispatchId = le.Group__r.Despatch_Location__r.Despatch_ID__c;
														AuthLocationAddress locaddr = new AuthLocationAddress();
														locaddr.line1 = le.Group__r.Despatch_Location__r.Street__c;
														locaddr.city = le.Group__r.Despatch_Location__r.City__c;
														locaddr.state = le.Group__r.Despatch_Location__r.State__c;
														locaddr.postCode = le.Group__r.Despatch_Location__r.Post_Code__c;
														//$loc.address = new List<AuthLocationAddress>{locaddr};
														loc.address = locaddr;
														//$grp.location = new List<AuthLocation>{loc};
														grp.location = loc;
													}
													//Add group to map
													grpMap.put(le.Group__c, grp);
												}
											}
											//If Org linked, then add to map and set
											if (le.Organisation__c != null) {
												AuthOrganization org = new AuthOrganization();
												org.id = le.Organisation__c;
												org.name = le.Organisation__r.Name;
												org.accountNumber = le.Organisation__r.Legacy_ID__c;
												org.type = le.Organisation__r.Role_Type_Roll_Up__c;
												orgSet.add(le.Organisation__c);
												orgMap.put(le.Organisation__c, org);
											}
										}//end LE not 'pending delete'
									}//end LE loop
								}//end if LE on role
								//}//end role not 'pending delete'

								//Set bas, orgs and grp Ids to contact role and add role to map
								AuthContactRole conRoleRec = new AuthContactRole();
								conRoleRec.role = cr.Application_Role_Role__c;
								conRoleRec.billingAccounts = new Set <Id> (baSet);
								conRoleRec.orgs = new Set <Id> (orgSet);
								conRoleRec.groups = new Set <Id> (grpSet);
								conRoleMap.put(cr.Id, conRoleRec);

								//If contact app not in set
								if (!conAppProvMap.containsKey(conAppId)) {
									//Create contact app Provision record and add to map
									AuthContactApp conAppRec = new AuthContactApp();
									conAppRec.appKey = cr.ContactApplication__r.Application__r.AppKey__c;
									conAppRec.app = cr.ContactApplication__r.Application__c;
									//If BSP then set additional attributes
									if (cr.ContactApplication__r.Application__r.AppKey__c == 'BSP') {
										conAppRec.showAllConsignments = '' + cr.ContactApplication__r.BSPCanViewAllConsignments__c;
										conAppRec.primaryBillingAccount = conRecord[0].BillingAccount__c;
									}
									conAppProvMap.put(conAppId, conAppRec);
								}

								//Set key of con role by con app, and con app by contact
								conRoleIdToConAppId.put(cr.Id, conAppId);

							}//end role not 'pending delete'

							baSet.clear();
							grpSet.clear();
							orgSet.clear();

						}//end app to be provisioned

						//If con app to be Deprovisioned
						if (conAppsToDeprovisionSet.contains(conAppId)) {
							//If contact app not in set
							if (!conAppDeprovMap.containsKey(conAppId)) {
								//Create contact app Provision record and add to map
								AuthContactApp conAppRec = new AuthContactApp();
								conAppRec.appKey = cr.ContactApplication__r.Application__r.AppKey__c;
								conAppDeprovMap.put(conAppId, conAppRec);
							}
						}//end app to be deprovisioned

					}//end contact role loop

					//if there are apps to be provisioned get group info
					if (!conAppsToProvisionSet.isEmpty()) {
						//##Get Group BAs for all Groups
						List<BAMGroupBillingAccount__c> groupBAsList = [
								SELECT Id, Group__c, BillingAccount__c, BillingAccount__r.Name, BillingAccount__r.Organisation__c,
										BillingAccount__r.MLID__c, BillingAccount__r.LEGACY_ID__c, BillingAccount__r.Source_System__c,
										BillingAccount__r.Organisation__r.Role_Type_Roll_Up__c
								FROM BAMGroupBillingAccount__c
								WHERE Group__c IN:grpSetAll
						];

						//Build grp ba Map
						for (BAMGroupBillingAccount__c gba : groupBAsList) {
							AuthBillingAccount grpBaRec = new AuthBillingAccount();
							grpBaRec.Id = gba.Id;
							grpBaRec.name = gba.BillingAccount__r.Name;
							grpBaRec.organisation = gba.BillingAccount__r.Organisation__c;
							grpBaRec.accountNumber = gba.BillingAccount__r.LEGACY_ID__c;
							grpBaRec.source = gba.BillingAccount__r.Source_System__c;
							grpBaRec.mlid = gba.BillingAccount__r.MLID__c;
							grpBaRec.type = gba.BillingAccount__r.Organisation__r.Role_Type_Roll_Up__c;
							baMap.put(gba.BillingAccount__c, grpBaRec);
							//Set BA Id against group
							tempSet = grpMap.get(gba.Group__c).billingAccounts;
							if (tempSet == null) {
								tempSet = new Set<Id>();
							}
							tempSet.add(gba.Id);
							grpMap.get(gba.Group__c).billingAccounts = tempSet;
							//Store mapping of group to ba
							if (grpIdToBAIdSetMap.containsKey(gba.Group__c)) {
								tempSet = grpIdToBAIdSetMap.get(gba.Group__c);
							} else {
								tempSet = new Set<Id>();
							}
							tempSet.add(gba.BillingAccount__c);
							grpIdToBAIdSetMap.put(gba.Group__c, tempSet);
						}
					}//end if con app to be provisioned get group info

					//Add roles to contact applications (provision requests only)
					for (Id conRoleId : conRoleIdToConAppId.keySet()) {
						conAppId = conRoleIdToConAppId.get(conRoleId);
						if (conAppProvMap.get(conAppId).roles == null) {
							conAppProvMap.get(conAppId).roles = (new List<AuthContactRole>{
									conRoleMap.get(conRoleId)
							});
						} else {
							conAppProvMap.get(conAppId).roles.add(conRoleMap.get(conRoleId));
						}
					}

					//For provisioning - Create request map and onboarding request list
					for (Id conApplId : conAppProvMap.keySet()) {
						//Create request map record for payload
						AuthRequest reqRec = new AuthRequest();
						reqProvMap.put(conApplId, reqRec);
						//Add onboarding request record List to insert
						BAMExternalOnboardingRequest__c eobreqRec = new BAMExternalOnboardingRequest__c();
						eobreqRec.Contact__c = provContactId;
						eobreqRec.Contact_Application__c = conApplId;
						eobreqRec.Type__c = 'Provision';
						eobreqRec.Request_Date__c = System.Now();
						eobreqRec.Status__c = 'Pending';
						eobreqRec.RecordTypeId = bamExtObRTId;
						eobreqRec.Application__c =(ID)conAppProvMap.get(conApplId).app;
						eobrList.add(eobreqRec);
					}

					//For deprovisioning - Create request map and onboarding request list
					for (Id conApplId : conAppDeprovMap.keySet()) {
						//Create request map record for payload
						AuthRequest reqRec = new AuthRequest();
						reqDeprovMap.put(conApplId, reqRec);
						//Add onboarding request record List to insert
						BAMExternalOnboardingRequest__c eobreqRec = new BAMExternalOnboardingRequest__c();
						eobreqRec.Contact__c = provContactId;
						eobreqRec.Contact_Application__c = conApplId;
						eobreqRec.Type__c = 'Deprovision';
						eobreqRec.Request_Date__c = System.Now();
						eobreqRec.Status__c = 'Pending';
						eobreqRec.RecordTypeId = bamExtObRTId;
						eobrList.add(eobreqRec);
					}

					//insert onboarding request records
					if (eobrList.size() > 0) {
						insert eobrList;
					}

					//Get ids of onboarding request records for onboarding request map
					for (BAMExternalOnboardingRequest__c eobr : eobrList) {
						eobrMap.put(eobr.Contact_Application__c, eobr);
					}

					//Clear list to use for payload update
					eobrList.clear();

					//Set Provision request map fields, including External Onboarding Request Id, and add contact apps to request
					for (Id conApplId : conAppProvMap.keySet()) {
						//set req record fields
						reqProvMap.get(conApplId).id = eobrMap.get(conApplId).Id;
						reqProvMap.get(conApplId).type = 'application';

						//add application to request
						reqProvMap.get(conApplId).application = conAppProvMap.get(conApplId);

						//build string of con apps to return
						conAppsToProvAndDeprovString = conAppsToProvAndDeprovString + conApplId + ',';
					}

					//Set Deprovision request map fields, including External Onboarding Request Id, and add contact apps to request
					for (Id conApplId : conAppDeprovMap.keySet()) {
						//set req record fields
						reqDeprovMap.get(conApplId).id = eobrMap.get(conApplId).Id;
						reqDeprovMap.get(conApplId).type = 'application';

						//add application to request
						reqDeprovMap.get(conApplId).application = conAppDeprovMap.get(conApplId);

						//build string of con apps to return
						conAppsToProvAndDeprovString = conAppsToProvAndDeprovString + conApplId + ',';
					}

					//If provision or deprovision required, then build requestor record
					AuthRequestor requestorRec = new AuthRequestor();
					if (!conAppProvMap.IsEmpty() || !conAppDeprovMap.IsEmpty()) {
						requestorRec.firstName = UserInfo.getFirstname();
						requestorRec.lastName = UserInfo.getLastname();
						requestorRec.emailAddress = UserInfo.getUserEmail();
					}

					//#Create provision request record

					//If provision map not empty
					if (!conAppProvMap.IsEmpty()) {
						AuthPayload authProvReq = new AuthPayload();
						authProvReq.Requestor = requestorRec;

						//Add contact, requests, billing accounts, orgs, and groups to payload
						authProvReq.Contact = conRecNew;
						authProvReq.Requests = reqProvMap.values();
						authProvReq.BillingAccounts = baMap.values();
						authProvReq.Organisations = orgMap.values();
						authProvReq.Groups = grpMap.values();

						//Add to returned map
						provPayloadString = JSON.serializePretty(authProvReq, true);
						payloadMap.put(FIELD_PROVISION, provPayloadString);

						//Update eobr record payload field
						for (Id conApplId : conAppProvMap.keySet()) {
							BAMExternalOnboardingRequest__c eobreqRec = new BAMExternalOnboardingRequest__c();
							eobreqRec.Id = eobrMap.get(conApplId).Id;
							eobreqRec.Request_Payload__c = provPayloadString.substring(0, Math.min(provPayloadString.length(), Schema.SObjectType.BAMExternalOnboardingRequest__c.fields.Request_Payload__c.getLength()));
							eobrList.add(eobreqRec);
						}
					}

					//#Create deprovision request record to append
					//If deprovision map not empty
					if (!conAppDeprovMap.IsEmpty()) {
						AuthPayload authDeprovReq = new AuthPayload();

						//Add requestor details
						authDeprovReq.Requestor = requestorRec;

						//Add contact and requests payload
						authDeprovReq.Contact = conRecNew;
						authDeprovReq.Requests = reqDeprovMap.values();

						//Add to returned map
						deprovPayloadString = JSON.serializePretty(authDeprovReq, true);
						payloadMap.put(FIELD_DEPROVISION, deprovPayloadString);

						//Update eobr record payload field
						for (Id conApplId : conAppDeprovMap.keySet()) {
							BAMExternalOnboardingRequest__c eobreqRec = new BAMExternalOnboardingRequest__c();
							eobreqRec.Id = eobrMap.get(conApplId).Id;
							eobreqRec.Request_Payload__c = deprovPayloadString.substring(0, Math.min(deprovPayloadString.length(), Schema.SObjectType.BAMExternalOnboardingRequest__c.fields.Request_Payload__c.getLength()));
							eobrList.add(eobreqRec);
						}
					}

					//Update payload field against all onboarding requests
					if (eobrList.size() > 0) {
						update eobrList;
					}

				}//end if contact app to provision or deprovision

				payloadMap.put('conapps', conAppsToProvAndDeprovString);

			}//end if validate portal user org same as contact org

		}//end if contact found

		//Return payload
		return payloadMap;
	}
}