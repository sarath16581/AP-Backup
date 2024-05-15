/**
 * @description Used for FacilitySearch page to search facility based on postcode/suburb, or specific addresses
 * @author Jack.li@bluewolf.com
 * @date 2013-13-12
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 9 Sept 2015 - christopher.henschke@auspost.com.au: added subscriberID into ExactTargetEmail class to allow for the use of ExactTarget Preference Centre for unsubscribe
 * 13 Oct 2015 - christopher.henschke@auspost.com.au: updated to improve performance
 * 12-Jan-2016 - kalpita.talwadekar@auspost.com.au  : updated the code to retrieve the critical incidents for networks and make available on the network search
 * 29-Mar-2016 - nandan.narasappa@auspost.com.au	: Commented code to fetch status tracking from getNumbers method as part of performance fix (INC0690144)
 * 7-Apr-2016 - kalpita.talwadekar@auspost.com.au  : updated code to accomodate product standardization messages for international networks
 * 11-Nov-2016 - nandan.narasappa@auspost.com.au  :  updated code to remove validation on Lodgement point for "Missing Item" for REQ0981472
 * 1-feb-2017	kalpita.talwadekar@auspost.com.au   : updated the code to add enterprise, feedback case check for resolution result. And show error to agents to enter 'Resolution Result'.
 * 28-Apr-2017 - Angelo.Rivera@auspost.com.au :	Updated sendAnEmail and sendMultipleEmail method and added contactID parameterthat will be passed to sendSingleMail method as the subscriberID
 * 1-Aug-2017 - nathan.franklin@auspost.com.au :   Update to use Post Code on from case contact only (Remove use of case post code to search page)
 * 2017-10-06 - nathan.franklin@auspost.com.au :   Major backend refactor for performance
 * 2017-10-30 - nathan.franklin@auspost.com.au :   Name change from FacilitySearch to FacilitySearchController
 * 2018-05-15 - Hasantha.Liyanage@auspost.com.au: read the url parameters for isReadOnly, when accessing through cpVisualforceWrapper.cmp
 * 23-feb-2018	kalpita.talwadekar@auspost.com.au   : updated the code to add root cause = AWAITING_NETW0RK_RESPONSE
 * 2018-06-27 - disha.kariya@auspost.com.au :	 Update to use SSSW Routing table for Auto Escalate
 * 2019-02-04 - saiswetha.pingali@auspost.com.au : Reset contact email from unknown@email.com - INC1241392
 * 2019-04-18 - ronnie.yang@sodastrategic.com.au : Hide Business Hubs in search if closed REQ1775138
 * 2021-09-02 - Nathan Franklin - Ordered the Networks in Always Shown by Name, Increased version to 52.0
 * 2021-09-02 - Nathan Franklin - Fixed some SOQL injection attack issues
 * 2024-04-13 - Raghav Ravipati - Replaced Critical incident articaltype with salesforce lighting article Knowledge__kav as part of knowledge lightning uplift
 */
