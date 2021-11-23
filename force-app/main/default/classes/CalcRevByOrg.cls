/*------------------------------------------------------------  
Author:        Mathanan Yogaratnam
Company:       Salesforce.com
Description:   A class for calculating the summary values and populating the Revenue by Organisation object
				- Input is a list of records from Target and Revenue Object
				- The class summarises the value across all products for a given organisation and writes the output
				  to the Revenue by Organisation object
				- If there is no existing record for the financial year in the Org by Revenue object, then a new record is created 
				- If there is an existing record for the financial year, then that record is updated 

Test Class:
History
<Date>      <Authors Name>     <Brief Description of Change>
27-03-2014	Mathanan Yogaranam	Initial Release
------------------------------------------------------------*/

public class CalcRevByOrg{

	List<Budget_and_Revenue__c> acctTrList; // T&R records for all accounts in input T&R recs
	Map<Id, Id> acctTRMap; //List of account Id's that exist in input T&R recs - map used for deduping

	List<Revenue_by_Organisation__c> currentOrgRevList; //List of existing Revenue by Organisation recs foe accounts
	Map<String, List<Budget_and_Revenue__c>> currentTargRevMap; //map of keys (Org Id+FY) to List of Target and Revenue recs - used to calculate the reveue for each org per fin year 
	Map<String, Revenue_by_Organisation__c> currentOrgRevMap; //map of keys (Org Id+FY) to rev org recs - used to determine which recs already exist 

	List<Revenue_by_Organisation__c> OrgRevListCreate; //Rev by Org records to create
	List<Revenue_by_Organisation__c> OrgRevListUpdate; //Rev by Org records to update

	public Integer num_of_tr_recs; //number of T&R revenue records in input
	public Integer num_of_revOrg_rec_created; //number of output Revenue by Org records created
	public Integer num_of_revOrg_rec_updated; //number of output Revenue by Org records updated

	public Integer num_of_revOrg_rec_create_errors; //number of output Revenue by Org records error on create
	public Integer num_of_revOrg_rec_update_errors; //number of output Revenue by Org records error on update

	public String erroredCreateRecsString;
	public String erroredUpdateRecsString;
	public Boolean RevOrgUpdateError;
	public Boolean RevOrgCreateError;

	//Constructor method
	public CalcRevByOrg(List<Budget_and_Revenue__c> targetRevList){

		if (targetRevList.size() ==0)
			return;

		num_of_tr_recs = targetRevList.size();
		//iniatlise
		OrgRevListCreate = new List<Revenue_by_Organisation__c>();
		OrgRevListUpdate = new List<Revenue_by_Organisation__c>();
		
		num_of_revOrg_rec_created = 0;
		num_of_revOrg_rec_updated = 0;
		num_of_revOrg_rec_create_errors = 0;
		num_of_revOrg_rec_update_errors = 0;

		//set up the list of accounts that need to be calculated based on input
		acctTRMap = new Map<Id, Id>();

		for (Budget_and_Revenue__c tr : targetRevList){

			acctTRMap.put(tr.Organisation__c, tr.Id); //map ensures uniqueness

		}

		//select all the existing Target and Revenue records for an org and build a structure (as not all of these are passed in input)
		setupTargetRevList();

		//select exising org by rev records
		setupCurrentOrgRevList();


	}

