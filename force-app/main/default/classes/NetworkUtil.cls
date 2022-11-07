/**
  * @author       : Bluewolf
  * @date         : 26/07/2016
  * @description  : Handler Class for Network object trigger
--------------------------------------- History --------------------------------------------------
03.10.2014    Bluewolf    Created
12.04.2019    disha.kariya@auspost.com.au    Added updateNetworkManagerOnLicence method
18.09,2019    ajudd@salesforce.com  		 PUD Added to updateBookingLocationAddress update address fields on booking location
16.10.2019    ajudd@salesforce.com  		 Added check to updateBookingLocationAddress to prevent recursion
06.11.2019    ajudd@salesforce.com  		 Applied fix to updateBookingLocationAddress where check for networkIdSet size was inside for loop (Incident INC1497717)
16.03.2022    saiswetha.pingali@auspost.com.au Updated updateBookingLocationAddress to invoke direct method for test class execution.
2022-11-04    Naveen Rajanna     			REQ3018517 Add null check to prevent nullpointerexception for updateNetworkManagerOnLicence
**/

public class NetworkUtil
{
	//class constant variables
	public static final String PICKLIST_VALUE_CHECK_ONLY = 'Cheque Only';
	public static final String PICKLIST_VALUE_CASH_AND_CHECK = 'Cash & Cheque';
	public  static final String NETWORK_OTHER_RECORDTYPES = 'Other';
	public  static final set<string> ACCOUNT_LICENCE_RECORDTYPES = ACCOUNT_LICENCE_RECORDTYPES__c.getAll().keySet();
    
    //This Set stores network record ids processed by the future method updateBookingLocationAddress.
    //It is used to prevent recursion of the trigger.
    public static Set<Id> networkIdProcessedSet = new Set<Id>();

	public static Map<String, BankMapping__c> BankMappings 
    {
        get
        {
            if (BankMappings == null)
            {
                BankMappings = BankMapping__c.getAll();
            }
            return BankMappings;
        }

        set;
    }
	
	public static void updateBankFields(List<Network__c> networks) 
	{
		for (Network__c nw : networks) 
		{
			blankAllBankFields(nw);
			updateBankFields(nw, nw.BusBankChq__c, PICKLIST_VALUE_CHECK_ONLY);
			updateBankFields(nw, nw.BusBankChqCash__c, PICKLIST_VALUE_CASH_AND_CHECK);
		}
	}
	
	public static void updateBankFields(Network__c nw, String banks, String picklistVal)
	{
		if (banks != null)
		{
			String[] bankTokens = banks.split(',');
			for (String t : bankTokens)
			{
				BankMapping__c bankMapping = BankMappings.get(t.trim());
				if (bankMapping != null)
				{
					nw.put(bankMapping.Network_Field__c, picklistVal);
				}
			}
		}
	}

	private static void blankAllBankFields(Network__c nw)
	{
		for (BankMapping__c bm : BankMappings.values())
		{
			nw.put(bm.Network_Field__c, null);
		}
	}