global with sharing class FacilitySearchController {

	// set on every page load
	public transient List<NetworkWrapper> caseNetworks { get; set; }
	public transient List<NetworkWrapper> alwaysShownNetworks { get; set; }
	public transient List<NetworkWrapper> internationalNetworks { get; set; }

	public transient NetworkTabs networkTabs { get; set; }
	public transient String listOfLocations { get; set; }
	public transient Map<String, FieldSet> fieldSets;
	public transient Map<String, List<FieldSetMember>> fieldsByRecordType;
	public transient String addressLocation { get; private set; }

	/**
	 * Cache holding whether or not to display business hours by record type
	 */
	public Map<String, Boolean> displayBusinessHours;

	public Case currentCase { get; set; }
	public Id caseId { get; set; }
	public String caseReferenceId { get; set; }
	public String caseProductSubCategory { get; set; }
	public string caseType { get; private set; }

	public string keyword { get; set; }
	public string senderAddress { get; set; }
	public string recipientAddress { get; set; }

	Map <Id, FacilityByPass__c> byPasses = new Map<Id, FacilityByPass__c>();
	public String str_case_Category { get; set; }

	// displays the address labels with options to pass in custom label names
	// why though... nobody knows!
	public string address1Label { get; private set; }
	public string address2Label { get; private set; }

	public string localityId { get; set; }

	// stores the last search type completed
	// this is used when an international search is completed so we know which search function should be called.
	// we do this because we are using transients
	public String currentSearchType;
	public String currentSearchParam;

	// used in test class
	public static Boolean isTest = false;

	public static final string SOBJECTNAME = 'network__c';
	public string emailContentcase { get; set; }
	public String deliveryNWRecordId { get; set; }
	public String internationalNWRecordDevName { get; set; }
	public string googleMapClient { get; set; }
	public boolean requiresLodgementPoint { get; private set; }
	public boolean contactRequiresEscalation { get; private set; }
	public boolean requiresToSetEmail { get; private set; }

	public Boolean searchedInternationalNetworks { get; set; }
	public String countryName { get; set; }

	private static string UNKNOWN_EMAIL = 'unknown@email.com';
	private static string AWAITING_NETW0RK_RESPONSE = 'Awaiting Network Response';

	// if the page is opened via the iFrame and need to be read only considered
	public Boolean isReadOnly {
		get {
			if(isReadOnly !=null) {
				return isReadOnly;
			}
			String iframeCheck = ApexPages.currentPage().getParameters().get('isReadOnly');
			return ((iframeCheck == null || iframeCheck == 'true') ? true : false);
		}
		set;
	}
	/**
	 * get search facility range(KM) from custom setting
	 */
	private static decimal searchRangeInKM {
		get {
			if (searchRangeInKM == null) {
				searchRangeInKM = [select Range_In_KM__c from FacilitySearchRange__c limit 1][0].Range_In_KM__c;
			}
			return searchRangeInKM;
		}
		private set;
	}

	public Map<Integer, String> tabPositions {
		get {
			if (tabPositions == null) {
				Map<Integer, String> tmpPositions = new Map<Integer, String>();

				for (RecordType recordType : networkRecordTypes) {
					if (recordType.DeveloperName.indexOf('_') == -1) {
						continue;
					}

					String position = recordType.DeveloperName.substring(recordType.DeveloperName.lastIndexOf('_') + 1);
					if (position.isNumeric()) {
						// put these values in a temp variable, it will be sorted later
						tmpPositions.put(Integer.valueOf(position), recordType.DeveloperName);
					}
				}

				List<Integer> keys = new List<Integer>(tmpPositions.keySet());
				keys.sort();

				tabPositions = new Map<Integer, String>();

				// add the case related tab if needed
				if(caseNetworks != null) {
					tabPositions.put(-1000, 'caserelated');
				}

				for (Integer key : keys) {
					tabPositions.put(key, tmpPositions.get(key));
				}
			}

			System.Debug('>> Retrieving tabPositions: ' + tabPositions);

			return tabPositions;
		}
		private set;
	}

	/*
	 * Grabs a list of the record types for used with facility search. This excludes StarTrack network types.
	 */
	public static List<RecordType> networkRecordTypes {
		get {
			if (networkRecordTypes == null) {
				Set<String> allowedList = SSSW_Facility_Search_Record_Types__c.getAll().keySet();
				Map<Id, RecordType> recordTypes = new Map<Id, RecordType>([Select Id, Name, DeveloperName From RecordType
				Where sObjectType = :SOBJECTNAME
				And DeveloperName In :allowedList]);
				System.Debug('>> Record Types: ' + recordTypes);
				networkRecordTypes = recordTypes.values();
			}

			return networkRecordTypes;
		}
		private set;
	}

	public static Map<Id, RecordType> networkRecordTypeMappings {
		get {
			if (networkRecordTypeMappings == null) {
				networkRecordTypeMappings = new Map<Id, RecordType>();
				for(RecordType recordType : networkRecordTypes) {
					networkRecordTypeMappings.put(recordType.Id, recordType);
				}
			}

			return networkRecordTypeMappings;
		}
		private set;
	}

	/*
	 * Grab the id/name mappings of record types
	 */
	public static Map<String, String> networkRecordTypeIdNameMappings {
		get {
			if (networkRecordTypeIdNameMappings == null) {
				networkRecordTypeIdNameMappings = new Map<String, String>();

				for(RecordType recordType : networkRecordTypes) {
					networkRecordTypeIdNameMappings.put(recordType.Id, recordType.Name);
				}
			}

			return networkRecordTypeIdNameMappings;
		}
		private set;
	}

	/*
	 * Grab the developer name mappings of record types
	 */
	public static Map<String, RecordType> networkRecordTypeDevNameMappings {
		get {
			if (networkRecordTypeDevNameMappings == null) {
				networkRecordTypeDevNameMappings = new Map<String, RecordType>();

				for(RecordType recordType : networkRecordTypes) {
					networkRecordTypeDevNameMappings.put(recordType.DeveloperName, recordType);
				}
			}

			return networkRecordTypeDevNameMappings;
		}
		private set;
	}

	/*
	 * Grab the record types loaded into a JSON object and pass them to
	 */
	public static String jsonNetworkRecordTypes {
		get {
			String output = '';
			for (RecordType recordType : networkRecordTypes) {
				output += ',["' + recordType.Id + '","' + recordType.DeveloperName + '"]';
			}

			if (output.length() > 0){
				output = output.substring(1);
			}

			return output;
		}
	}

	public FacilitySearchController() {
		deliveryNWRecordId = 'Delivery_1';
		internationalNWRecordDevName = 'International_4';
		displayBusinessHours = new Map<String, Boolean>();
		requiresLodgementPoint = false;
		requiresToSetEmail = false;
		googleMapClient = Util.googleMapClient();

		networkTabs = new NetworkTabs();

		// populate the address information and any information specific to the passed in Contact, Account or Case.
		loadSourceObjectInformation();

		// populate the business hours map for all network record types
		populateBusinessHoursMap();

		// after all page vars are loaded, because the referred object is a case we do an initial search straight away.
		// this is done to populate basic information about the networks related to the case and the article
		if (currentCase != null && currentCase.Network__c != null && currentCase.Network__r.Geolocation__Latitude__s != null && currentCase.Network__r.Geolocation__Longitude__s != null) {
			string geoCode = currentCase.Network__r.Geolocation__Latitude__s + '_' + currentCase.Network__r.Geolocation__Longitude__s;
			searchFacilitiesByGeoCode(geoCode);
		} else if(currentCase != null && !String.isEmpty(keyword)) {
			searchFacilitiesBySuburbPostcode(keyword);
		} else {
			// load the initial data which just includes the always show networks and the basics.
			setDisplayData();
		}
	}

	public void postback_searchFacilitiesByGeoCode() {
		String geocode = Apexpages.currentPage().getParameters().get('geocode');
		if (String.isBlank(geocode) || geocode.length() < 5 || !geocode.contains('_')) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'Geocode is incorrect. Google map may not work at the moment. Please wait and try again later.');
			ApexPages.addMessage(myMsg);
		} else {
			searchFacilitiesByGeoCode(geocode);
		}

	}

	//return facilities match keyword (either suburb or postcode matches keyword)
	public void postback_searchFacilitiesBySuburbPostCode() {
		searchFacilitiesBySuburbPostcode(keyword);
	}

	public void searchFacilitiesByGeoCode(String geoCode) {

		String caseCategory = findCaseCategory();

		// Check to see if geoCode is blank or not
		Set<Id> networkIds = new Set<Id>();
		List<NetworkWrapper> searchedNetworks = new List<NetworkWrapper>();
		List <Network__c> networksToWrap = new List <Network__c>();
		if (String.isNotBlank(geoCode)) {

			// if the address contains post code , search delivery network by post code
			List<Network__c> deliveryNetworks = new List<Network__c>();
			String[] parameters = geoCode.split('_');
			String postCode;
			if (parameters != null && parameters.size() > 2) {
				postCode = parameters[2];

				if (postcode != null && postcode.length() == 4) {
					deliveryNetworks = getDeliveryNetworks(postCode);

					for(Network__c network : deliveryNetworks) {
						if (!checkPassNetWork(network, caseCategory)) {
							continue;
						}

						networkIds.add(network.Id);
						networksToWrap.add(network);
					}
				}
			}

			addressLocation = '[' + geoCode.split('_')[0] + ', ' + geoCode.split('_')[1] + ']';
			List<Network__c> geoCodeNetworks = getNetworksByGeoCode(geoCode, (deliveryNetworks.size() == 0));
			System.Debug('>> geoCodeNetworks: ' + geoCodeNetworks);

			for (Network__c network : geoCodeNetworks) {
				if (network.RecordType.DeveloperName == 'Delivery_1' && !checkPassNetWorkGeolocation(network, caseCategory)) {
					continue;
				}

				networkIds.add(network.Id);
				networksToWrap.add(network);

			}

			searchedNetworks.addAll(wrapNetworks(networksToWrap));
		}

		// store the current search incase a new international network search is done in the current state
		currentSearchType = 'geocode';
		currentSearchParam = geoCode;

		// collate and load all the data needed for display on the VF page
		setDisplayData(searchedNetworks);
	}

	private void searchFacilitiesBySuburbPostcode(string suburbPostcode) {

		List<NetworkWrapper> searchedNetworks = new List<NetworkWrapper>();
		Set<Id> networkIds = new Set<Id>();

		// parse keyword format: postcode - suburb
		Integer postCode;
		String postCodeStr;
		String suburb;
		String query = '';
		if (!String.isEmpty(suburbPostcode) && suburbPostcode.indexOf('-') > 0) {
			try {
				postCodeStr = suburbPostcode.split('-')[0].trim();
				postCode = Integer.valueOf(postCodeStr);
			} catch (Exception e) {}

			try {
				suburb = suburbPostcode.split('-')[1].trim();
			} catch (Exception e) {}
		}

		System.Debug('>> Using search params: ' + postCodeStr + ', ' + postCode + ', ' + suburb);

		// get the locality id and use that as one of our search conditions
		// this will retrieve all the networks within in a particular locality if it exists
		String localityId = '';
		if (!String.isEmpty(postCodeStr) && !String.isEmpty(suburb)) {
			List<Postcode__c> localityMapping = [Select Locality_Postcode_ID__c From Postcode__c Where Name =: postCodeStr And Suburb__c =: suburb Limit 1];
			if(localityMapping.size() > 0) {
				localityId = localityMapping[0].Locality_Postcode_ID__c;
			}
		}

		if (!String.isEmpty(postCodeStr)) {
			// select our networks based on the postcode / suburb that was passed in.
			query = 'Select Network__c ' +
				'From PostcodeMapping__c ';

			query += 'Where ';
			query += '(Postcode__r.Name = :postCodeStr ';
			if(localityId != null) {
				query += 'Or Postcode__r.Locality_Postcode_ID__c = :localityId) ';
			}
			else{
				query += ') ';
			}

			//REQ1775138 Do not display Business Hubs are that closed ronnie.yang@sodastrategic.com.au		 
			query += 'And ((Network__r.RecordType.DeveloperName = \'Business_Hub_3\' AND Network__r.Status__c != \'Closed\') ';
			query += 'Or Network__r.RecordType.DeveloperName != \'Business_Hub_3\') ';


			System.Debug('>> postCodeStr: ' + postCodeStr);
			System.Debug('>> localityId: ' + localityId);
			System.Debug('>> Running Query: ' + query);
			
			for (PostcodeMapping__c postcodeMapping : Database.query(query)) {
				networkIds.add(postcodeMapping.Network__c);
			}
			
			for(Network__c network : [select Id from Network__c where Post_Code__c =: postCodeStr 
									  AND RecordType.DeveloperName != 'Delivery_1'
									  //REQ1775138 Do not display Business Hubs are that closed ronnie.yang@sodastrategic.com.au
									  AND ((RecordType.DeveloperName = 'Business_Hub_3' AND Status__c != 'Closed')
											OR RecordType.DeveloperName != 'Business_Hub_3')]) {
			   networkIds.add(network.Id);
		   }
		} else {
			List<PostcodeMapping__c> postcodeMappings = new List<PostcodeMapping__c>([Select Network__c, Postcode__r.Name
																					  From PostcodeMapping__c
																					  Where (Postcode__r.Name = :suburbPostcode Or Postcode__r.Suburb__c = :suburbPostcode)
																					  //REQ1775138 Do not display Business Hubs are that closed ronnie.yang@sodastrategic.com.au
																					  And ((Network__r.RecordType.DeveloperName = 'Business_Hub_3' AND Network__r.Status__c != 'Closed')
																						   Or Network__r.RecordType.DeveloperName != 'Business_Hub_3')]);
			for (PostcodeMapping__c postcodeMapping : postcodeMappings) {
				networkIds.add(postcodeMapping.Network__c);
				postCodeStr = postcodeMapping.Postcode__r.Name;
			}
			
			for (network__c n : [select Id from Network__c where (Post_Code__c = :suburbPostcode or ORG_UNIT_ADDR_3__c = :suburbPostcode) AND RecordType.DeveloperName != 'Delivery_1'
								 //REQ1775138 Do not display Business Hubs are that closed ronnie.yang@sodastrategic.com.au
								 AND ((RecordType.DeveloperName = 'Business_Hub_3' AND Status__c != 'Closed')
									  OR RecordType.DeveloperName != 'Business_Hub_3')]) {
										  networkIds.add(n.Id);
									  }
		}
		
		if(!networkIds.isEmpty()) {
			String caseCategory = findCaseCategory();
			System.Debug('Case Category: ' + caseCategory);

			List<Network__c> networks = getNetworksById(networkIds, postCodeStr);
			System.Debug('Found Networks: ' + networks);

			// reset network id's because we might not be keeping all of them
			// we rebuild it below only with the ones that will be displayed on the page
			networkIds.clear();

			List <Network__c> networksToWrap = new List <Network__c> ();

			for(Network__c network : networks) {
				if (network.RecordType.DeveloperName == 'Delivery_1' && !checkPassNetWork(network, caseCategory)) {
					continue;
				}
				if (network.RecordType.DeveloperName == 'General') {
					continue;
				}

				networksToWrap.add(network);
				networkIds.add(network.Id);

			}

			searchedNetworks.addAll(wrapNetworks(networksToWrap));

		}

		// store the current search incase a new international network search is done in the current state
		currentSearchType = 'suburbpostcode';
		currentSearchParam = suburbPostcode;

		// collate and load all the data needed for display on the VF page
		setDisplayData(searchedNetworks);

	}

	public void setDisplayData() {
		setDisplayData(null);
	}

	/**
	 * This will load all the data required to show the visual force page.
	 * This is done on every action because we don't utilise the viewstate.
	 * The cost of these transactions are smaller than the cost of transferring the viewstate
	 */
	public void setDisplayData(List<NetworkWrapper> searchedNetworks) {
		System.Debug('>> country: ' + countryName);

		Set<Id> networkIds = new Set<Id>();
		if(searchedNetworks == null) {
			searchedNetworks = new List<NetworkWrapper>();
		}

		// load case related tabs if applicable
		// this is reset here because our networkTabs variable is transient.
		// the cost of this call is much cheaper than the the cost of passing networkTabs into the viewstate
		caseNetworks = getCaseRelatedNetworks();

		// load the networks that should be visible all the time.
		// these are merged in when a search is completed.
		// this is reset here because our networkTabs variable is transient.
		// the cost of this call is much cheaper than the the cost of passing networkTabs into the viewstate
		alwaysShownNetworks = getAlwaysShownNetworks();
		System.Debug('>> alwaysShownNetworks: ' + alwaysShownNetworks);

		// since we are refreshing the recordtype networks, we add the case related and always shown networks too to retrieve any bypass information
		if(caseNetworks != null) {
			for (NetworkWrapper nw : caseNetworks) {
				networkIds.add(nw.Id);
			}
		}
		if(alwaysShownNetworks != null) {
			for (NetworkWrapper nw : alwaysShownNetworks) {
				networkIds.add(nw.Id);
			}
		}

		// ensure the international networks are loaded if they have a value.
		if(!String.isEmpty(countryName)) {
			searchedNetworks.addAll(getNetworksInternational(countryName));
		}

		// include all the networks search and look for bypass networks
		for(NetworkWrapper wrapper : searchedNetworks) {
			networkIds.add(wrapper.id);
		}

		// we now have all the network ids that will be displayed on the page
		// now we need to check if we should add any bypass networks either as the source or the destination
		searchedNetworks.addAll(loadByPassFacilities(networkIds));

		// this will set a transient variable which is used to display the initial list of networks
		// NOTE: the transient will help keep the view state nice and slim.
		setNetworkTabs(searchedNetworks);

		// build JSON string representation of the network tabs being displayed.
		// this should be refactored eventually.
		setJsonResponse();
	}

	/**
	 * Grab the fields sets which will be mapped to recordtypes.
	 * Fieldsets are in the format of Facility_Search_{record type API name}
	 */
	public Map<String, FieldSet> getFieldSets() {
		if(fieldSets == null) {
			fieldSets = new Map<String, FieldSet>();

			Map<String, Schema.FieldSet> fsMap = Schema.SObjectType.Network__c.fieldSets.getMap();
			for (String key : fsMap.keySet()) {
				fieldSets.put(key.toLowerCase().replace('facility_search_', ''), fsMap.get(key));
			}
		}
		return fieldSets;
	}

	/**
	 * Grab the actual fields that are mapped to recordtypes.
	 */
	public Map<String, List<Schema.FieldSetMember>> getFieldsByRecordType() {
		if(fieldsByRecordType == null) {
			fieldsByRecordType = new Map<String, List<Schema.FieldSetMember>>();

			for (String key : getFieldSets().keySet()) {
				fieldsByRecordType.put(key, fieldSets.get(key).getFields());
			}

			System.Debug('>> Retrieved Fields By Record Type: ' + fieldsByRecordType);
		}
		return fieldsByRecordType;
	}

	/**
	 * This is used to determine whether or not business hours should be displayed on a network
	 * This is defined in the fieldset connected to the recordtype. If the fieldset contains the Display_Business_Hours__c field
	 *	  then this marks that the business hours should be rendered to the screen.
	 */
	public void populateBusinessHoursMap() {
		displayBusinessHours = (Map<String, Boolean>)CacheManager.get('NETWORK_SEARCH_BUSINESS_HOURS');
		if(displayBusinessHours != null) {
			return;
		}

		displayBusinessHours = new Map<String, Boolean>();
		for (RecordType rt : [SELECT DeveloperName FROM RecordType WHERE sObjectType = :SOBJECTNAME AND IsActive = true]) {
			String rtLower = rt.DeveloperName.toLowerCase();

			Boolean showHours = false;
			FieldSet fs = getFieldSets().get(rtLower);

			if (fs != null) {
				for (Schema.FieldSetMember f : fs.getFields()) {
					if (f.getFieldPath() == 'Display_Business_Hours__c') {
						showHours = true;
						break;
					}
				}
			}

			displayBusinessHours.put(rt.DeveloperName, showHours);
		}

		CacheManager.put('NETWORK_SEARCH_BUSINESS_HOURS', displayBusinessHours);
	}

	/**
	 * This will build a list of networks into a format the page uses to build map markers.
	 * Ideally, this should use JSON serialize rather than manually building this string.
	 */
	private void setJsonResponse() {
		listOfLocations = '';

		// make sure we have values to process
		if(networkTabs != null && networkTabs.tabCount() == 0) {
			return;
		}

		for(NetworkTab tab : networkTabs.getTabs().values()) {
			if(tab.networks != null) {
				for (NetworkWrapper wrapper : tab.networks) {
					if (!String.isEMpty(wrapper.lat) && !String.isEMpty(wrapper.lon)) {
						listOfLocations += ',["' + string.escapeSingleQuotes(wrapper.Name) + '",' + wrapper.lat + ','
							+ wrapper.lon + ',"' + wrapper.recordTypeId + '","' + wrapper.id + '","'
							+ (wrapper.ORG_UNIT_ADDR_2 != null ? string.escapeSingleQuotes(wrapper.ORG_UNIT_ADDR_2) : '') + '","'
							+ (wrapper.ORG_UNIT_ADDR_3 != null ? string.escapeSingleQuotes(wrapper.ORG_UNIT_ADDR_3) : '') + '", "'
							+ wrapper.recordTypeDevName + '"]';
					}
				}
			}
		}

		if(!String.isEmpty(listOfLocations)) {
			listOfLocations = listOfLocations.substring(1);
		}
	}

	/**
	 * this will set the transient networkTabs which should be set on every post back (thats not a remoting call)
	 * This ensures the view state stays nice and slim
	 */
	public void setNetworkTabs() {
		setNetworkTabs(null);
	}

	/**
	 * Builds the displayable list of tabs for the visual force page.
	 * This takes into account Case related networks, always shown networks, bypass networks and searched networks
	 */
	public void setNetworkTabs(List<NetworkWrapper> searchedNetworks) {

		Map<String, List<Knowledge__kav>> criticalIncidents = getCriticalIncidents();

		networkTabs = new NetworkTabs();

		// this used to build up all the displayable networks by record type
		// each record type represents a tab on the page.
		Map<String, NetworkTab> recordTypeTabMaps = new Map<String, NetworkTab>();

		// load the case related
		if(caseNetworks != null) {
			networkTabs.addTab('caserelated', new NetworkTab('Case Related', 'caserelated', 'caserelated', caseNetworks));
		}

		// check if the search networks need to be added.
		if(searchedNetworks != null && searchedNetworks.size() > 0) {
			for(NetworkWrapper wrapper : searchedNetworks) {
				if(recordTypeTabMaps.get(wrapper.recordTypeDevName) == null) {
					RecordType rt = networkRecordTypeDevNameMappings.get(wrapper.recordTypeDevName);
					recordTypeTabMaps.put(wrapper.recordTypeDevName, new NetworkTab(rt.Name, rt.DeveloperName, rt.Id));
				}

				if(criticalIncidents.get(wrapper.orgId) != null) {
					System.Debug('>> Found Critical Incident: ' + criticalIncidents.get(wrapper.orgId));
					wrapper.criticalIncidents.addAll(criticalIncidents.get(wrapper.orgId));
				}
				recordTypeTabMaps.get(wrapper.recordTypeDevName).addNetwork(wrapper);
			}
		}

		// add the always shown networks
		//System.Debug('>> alwaysShownNetworks: ' + alwaysShownNetworks);
		if(alwaysShownNetworks != null) {
			for(NetworkWrapper wrapper : alwaysShownNetworks) {
				if(recordTypeTabMaps.get(wrapper.recordTypeDevName) == null) {
					RecordType rt = networkRecordTypeDevNameMappings.get(wrapper.recordTypeDevName);
					recordTypeTabMaps.put(wrapper.recordTypeDevName, new NetworkTab(rt.Name, rt.DeveloperName, rt.Id));
				}

				if(criticalIncidents.get(wrapper.orgId) != null) {
					System.Debug('>> Found Critical Incident: ' + criticalIncidents.get(wrapper.orgId));
					wrapper.criticalIncidents.addAll(criticalIncidents.get(wrapper.orgId));
				}
				recordTypeTabMaps.get(wrapper.recordTypeDevName).addNetwork(wrapper);
			}
		}

		// now we need to build each record tab and assign it to the networkTabs which is used to build the VF page
		// this is done by display priority
		for(String recordType : tabPositions.values()) {
			if(recordType == 'caserelated') {
				// this was already added to networktabs above.
				continue;
			}
			if(recordTypeTabMaps.get(recordType) != null) {
				networkTabs.addTab(recordType, recordTypeTabMaps.get(recordType));
			} else {
				RecordType rt = networkRecordTypeDevNameMappings.get(recordType);
				networkTabs.addTab(recordType, new NetworkTab(rt.Name, rt.DeveloperName, rt.Id));
			}
		}
	}

	/**
	 * If a case id is passed in to the page then we make sure we load all the network related info on the case.
	 */
	public List<NetworkWrapper> getCaseRelatedNetworks() {

		// only proceed if a case was loaded
		if(currentCase == null) {
			return null;
		}

		List<Case> allCases = new List<Case>();
		Set<Id> networkIds = new Set<Id>();
		List<Id> articleIds = new List<Id>();
		Map<Id, String> eventMessageFacilityDescriptions = new Map<Id, String>();
		Map<Id, String> messageFacilityPrefixes = new Map<Id, String>();
	   
		allCases.add(currentCase);

		// loop through all the child cases to grab related information
		if(currentCase.Cases != null) {
			allCases.addAll(currentCase.Cases);
		}

		for(Case theCase : allCases) {
			// load the network connected to the case;
			if (theCase.Network__c != null) {
				networkIds.add(theCase.Network__c);
				messageFacilityPrefixes.put(theCase.Network__c, 'Case: ');
			}

			// load the networks connected to the event messages
			if (theCase.ArticleTest__c != null) {
				articleIds.add(theCase.ArticleTest__c);
			}
		}

		if(!articleIds.isEmpty()) {
			// grab the networks from event messages
		 set<string> blacklistedeventtypes = SSSW_Blacklisted_Event_Types__c.getall().keyset();
			for(EventMessage__c message : [Select Facility__c, Article__r.ReceiverCountryName__c, ActualDateTime__c, EventDescription__c, Facility__r.Name
			From EventMessage__c
			Where Article__c in :articleIds
			And EventType__c not in :blacklistedeventtypes
			Order by ActualDateTime__c desc]) {
				if(message.Facility__c != null) {
					// set the country name of the first valid event
					if (String.isEmpty(countryName) && message.Article__r != null && String.isNotEmpty(message.Article__r.ReceiverCountryName__c)) {
						countryName = message.Article__r.ReceiverCountryName__c;
					}

					String scanDateTime = '';
					if (message.ActualDateTime__c == null) {
						scanDateTime = 'Unknown';
					} else {
						scanDateTime = message.ActualDateTime__c.format('dd/MM/yyyy HH:mm:ss');
					}

					if(eventMessageFacilityDescriptions.get(message.Facility__c) == null) {
						eventMessageFacilityDescriptions.put(message.Facility__c, 'Event Message: ' + message.Facility__r.Name + ' - ' + message.EventDescription__c + ' @ ' + scanDateTime);
					}

					networkIds.add(message.Facility__c);
				}
			}
		}

		System.Debug('>> Case Related Networks: ' + networkIds);

		// load the actual networks related to the case now we have fully populated the list
		List<NetworkWrapper> wrappedNetworks = new List<NetworkWrapper>();
		Map<Id, Network__c> networks = new Map<Id, Network__c>();
		if(!networkIds.isEmpty()) {
			networks = new Map<Id, Network__c>(getNetworksById(networkIds));

			// convert name of network for allevent messages
			for(Id networkId : eventMessageFacilityDescriptions.keySet()) {
				networks.get(networkId).Name = eventMessageFacilityDescriptions.get(networkId);
			}
			// add the 'case' word if needed.
			for(Id networkId : messageFacilityPrefixes.keySet()) {
				if(eventMessageFacilityDescriptions.get(networkId) == null) {
					networks.get(networkId).Name = messageFacilityPrefixes.get(networkId) + networks.get(networkId).Name;
				}
			}

			wrappedNetworks = wrapNetworks(networks.values());
		}

		return wrappedNetworks;
	}

	/**
	 * Because different record types have different field selections,
	 *  we grab all the fields from all the fieldsets including a few
	 *  generic ones and select these out for all
	 */
	public String getSelectableFields() {
		Set<String> selectableFields;

		String fields = String.valueOf(CacheManager.get('NETWORK_SEARCH_SELECTABLE_FIELDS'));
		if(!String.isEmpty(fields)) {
			return fields;
		}

		selectableFields = new Set<String>{
			'AlwaysShown__c', 'Hatch_Desc__c', 'Name', 'Geolocation__Longitude__s', 'Geolocation__Latitude__s',
			'RecordTypeId', 'Id', 'ORG_UNIT_ADDR_2__c', 'ORG_UNIT_ADDR_3__c', 'State__c', 'Email_1__c',
			'RecordType.Name', 'RecordType.DeveloperName', 'Email__c', 'Comment__c', 'Contact_Facility__c',
			'Courier__c', 'EMS_Delivery__c', 'Sea_Parcel__c',  'Registered_Post__c', 'Small_Packet_Air__c',
			'Pack_Track_Asia_Pacific_Parcel__c', 'Air_Parcel_Air_Parcel_Insured__c',
			'Mon__c', 'CL_Mon__c', 'Hatch_Mon__c',
			'Tue__c', 'CL_Tue__c', 'Hatch_Tue__c',
			'Wed__c', 'CL_Wed__c', 'Hatch_Wed__c',
			'Thu__c', 'CL_Thu__c', 'Hatch_Thu__c',
			'Fri__c', 'CL_Fri__c', 'Hatch_Fri__c',
			'Sat__c', 'CL_Sat__c', 'Hatch_Sat__c',
			'Sun__c', 'CL_Sun__c', 'Hatch_Sun__c'
		};

		for(String key : getFieldSets().keySet()) {
			for(FieldSetMember member : getFieldSets().get(key).getFields()) {
				selectableFields.add(member.getFieldPath());
			}
		}

		fields = String.join(new List<String>(selectableFields), ', ');
		CacheManager.put('NETWORK_SEARCH_SELECTABLE_FIELDS', fields);

		return fields;
	}

	public List<Network__c> getNetworksById(Set<Id> ids) {
		return getNetworksById(ids, '');
	}

	/**
	 * Retrieve all networks based on Id's
	 * Optionally can pass in a postcode to retreive all postcode mappings that match a specific postcode.
	 */
	public List<Network__c> getNetworksById(Set<Id> ids, String postCode) {
		Set<Id> includedRecordTypeIds = networkRecordTypeMappings.keySet();
		String fields = getSelectableFields();
		// some requirement in searchFacilitiesBySuburbPostcode requires this child object, but only when postcode is available
		// it's not clear what it's used for apart from hiding specific networks based on case category.
		if(!String.isEmpty(postCode)) {
			fields += ',(SELECT UniqueKey__c FROM Postcode_Mappings__r WHERE Postcode__r.name = :postCode)';
		}
		//NOTE, I get that String.escapeSingleQuotes is probably not really necessary here, but I'd rather the query fail if quotes are introduced then allowing injection attacks
		String soql = 'Select ' + String.escapeSingleQuotes(fields) + ' From Network__c Where Id in :ids And RecordTypeId In :includedRecordTypeIds Order By State__c, Name Asc';
		List<Network__c> networks = Database.query(soql);
		return networks;
	}

	public List<NetworkWrapper> getNetworksInternational(String countryName) {
		String cn = '%' + countryName + '%';
		String fields = getSelectableFields();
		//NOTE, I get that String.escapeSingleQuotes is probably not really necessary here, but I'd rather the query fail if quotes are introduced then allowing injection attacks
		String soql = 'Select ' + String.escapeSingleQuotes(fields) + ' From Network__c Where name like :cn And RecordType.DeveloperName = \'International_4\' Order By State__c, Name Asc';
		List<Network__c> networks = Database.query(soql);
		List<NetworkWrapper> wrappedNetworks = wrapNetworks(networks);
		for(NetworkWrapper wrapper : wrappedNetworks) {
			//added by kalpita for prd stad
			wrapper.prdStdMessag = 'Refer to Knowledge for contact method';
			wrapper.nwExtSystemValue = '';
			if (!String.isBlank(caseReferenceId)) {
				wrapper = prodStdMessageCapture(wrapper, caseReferenceId, currentCase);
			}
		}
		return wrappedNetworks;
	}

	public List<Network__c> getNetworksByGeoCode(String geoCode, Boolean withDeliveryNetworks) {
		Set<Id> includedRecordTypeIds = networkRecordTypeMappings.keySet();
		String fields = getSelectableFields();
		String soql = 'Select ' + String.escapeSingleQuotes(fields) + ' From Network__c ' +
			'Where RecordType.DeveloperName<>\'General\' ' +
			'And DISTANCE(Geolocation__c, GEOLOCATION(' + String.escapeSingleQuotes(geoCode.split('_')[0]) + ',' + String.escapeSingleQuotes(geoCode.split('_')[1]) + '), \'km\') < ' + searchRangeInKM;

		if (!withDeliveryNetworks) {
			soql += ' And RecordType.DeveloperName != \'Delivery_1\'';
		}

		//REQ1775138 Do not display Business Hubs are that closed ronnie.yang@sodastrategic.com.au
		soql += 'AND ((RecordType.DeveloperName = \'Business_Hub_3\' AND Status__c != \'Closed\') OR RecordType.DeveloperName != \'Business_Hub_3\') ';
		soql += 'And RecordTypeId In :includedRecordTypeIds ';
		soql += 'Order By DISTANCE(Geolocation__c, GEOLOCATION(' + String.escapeSingleQuotes(geoCode.split('_')[0]) + ',' + String.escapeSingleQuotes(geoCode.split('_')[1]) + '), \'km\') ';

		List<Network__c> networks = Database.query(soql);
		return networks;
	}

	/**
	 * List of networks that are always visible regardless of individual settings
	 */
	public List<NetworkWrapper> getAlwaysShownNetworks() {
		List<NetworkWrapper> wrappedNetworks;
		wrappedNetworks = (List<NetworkWrapper>)CacheManager.get('NETWORK_SEARCH_ALWAYS_SHOW_NETWORKS', UserInfo.getProfileId());
		if(wrappedNetworks != null) {
			return wrappedNetworks;
		}

		Set<Id> includedRecordTypeIds = networkRecordTypeMappings.keySet();
		String fields = getSelectableFields();
		//NOTE, I get that String.escapeSingleQuotes is probably not really necessary here, but I'd rather the query fail if quotes are introduced then allowing injection attacks
		String soql = 'Select ' + String.escapeSingleQuotes(fields) + ' From Network__c Where AlwaysShown__c = true And RecordType.DeveloperName != \'International_4\' And RecordTypeId In :includedRecordTypeIds Order By Name';

		wrappedNetworks = wrapNetworks(Database.query(soql));
		CacheManager.put('NETWORK_SEARCH_ALWAYS_SHOW_NETWORKS', UserInfo.getProfileId(), wrappedNetworks);

		return wrappedNetworks;
	}

	public List<Network__c> getDeliveryNetworks(String postCode) {
		Set<Id> includedRecordTypeIds = networkRecordTypeMappings.keySet();
		String fields = getSelectableFields();
		//NOTE, I get that String.escapeSingleQuotes is probably not really necessary here, but I'd rather the query fail if quotes are introduced then allowing injection attacks
		String soql = 'Select ' + String.escapeSingleQuotes(fields) + ',(SELECT UniqueKey__c FROM Postcode_Mappings__r WHERE Postcode__r.name = :postCode) ' +
			'From Network__c ' +
			'Where RecordType.DeveloperName = \'Delivery_1\' ' +
			'And Id in (Select Network__c From PostcodeMapping__c ' +
			'	  Where Postcode__r.Name = :postCode) ' +
			'And RecordTypeId In :includedRecordTypeIds ' +
			'Order By State__c, Name Asc';
		List<Network__c> networks = Database.query(soql);
		return networks;
	}

	public List<PostcodeMapping__c> getPostCodeMappings(String postCode) {
		return [Select Locality_Id__c, Postcode__c, Suburb__c, UniqueKey__c, Network__c
				From PostcodeMapping__c
				Where Postcode__r.Name = :postCode
				//REQ1775138 Do not display Business Hubs are that closed ronnie.yang@sodastrategic.com.au
				And ((Network__r.RecordType.DeveloperName = 'Business_Hub_3' AND Network__r.Status__c != 'Closed')
					  Or Network__r.RecordType.DeveloperName != 'Business_Hub_3')];
	}

	public List<SelectOption> networkExternalSystem {
		get {
			if (networkExternalSystem == null) {
				networkExternalSystem = new List<SelectOption >();
				networkExternalSystem.add(new SelectOption('', '--NONE--'));
				Schema.DescribeFieldResult field = Network__c.ExternalSystem__c.getDescribe();
				for (Schema.PicklistEntry f : field.getPicklistValues()) {
					networkExternalSystem.add(new SelectOption(f.getLabel(), f.getLabel()));
				}

			}
			return networkExternalSystem;
		}
		private set;
	}

	public void loadInternationalNetworks() {
		System.Debug('Searching International Networks By: ' + countryName);

		// show that an initial search of international networks has been completed
		searchedInternationalNetworks = true;

		// because we requery the database when an international network is search
		// these variables contain the info on the last searched network
		// we do this to save the viewstate.
		if(currentSearchType == 'geocode' && !String.isEmpty(currentSearchParam)) {
			searchFacilitiesByGeoCode(currentSearchParam);
		} else if(currentSearchType == 'suburbpostcode' && !String.isEmpty(currentSearchParam)) {
			searchFacilitiesBySuburbPostcode(currentSearchParam);
		} else {
			// reset the tabs
			setDisplayData();
		}
	}

	/**
	  * @description	   method to loop through the networks and check the type and display appropriate message
	  * @param			 NetworkWrapper wrapper, String articleId, Network__c f
	  * @return			Facilities
	  *
	  */
	public NetworkWrapper prodStdMessageCapture(NetworkWrapper wrapper, String articleId, Case currCase) {
		Network__c f = wrapper.network;

		Set<String> EMSDelList = new Set<String>{
			'EJ', 'EW', 'EY', 'EE', 'EQ', 'EX'
		};
		Set<String> seaParcelList = new Set<String>{
			'CT', 'CR', 'CU'
		};
		Set<String> pcTrackList = new Set<String>{
			'LK', 'LP', 'LY', 'LZ'
		};
		Set<String> smallParcelList = new Set<String>{
			'UA', 'UW', 'LC', 'LX', 'UC', 'LS', 'US', 'UX'
		};
		Set<String> airParcelList = new Set<String>{
			'CF', 'CW', 'CY', 'CP', 'CR', 'CV'
		};
		Set<String> regPostList = new Set<String>{
			'RA', 'RR', 'RP', 'RQ', 'RS'
		};

		if (!String.isBlank(f.Courier__c) && 'DHL'.equalsIgnoreCase(f.Courier__c) &&
			('International Courier'.equalsIgnoreCase(currCase.ProductSubCategory__c) || 'ECI Platinum'.equalsIgnoreCase(currCase.ProductSubCategory__c))) {
			wrapper.prdStdMessag = LABEL.CL_Courier_DHL;
		} else if (!String.isBlank(f.Courier__c) && 'Product not available'.equalsIgnoreCase(f.Courier__c) &&
			('International Courier'.equalsIgnoreCase(currCase.ProductSubCategory__c) || 'ECI Platinum'.equalsIgnoreCase(currCase.ProductSubCategory__c))) {
			wrapper.prdStdMessag = LABEL.CL_Courier_ProdNA;
		} else if (!String.isBlank(f.EMS_Delivery__c) && 'DHL'.equalsIgnoreCase(f.EMS_Delivery__c) &&
			(EMSDelList.contains(String.valueOf(articleId).substring(0, 2)))) {
			//'PRX'.equalsIgnoreCase(String.valueOf(articleId).substring(0,3)) ) ) {
			wrapper.prdStdMessag = LABEL.CL_EMSDelivery_DHL;
		} else if (!String.isBlank(f.EMS_Delivery__c) && 'Local Postal Authority'.equalsIgnoreCase(f.EMS_Delivery__c) &&
			(EMSDelList.contains(String.valueOf(articleId).substring(0, 2)))) {
			//'PRX'.equalsIgnoreCase(String.valueOf(articleId).substring(0,3)) ) ) {
			wrapper.prdStdMessag = LABEL.CL_EMSDelivery_LocalPostAuth;
			wrapper.nwExtSystemValue = 'Rugby';
		} else if (!String.isBlank(f.EMS_Delivery__c) && 'Product not available'.equalsIgnoreCase(f.EMS_Delivery__c) &&
			(EMSDelList.contains(String.valueOf(articleId).substring(0, 2)))) {
			//'PRX'.equalsIgnoreCase(String.valueOf(articleId).substring(0,3)) ) ) {
			wrapper.prdStdMessag = LABEL.CL_EMSDelivery_ProdNA;
		} else if (!String.isBlank(f.Sea_Parcel__c) && 'European'.equalsIgnoreCase(f.Sea_Parcel__c) &&
			seaParcelList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_SeaParcel_European;
		} else if (!String.isBlank(f.Sea_Parcel__c) && 'Non-European'.equalsIgnoreCase(f.Sea_Parcel__c) &&
			seaParcelList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_SeaParcel_NonEuropean;
			wrapper.nwExtSystemValue = 'Cricket';
		} else if (!String.isBlank(f.Sea_Parcel__c) && 'Product not available'.equalsIgnoreCase(f.Sea_Parcel__c) &&
			seaParcelList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_SeaParcel_ProdNA;
		} else if (!String.isBlank(f.Registered_Post__c) && 'PRIME'.equalsIgnoreCase(f.Registered_Post__c) &&
			regPostList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_RegPost_Prime;
			wrapper.nwExtSystemValue = 'Prime';
		} else if (!String.isBlank(f.Registered_Post__c) && 'CN08 - email'.equalsIgnoreCase(f.Registered_Post__c) &&
			regPostList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_RegPost_CN08email;
			wrapper.nwExtSystemValue = 'CN08 - Email';
		} else if (!String.isBlank(f.Registered_Post__c) && 'CN08 - post'.equalsIgnoreCase(f.Registered_Post__c) &&
			regPostList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_RegPost_CN08post;
			wrapper.nwExtSystemValue = 'CN08 - Post';
		} else if (!String.isBlank(f.Registered_Post__c) && 'Product not available'.equalsIgnoreCase(f.Registered_Post__c) &&
			regPostList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_RegPost_ProdNA;
		} else if (!String.isBlank(f.Small_Packet_Air__c) && 'No international enquiry can be lodged'.equalsIgnoreCase(f.Small_Packet_Air__c) &&
			smallParcelList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_SmallPcktAir;
		} else if (!String.isBlank(f.Small_Packet_Air__c) && 'Product not available'.equalsIgnoreCase(f.Small_Packet_Air__c) &&
			smallParcelList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_SmallPcktAir_prodNA;
		} else if (!String.isBlank(f.Pack_Track_Asia_Pacific_Parcel__c) && 'PRIME'.equalsIgnoreCase(f.Pack_Track_Asia_Pacific_Parcel__c) &&
			pcTrackList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_PackTrack_Prime;
			wrapper.nwExtSystemValue = 'Prime';
		} else if (!String.isBlank(f.Pack_Track_Asia_Pacific_Parcel__c) && 'Product not available'.equalsIgnoreCase(f.Pack_Track_Asia_Pacific_Parcel__c) &&
			pcTrackList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_PackTrack_ProdNA;
		} else if (!String.isBlank(f.Air_Parcel_Air_Parcel_Insured__c) && 'Cricket'.equalsIgnoreCase(f.Air_Parcel_Air_Parcel_Insured__c) &&
			airParcelList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_AirParcel_Cricket;
			wrapper.nwExtSystemValue = 'Cricket';
		} else if (!String.isBlank(f.Air_Parcel_Air_Parcel_Insured__c) && 'Product not available'.equalsIgnoreCase(f.Air_Parcel_Air_Parcel_Insured__c) &&
			airParcelList.contains(String.valueOf(articleId).substring(0, 2))) {
			wrapper.prdStdMessag = LABEL.CL_AirParcel_ProdNA;
		}

		return wrapper;
	}


	public boolean getAllowContactNetwork() {
		//return caseID != null && caseID.startsWith(Case.sObjectType.getDescribe().getKeyPrefix());
		if (ApexPages.currentPage().getParameters().get('id') <> null && ApexPages.currentPage().getParameters().get('id').length() > 0) {
			return CommonUtils.getObjectAPINameByRecordId(ApexPages.currentPage().getParameters().get('id')) == 'Case';
		} else {
			return false;
		}
	}

	@RemoteAction
	global static string lodgementPoint(id caseId, id facilityId) {
		string result = '';
		try {
			List<Case> cases = [select Lodgement_Network__c from case where id = :caseId];
			if (cases.size() > 0) {
				cases[0].Bypass_Data_enforcement__c = true;
				cases[0].Lodgement_Network__c = facilityId;
				update cases[0];
				result = 'Lodgement Point set successfully...';
			} else {
				result = 'Error: Unable to find Case with id = ' + caseId;
			}
		} catch (Exception ex) {
			result = 'Error:' + ex.getMessage();
		}
		return result;
	}

	/**
	  * retrieve the critical incidents for networks and make available on the network search
	  */
	private Map<String, List<Knowledge__kav>> getCriticalIncidents() {
		Map<String, List<Knowledge__kav>> criticalIncidentMap;
		criticalIncidentMap = (Map<String, List<Knowledge__kav>>)CacheManager.get('NETWORK_SEARCH_INCIDENTS', UserInfo.getProfileId());
		if(criticalIncidentMap != null) {
			return criticalIncidentMap;
		}

		try {
			criticalIncidentMap = new Map<String, List<Knowledge__kav>>();
			Set<SObjectField> fields = new Set<SObjectField>{
				Knowledge__kav.Id,
				Knowledge__kav.Message__c,
				Knowledge__kav.NetworkOrgId__c,
				Knowledge__kav.KnowledgeArticleId,
				Knowledge__kav.UrlName,
				Knowledge__kav.Title
			};
			Map<String, Object> params = new Map<String, Object>{'statuses' => new Set<String>{'Online'}, 'languages' => new Set<String>{'en_US'}, 'recordTypeNames' => new Set<String>{'Critical_Incident'}};
			KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(fields);
						
			for (Knowledge__kav criticalIncident : (List<Knowledge__kav>) kavSelector.search(params, true)) {
				if (!String.isBlank(criticalIncident.NetworkOrgId__c)) {
					for (String networkOrgId : criticalIncident.NetworkOrgId__c.split(';')) {
						if(!String.isEmpty(networkOrgId)) {
							if(criticalIncidentMap.get(networkOrgId) == null) {
								criticalIncidentMap.put(networkOrgId, new List<Knowledge__kav>());
							}
							criticalIncidentMap.get(networkOrgId).add(criticalIncident);
						}
					}
				}
			}
		} catch (Exception exp) {
			//log the exception
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
				FacilitySearchController.class.getName(), 'getSystemFacilityList',
				'', LoggingLevel.ERROR);
		}

		// 5 min cache
		CacheManager.put('NETWORK_SEARCH_INCIDENTS', UserInfo.getProfileId(), criticalIncidentMap);
		return criticalIncidentMap;
	}


	// returns an empty string
	private string nullToString(string nullString) {
		string emptyString = nullString == null ? '' : nullString;
		return emptyString;
	}

	//get addresses based on object type: either contact or case; get address fields lables from URL
	private void loadSourceObjectInformation() {
		str_case_Category = 'This_is_NOT_CASE';
		String recordId = ApexPages.currentPage().getParameters().get('id');
		String contactId = ApexPages.currentPage().getParameters().get('contactId');

		if (String.isNotBlank(recordId)) {

			if (CommonUtils.getObjectAPINameByRecordId(recordId) == 'Case') {
				List<Case> cases = [select EnquirySubType__c, CaseOriginator__c, Address1Postcode__c, Address2Postcode__c, Address2State__c, Address2Suburb__c, Address1__c,
					Address2__c, recordtype.name, Network__c, Network__r.Geolocation__Longitude__s, Network__r.Geolocation__Latitude__s,
					Network__r.State__c, Type, ArticleTest__c, ProductCategory__c, Contactid, Contact.MailingStreet,
					Contact.MailingStreet2__c, Contact.MailingCity, Contact.MailingState, Contact.MailingPostalCode,
					Contact.MailingCountry, Contact.OtherStreet, Contact.OtherStreet2__c, Contact.OtherCity,
					Contact.OtherState, Contact.OtherPostalCode, Contact.OtherCountry, Lodgement_Network__c,
					Contact.isPersonAccount, Contact.Email, IsHLC__c, IsCR__c, Status, IsNew__c, 
					ProductSubCategory__c, ReferenceID__c, Customer_Type__c, IsNewForRouting__c, Origin,
				(Select Id, ArticleTest__c, Network__c From Cases)
				from Case
				where id = :recordId];

				System.Debug('>> Found Cases: ' + cases);

				if (cases.size() > 0) {
					currentCase = cases[0];
					caseId = cases[0].Id;
					caseProductSubCategory = cases[0].ProductSubCategory__c;
					caseReferenceId = cases[0].ReferenceID__c;

					// check if contact should be auto escalated
					setContactRequiresEscalation();

					// populate our variables to use throughout this page
					caseType = currentCase.type + (string.isEmpty(currentCase.EnquirySubType__c) ? '' : ' - ' + currentCase.EnquirySubType__c);
					str_case_Category = currentCase.ProductCategory__c;
					requiresToSetEmail = currentCase.Contact != null && currentCase.Contact.isPersonAccount && String.isBlank(currentCase.Contact.Email);
					senderAddress = nullToString(cases[0].address1__c);
					recipientAddress = nullToString(cases[0].address2__c);

					if (!String.isBlank(currentCase.EnquirySubType__c)) {
						// 21/11/2016 : Nandan N - Removed validation on lodgementPoint for missing item for REQ0981472
						requiresLodgementPoint = (currentCase.Lodgement_Network__c == null && currentCase.EnquirySubType__c.toLowerCase().contains('delayed'));
					}

					// use the receiver address on the case if it is available
					// if not we default to the contact address (if it's available)
					if(!String.isEmpty(cases[0].Address2Postcode__c)) {
						keyword = cases[0].Address2Postcode__c + (!String.isEmpty(cases[0].Address2Suburb__c) ? ' - ' + cases[0].Address2Suburb__c.toUpperCase() : '') + (!String.isEmpty(cases[0].Address2State__c) && !String.isEmpty(cases[0].Address2Suburb__c) ? '(' + cases[0].Address2State__c.toUpperCase() + ')' : '');
					} else if(!String.isBlank(nullToString(cases[0].ContactId))) {
						keyword = nullToString(cases[0].Contact.MailingPostalCode) + ' - ' + nullToString(cases[0].Contact.MailingCity) + '(' + nullToString(cases[0].Contact.MailingState) + ')';
					} else {
						keyword = '';
					}

					// if case has no addresses, try and get from the contact details - QC650
					if(String.isblank(senderAddress) && String.isblank(recipientAddress) && !String.isBlank(nullToString(cases[0].Contactid))) {
						senderAddress = nullToString(cases[0].Contact.MailingStreet) + ' ' + nullToString(cases[0].Contact.MailingStreet2__c) + ', ' + nullToString(cases[0].Contact.MailingCity) + ' ' + nullToString(cases[0].Contact.MailingState) + ' ' + nullToString(cases[0].Contact.MailingPostalCode) + ' ' + nullToString(cases[0].Contact.MailingCountry);
						recipientAddress = nullToString(cases[0].Contact.OtherStreet) + ' ' + nullToString(cases[0].Contact.OtherStreet2__c) + ', ' + nullToString(cases[0].Contact.OtherCity) + ' ' + nullToString(cases[0].Contact.OtherState) + ' ' + nullToString(cases[0].Contact.OtherPostalCode) + ' ' + nullToString(cases[0].Contact.OtherCountry);
					}
				}
			} else if (CommonUtils.getObjectAPINameByRecordId(recordId) == 'Account') {
				Account anAccount = [Select PersonOtherStreet, PersonOtherCity, PersonOtherState, PersonMailingStreet, PersonMailingCity, PersonMailingState From Account at where id = :recordId][0];
				senderAddress = nullToString(anAccount.PersonMailingStreet) + ' ' + nullToString(anAccount.PersonMailingCity) + ' ' + nullToString(anAccount.PersonMailingState);
				recipientAddress = nullToString(anAccount.PersonOtherStreet) + ' ' + nullToString(anAccount.PersonOtherCity) + ' ' + nullToString(anAccount.PersonOtherState);
			} else if (CommonUtils.getObjectAPINameByRecordId(recordId) == 'Contact') {
				Contact aContact = [Select OtherStreet, OtherCity,otherState, MailingStreet, MailingCity,mailingState From Contact c where id = :recordId][0];
				senderAddress = nullToString(aContact.MailingStreet) + ' ' + nullToString(aContact.MailingCity) + ' ' + nullToString(aContact.MailingState);
				recipientAddress = nullToString(aContact.OtherStreet) + ' ' + nullToString(aContact.OtherCity) + ' ' + nullToString(aContact.OtherState);
			}

		} else if (String.isNotBlank(contactId)) {
			if (CommonUtils.getObjectAPINameByRecordId(contactId) == 'Account') {
				Account anAccount = [Select PersonOtherStreet, PersonOtherCity, PersonOtherState, PersonOtherPostalCode, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode From Account at where id = :contactId][0];
				if (anAccount.PersonMailingPostalCode != null) {
					keyword = nullToString(anAccount.PersonMailingPostalCode) + ' - ' + nullToString(anAccount.PersonMailingCity) + '(' + nullToString(anAccount.PersonMailingState) + ')';
				}
				senderAddress = nullToString(anAccount.PersonMailingStreet) + ' ' + nullToString(anAccount.PersonMailingCity) + ' ' + nullToString(anAccount.PersonMailingState) + ' ' + nullToString(anAccount.PersonMailingPostalCode);
				recipientAddress = nullToString(anAccount.PersonOtherStreet) + ' ' + nullToString(anAccount.PersonOtherCity) + ' ' + nullToString(anAccount.PersonOtherState) + ' ' + nullToString(anAccount.PersonOtherPostalCode);
			}

			if (CommonUtils.getObjectAPINameByRecordId(contactId) == 'Contact') {
				Contact aContact = [Select OtherStreet, OtherCity,otherState, otherPostalcode, MailingStreet, MailingCity,mailingState, mailingPostalcode From Contact c where id = :contactId][0];
				if (aContact.mailingPostalcode != null) {
					keyword = nullToString(aContact.mailingPostalcode) + ' - ' + nullToString(aContact.MailingCity) + '(' + nullToString(aContact.mailingState) + ')';
				}
				senderAddress = nullToString(aContact.MailingStreet) + ' ' + nullToString(aContact.MailingCity) + ' ' + nullToString(aContact.MailingState) + ' ' + nullToString(aContact.mailingPostalcode);
				recipientAddress = nullToString(aContact.OtherStreet) + ' ' + nullToString(aContact.OtherCity) + ' ' + nullToString(aContact.OtherState) + ' ' + nullToString(aContact.otherPostalcode);
			}

		}


		if (ApexPages.currentPage().getParameters().get('address1Label') <> null && ApexPages.currentPage().getParameters().get('address1Label').length() > 0) {
			address1Label = ApexPages.currentPage().getParameters().get('address1Label');
		} else {
			address1Label = 'Primary Address';
		}
		if (ApexPages.currentPage().getParameters().get('address2Label') <> null && ApexPages.currentPage().getParameters().get('address2Label').length() > 0) {
			address2Label = ApexPages.currentPage().getParameters().get('address2Label');
		} else {
			address2Label = 'Secondary Address';
		}

	}

	private void setContactRequiresEscalation() {
		/*string key = '';
		string key1 = '';
		if (currentCase.ProductCategory__c != null) key += currentCase.ProductCategory__c;
		if (currentCase.ProductSubCategory__c != null) key += currentCase.ProductSubCategory__c;
		if (currentCase.Type != null) key += currentCase.Type;
		if (currentCase.EnquirySubType__c != null) key += currentCase.EnquirySubType__c;
		if (currentCase.Customer_Type__c != null) key += currentCase.Customer_Type__c;
		if (currentCase.IsNewForRouting__c) key += 'true'; else key += 'false';
		key1 = key;
		if (currentCase.Origin != null) key += currentCase.Origin;
		Set<String> keys = new Set<String>{
			key
		};
		List<SSSWRouting__c> routings = CaseUtility.getRoutingsFromCache(keys);*/
		contactRequiresEscalation = SSSW_Routing.checkAutoEscalate(currentCase);
		/*if (routings.isEmpty()) {
			keys = new Set<String>{
				key1
			};
			routings = CaseUtility.getRoutingsFromCache(keys);
			contactRequiresEscalation = !routings.isEmpty() && routings[0].AutoEscalate__c;
		}*/
	}

	//according to BKLG 000420, additional check logic for the network,
	//being used for the Primary and Secondary Address Network Search
	boolean checkPassNetWorkGeolocation(Network__c network, String category) {
		if (category == 'Parcel') {
			if (network.parcel__c == true) {
				return true;
			} else {
				return false;
			}
		} else if (category == 'Letter') {
			if (network.letter__c == true) {
				return true;
			} else {
				return false;
			}
		} else {
			return true;
		}
	}

	//Being used on postcode Network Search and when page is loading from case
	private Boolean checkPassNetWork(Network__c network, String category) {
		//If the product category is not Parcel or Letter always returns true
		if (category != 'Parcel' && category != 'Letter') {
			return true;
		}
		//Check the post code mappings "UniqueKey" field contains "Letter" or "Parcel"
		if (network.Postcode_Mappings__r != null) {
			for (PostCodeMapping__c pm : network.Postcode_Mappings__r) {
				if (String.isNotBlank(pm.UniqueKey__c) && pm.UniqueKey__c.containsIgnoreCase(category)) { // 16/06/2015 - Added Empty check
					return true;
				}
			}
		}

		return false;
	}

	string findCaseCategory() {
		string str_category = str_case_Category;
		if (str_category == null || str_category == '') {
			return '';
		} else if (str_category.contains('Parcel')) {
			return 'Parcel';
		} else if (str_category.contains('Letter')) {
			return 'Letter';
		} else {
			return 'other';
		}
	}

	private List<NetworkWrapper> loadByPassFacilities(Set<Id> facilitiesIds) {
		//get all bypass facilities linked with facilities from above search result
		byPasses = new Map<Id, FacilityByPass__c>([select Id, Facility_By_Pass_To__c, Facility_By_Pass_To_Name__c, Facility_By_Pass_To__r.RecordTypeId,
			Facility_By_Pass_From__c, Facility_By_Pass_From_Name__c, Facility_By_Pass_From__r.RecordTypeId,
			Comment__c, Frequency__c, CommencementDate__c, Occurrence__c, ScheduledEndDate__c
		From FacilityByPass__c
		Where Facility_By_Pass_From__c in :facilitiesIds or Facility_By_Pass_To__c in :facilitiesIds]);

		//bypass facilities may or may not in the facilitiesIds list, then compare byPasses list with facilitiesIds list, eventually get bypass facilities not in the facilities list
		Set<Id> byPassFacilityIds = new Set<Id>();
		Map<String, String> byPassFacilityToFromMap = new Map<String, String>();
		for (FacilityByPass__c byPass : byPasses.values()) {
			if (byPass.Facility_By_Pass_To__c != null) {
				byPassFacilityIds.add(byPass.Facility_By_Pass_To__c);
				byPassFacilityToFromMap.put(byPass.Facility_By_Pass_To__c, 'To');
			}
			if (byPass.Facility_By_Pass_From__c != null) {
				byPassFacilityIds.add(byPass.Facility_By_Pass_From__c);
				byPassFacilityToFromMap.put(byPass.Facility_By_Pass_From__c, 'From');
			}
		}

		List<Network__c> byPassNetworks = getNetworksById(byPassFacilityIds);
		for(Network__c network : byPassNetworks) {
			network.Name = network.Name + ' (Bypass Network - ' + byPassFacilityToFromMap.get(network.Id) + ')';
		}

		return wrapNetworks(byPassNetworks);
	}

	private List<NetworkWrapper> wrapNetworks(List<Network__c> networks) {
		List<NetworkWrapper> wrappers = new List<NetworkWrapper>();

		Map<String, List<Schema.FieldSetMember>> fieldsByRecordType = getFieldsByRecordType();

		for (Network__c nw : networks) {
			NetworkWrapper wrapper = new NetworkWrapper(nw, fieldsByRecordType.get(nw.RecordType.DeveloperName.toLowerCase()), networkExternalSystem, displayBusinessHours.get(nw.RecordType.DeveloperName));
			wrappers.add(wrapper);
		}

		return wrappers;
	}

	public list<FacilityByPass__c> getByPasses() {
		return byPasses.values();
	}

	@RemoteAction
	global static string setTempEmailToContact(string contactId) {
		string result = '';
		try {
			Contact ct = [select account.PersonEmail from Contact where id = :contactId limit 1][0];
			if (ct != null) {
				ct.account.PersonEmail = UNKNOWN_EMAIL;
				update ct.account;
			} else {
				result = 'Error: Unable to find contact.';
			}
		} catch (Exception ex) {
			result = 'Error: ' + ex.getMessage();
		}
		return result;
	}

	public static string setEscEmailContent(string caseID) {
		Case aCase = [select EscalationEmail__c,EnquirySubType__c,ContactId,Network__r.Email__c from Case where id = :caseID];

		//Contact contact;
		String GENERAL_TEMPLATE = 'SSSW_Case_GeneralTemplate';
		EmailTemplate emailTemplate;

		String templateName = 'SSSW Case ' + aCase.EnquirySubType__c;
		List<EmailTemplate> tempList = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE Name = :templateName OR DeveloperName = :GENERAL_TEMPLATE];
		if (tempList.size() > 1) {
			for (EmailTemplate et : tempList) {
				if (et.DeveloperName != GENERAL_TEMPLATE) {
					emailTemplate = et;
				}
			}
		} else if (tempList.size() == 1) {
			emailTemplate = tempList[0];
		}

		Contact ct;
		// If Case contact is blank - we need to ensure the Email Template can be rendered. SSSW Contact used.
		List<Contact> contList = [select id, email,IsPersonAccount, FirstName, LastName, accountid, account.personEmail from contact where (id = :aCase.contactId and Email != null) OR (FirstName = 'SSSW' AND LastName = 'Entitlements')];
		if (contList.size() > 1) {
			for (Contact c : contList) {
				if (!(c.FirstName == 'SSSW' && c.LastName == 'Entitlements')) {
					ct = c;
				}
			}
		} else if (contList.size() == 1) {
			ct = contList[0];
		}

		string emailContent = '';
		string subject = '';

		Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
		string message = generateEmail(sem, new String[]{
			'CSS@Escalation.com'
		}, ct, emailTemplate.Id, aCase.id);
		if (message.startsWith('Error:')) {
			return message;
		} else {
			return sem.getHtmlBody().normalizeSpace().replace(UNKNOWN_EMAIL, '');
		}
	}


	@RemoteAction
	global static string contactViaManually(id caseId, id facilityId, string externalSystem) {
		string result = caseId;
		try {
			system.debug('>>>>>>>>> externalSystem ========= ' + externalSystem);
			List<Case> cases = [select id, IsHLC__c,IsCR__c,EscalationEmail__c,Account.ServiceSLA__c,Type, Resolution_Result__c, ExternalSystem__c, Status, Network__c, ownerId, contactId, ResolutionCode__c from case where id = :caseId limit 2];
			if (cases.size() > 0) {
				if (cases[0].Type == 'Feedback' && String.isBlank(cases[0].Resolution_Result__c) && 'Enterprise' == String.valueOf(cases[0].Account.ServiceSLA__c)) {
					result = 'Error: Please enter Resolution Result to proceed';
				} else {

					cases[0].Network__c = facilityId;
					cases[0].ExternalSystem__c = externalSystem;

					List<Group> groups = [select id from Group where developerName = 'SSSWNetworkQueue'];
					if (groups.size() > 0 && (!cases[0].IsHLC__c && !cases[0].IsCR__c)) {
						cases[0].ownerId = groups[0].id;
					}
					if (cases[0].Type == 'Feedback') {
						if (string.isBlank(cases[0].ResolutionCode__c)) {
							cases[0].ResolutionCode__c = 'Feedback (Issue captured and logged)';
						}
						cases[0].Status = 'Closed';
					} else {
						cases[0].Status = AWAITING_NETW0RK_RESPONSE;
						cases[0].EscalationEmail__c = setEscEmailContent(caseId);
					}
					cases[0].Root_cause__c = AWAITING_NETW0RK_RESPONSE;
					update cases[0];
				}


			} else {
				result = 'Error: Unable to find Case with id = ' + caseId;
			}
			//INC1241392 - Modified if condition to reset the email
			if (!String.isBlank(cases[0].contactId)) {
				resetContactEmail(cases[0].contactId);
			}

		} catch (Exception ex) {
			result = 'Error:' + ex.getMessage();
		}
		return result;
	}

	@RemoteAction
	global static String contactViaFax(string facilityID, string caseID, string comment, boolean preventStatusChange) {
		Case aCase = [select IsHLC__c,IsCR__c,Updated_Case_Comments__c,Account.ServiceSLA__c,Resolution_Result__c,ResolutionCode__c,type, EscalationEmail__c, contactId from Case where id = :caseID];
		if (aCase.Type == 'Feedback' && String.isBlank(aCase.Resolution_Result__c) && 'Enterprise' == String.valueOf(aCase.Account.ServiceSLA__c)) {
			return 'Error: Please enter Resolution Result to proceed';
		}
		network__c f = [
			select name, Fax_Number__c
			from network__c
			where id = :facilityID
		];

		RecordType rt = [select id from RecordType where DeveloperName = 'outbound' and sobjecttype = 'Fax__c'];

		Fax__c aFax = new Fax__c();
		String tempNumber = f.fax_number__c;
		system.debug('Original Fax:' + tempNumber);
		if (!String.isBlank(f.fax_number__c)) {
			tempNumber = tempNumber.replaceAll('[^0-9+]', '');
			if (tempNumber.startsWith('0')) {
				tempNumber = tempNumber.substring(1);
			}
			aFax.emailto__c = tempNumber + '@fax2mail.com';
		} else {
			aFax.emailto__c = '211119999@fax2mail.com';
		}
		system.debug('Cleaned Fax:' + tempNumber);

		aFax.to__c = tempNumber;
		aFax.from__c = userinfo.getUserName();
		aFax.subject__c = 'Fax to Network: ' + f.name;
		aFax.case__c = caseID;
		aFax.recordtypeid = rt.id;
		aFax.name = 'Fax - ' + datetime.now().format('dd-MM-yyyy hh:mm:ss a');

		//Assign Case to Network and move to Network Queue
		if (!preventStatusChange) {
			id ownerId = null;
			List<Group> groups = [select id from Group where developerName = 'SSSWNetworkQueue'];
			if (groups.size() > 0) {
				ownerId = groups[0].id;
			}

			if (ownerId != null && (!aCase.IsHLC__c && !aCase.IsCR__c)) {
				aCase.OwnerId = ownerId;
			}

			aCase.Network__c = facilityId.trim();
			if (aCase.Type == 'Feedback') {
				if (string.isBlank(aCase.ResolutionCode__c)) {
					aCase.ResolutionCode__c = 'Feedback (Issue captured and logged)';
				}
				aCase.Status = 'Closed';
			} else {
				aCase.Status = AWAITING_NETW0RK_RESPONSE;

			}
			CaseMileStoneUtil.dontUpdateMilestone = true;
		}
		aCase.Root_cause__c = AWAITING_NETW0RK_RESPONSE;
		update aCase;

		if (!String.isBlank(aCase.contactId)) {
			resetContactEmail(aCase.contactId);
		}

		insert aFax;
		system.debug('Fax Created:' + aFax.id);

		List<Fax__c> tempfax = new List<Fax__c>();
		tempfax.add(aFax);

		//SSSWFaxUtility.generateAttachment(tempfax);
		return aFax.Id;
	}

	global class ContactViaFaxResponse {
		public ContactViaFaxResponse(string faxUrl, id faxId) {
			this.faxUrl = faxUrl;
			this.faxId = faxId;
		}
		public string faxUrl { get; set; }
		public id faxId { get; set; }
	}


	@RemoteAction
	global static string addAttachmentToFax(id caseId, id faxId) {
		PageReference pdf = new PageReference('/apex/SSSW_Case_FaxTemplate');
		pdf.getParameters().put('id', caseId);
		Attachment a = new Attachment(Name = 'Fax.pdf');
		if (!test.isRunningTest()) {
			a.Body = pdf.getContent();
		} else {
			a.Body = blob.valueof('TEST');
		}

		a.ParentId = faxId;
		insert a;

		Case tempCase = [Select Id, EscalationEmail__c from Case where Id = :caseId Limit 1][0];

		PageReference htmlpdf = new PageReference('/apex/SSSW_Case_FaxTemplateHTML');
		htmlpdf.getParameters().put('id', tempCase.id);
		if (!test.isRunningTest()) {
			tempCase.EscalationEmail__c = htmlpdf.getContent().toString();
		} else {
			tempCase.EscalationEmail__c = 'test';
		}
		update tempCase;

		return a.id;
	}

	@RemoteAction
	global static string contactViaSalesforce(string caseId, string escalationEmail, string facilityId, boolean preventStatusChange) {

		string result = '';

		//check email 1 and network users
		list<EmailParticipant> list_emailparticipants = new list<EmailParticipant>();
		for (Facility_User__c networkUser : [
			SELECT User__r.name, User__r.Email
			FROM Facility_User__c
			WHERE Network__c = :facilityId
			AND User__r.Email != null
			AND User__r.name != null
		]) {
			list_emailparticipants.add(new EmailParticipant(networkUser.User__r.name, networkUser.User__r.Email));
		}
		if (list_emailparticipants.size() == 0) {
			result = 'Error: There are no Network Users for this Network to contact via Salesforce. Please inform your admin team.';
			return result;
		}


		Case c = [select id,IsHLC__c,IsCR__c, EscalationEmail__c, Status,Account.ServiceSLA__c,Resolution_Result__c, Type, Network__c, ResolutionCode__c, OwnerId, contactId from Case where id = :caseID];
		if (c.Type == 'Feedback' && String.isBlank(c.Resolution_Result__c) && 'Enterprise' == String.valueOf(c.Account.ServiceSLA__c)) {
			result = 'Error: Please enter Resolution Result to proceed';
			return result;
		}
		//added by shengpeng.xiao@bluewolf.com at 2014.6.18 end
		if (!preventStatusChange) {
			Network__c aNetwork = [select name, Email_1__C from network__c where id = :facilityID limit 1];

			id ownerId = null;
			List<Group> groups = [select id from Group where developerName = 'SSSWNetworkQueue'];
			if (groups.size() > 0) {
				ownerId = groups[0].id;
			}


			if (ownerId != null && (!c.IsHLC__c && !c.IsCR__c)) {
				c.OwnerId = ownerId;
			}
			c.Network__c = facilityId.trim();


			if (c.Type == 'Feedback') {
				if (string.isBlank(c.ResolutionCode__c)) {
					c.ResolutionCode__c = 'Feedback (Issue captured and logged)';
				}
				c.Status = 'Closed';
			} else {
				c.Status = AWAITING_NETW0RK_RESPONSE;
				c.EscalationEmail__c = setEscEmailContent(caseID);
			}
			c.Root_cause__c = AWAITING_NETW0RK_RESPONSE;
			update c;

			result = 'Case assigned to Network Queue';
		}

		if (!String.isBlank(c.contactId)) {
			resetContactEmail(c.contactId);
		}

		return result;
	}

	static public void resetContactEmail(id contactId) {

		Contact ct = [select account.PersonEmail, isPersonAccount,email from Contact where id = :contactId limit 1];

		if (ct.IsPersonAccount) {
			if (ct.Account.personEmail == UNKNOWN_EMAIL) {
				ct.Account.personEmail = '';
				update ct.Account;
			}
		} else if (ct.email == UNKNOWN_EMAIL) {
			ct.email = '';
			update ct;
		}
	}

	//added by shengpeng.xiao@bluewolf.com at 2014.6.18
	//This method is used to get the Email template and send the email by ExactTargetEmail
	public static string getEmailTemplateAndSendMail(string facilityID, string caseID, List<EmailParticipant> list_emailparticipants) {
		string hasSend = '';

		Case aCase = [select Updated_Case_Comments__c,EnquirySubType__c,ContactId,Network__r.Email__c from Case where id = :caseID];

		//String GENERAL_TEMPLATE = 'SSSW_Case_GeneralTemplate';//Comment out by yuanyuan zhang 2014-08-11 use new generic template
		//Start : added by yuanyuan zhang 2014-08-11 new generic template
		String GENERAL_TEMPLATE = 'SSSWNetworkNotification';
		//END : added by yuanyuan zhang 2014-08-11 new generic template
		EmailTemplate emailTemplate;

		String templateName = 'SSSW Case ' + aCase.EnquirySubType__c;
		List<EmailTemplate> tempList = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE Name = :templateName OR DeveloperName = :GENERAL_TEMPLATE];
		if (tempList.size() > 1) {
			for (EmailTemplate et : tempList) {
				if (et.DeveloperName != GENERAL_TEMPLATE) {
					emailTemplate = et;
				}
			}
		} else if (tempList.size() == 1) {
			emailTemplate = tempList[0];
		}

		// Carmelo Andronaco (03/07/2014)
		// If Case contact is blank - we need to ensure the Email Template can be rendered. SSSW Contact used.
		Contact contact;
		List<Contact> contList = [select id, email, FirstName, LastName from contact where id = :aCase.contactId OR (FirstName = 'SSSW' AND LastName = 'Entitlements')];
		if (contList.size() > 1) {
			for (Contact c : contList) {
				if (!(c.FirstName == 'SSSW' && c.LastName == 'Entitlements')) {
					contact = c;
				}
			}
		} else if (contList.size() == 1) {
			contact = contList[0];
		}

		string emailContent = '';
		string subject = '';
		String[] toAddresses = new String[]{
			list_emailparticipants[0].participantEmail
		};
		string[] toNames = new string[]{
		};

		// Carmelo Andronaco (03/07/2014)
		// If there is a case contact, but the contact does not have an email, which is required.
		// Temporarily update the contact email. This must be within the database save/rollback.
		if (String.isEmpty(contact.Email)) {
			contact.Email = UNKNOWN_EMAIL;
			update contact;
		}
		contact = [select Id, Email from Contact where Id = :contact.id limit 1][0];

		Savepoint sp = Database.setSavepoint();

		try {
			Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();


			System.debug('XXXBWXXX: contact.Email - ' + contact.Email);
			sem.setToAddresses(toAddresses);

			sem.setTargetObjectId(contact.id);
			sem.setWhatId(aCase.id);
			sem.setTemplateId(emailTemplate.Id);
			system.debug('#########email: ' + sem);
			if(!Test.isRunningTest()) {
				Messaging.sendEmail(new Messaging.Email[]{
					sem
				});

				emailContent = sem.getHtmlBody();
				subject = sem.getSubject();

				emailContent = emailContent.normalizeSpace();
			}

			toAddresses = new String[]{};
			for (EmailParticipant ep : list_emailparticipants) {
				toAddresses.add(ep.participantEmail);
				toNames.add(ep.participantName);
			}
		} catch (Exception e) {
			hasSend = 'Error: ' + e.getMessage();
		} finally {
			Database.rollback(sp);
		}

		system.debug('>>>>>>>>>>> emailContent: ' + emailContent);
		system.debug('>>>>>>>>>>> toAddresses: ' + toAddresses.size());
		system.debug('>>>>>>>>>>> toNames: ' + toNames.size());
		sendMultipleEmail(aCase.id, facilityID, emailContent, toAddresses, toNames, subject, contact.id);
		// 04.28.17 - Angelo P. Rivera - Added contactID parameter that will be passed to sendSingleMail method as the subscriberID

		return hasSend;
	}


	@RemoteAction
	global static string contactViaEmail(string comment, string facilityID, string caseID, boolean preventStatusChange, boolean contactRequiresEscalation, string escalationEmail) {
		// added by shengpeng.xiao@bluewolf.com at 2014.7.15
		// check the network's email address, if null return
		Network__c aNetwork;
		for (Network__c ntw : [select Email__c,name from network__c where id = :facilityID limit 1]) {
			aNetwork = ntw;
		}

		if (aNetwork == null) {
			return 'Error : no network find.';
		}

		string toEmailAdd = contactRequiresEscalation ? escalationEmail : aNetwork.Email__c;
		if (String.isEmpty(toEmailAdd)) {
			return 'Error : The Network has no Email address.';
		}


		Case aCase = [select IsHLC__c,IsCR__c,Updated_Case_Comments__c,Account.ServiceSLA__c,Resolution_Result__c,EnquirySubType__c,ContactId,Network__r.Email__c,Type,Status,OwnerId, EscalationEmail__c, ResolutionCode__c from Case where id = :caseID];
		system.debug('FacilitySearch > contactViaEmail aCase.OwnerId:' + aCase.OwnerId);
		system.debug('>>>>>>>>>>>>>>>> preventStatusChange:' + preventStatusChange);
		if (aCase.Type == 'Feedback' && String.isBlank(aCase.Resolution_Result__c) && 'Enterprise' == String.valueOf(aCase.Account.ServiceSLA__c)) {
			//  result = 'Error: Please enter Resolution Code to proceed';
			return 'Error: Please enter Resolution Result to proceed';
		}
		if (!preventStatusChange) {
			aCase.Network__c = facilityID;
			id ownerId = null;
			List<Group> groups = [select id from Group where developerName = 'SSSWNetworkQueue'];
			if (groups.size() > 0) {
				ownerId = groups[0].id;
			}

			if (ownerId != null && (!aCase.IsHLC__c && !aCase.IsCR__c)) {   // condition to bypass owner change for HLC & CR cases : Nandan N : 24/06/2015
				aCase.Ownerid = ownerId;
			}

			if (aCase.Type == 'Feedback') {
				if (string.isBlank(aCase.ResolutionCode__c)) {
					aCase.ResolutionCode__c = 'Feedback (Issue captured and logged)';
				}
				aCase.Status = 'Closed';
			} else {
				aCase.Status = AWAITING_NETW0RK_RESPONSE;
			}
			//update aCase;
		}

		//Contact contact;
		String GENERAL_TEMPLATE = 'SSSW_Case_GeneralTemplate';
		EmailTemplate emailTemplate;

		String templateName = 'SSSW Case ' + aCase.EnquirySubType__c;
		List<EmailTemplate> tempList = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE Name = :templateName OR DeveloperName = :GENERAL_TEMPLATE];
		if (tempList.size() > 1) {
			for (EmailTemplate et : tempList) {
				if (et.DeveloperName != GENERAL_TEMPLATE) {
					emailTemplate = et;
				}
			}
		} else if (tempList.size() == 1) {
			emailTemplate = tempList[0];
		}

		Contact ct;
		// If Case contact is blank - we need to ensure the Email Template can be rendered. SSSW Contact used.
		List<Contact> contList = [select id, email,IsPersonAccount, FirstName, LastName, accountid, account.personEmail from contact where id = :aCase.contactId OR (FirstName = 'SSSW' AND LastName = 'Entitlements')];
		if (contList.size() > 1) {
			for (Contact c : contList) {
				if (!(c.FirstName == 'SSSW' && c.LastName == 'Entitlements')) {
					ct = c;
				}
			}
		} else if (contList.size() == 1) {
			ct = contList[0];
		}

		aCase.Root_cause__c = AWAITING_NETW0RK_RESPONSE;
		update aCase;

		string emailContent = '';
		string subject = '';

		Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
		string message = generateEmail(sem, new String[]{
			toEmailAdd
		}, ct, emailTemplate.Id, aCase.id);
		if (message.startsWith('Error:')) {
			return message;
		} else {
			emailContent = sem.getHtmlBody().normalizeSpace().replace(UNKNOWN_EMAIL, '');
			subject = sem.getSubject();
			sendAnEmail(aCase.id, facilityID, emailContent, toEmailAdd, aNetwork.Name, subject, ct.Id);
			// 04.28.17 - Angelo P. Rivera - Added contactID parameter that will be passed to sendSingleMail method as the subscriberID
		}

		system.debug('>>>>>>>>>>>>>>>>> emailContent:' + emailContent.length());
		aCase.EscalationEmail__c = emailContent;
		update aCase;

		if (ct != null) {
			if (ct.IsPersonAccount) {
				if (ct.Account.personEmail == UNKNOWN_EMAIL) {
					ct.Account.personEmail = '';
					update ct.Account;
				}
			} else if (ct.email == UNKNOWN_EMAIL) {
				ct.email = '';
				update ct;
			}
		}

		return aCase.id;
	}

	static string generateEmail(Messaging.SingleEmailMessage sem, String[] toAddresses, Contact ct, id emailTemplateId, id whatId) {
		string result = '';
		sem.setTargetObjectId(ct.id);
		sem.setWhatId(whatId);
		sem.setTemplateId(emailTemplateId);
		sem.setToAddresses(toAddresses);

		Savepoint sp = Database.setSavepoint();
		try {
			system.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ct.email: ' + ct.email);
			/*if (string.isBlank(ct.email)) {
				ct.email = UNKNOWN_EMAIL;
				update ct;
			} */
			//INC1241392 - If contact is person account update appropriate field
			if(!ct.IsPersonAccount)
			{
				if (string.isBlank(ct.email)) {
					ct.email = UNKNOWN_EMAIL;
					update ct;
					}
			}
			else
			{
				if (string.isBlank(ct.account.PersonEmail)) {
					ct.account.PersonEmail = UNKNOWN_EMAIL;
					update ct.account;
					}
			}
			//INC1241392 - If contact is person account update appropriate field
			Messaging.sendEmail(new Messaging.Email[]{
				sem
			});
		} catch (Exception ex) {
			result = 'Error: ' + ex.getMessage();
		} finally {
			Database.rollback(sp);
		}
		return result;
	}

	//added by shengpeng.xiao@bluewolf.com at 2014.6.25
	//used for send email to mutiple recievers
	@future(callout=true)
	global static void sendMultipleEmail(string caseID, string facilityID, string emailContent, String[] toAddresses, String[] toNames, string subject, string contactID) {
		QM__c qm = [Select NetworkEmail__c From QM__c limit 1];

		if (!isTest) {

			// added noreply@auspost.com.au as the subscriberID value
			ExactTargetEmail.ExactTargetSentResult sendResult = new ExacttargetEmail().sendMailToMultipleAddresses(qm.NetworkEmail__c, 'Customer Enquiry', toAddresses, toNames, emailContent, subject, contactID);
			// 04.28.17 - Angelo P. Rivera - Added contactID parameter that will be passed to sendSingleMail method as the subscriberID
			List<EmailMessage> list_emailMessages = new List<EmailMessage>();
			for (String toEmailAddress : toAddresses) {
				EmailMessage e = new EmailMessage(subject = subject, HtmlBody = emailContent, ParentId = caseID, FromAddress = qm.NetworkEmail__c, FromName = 'Customer Enquiry', ToAddress = toEmailAddress, MessageDate = datetime.now());
				list_emailMessages.add(e);
			}

			if (sendResult.isSuccessful) {
				insert list_emailMessages;
			} else {
				ExactTargetBacklog__c c = new ExactTargetBacklog__c();
				c.EmailContentJSON__c = sendResult.requestBody;
				c.ErrorMessage__c = sendResult.message;
				c.IsBatchEmail__c = sendResult.IsBatchEmail;
				c.EmailMessageObjectsJSON__c = JSON.serialize(list_emailMessages);
				insert c;
			}
		}
	}

	@future(callout=true)
	global static void sendAnEmail(string caseID, string facilityID, string emailContent, string toAddress, string toName, string subject, string contactId) {
		// 04.28.17 - Angelo P. Rivera - Added contactID parameter that will be passed to sendSingleMail method as the subscriberID
		QM__c qm = [Select NetworkEmail__c From QM__c limit 1];

		if (!isTest) {

			// added noreply@auspost.com.au as the subscriberID value
			ExactTargetEmail.ExactTargetSentResult sendResult = new ExacttargetEmail().sendSingleMail(qm.NetworkEmail__c, 'Customer Enquiry', toAddress, toName, emailContent, subject, contactId);
			// 04.28.17 - Angelo P. Rivera - Added contactID parameter that will be passed to sendSingleMail method as the subscriberID
			List<EmailMessage> list_emailMessages = new List<EmailMessage>();
			list_emailMessages.add(new EmailMessage(subject = subject, HtmlBody = emailContent, ParentId = caseID, FromAddress = qm.NetworkEmail__c, FromName = 'Customer Enquiry', ToAddress = toaddress, MessageDate = datetime.now()));

			if (sendResult.isSuccessful) {
				insert list_emailMessages;
			} else {
				ExactTargetBacklog__c c = new ExactTargetBacklog__c();
				c.EmailContentJSON__c = sendResult.requestBody;
				c.ErrorMessage__c = sendResult.message;
				c.IsBatchEmail__c = sendResult.IsBatchEmail;
				c.EmailMessageObjectsJSON__c = JSON.serialize(list_emailMessages);
				insert c;
			}
		}
	}

	//added by shengpeng.xiao@bluewolf.com at 2014.6.25
	//wrapper class to store email participant informations
	global class EmailParticipant {
		public String participantName;
		public String participantEmail;
		public EmailParticipant(String participantName, String participantEmail) {
			this.participantName = participantName;
			this.participantEmail = participantEmail;
		}
	}

	public class NetworkTabs {
		Map<String, NetworkTab> tabs { get; set; }

		public NetworkTabs() {
			tabs = new Map<String, NetworkTab>();
		}

		public Set<String> tabIds {
			get {
				return tabs.keySet();
			}
		}

		public void addTab(String nameId, NetworkTab tab) {
			tabs.put(nameId, tab);
		}

		public NetworkTab getTab(String nameId) {
			return tabs.get(nameId);
		}

		public Map<String, NetworkTab> getTabs() {
			return tabs;
		}

		public Integer tabCount() {
			return tabs.size();
		}

	}

	public class NetworkTab {
		public String recordTypeDevName { get; set; }
		public String recordTypeId { get; set; }
		public String tabName { get; set; }
		private Map<Id, NetworkWrapper> networkMap { get; set; }

		public List<NetworkWrapper> networks {
			get {
				return networkMap.values();
			}
		}

		public Boolean hasGeoNetworks {
			get {
				if(networks == null) {
					return false;
				}

				for(NetworkWrapper network : networks) {
					if(!String.isEmpty(network.lon) && !String.isEmpty(network.lat)) {
						return true;
					}
				}

				return false;
			}
		}

		public NetworkTab(String tabName, String recordTypeDevName, String recordTypeId, List<NetworkWrapper> networks) {
			this.networkMap = new Map<Id, NetworkWrapper>();
			this.recordTypeId = recordTypeId;
			this.recordTypeDevName = recordTypeDevName;
			this.tabName = tabName;

			for(NetworkWrapper network : networks) {
				this.networkMap.put(network.id, network);
			}
		}
		public NetworkTab(String tabName, String recordTypeDevName, String recordTypeId) {
			this.tabName = tabName;
			this.recordTypeId = recordTypeId;
			this.recordTypeDevName = recordTypeDevName;
			this.networkMap = new Map<Id, NetworkWrapper>();
		}

		public void addNetworks(List<NetworkWrapper> networks) {
			for(NetworkWrapper network : networks) {
				networkMap.put(network.id, network);
			}
		}

		public void addNetwork(NetworkWrapper network) {
			networkMap.put(network.id, network);
		}
	}

	//wraper class for facility record
	public class NetworkWrapper {
		public Network__c network { get; set; }
		public String id { get; private set; }
		public String name { get; private set; }
		public String state { get; private set; }
		public String lon { get; private set; }
		public String lat { get; private set; }
		public String recordTypeDevName { get; private set; }
		public String recordTypeDevNameLC { get; private set; }
		public String recordTypeId { get; private set; }
		public String email { get; private set; }
		public String comment { get; private set; }
		public String contactFacility { get; private set; }
		public String escalationEmail { get; private set; }
		public String orgId { get; private set; }
		public Boolean displayBusinessHours { get; private set; }
		public List<Knowledge__kav> criticalIncidents { get; set; }
		public List<String> htmlFields { get; set; }
		public String relatedListUniqueId {get; private set;}

		public String ORG_UNIT_ADDR_2 { get; set; }
		public String ORG_UNIT_ADDR_3 { get; set; }

		//variables added by kalpita for product standardization message captures
		public string prdStdMessag { get; set; }
		public string nwExtSystemValue { get; set; }

		public List<SelectOption> networkExternalSystem {
			get; set;
		}

		// public NetworkWrapper(Network__c nw, FacilitySearch instance) { // String id, String name, String state, String lon, String lat, String recordTypeId, String email, String comment, String contactfacility, String escalationEmail) {
		public NetworkWrapper(Network__c nw, List <FieldSetMember> fieldsByRecordType, List <SelectOption> netExtSys, Boolean showBusinessHours) {
			this.network = nw;
			this.id = nw.Id;
			this.name = nw.Name;
			this.state = nw.State__c;
			this.lon = String.valueOf(nw.Geolocation__Longitude__s);
			this.lat = String.valueOf(nw.Geolocation__Latitude__s);

			this.recordTypeId = nw.RecordTypeId;
			this.recordTypeDevName = nw.RecordType.DeveloperName;
			this.recordTypeDevNameLC = nw.RecordType.DeveloperName.toLowerCase();
			this.email = nw.Email__c;
			this.comment = nw.Comment__c;
			this.escalationEmail = nw.Email_1__c;
			this.networkExternalSystem = netExtSys;
			this.displayBusinessHours = showBusinessHours;
			this.ORG_UNIT_ADDR_2 = nw.ORG_UNIT_ADDR_2__c;
			this.ORG_UNIT_ADDR_2 = nw.ORG_UNIT_ADDR_3__c;
			this.orgId = nw.Org_ID__c;

			if (nw.Contact_facility__c == null || nw.Contact_facility__c.trim() == '') {
				this.contactFacility = 'Manually';
			} else if (nw.Contact_facility__c == 'Manually') {
				this.contactFacility = nw.Contact_facility__c;
			} else {
				this.contactFacility = 'via ' + nw.Contact_facility__c;
			}

			this.criticalIncidents = new List<Knowledge__kav>();

			// Generate the HTML for displaying the fields in APEX because it's a lot slower in VF (complex logic)
			List <FieldSetMember> fields = fieldsByRecordType;
			List <String> htmlFields = new List <String> ();

			for (FieldSetMember flm : fields) {
				String fieldPath = flm.getFieldPath();
				String fieldLabel = flm.getLabel();
				String fieldType = flm.getType().name();
				Object fieldValue = network.get(fieldPath);
				Boolean redCss = fieldLabel == 'Status' && fieldValue == 'Closed';

				if (fieldValue == null || fieldValue == false || fieldPath == 'Display_Business_Hours__c') {
					continue;
				}

				String htmlField = '<div class="facility-detail-field" style="border:red; border-style: ' + (redCss ? 'solid; color: red' : '') + '">';
				htmlField += '<label class="fs-label">' + fieldLabel + '</label><br/>';

				if (fieldType == 'BOOLEAN') {
					htmlField += '<span class="field-value ' + fieldType + '"><img src="/img/checkbox_checked.gif" alt="Checked" class="checkImg" title="Checked" width="21" height="16"></span>';
				} else {
					htmlField += '<span class="field-value ' + fieldType + '">' + fieldValue + '</span>';
				}

				htmlField += '</div>';

				htmlFields.add(htmlField);
			}

			this.htmlFields = htmlFields;

			// Unique Id used to dynamically display related lists
			this.relatedListUniqueId = nw.Id + '_trueFacility_Box_Bag__rFacility_Box_Price__r';
		}
	}
}