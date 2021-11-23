/**
 ** Description: Utility class calculate Depot area for a case.
 ** Author: Fahad Akhtar(CloudSherpas)
 ** Date Created: SEPT.11.2015
 ** History:--------------------------------------------
 ** July 7, 2016 - David E. Catindoy - Modified to make it align to coding best practices and make it more readable
 **/
public class StarTrackTaskingRuleUtility {
	//Tasking rule method to run all rules and return map with case id as key and depot are as value.
	public static Map<Id, Depot_Area__c> taskingRule(List<Case> lst_cases){
		Map<Id, Depot_Area__c> map_CaseIdToDepotArea = new Map<Id, Depot_Area__c>();
		Map<String, Id> map_ReceiverNameToNetwork = new Map<String, Id>();
		Map<String, Id> map_BookInCustomers = new Map<String, Id>();
		Map<Id, String> map_CaseToArea = new Map<Id, String>();
		Map<String, Depot_Area__c> map_NetworkAreaDepotArea = new Map<String, Depot_Area__c>();
		Set<Id> set_id = new Set<Id>();

		//Query all rule sort by order.
		List<StarTrack_Tasking_Rules__c> lst_Rules = [SELECT Id, Book_In_Customer__c, Depot_Area__c,
															 Depot_RecordType__c, Enquiry_Type__c,
															 Freight_Type__c, Order__c, Quantity__c, Weight__c
													  FROM StarTrack_Tasking_Rules__c
													  ORDER BY Order__c];
		
		/*Loop through list of cases to get receiver as key and 
		network as value and network id on cases as set */
		for(Case c : lst_cases){
		    if(c.Network__r.Preferred_Method_of_Tasking__c != StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT){
		        map_ReceiverNameToNetwork.put(c.ArticleTest__r.ReceiverName__c, c.Network__c);
			    set_id.add(c.Network__c);
		    } else if(c.Network__r.Parent_Network__c != null){
		        map_ReceiverNameToNetwork.put(c.ArticleTest__r.ReceiverName__c, c.Network__r.Parent_Network__c);
			    set_id.add(c.Network__r.Parent_Network__c);
		    }
		}
		//Query all networks associated with cases.
		Map<Id, Network__c> map_network = new Map<Id, Network__c>([SELECT Id, RecordType.DeveloperName 
																   FROM Network__c 
																   WHERE Id =: set_id]);
																   
		//Query all book in customer associated with receiver name and network
		if(map_ReceiverNameToNetwork.size() > 0){
		    for(Book_In_Customer__c b : [SELECT Network__c, Name FROM Book_In_Customer__c WHERE Network__c IN: map_ReceiverNameToNetwork.values() AND Name IN: map_ReceiverNameToNetwork.keySet()]){
    			map_BookInCustomers.put(b.Name, b.Network__c);
    		}
		}
		
		//Run all rules for all cases
		for(Case c : lst_cases){
			//Run all star track rule order by order__c
			for(StarTrack_Tasking_Rules__c str : lst_Rules){
				//Check if its book in customer
				if(map_BookInCustomers.containsKey(c.ArticleTest__r.ReceiverName__c) && 
				   networkId(c) == map_BookInCustomers.get(c.ArticleTest__r.ReceiverName__c) && 
				   str.Book_In_Customer__c &&
				   map_network.get(networkId(c)).RecordType.DeveloperName == str.Depot_RecordType__c){
					map_CaseToArea.put(c.Id, str.Depot_Area__c);
					break;
				//Check if unit type, weight, quantity matches.
				} else if(((String.isNotBlank(str.Freight_Type__c) && c.ArticleTest__r.Unit_Type__c == str.Freight_Type__c) || 
						   (String.isNotBlank(String.ValueOf(str.Weight__c)) && c.ArticleTest__r.ActualWeight__c >= str.Weight__c) || 
						   (String.isNotBlank(String.ValueOf(str.Quantity__c)) && c.ArticleTest__r.Number_of_Items__c >= str.Quantity__c)) &&
						    map_network.get(networkId(c)).RecordType.DeveloperName == str.Depot_RecordType__c){
					map_CaseToArea.put(c.Id, str.Depot_Area__c);
					break;
				//Check if enquiry type matches
				} else if(String.isNotBlank(str.Enquiry_Type__c) && c.Enquiry_Type__c == str.Enquiry_Type__c && map_network.get(networkId(c)).RecordType.DeveloperName == str.Depot_RecordType__c){
					map_CaseToArea.put(c.Id, str.Depot_Area__c);
					break;
				//Check if record type matches and remaining fields are empty and no other rule is executed.
				}else if((String.isNotBlank(str.Depot_RecordType__c) && map_network.get(networkId(c)).RecordType.DeveloperName == str.Depot_RecordType__c) && 
						 (str.Book_In_Customer__c ==  FALSE && String.isBlank(str.Freight_Type__c) && String.isBlank(String.ValueOf(str.Weight__c)) && String.isBlank(String.ValueOf(str.Quantity__c)) && String.isBlank(str.Enquiry_Type__c))){
					map_CaseToArea.put(c.Id, str.Depot_Area__c);
					break;
				}
			}
		}
		
		//Query depot area for depot and area from cases.
		for(Depot_Area__c da : [SELECT Id, Area__c, Depot__c FROM Depot_Area__c WHERE Used_for_Tasking__c = TRUE AND Depot__c IN : set_id AND Area__c IN: map_CaseToArea.values()]){
			map_NetworkAreaDepotArea.put(da.Depot__c +''+ da.Area__c, da);
		}
		
		//Create map with key as case and value as depot
		for(Case c : lst_cases){
		    if(map_NetworkAreaDepotArea.containsKey(networkId(c) + '' + map_CaseToArea.get(c.Id))){
		        map_CaseIdToDepotArea.put(c.Id, map_NetworkAreaDepotArea.get(networkId(c) + '' + map_CaseToArea.get(c.Id)));
		    }
		}
		return map_CaseIdToDepotArea;
	}
	
	public static Id networkId(Case c){
	    return (c.Network__r.Preferred_Method_of_Tasking__c == StarTrack_Constants.NETWORK_PREFMETHOFTASKING_PARENT && c.Network__r.Parent_Network__c != null ? c.Network__r.Parent_Network__c : c.Network__c);
	}
 }