	//sets up map of Target and Revenue Records record for the orgs for evaluation later
	private void setupTargetRevList(){

		//select exising org by rev records
		acctTrList = [select 
		              Id,
		              Jan_Revenue_Amount__c,
		              Feb_Revenue_Amount__c,
		              Mar_Revenue_Amount__c,
		              Apr_Revenue_Amount__c,
		              May_Revenue_Amount__c,
		              Jun_Revenue_Amount__c,
		              Jul_Revenue_Amount__c,
		              Aug_Revenue_Amount__c,
		              Sep_Revenue_Amount__c,
		              Oct_Revenue_Amount__c,
		              Nov_Revenue_Amount__c,
		              Dec_Revenue_Amount__c,
		              Jan_Original_Budget__c,
		              Feb_Original_Budget__c,
		              Mar_Original_Budget__c,
		              Apr_Original_Budget__c,
		              May_Original_Budget__c,
		              Jun_Original_Budget__c,
		              Jul_Original_Budget__c,
		              Aug_Original_Budget__c,
		              Sep_Original_Budget__c,
		              Oct_Original_Budget__c,
		              Nov_Original_Budget__c,
		              Dec_Original_Budget__c,
		              Q1_Revenue_Amount__c,
		              Q2_Revenue_Amount__c,
		              Q3_Revenue_Amount__c,
		              Q4_Revenue_Amount__c,
		              Q1_Original_Budget__c,
		              Q2_Original_Budget__c,
		              Q3_Original_Budget__c,
		              Q4_Original_Budget__c,
		              Organisation__c,
		              Financial_Year__c
		              FROM Budget_and_Revenue__c where Organisation__c in :acctTRMap.keySet()];

		//create a map of recId+FY as key for revenue calculation by Fin Year
		currentTargRevMap = new Map<String, List<Budget_and_Revenue__c>>();

		for (Budget_and_Revenue__c targRev : acctTrList){
			String keyString = targRev.Organisation__c + targRev.Financial_Year__c;
			
			System.Debug('Setting Up targRev Map. KeyString: ' + keyString);
			
			//if it already exists in map, then add to the list corresponding to the key
			if (currentTargRevMap.containsKey(keyString)){
				System.Debug('Entry exists in currentTargRevMap for keyString: ' + keyString);
				currentTargRevMap.get(keyString).add(targRev);

			}else{ //else create a list and add it to the map
				
				System.Debug('Entry does not exist in currentTargRevMap. Adding entry for keyString: ' + keyString);
				List<Budget_and_Revenue__c> targRevList = new List<Budget_and_Revenue__c>();
				targRevList.add(targRev);
				currentTargRevMap.put(keyString, targRevList);
			}


		}

	}


	//sets up map of current Revenue by Organisation record for evaluation later
	private void setupCurrentOrgRevList(){

		//select exising org by rev records
		currentOrgRevList = [select 
		                     Id,
		                     Jan_Revenue_Amount__c,
		                     Feb_Revenue_Amount__c,
		                     Mar_Revenue_Amount__c,
		                     Apr_Revenue_Amount__c,
		                     May_Revenue_Amount__c,
		                     Jun_Revenue_Amount__c,
		                     Jul_Revenue_Amount__c,
		                     Aug_Revenue_Amount__c,
		                     Sep_Revenue_Amount__c,
		                     Oct_Revenue_Amount__c,
		                     Nov_Revenue_Amount__c,
		                     Dec_Revenue_Amount__c,
		                     Jan_Target_Amount__c,
		                     Feb_Target_Amount__c,
		                     Mar_Target_Amount__c,
		                     Apr_Target_Amount__c,
		                     May_Target_Amount__c,
		                     Jun_Target_Amount__c,
		                     Jul_Target_Amount__c,
		                     Aug_Target_Amount__c,
		                     Sep_Target_Amount__c,
		                     Oct_Target_Amount__c,
		                     Nov_Target_Amount__c,
		                     Dec_Target_Amount__c,
		                     Q1_Revenue__c,
		                     Q2_Revenue__c,
		                     Q3_Revenue__c,
		                     Q4_Revenue__c,
		                     Q1_Target__c,
		                     Q2_Target__c,
		                     Q3_Target__c,
		                     Q4_Target__c,
		                     Organisation__c,
		                     Financial_Year__c
		                     FROM Revenue_by_Organisation__c where Organisation__c in :acctTRMap.keySet()];

		//create a map of recId+FY as key for uniqueness checking
		currentOrgRevMap = new Map<String, Revenue_by_Organisation__c>();

		for (Revenue_by_Organisation__c revOrg : currentOrgRevList){
			String keyString = revOrg.Organisation__c + revOrg.Financial_Year__c; //this value is unique in revOrg
			System.Debug('Setting Up Rev Org Map. KeyString: ' + keyString);
			currentOrgRevMap.put(keyString, revOrg);
		}

	}



