/**
 * @File Name			: MyNetworkStarTrackCaseController.cls
 * @Description			: Controller class for StarTrack MyNetwork Console App
 * @Author				: Mahesh Parvathaneni
 * @changelog
 * 2022-12-12 - Mahesh Parvathaneni - Added getCriticalIncidents method and updates to getArticlesByCase method
 * 2023-01-17 - Mahesh Parvathaneni - Updated to set the StarTrack MyNetwork record type for Case Investigation
 * 2023-03-10 - Mahesh Parvathaneni - SF-889 - Updated wrapper to get the network for event messages based on Post office code
 * 2023-04-03 - Mahesh Parvathaneni - SF-948 - Added validation for case type
 * 2023-05-10 - Mahesh Parvathaneni - SF-946 - Added logic to submit case investigations when no AP network scans
 * 2024-04-15 - Raghav Ravipati		- Replaced Critical incident articaltype with salesforce lighting article Knowledge__kav as part of knowledge lightning uplift
 **/

public with sharing class MyNetworkStarTrackCaseController {

	@TestVisible
	private static final String ST_MYNETWORK_RECORD_TYPE = 'StarTrack_MyNetwork';
	private static final String STAR_TRACK = 'startrack'; 

	/**
	 * Function to get the articles and related event messages for a case that is associated with AP Network
	 */
	@AuraEnabled
	public static ArticleResponseWrapper getArticlesByCase(String caseId){
		try {
			ArticleResponseWrapper wrapper = new ArticleResponseWrapper();
			wrapper.hasPassedThroughAPNetwork = false;
			List<ArticleDetails> articleDetails = new List<ArticleDetails>();
			Set<Id> articleIds = new Set<Id>();

			//get consignment for the case
			List<Case> cases = CasesSelector.newInstance().selectById(new Set<Id>{Id.valueOf(caseId)}).values();

			//check call purpose and enquiry type is populated on case
			if (cases.size() > 0 && String.isBlank(cases[0].Enquiry_Type__c) && String.isBlank(cases[0].Call_Purpose__c)) {
				wrapper.hasCaseTypeBlankOnCase = true;
				return wrapper;
			}

			if (cases.size() > 0 && cases[0].ArticleTest__c != null) {
				wrapper.receiverPostcode = cases[0].Article_Receiver_Postcode__c;
				wrapper.receiverSuburb = cases[0].Article_Receiver_Suburb__c;
				Id consignmentId = cases[0].ArticleTest__c;
				//get child articles for the consignments
				List<Article__c> articles = ArticlesSelector.newInstance().selectById(new Set<Id>{consignmentId}, new Set<Object>{ArticlesSelector.Options.WITH_CHILDARTICLES}).values();

				for(Article__c article : articles) {
					if(article.Articles__r != null && article.Articles__r.size() > 0) {
						for (Article__c a : article.Articles__r) {
							articleIds.add(a.Id);
						}
					}
				}

				if (articleIds.size() > 0) {
					//get articles with event messages
					List<Article__c> articlesWithEventMessages = ArticlesSelector.newInstance().selectById(articleIds, new Set<Object>{ArticlesSelector.Options.WITH_EVENTMESSAGES_DESC_ORDER}).values();

					List<Article__c> articleList = new List<Article__c>();
					for (Article__c aem : articlesWithEventMessages) {
						//add the articles if there are related event messages
						if (aem.Event_Messages__r.size() > 0) {
							articleList.add(aem);
						}
					}

					if (articleList.size() > 0) {
						//get the network for the event messages based on the post office code to render on UI
						//since StarTrack articles eventmessage doesn't have facility populated.
						Map<Id, Network__c> eventMessageToNetworkMap = getEventMessageToNetworkMap(articleList);

						for (Article__c a : articleList) {
							ArticleDetails ad = new ArticleDetails();
							ad.article = a;
							List<EventMessage> emList = new List<EventMessage>();
							//add the articles if related event messages passed through AP network
							for (EventMessage__c em : a.Event_Messages__r) {
								if (eventMessageToNetworkMap.containsKey(em.Id)) {
									EventMessage evm = new EventMessage();
									evm.eventMessage = em;
									evm.network = eventMessageToNetworkMap.get(em.Id);
									//check if any network name contains StarTrack, ignore these events
									if (!evm.network.Name.toLowerCase().contains(STAR_TRACK)) {
										emList.add(evm);
									}
								}
							}
							//if there are event messages add to article details
							if (emList.size() > 0) {
								ad.eventMessages = emList;
							}
							articleDetails.add(ad);
						}
					}
				}

				if (articleDetails.size() > 0) {
					wrapper.hasPassedThroughAPNetwork = true;
					wrapper.articleDetails = articleDetails;
				}
			}
			return wrapper;
			
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * This function get the facility for the event message based on the post office code
	 * This is required to do some validation on the UI based on the network
	 */
	private static Map<Id, Network__c> getEventMessageToNetworkMap(List<Article__c> articles) {
		Map<Id, Network__c> eventMessageToNetworkMap = new Map<Id, Network__c>();
		Map<String, Network__c> networkOrgsMap = new Map<String, Network__c>();
		Set<String> networkOrgs = new Set<String>();

		//Process all ORGs from the incomming events.
		for (Article__c article : articles) {
			for (EventMessage__c e : article.Event_Messages__r) {
				if (e.Post_Office_Code__c != null) {
					networkOrgs.add(e.Post_Office_Code__c);
				}
			}
		}

		if (networkOrgs.size() > 0) {
			//get AP networks related to Org Ids
			for (Network__c nOrg : NetworksSelector.newInstance().selectByOrgId(networkOrgs, new Set<Object> {NetworksSelector.Options.FILTER_AP_NETWORK}).values()) {
				networkOrgsMap.put(nOrg.Org_ID__c, nOrg);
			}

			for (Article__c article : articles) {
				for (EventMessage__c e : article.Event_Messages__r) {
					//Set the ORG on the Event, if it is blank and found.
					if (networkOrgsMap.containsKey(e.Post_Office_Code__c)) {
						e.Facility__c = networkOrgsMap.get(e.Post_Office_Code__c).Id;
						eventMessageToNetworkMap.put(e.Id, networkOrgsMap.get(e.Post_Office_Code__c));
					}
				}
			}
		}

		return eventMessageToNetworkMap;
	}

	/**
	 * Function to create the case investigation records to AP Network
	 */
	@AuraEnabled
	public static SaveResult saveCaseInvestigations(List<CaseInvestigation__c> recordsToSave, String comments) {
		// since we have multiple DML statements we use this to roll back if errors occur
		Savepoint sp = ApplicationDatabase.getInstance().dmlSetSavePoint();
		SaveResult result = new SaveResult();
		try {
			if (String.isBlank(result.errorMessage) && !recordsToSave.isEmpty()) {
				//set the star track record type
				setStarTrackRecordType(recordsToSave);
				// insert case investigation records
				Database.SaveResult[] srList = ApplicationDatabase.getInstance().dmlInsert(recordsToSave);
				// get feed items to post
				if (String.isNotBlank(comments)) {
					List<FeedItem> feedItems = getChatterFeedItems(srList, comments);
					// insert chatter feed items
					if (feedItems.size() > 0) {
						ApplicationDatabase.getInstance().dmlInsert(feedItems);
						result.status = Status.SUCCESSFUL.name();
					} 
				} else {
					result.status = Status.SUCCESSFUL.name();
				}
			}
			return result;
		} catch (DmlException e) {
			// because we are doing multiple DML statements, we want all the DML's to be rolled back
			ApplicationDatabase.getInstance().dmlRollback(sp);
			result.status = Status.ERROR.name();
			for(Integer i = 0; i < e.getNumDml(); i++) {
				result.errorMessage = e.getDmlMessage(i);
				//find the custom validation message by type.
				if (e.getDmlType(i) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
					result.errorMessage = System.Label.MyNetworkDuplicateCaseInvestigationErrorMessage;
				}
			} 
			return result;
		} catch (Exception e) {
			// because we are doing multiple DML statements, we want all the DML's to be rolled back
			ApplicationDatabase.getInstance().dmlRollback(sp);
			//throw all other exceptions
			throw new AuraHandledException(e.getMessage());
		}
	}

	//sets the StarTrack record type for case investigation records
	@TestVisible
	private static void setStarTrackRecordType(List<CaseInvestigation__c> recordsToSave) {
		Id starTrackRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName().get(ST_MYNETWORK_RECORD_TYPE).getRecordTypeId();
		for (CaseInvestigation__c ciRecord : recordsToSave) {
			ciRecord.RecordTypeId = starTrackRecordTypeId;
		}
	}
		

	/**
	 * Function to return the feed items based on network comments
	 */
	@TestVisible
	private static List<FeedItem> getChatterFeedItems(Database.SaveResult[] srList, String comments) {
		Set<Id> caseInvestigationIds = new Set<Id>();
		List<FeedItem> feedItems = new List<FeedItem>();
		// Iterate through each returned result
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				caseInvestigationIds.add(sr.getId());
			}
		}

		//create feed items
		if (caseInvestigationIds.size() > 0) {
			for (Id ciId : caseInvestigationIds) {
				FeedItem item = new FeedItem();
				item.ParentId = ciId;
				item.Body = comments;
				feedItems.add(item);
			}
		}
		return feedItems;
	}

	/**
	 * Function to return the critical incidents knowledge articles
	 */
	@AuraEnabled(cacheable=true)
	public static List<CriticalIncidentWrapper> getCriticalIncidents() {
		List<CriticalIncidentWrapper> wrapperList = new List<CriticalIncidentWrapper>();
		Map<String, List<CriticalIncident>> criticalIncidentMap = new Map<String, List<CriticalIncident>>();

		Set<SObjectField> fields = new Set<SObjectField>{
			Knowledge__kav.Id, Knowledge__kav.NetworkOrgId__c, Knowledge__kav.KnowledgeArticleId, 
			Knowledge__kav.Title, Knowledge__kav.Summary, Knowledge__kav.PublishStatus, Knowledge__kav.language,
			Knowledge__kav.URLName
		};

		KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(fields);
		Map<String, Object> params = new Map<String, Object>{'statuses' => new Set<String>{'Online'}, 'languages' => new Set<String>{'en_US'}, 'recordTypeNames' => new Set<String>{'Critical_Incident'}};
		// query critical incidents knowledge articles
		for (Knowledge__kav ci : kavSelector.search(params, true)){
			if (!String.isBlank(ci.NetworkOrgId__c)) {
				for (String networkOrgId : ci.NetworkOrgId__c.split(';')) {
					if(!String.isEmpty(networkOrgId)) {
						if(criticalIncidentMap.get(networkOrgId) == null) {
							criticalIncidentMap.put(networkOrgId, new List<CriticalIncident>());
						}
						CriticalIncident incident = new CriticalIncident();
						incident.id = ci.Id;
						incident.urlName = ci.UrlName;
						incident.knowledgeArticleId = ci.KnowledgeArticleId;
						criticalIncidentMap.get(networkOrgId).add(incident);
					}
				}
			}
		}

		for (String networkId : criticalIncidentMap.keySet()) {
			CriticalIncidentWrapper wrapper = new CriticalIncidentWrapper();
			wrapper.networkOrgId = networkId;
			wrapper.criticalIncidentList = criticalIncidentMap.get(networkId);
			wrapperList.add(wrapper);
		}
		return wrapperList;
	}

	/**
	 * Function to return the networks based on the postcode suburb and locality id
	 */
	@AuraEnabled
	public static List<NetworkWrapper> getNetworksRelatedToPostcodeSuburbLocality(String suburb, String postcode, String localityId) {
		try {
			List<NetworkWrapper> networkList = new List<NetworkWrapper>();
			Set<Id> networkIds = new Set<Id>();
			if (String.isNotBlank(suburb) || String.isNotBlank(postcode) || String.isNotBlank(localityId)) {
				//get the postcodes with postcode mappings
				Map<String, Object> params = new Map<String, Object>{
					'postcodes' => postcode,
					'suburbs' => suburb,
					'localityIds' => localityId
				};

				for (Postcode__c pc : PostcodesSelector.newInstance().search(params, new Set<Object>{PostcodesSelector.Options.WITH_POSTCODE_MAPPING, 
												PostcodeMappingsSelector.Options.WITH_NETWORK}, true)) {
					if(pc.Postcode_Mappings__r != null && pc.Postcode_Mappings__r.size() > 0) {
						for (PostcodeMapping__c pcm : pc.Postcode_Mappings__r) {
							//get AP network ids where parcel is true and status is not closed
							if(!NetworksSelector.ST_NETWORK_RECORD_TYPES.contains(pcm.Network__r.RecordType.DeveloperName) && pcm.Network__r.Parcel__c && pcm.Network__r.Status__c != 'Closed') {
								networkIds.add(pcm.Network__c);
							}
						}
					}
				}

				if (networkIds.size() > 0) {
					networkList = getNetworkWrapperResults(networkIds);
				}
			}
			return networkList;
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * Function to return the networks based on the name
	 */
	@AuraEnabled
	public static List<NetworkWrapper> getNetworksRelatedToFacilityName(String facilityName) {
		try {
			List<NetworkWrapper> networkList = new List<NetworkWrapper>();
			if (String.isNotBlank(facilityName)) {
				//get AP networks related to facility name
				for (Network__c network : NetworksSelector.newInstance().selectByNetworkNamePartial(facilityName, new Set<Object>{NetworksSelector.Options.FILTER_AP_NETWORK, 
											NetworksSelector.Options.FILTER_IS_PARCEL, NetworksSelector.Options.FILTER_STATUS_NOT_CLOSED, NetworksSelector.Options.FILTER_MYNETWORK})) {
					NetworkWrapper nw = new NetworkWrapper();
					nw.networkId = network.Id;
					nw.network = network;
					nw.isBypassNetwork = false;
					networkList.add(nw);
				}
			}
			return networkList;
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	//funciton to check if any bypass facilities for the networks
	//if bypass facilities found, return the bypass facilities which of MyNetwork otherwise return the MyNetwork facilities.
	private static List<NetworkWrapper> getNetworkWrapperResults(Set<Id> networkIds) {
		List<NetworkWrapper> networkWrapperList = new List<NetworkWrapper>();

		if (networkIds.size() > 0) {
			// get bypass facilities if any
			List<FacilityByPass__c> bypassFacilityList = getBypassFacilitiesForNetworks(networkIds);
			Map<Id, List<FacilityByPass__c>> byPassNetworkToFacilityListMap = new Map<Id, List<FacilityByPass__c>>();

			for (FacilityByPass__c fb : bypassFacilityList) {
				networkIds.add(fb.Facility_By_Pass_To__c);
				//create map with bypass facility to as key and list of facility by pass records
				if(!byPassNetworkToFacilityListMap.containsKey(fb.Facility_By_Pass_To__c)) {
					byPassNetworkToFacilityListMap.put(fb.Facility_By_Pass_To__c, new List<FacilityByPass__c>());
				}
				byPassNetworkToFacilityListMap.get(fb.Facility_By_Pass_To__c).add(fb);
			}

			Set<SObjectField> fieldOverrides = new Set<SObjectField>{ Network__c.Id, Network__c.Org_ID__c, Network__c.Name, 
				Network__c.Contact_Facility__c, Network__c.Phone_Number__c, Network__c.Comment__c, Network__c.Network_Address__c};
			
			//get AP networks where contact facility is of MyNetwork
			Map<Id, Network__c> networkMap = NetworksSelector.newInstance(fieldOverrides).selectById(networkIds, new Set<Object> {NetworksSelector.Options.FILTER_MYNETWORK});
			
			for (Network__c network : networkMap.values()) {
				//if there is bypassnetwork, add the bypass facilities to wrapper
				if (byPassNetworkToFacilityListMap.containsKey(network.Id)) {
					for (FacilityByPass__c fbp : byPassNetworkToFacilityListMap.get(network.Id)) {
						NetworkWrapper nw = new NetworkWrapper();
						nw.networkId = network.Id;
						nw.network = network;
						nw.isBypassNetwork = true;
						nw.bypassNetwork = fbp;
						networkWrapperList.add(nw);
					}
				} else {
					NetworkWrapper nw = new NetworkWrapper();
					nw.networkId = network.Id;
					nw.network = network;
					nw.isBypassNetwork = false;
					networkWrapperList.add(nw);
				}
			}
		}
		return networkWrapperList;
	}

	/**
	 * Function to get the bypass facilites related to network
	 */
	private static List<FacilityByPass__c> getBypassFacilitiesForNetworks(Set<Id> networkIds) {
		List<FacilityByPass__c> networkBypassList = new  List<FacilityByPass__c>();
		if(networkIds.size() > 0) {
			//get bypass facilities related to networkIds
			Map<String, Object> params = new Map<String, Object>{
				'bypassFromIds' => networkIds
			};
			networkBypassList = NetworkBypassesSelector.newInstance().search(params, true);
		}
		return networkBypassList;
	}

	/**
	 * Function to return the postcode record based on postcode and suburb
	 */
	@AuraEnabled
	public static Postcode__c getPostcode(String postcode, String suburb){
		try {
			Postcode__c pc = null;
			if (String.isNotBlank(postcode) || String.isNotBlank(suburb)) {
				Map<String, Object> params = new Map<String, Object>{
					'postcodes' => postcode,
					'suburbs' => suburb
				};
				List<Postcode__c> postcodes = PostcodesSelector.newInstance(1).search(params, true);
				if (postcodes.size() > 0) {
					pc = postcodes[0];
				}
			}
			return pc;
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	public class CriticalIncidentWrapper {
		@AuraEnabled
		public String networkOrgId {get;set;}
		@AuraEnabled
		public List<CriticalIncident> criticalIncidentList {get;set;}
	}

	public class CriticalIncident {
		@AuraEnabled
		public Id id {get;set;}
		@AuraEnabled
		public String urlName {get;set;}
		@AuraEnabled
		public String knowledgeArticleId {get;set;}
	}

	// Status of Case Investigation creation
	public enum Status {
		SUCCESSFUL,
		ERROR
	}

	public class SaveResult {
		@AuraEnabled 
		public String status {get; set;}
		@AuraEnabled 
		public String errorMessage {get; set;}
	}

	public class ArticleResponseWrapper {
		@AuraEnabled
		public List<ArticleDetails> articleDetails {get; set;}
		@AuraEnabled
		public Boolean hasPassedThroughAPNetwork {get; set;}
		@AuraEnabled
		public Boolean hasCaseTypeBlankOnCase {get; set;}
		@AuraEnabled
		public String receiverPostcode {get; set;}
		@AuraEnabled
		public String receiverSuburb {get; set;}
	}

	public class ArticleDetails {
		@AuraEnabled
		public Article__c article {get; set;}
		@AuraEnabled
		public List<EventMessage> eventMessages {get; set;}
	}

	public class EventMessage {
		@AuraEnabled 
		public EventMessage__c eventMessage {get; set;}
		@AuraEnabled
		public Network__c network {get; set;}
	}

	public class NetworkWrapper {
		@AuraEnabled
		public Id networkId {get;set;}
		@AuraEnabled
		public Network__c network {get;set;}
		@AuraEnabled
		public Boolean isBypassNetwork {get;set;}
		@AuraEnabled
		public FacilityByPass__c bypassNetwork {get;set;}
	}

}