	/*
    @Description 		: Apex method Update Network Manager & State Admin on Licence & partener Addendums
    @Params             : List of Network__c (Network), Map of Id & old Network
    @Return             : Void
    */
	public static void updateNetworkManagerOnLicence(List<Network__c> networks, map<id, Network__c> oldNetworks){
        
		//Get Other recordtype Id on Network object
		Id otherRTs = RecordTypes.getRecordTypeByName(NETWORK_OTHER_RECORDTYPES,SSSWConstants.FLD_NETWORK).Id;
		//Get Licence record types on Account Object
		String ACCOUNT_STRING = 'Account';
		Map<Id,RecordType> licenceRTs = new Map<Id,RecordType>(RecordTypes.getRecordTypesByName(ACCOUNT_LICENCE_RECORDTYPES,ACCOUNT_STRING));
		Set<Id> licenceRTIds = new Set<Id>(licenceRTs.keySet());
		set<id> networkIds = new set<id>();
		Map<Id, Account> licenceToUpdate = new Map<Id, Account>();
		Map<Id, Partner_Addendum__c> addendumToUpdate = new Map<Id, Partner_Addendum__c>();
		Map<Id,Id> mapParentNetworkManager = new Map<Id, Id>();
		Map<Id,String> mapParentNetworkState = new Map<Id, String>();
		Partner_Info_Settings__c setting = Partner_Info_Settings__c.getInstance();
        Id parentNetwork;
		try {
			//Loop through Networks which are updated
			for (Network__c net : networks) {
				System.debug('otherRTs--->'+otherRTs);
				System.debug('licenceRTIds--->'+licenceRTIds);
                System.debug('net.RecordTypeId--->'+net.RecordTypeId);
				//Check if Network Manager on Parent Network is changed
				if (otherRTs.equals(net.RecordTypeId) &&
						(!(net.Network_Manager__c != null && net.Network_Manager__c.equals(oldNetworks.get(net.id).Network_Manager__c)))) { //REQ3018517
					//Add Network Id in Set<id> to retrieve Licence and Partner Addendums
					networkIds.add(net.id);
					//Add Network Manager in Map along with Parent Network Id
					mapParentNetworkManager.put(net.Id, net.Network_Manager__c);
				}
				//Check if State on Parent Network is changed
				if (otherRTs.equals(net.RecordTypeId) &&
						(!(net.State__c.equalsIgnoreCase(oldNetworks.get(net.id).State__c)))) {
					//Add Network Id in Set<id> to retrieve Licence and Partner Addendums
					networkIds.add(net.id);
					//Add State in Map along with Parent Network Id
					mapParentNetworkState.put(net.Id, net.State__c);
				}
			}
			networkIds.remove(null);
			System.debug('networkIds--->'+networkIds);
			System.debug('mapParentNetworkManager--->'+mapParentNetworkManager);
			System.debug('mapParentNetworkState--->'+mapParentNetworkState);
			//Extract Licence and Partner Addendums to update
			if (networkIds.size() > 0) {
				//Get Licence details based on parent network
				map<id, Account> licences = new map<id, Account>([
						SELECT id, Network_Manager__c, Licence_Status__c, Approval_Status__c,
								Facility__r.Network_Facility__r.Parent_Network__c, Email__c,
								Facility__r.Network_Facility__r.Parent_Network__r.Network_Manager__c
						FROM Account
						WHERE RecordTypeId IN :licenceRTIds AND Facility__r.Network_Facility__r.Parent_Network__c in :networkIds
				]);

                //Get Partner Addendums based on licence parent network
				Map<Id, Partner_Addendum__c> addendums = new Map<Id, Partner_Addendum__c>([SELECT id,
						Network_Manager__c, Licence__r.Facility__r.Network_Facility__r.Parent_Network__c, State_Admin__c,
						End_Date__c
				FROM Partner_Addendum__c
				WHERE Licence__r.Facility__r.Network_Facility__r.Parent_Network__c in:networkIds ]);
				System.debug('licences--->'+licences);
				System.debug('addendums--->'+addendums);
				//Loop through all licences to update Network Manager and State Admin
				for (Account licence : licences.values()) {
                    parentNetwork =  licence.Facility__r.Network_Facility__r.Parent_Network__c;
					System.debug('licence.Network_Manager__c--->'+licence.Network_Manager__c);
					System.debug('mapParentNetworkManager.get(licence.Facility__r.Network_Facility__r.Parent_Network__c)--->'+mapParentNetworkManager.get(licence.Facility__r.Network_Facility__r.Parent_Network__c));
					//Check if Network Manager on Licence is different than Network Manager on Parent Network
					if(mapParentNetworkManager.containsKey(parentNetwork) && licence.Network_Manager__c != mapParentNetworkManager.get(parentNetwork)) {
						//Assign update Network manager to updated Network Manager
						licence.Network_Manager__c = mapParentNetworkManager.get(parentNetwork);
						licenceToUpdate.put(licence.Id, licence);
					}

					System.debug('licence.Email__c--->'+licence.Email__c);
					//Check if State Admin Email on Licence is different than State on Parent Network
					if(mapParentNetworkState.containsKey(parentNetwork) && licence.Email__c != setting.get('Email_List_'+mapParentNetworkState.get(parentNetwork)+'__c')){
                        System.debug('setting.get(\'Email_List_\'+mapParentNetworkState.get(parentNetwork)+\'__c\')--->'+setting.get('Email_List_'+mapParentNetworkState.get(parentNetwork)+'__c'));
						//If Licence is already updated with new Network Manager then latest Licence and update State admin
						if(licenceToUpdate.containsKey(licence.Id)){
							Account acc = licenceToUpdate.get(licence.Id);
							acc.Email__c = String.valueOf(setting.get('Email_List_'+mapParentNetworkState.get(parentNetwork)+'__c'));
							licenceToUpdate.put(acc.Id, acc);
						}
						else {
                            licence.Email__c = String.valueOf(setting.get('Email_List_'+mapParentNetworkState.get(parentNetwork)+'__c'));
							licenceToUpdate.put(licence.Id, licence);
						}
					}
				}
				//Loop through all addendums for changes
				for(Partner_Addendum__c addendum : addendums.values()){
                    parentNetwork =  addendum.Licence__r.Facility__r.Network_Facility__r.Parent_Network__c;
					System.debug('addendum.Network_Manager__c--->'+addendum.Network_Manager__c);
					System.debug('mapParentNetworkManager.get(parentNetwork)--->'+mapParentNetworkManager.get(parentNetwork));
					//Check if Network Manager on Licence is different than Network Manager on Parent Network
					if(mapParentNetworkManager.containsKey(parentNetwork) && addendum.Network_Manager__c != mapParentNetworkManager.get(parentNetwork)) {
						addendum.Network_Manager__c = mapParentNetworkManager.get(parentNetwork);
						addendumToUpdate.put(addendum.Id, addendum);
					}

					System.debug('addendum.State_Admin__c--->'+addendum.State_Admin__c);
					//Check if State Admin Email on Licence is different than State on Parent Network
					if(mapParentNetworkState.containsKey(parentNetwork) && addendum.State_Admin__c != setting.get('Email_List_'+mapParentNetworkState.get(parentNetwork)+'__c')){
                        System.debug('setting.get(\'Email_List_\'+mapParentNetworkState.get(parentNetwork)+\'__c\')--->'+setting.get('Email_List_'+mapParentNetworkState.get(parentNetwork)+'__c'));
						if(addendumToUpdate.containsKey(addendum.Id)){
							Partner_Addendum__c add = addendumToUpdate.get(addendum.Id);
							add.State_Admin__c = String.valueOf(setting.get('Email_List_'+mapParentNetworkState.get(parentNetwork)+'__c'));
							addendumToUpdate.put(add.Id, add);
						}
						else {
                            addendum.State_Admin__c = String.valueOf(setting.get('Email_List_'+mapParentNetworkState.get(parentNetwork)+'__c'));
							addendumToUpdate.put(addendum.Id, addendum);
						}
					}
				}
			}
            System.debug('licenceToUpdate--->'+licenceToUpdate);
            System.debug('addendumToUpdate--->'+addendumToUpdate);
            System.debug('licenceToUpdate.size()--->'+licenceToUpdate.size());
            System.debug('addendumToUpdate.size()--->'+addendumToUpdate.size());
			if (licenceToUpdate.size() > 0) {
				Database.update(licenceToUpdate.values());
			}
			if (addendumToUpdate.size() > 0) {
				Database.update(addendumToUpdate.values());
			}
		}catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
					AccountTriggerUtility.class.getName(), SSSWConstants.NETWORK_MANAGER_UPDATE,
					SSSWConstants.NETWORK_TRIGGER, LoggingLevel.ERROR);
		}

	}
	
    //PUD ajudd@salesforce.com 18/09/2019 Added to update address fields on booking location - START
    //Method to update any impacted Booking Locations if the Network address has been updated
    //Called from NetworkTrigger
    //Test Class is TestNetworkUtil.testNetworkAddressUpdate
    public static void updateBookingLocationAddress(Map<Id,Network__c> networkOldMap, List<Network__c> networkNewList) 
	{        
        Set<Id> networkIdSet = new Set<Id>();
        
        for (Network__c networkNew : networkNewList){
               
            //If any address fields have changed (these are fields whos values are dictated to booking locations)
            if(networkOldMap.get( networkNew.Id ).ORG_UNIT_ADDR_1__c 		!= networkNew.ORG_UNIT_ADDR_1__c || 
               networkOldMap.get( networkNew.Id ).ORG_UNIT_ADDR_2__c 		!= networkNew.ORG_UNIT_ADDR_2__c || 
               networkOldMap.get( networkNew.Id ).ORG_UNIT_ADDR_3__c 		!= networkNew.ORG_UNIT_ADDR_3__c || 
               networkOldMap.get( networkNew.Id ).Post_Code__c	 	 		!= networkNew.Post_Code__c || 
               networkOldMap.get( networkNew.Id ).State__c           		!= networkNew.State__c || 
               networkOldMap.get( networkNew.Id ).Geolocation__Latitude__s  != networkNew.Geolocation__Latitude__s || 
               networkOldMap.get( networkNew.Id ).Geolocation__Longitude__s != networkNew.Geolocation__Longitude__s ){
                      
                   //If record not previously processed in same transaction
                   if(!networkIdProcessedSet.contains(networkNew.Id)){
                       	//Add Network to set
                   		networkIdSet.add(networkNew.Id);
                        //Add Id to processed set
                        networkIdProcessedSet.add(networkNew.Id);
                   }
            }
        }
            
        //If any networks have address fields updated. AJ 06/11/19 For for INC1497717 - moved outside for loop
        if(networkIdSet.size() > 0 ){
            
            //If this is being called from a future, batch or scheduled method - directly call method to check for and update booking location address 
            if(System.IsBatch() || System.isFuture() || System.isScheduled() || System.isQueueable() || Test.IsRunningTest()){
                updateBookingLocationAddressProcess(networkIdSet);
            } else {
                //Else call method in future mode
                updateBookingLocationAddressAsync(networkIdSet);
            }
        }
	}
    //To call method in future mode
    @future
    private static void updateBookingLocationAddressAsync(Set<Id> networkIdSet){
        try{
        	updateBookingLocationAddressProcess(networkIdSet);
        } 
        catch(Exception exp) {
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'Pickup Booking', 'NetworkUtil', 'updateBookingLocationAddressAsync', 'NetworkTrigger', LoggingLevel.ERROR);
            System.debug('ERROR Logged');
		}
    }
    //Method to update booking locations
    private static void updateBookingLocationAddressProcess(Set<Id> networkIdSet){
                
        List<PUD_Booking_Location__c> bookingLocationList = new List<PUD_Booking_Location__c>();
        
        //Get all Booking Locations associated to the networks
        bookingLocationList = [SELECT Id, 
                               Street__c, Network_Street__c,
                               City__c, Network_City__c, 
                               Post_Code__c, Network_Post_Code__c, 
                               State__c, Network_State__c, Network_Latitude__c, Network_Longitude__c 
                               FROM PUD_Booking_Location__c WHERE Network__c IN :networkIdSet];
        
        //If locations found
        if(bookingLocationList.size() > 0 ){
            for(PUD_Booking_Location__c bookingLocation : bookingLocationList){

                bookingLocation.Street__c = bookingLocation.Network_Street__c;
                bookingLocation.City__c = bookingLocation.Network_City__c;
                bookingLocation.Post_Code__c = bookingLocation.Network_Post_Code__c;
                bookingLocation.State__c = bookingLocation.Network_State__c;
                bookingLocation.Geo__Latitude__s = bookingLocation.Network_Latitude__c;
                bookingLocation.Geo__Longitude__s = bookingLocation.Network_Longitude__c;
            }
            update bookingLocationList;
        } 
               
    }
    //PUD ajudd@salesforce.com 18/09/2019 Added to update address fields on booking location - END
}