	//This method begins the calculation process and updates the Revenue by Org object
	//- If there is no existing record for the financial year in the Org by Revenue object, then a new record is created 
	//- If there is an existing record for the financial year, then that record is updated 
	public void calcAndUpdateRevOrg(){

		//calculate total amounts for each field based on values in list for a given Fin Year
		for (String keyString: currentTargRevMap.keySet()){

			Revenue_by_Organisation__c revOrg = getSummarisedOrg(currentTargRevMap.get(keyString));


			//check if this record already exists in the Rev Org object (i.e. for this financial year, if so update the record
			if (currentOrgRevMap.containsKey(keyString)){

				revOrg.Id = currentOrgRevMap.get(keyString).Id;
				OrgRevListUpdate.add(revOrg);

			}else{ //if not create the record - i.e. new financial year record

				OrgRevListCreate.add(revOrg);
			}

		}

		list<database.saveresult>  saveResultList = new list<database.saveresult>();



		//****************update Revenue by Org Records
		RevOrgUpdateError = false;
		saveResultList =  database.update(OrgRevListUpdate, false);

		//check for failure in update - log message and record all errors 
		// Iterate through each returned result and look for errors - error to be logged by invoking class
		for (Database.SaveResult sr : saveResultList) {
			if (!sr.isSuccess()){ 
				RevOrgUpdateError = true;
				num_of_revOrg_rec_update_errors++;
				// Operation failed, so get all errors                
				for(Database.Error err : sr.getErrors()) {
					erroredUpdateRecsString += 'Error updating Revenue by Org with record Id: ' + sr.getId() + ' Error: ' + err.getStatusCode() + ': ' + err.getMessage() 
					+ 'Fields that affected this error: '+ err.getFields();

				}
			}else{
				num_of_revOrg_rec_updated++;
			}
		}

		//****************Insert Revenue by Org Records
		RevOrgCreateError = false;
		saveResultList =  database.insert(OrgRevListCreate, false);

		//check for failure in update - log message and record all errors 
		// Iterate through each returned result and look for errors - error to be logged by invoking class
		for (Database.SaveResult sr : saveResultList) {
			if (!sr.isSuccess()) {
				RevOrgCreateError = true;
				num_of_revOrg_rec_create_errors++;
				// Operation failed, so get all errors                
				for(Database.Error err : sr.getErrors()) {
					erroredCreateRecsString += 'Error Inserting Revenue by Org with record Id: ' + sr.getId() + ' Error: ' + err.getStatusCode() + ': ' + err.getMessage() 
					+ 'Fields that affected this error: '+ err.getFields();

				}
			}else{
				num_of_revOrg_rec_created++;
			}
		}		





	}

	//This method accepts a list of Target and Revenue records for a given financial year as input and returns a Rev by Org record
	private Revenue_by_Organisation__c getSummarisedOrg(List<Budget_and_Revenue__c> trList){

		if (trList.size()==0)
			return null;

		Revenue_by_Organisation__c revOrg = new Revenue_by_Organisation__c();

		//get org and FY value from first record - as they are all the same
		revOrg.Organisation__c = trList[0].Organisation__c;
		revOrg.Financial_Year__c = trList[0].Financial_Year__c;

		System.Debug('trList size for Org ' + revOrg.Organisation__c + ' FY ' + revOrg.Financial_Year__c + ' : ' + trList.size());
		
		
		//Initialise amounts
		revOrg.Jan_Revenue_Amount__c	 = 0;
		revOrg.Feb_Revenue_Amount__c 	 = 0;
		revOrg.Mar_Revenue_Amount__c 	 = 0;
		revOrg.Apr_Revenue_Amount__c 	 = 0;
		revOrg.May_Revenue_Amount__c 	 = 0;
		revOrg.Jun_Revenue_Amount__c 	 = 0;
		revOrg.Jul_Revenue_Amount__c 	 = 0;
		revOrg.Aug_Revenue_Amount__c 	 = 0;
		revOrg.Sep_Revenue_Amount__c 	 = 0;
		revOrg.Oct_Revenue_Amount__c 	 = 0;
		revOrg.Nov_Revenue_Amount__c 	 = 0;
		revOrg.Dec_Revenue_Amount__c 	 = 0;
		revOrg.Jan_Target_Amount__c 	 = 0;
		revOrg.Feb_Target_Amount__c 	 = 0;
		revOrg.Mar_Target_Amount__c 	 = 0;
		revOrg.Apr_Target_Amount__c 	 = 0;
		revOrg.May_Target_Amount__c 	 = 0;
		revOrg.Jun_Target_Amount__c 	 = 0;
		revOrg.Jul_Target_Amount__c 	 = 0;
		revOrg.Aug_Target_Amount__c 	 = 0;
		revOrg.Sep_Target_Amount__c 	 = 0;
		revOrg.Oct_Target_Amount__c 	 = 0;
		revOrg.Nov_Target_Amount__c 	 = 0;
		revOrg.Dec_Target_Amount__c 	 = 0;
		revOrg.Q1_Revenue__c 	 		 = 0;
		revOrg.Q2_Revenue__c	 		 = 0;
		revOrg.Q3_Revenue__c 	 		 = 0;
		revOrg.Q4_Revenue__c 	 		 = 0;
		revOrg.Q1_Target__c 	 		 = 0;
		revOrg.Q2_Target__c 	 		 = 0;
		revOrg.Q3_Target__c 	 		 = 0;
		revOrg.Q4_Target__c 	 		 = 0;
		
		//summary value calculation
		for (Budget_and_Revenue__c targRev: trList){

			
			if(	 targRev.Jan_Revenue_Amount__c	!= null) 		revOrg.Jan_Revenue_Amount__c 	+= targRev.Jan_Revenue_Amount__c;
			if(	 targRev.Feb_Revenue_Amount__c	!= null) 		revOrg.Feb_Revenue_Amount__c 	+= targRev.Feb_Revenue_Amount__c;
			if(	 targRev.Mar_Revenue_Amount__c	!= null) 		revOrg.Mar_Revenue_Amount__c 	+= targRev.Mar_Revenue_Amount__c;
			if(	 targRev.Apr_Revenue_Amount__c	!= null) 		revOrg.Apr_Revenue_Amount__c 	+= targRev.Apr_Revenue_Amount__c;
			if(	 targRev.May_Revenue_Amount__c	!= null) 		revOrg.May_Revenue_Amount__c 	+= targRev.May_Revenue_Amount__c;
			if(	 targRev.Jun_Revenue_Amount__c	!= null) 		revOrg.Jun_Revenue_Amount__c 	+= targRev.Jun_Revenue_Amount__c;
			if(	 targRev.Jul_Revenue_Amount__c	!= null) 		revOrg.Jul_Revenue_Amount__c 	+= targRev.Jul_Revenue_Amount__c;
			if(	 targRev.Aug_Revenue_Amount__c	!= null) 		revOrg.Aug_Revenue_Amount__c 	+= targRev.Aug_Revenue_Amount__c;
			if(	 targRev.Sep_Revenue_Amount__c	!= null) 		revOrg.Sep_Revenue_Amount__c 	+= targRev.Sep_Revenue_Amount__c;
			if(	 targRev.Oct_Revenue_Amount__c	!= null) 		revOrg.Oct_Revenue_Amount__c 	+= targRev.Oct_Revenue_Amount__c;
			if(	 targRev.Nov_Revenue_Amount__c	!= null) 		revOrg.Nov_Revenue_Amount__c 	+= targRev.Nov_Revenue_Amount__c;
			if(	 targRev.Dec_Revenue_Amount__c	!= null) 		revOrg.Dec_Revenue_Amount__c 	+= targRev.Dec_Revenue_Amount__c;
			if(	 targRev.Jan_Original_Budget__c	!= null) 		revOrg.Jan_Target_Amount__c 	+= targRev.Jan_Original_Budget__c;
			if(	 targRev.Feb_Original_Budget__c	!= null) 		revOrg.Feb_Target_Amount__c 	+= targRev.Feb_Original_Budget__c;
			if(	 targRev.Mar_Original_Budget__c	!= null) 		revOrg.Mar_Target_Amount__c 	+= targRev.Mar_Original_Budget__c;
			if(	 targRev.Apr_Original_Budget__c	!= null) 		revOrg.Apr_Target_Amount__c 	+= targRev.Apr_Original_Budget__c;
			if(	 targRev.May_Original_Budget__c	!= null) 		revOrg.May_Target_Amount__c 	+= targRev.May_Original_Budget__c;
			if(	 targRev.Jun_Original_Budget__c	!= null) 		revOrg.Jun_Target_Amount__c 	+= targRev.Jun_Original_Budget__c;
			if(	 targRev.Jul_Original_Budget__c	!= null) 		revOrg.Jul_Target_Amount__c 	+= targRev.Jul_Original_Budget__c;
			if(	 targRev.Aug_Original_Budget__c	!= null) 		revOrg.Aug_Target_Amount__c 	+= targRev.Aug_Original_Budget__c;
			if(	 targRev.Sep_Original_Budget__c	!= null) 		revOrg.Sep_Target_Amount__c 	+= targRev.Sep_Original_Budget__c;
			if(	 targRev.Oct_Original_Budget__c	!= null) 		revOrg.Oct_Target_Amount__c 	+= targRev.Oct_Original_Budget__c;
			if(	 targRev.Nov_Original_Budget__c	!= null) 		revOrg.Nov_Target_Amount__c 	+= targRev.Nov_Original_Budget__c;
			if(	 targRev.Dec_Original_Budget__c	!= null) 		revOrg.Dec_Target_Amount__c 	+= targRev.Dec_Original_Budget__c;
			if(	 targRev.Q1_Revenue_Amount__c	!= null) 		revOrg.Q1_Revenue__c 	+= targRev.Q1_Revenue_Amount__c;
			if(	 targRev.Q2_Revenue_Amount__c	!= null) 		revOrg.Q2_Revenue__c	+= targRev.Q2_Revenue_Amount__c;
			if(	 targRev.Q3_Revenue_Amount__c	!= null) 		revOrg.Q3_Revenue__c 	+= targRev.Q3_Revenue_Amount__c;
			if(	 targRev.Q4_Revenue_Amount__c	!= null) 		revOrg.Q4_Revenue__c 	+= targRev.Q4_Revenue_Amount__c;
			if(	 targRev.Q1_Original_Budget__c	!= null) 		revOrg.Q1_Target__c 	+= targRev.Q1_Original_Budget__c;
			if(	 targRev.Q2_Original_Budget__c	!= null) 		revOrg.Q2_Target__c 	+= targRev.Q2_Original_Budget__c;
			if(	 targRev.Q3_Original_Budget__c	!= null) 		revOrg.Q3_Target__c 	+= targRev.Q3_Original_Budget__c;
			if(	 targRev.Q4_Original_Budget__c	!= null) 		revOrg.Q4_Target__c 	+= targRev.Q4_Original_Budget__c;			
			
			

		}


		return revOrg;
	}

}