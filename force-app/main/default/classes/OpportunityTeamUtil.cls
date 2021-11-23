/******************************************************************************************
    @description: Util Class for Trigger; 'OpportunityTeamListener'
                  The class implements a logic to update 'Has_Product_Specialist__c' and 'Has_Solution_Consultant__c' flags on Opportunity
                  based on changes detected on OpportunityTeamListener's TeamMemberRole field by the trigger
    @author: Eric Shen    23/09/2015  
History:
-----------------------------------------------------------------------------------------
23.09.2015  	Eric Shen			                Created
07.07.2016  	paul.stamer@auspost.com.au			Added the Strategic Account Executive Driver
12-10-2020      seth.heang@auspost.com.au	        Repurpose Test scenarios for Product Specialist and Solution Consultant flag on Opportunity
*****************************************************************************************/

public class OpportunityTeamUtil implements Queueable {
    
    
    private static final string SOLUTION_CONSULTANT = 'Solution Consultant';
    private static final string PRODUCT_SPECIALIST = 'Product Specialist';
    private List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
    
    /*
     * The following method is decommissioned as part of Opportunity Split Implementation. 
     * The following TeamMemberRole which were used in the method, have also been decommissioned and deactivated:
     * -Business Development Driver
     * -Supply Chain Optimisation Driver
     * -Strategic Account Executive Driver
     *
        // Constants
        //private static final String BDD = 'Business Development Driver';  
        //private static final String SCOD = 'Supply Chain Optimisation Driver';
        //private static final String SAED = 'Strategic Account Executive Driver';

      /**
      * @description       This method clear Business development driver and Supply chain optimisation driver fields on opportunity object on deletion or update
       if no such team member roles are allocated anymore
      * @param             newOppTeamList - List<OpportunityTeamMember>, oldMap -Map<Id,OpportunityTeamMember>
      * @return            Void
      * @throws            Method might throw exception which is handled by Try-Catch block
      *
      public static void handleTeamMembers(List<OpportunityTeamMember> newOppTeamList,Map<Id,OpportunityTeamMember> oldMap){
        
        Set<Id> oppIds = new set<Id>(); // to create a set of unique opportunity IDs

        List<OpportunityTeamMember> oppTeamList = New List<OpportunityTeamMember>();
     
        OpportunityTeamMember oldRec = New OpportunityTeamMember() ;
        
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        
        //on delettion, assign the old values to this list, otherwise the newOppTeamList is assigned
        oppTeamList = newOppTeamList != null ? newOppTeamList : oldMap.values();
        
        // to set flag to differ delete from update
        Boolean isDelete = false;
        
        isDelete = (oldMap != null && newOppTeamList==null )? true : false;
        
        //loop through opportunity team member to get all Opportunity IDs and assign to the ID set.
        
        for(OpportunityTeamMember oppTeam : oppTeamList){
            
               oppIds.add(oppTeam.OpportunityId);
        }
        
         // loop through opportunities to get values for these two driver fields and put it into oppMap.
         for(Opportunity opptemp:[Select Id,Business_Development_Driver__c,Supply_Chain_Optimisation_Driver__c, Strategic_Account_Executive_Driver__c from Opportunity WHERE id in :oppIds] )
             
        {        
            oppMap.Put(opptemp.id,opptemp)   ;       
        }
         
      //Loop through opportunity team again and compare each scenarios for actions
      
        for(OpportunityTeamMember oppTeam : oppTeamList){
        
            Opportunity opp = oppMap.get(oppTeam.OpportunityId); // retrieve the values of relevant fields on opportunity
            
            oldRec = oldMap != null ? oldMap.get(oppTeam.Id): null;
        
        
        //If it's a deletion trigger or update with old values equal to these two roles.
            if(oldRec != null){
                if((oldRec.TeamMemberRole != oppTeam.TeamMemberRole) || isDelete){
                    if(BDD.equalsIgnoreCase(oldRec.TeamMemberRole)){
                        
                        //reset opportunity field values.
                        opp.Business_Development_Driver__c = null;
                     
                    }
                     // for update, if the team members are assigned to these two roles. 
                    if(BDD.equalsIgnoreCase(oppTeam.TeamMemberRole) && !isDelete){
                        
                        // There's only one member who can have BDD role. Otherwise throw an error. 
                        if (opp.Business_Development_Driver__c !=null) {
                            
                        oppTeam.addError(Label.Opportunity_BDD_Error);
                            
                        }
                       
                        else{
                         // assign the team member's name to the opportunity driver field. 
                        opp.Business_Development_Driver__c = oppTeam.UserId;
                        
                        }
                    }
                    
                    if(SCOD.equalsIgnoreCase(oldRec.TeamMemberRole)){
                            //reset opportunity field values.
                        opp.Supply_Chain_Optimisation_Driver__c = null;
                    }
                     // for update, if the team members are assigned to these two roles. 
                    if(SCOD.equalsIgnoreCase(oppTeam.TeamMemberRole) && !isDelete){
                        
                            // There's only one member who can have SCOD role. Otherwise throw an error. 
                        if (opp.Supply_Chain_Optimisation_Driver__c!=null) {
                            
                         oppTeam.addError(Label.Opportunity_SCOD_Error);
                            
                        }
                        
                        else {
                        // assign the team member's name to the opportunity driver field. 
                        opp.Supply_Chain_Optimisation_Driver__c = oppTeam.UserId;
                        }
                    }     
                    
                    if(SAED.equalsIgnoreCase(oldRec.TeamMemberRole)){
                            //reset opportunity field values.
                        opp.Strategic_Account_Executive_Driver__c = null;
                    }
                     // for update, if the team members are assigned to these two roles. 
                    if(SAED.equalsIgnoreCase(oppTeam.TeamMemberRole) && !isDelete){
                        
                            // There's only one member who can have SAED role. Otherwise throw an error. 
                        if (opp.Strategic_Account_Executive_Driver__c!=null) {
                            
                         oppTeam.addError(Label.Opportunity_SAED_Error);
                            
                        }
                        
                        else {
                        // assign the team member's name to the opportunity driver field. 
                        opp.Strategic_Account_Executive_Driver__c = oppTeam.UserId;
                        }
                    }           
                    
                }
            }
            
            // if it's an insert, assign roles only if it's an unique value. 
            else{
                
                
                if(BDD.equalsIgnoreCase(oppTeam.TeamMemberRole)){
                    
                    if (opp.Business_Development_Driver__c !=null) {
                            
                        oppTeam.addError(Label.Opportunity_BDD_Error);
                            
                        }
                        
                     else {
                    
                    opp.Business_Development_Driver__c =  oppTeam.UserId;
                    
                         }
                }
                
                if(SCOD.equalsIgnoreCase(oppTeam.TeamMemberRole)){
                    
                        if (opp.Supply_Chain_Optimisation_Driver__c!=null) {
                            
                         oppTeam.addError(Label.Opportunity_SCOD_Error);
                            
                        }
                        
                        else{
                    opp.Supply_Chain_Optimisation_Driver__c =  oppTeam.UserId;
                        }
                }    

                if(SAED.equalsIgnoreCase(oppTeam.TeamMemberRole)){
                    
                        if (opp.Strategic_Account_Executive_Driver__c!=null) {
                            
                         oppTeam.addError(Label.Opportunity_SAED_Error);
                            
                        }
                        
                        else{
                    opp.Strategic_Account_Executive_Driver__c =  oppTeam.UserId;
                        }
                }   
            }
            
            
            // put the updated opportunities into this map
            oppMap.put(opp.Id,opp);
        }
           // update all affected opportunities. 
        update oppMap.values();
    }*/
    
    /**
      * @description       Constructor class to accept a list of OpportunityTeamMember passed from Trigger 'OpportunityTeamListener'
      * @param             newOppTeamList - List<OpportunityTeamMember>
      * @return            Void
      * @throws            Method might throw exception which is handled by Try-Catch block
      */ 
    public OpportunityTeamUtil(List<OpportunityTeamMember> newOppLists){
        oppTeamList = newOppLists;
    }
    
    /**
        * @description      The execute method of this queabale class implements the logic to 
                            update 'Has_Product_Specialist__c' and 'Has_Solution_Consultant__c' flags on Opportunity
                            based on changes detected on OpportunityTeamListener's TeamMemberRole field 
        * @param             context - QueuableContext
        * @return            Void
        * @throws            Method might throw exception which is handled by Try-Catch block
      */ 
    public void execute(QueueableContext context) {
        Set<Id> oppIds = new set<Id>(); // to create a set of unique opportunity IDs
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        try{
            // exit if the list is empty
            if(oppTeamList.IsEmpty()){
                return;
            }
            
            // get IDs from trigger and saved to a set
            for(OpportunityTeamMember oppTeam : oppTeamList){
                oppIds.add(oppTeam.OpportunityId);
            }
        
            // loop through opportunities to get values for these two flags and put it into oppMap.
            for(Opportunity opptemp:[Select Id, Has_Product_Specialist__c, Has_Solution_Consultant__c from Opportunity WHERE id in :oppIds] ){        
                oppMap.Put(opptemp.id,opptemp);       
            }
        
            // Add Product Specialist and Solution Consultant roles for counting
            List<String> searchRoles = new List<String>();
            searchRoles.add(PRODUCT_SPECIALIST);
            searchRoles.add(SOLUTION_CONSULTANT);

            // call countTeamRole() method to count the list of roles (ie, 'Product Specialist' & 'Solution Consulant') from each opportunity
            Map<Opportunity, Map<String, Integer>> countRolesMap = new Map<Opportunity, Map<String, Integer>>();
            countRolesMap = countTeamRole(oppMap,searchRoles);

            // track new changes
            Boolean hasChanges = false;
			
        	
            for(Opportunity opp: countRolesMap.keyset()){
                Integer counterPS;
                Integer counterSC;
                // get counts for Product Specialist or Solution Consultant roles
                for(String role : countRolesMap.get(opp).keyset()){
                    if(role.equalsIgnoreCase(PRODUCT_SPECIALIST)){
                        counterPS = countRolesMap.get(opp).get(role);
                    }else if(role.equalsIgnoreCase(SOLUTION_CONSULTANT)){
                        counterSC = countRolesMap.get(opp).get(role);
                    }
                }

                Opportunity newOpp = new Opportunity();
                // check if there is at least one role found, set 'Product Specialist' flag to true
                if(counterPS > 0){
                    newOpp.Has_Product_Specialist__c = true;
                }else{
                    newOpp.Has_Product_Specialist__c = false;
                }

                // check if there is at least one role found, set 'Solution Consultant' flag to true
                if(counterSC > 0){
                    newOpp.Has_Solution_Consultant__c = true;
                }else{
                    newOpp.Has_Solution_Consultant__c = false;
                }
                
                //check for new changes and update the 'hasChanges' flag
                if(newOpp.Has_Product_Specialist__c != opp.Has_Product_Specialist__c){
                    opp.Has_Product_Specialist__c = newOpp.Has_Product_Specialist__c;
                    hasChanges = true;
                }
                if(newOpp.Has_Solution_Consultant__c != opp.Has_Solution_Consultant__c){
                    opp.Has_Solution_Consultant__c = newOpp.Has_Solution_Consultant__c;
                    hasChanges = true;
                }
                oppMap.put(opp.Id,opp);
            }

            // update all affected opportunities if new changes is detected
            if(hasChanges){
                update oppMap.values();
            }
        }catch(Exception ex){
            // log error
           GlobalUtility.logMessage('ERROR','manageOpportunityTeamMemberRole', 'updateOpportunity','','',ex.getMessage(),'',null,0);
        }
    }

    
    /**
      * @description       This method is used to count the number of duplicate roles of Opportunity Team Member
                            under its respective opportunity
      * @param             allOppMap - Map<Id,Opportunity>
      * @param             teamRole - String
      * @return            Map<Opportunity, Integer>
      * @throws            Method might throw exception which is handled by Try-Catch block
      */ 
    public static Map<Opportunity, Map<String,Integer>> countTeamRole(Map<Id,Opportunity> allOppMap, List<String> teamRoles){

        Map<Opportunity, Map<String,Integer>> counterTeamRole = new Map<Opportunity, Map<String,Integer>>();
        List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
        Map<String,Integer> roleCounterMap = new Map<String,Integer>();
        try{
            // query all OpportunityTeamMember records based on the opportunity passed from the method's parameters
            for(OpportunityTeamMember oppTeam : [SELECT id, TeamMemberRole,OpportunityId FROM OpportunityTeamMember WHERE OpportunityId IN :allOppMap.keyset()]){
                oppTeamList.add(oppTeam);
                // Initialise the map with count = 0 for each opportunity
                Opportunity opp = new Opportunity();
                opp = allOppMap.get(oppTeam.opportunityId);
                roleCounterMap.put(oppTeam.TeamMemberRole, 0);
                counterTeamRole.put(opp, roleCounterMap);
            }
            
            for(OpportunityTeamMember oppTeam : oppTeamList){
                // Increase counter for each matching TeamMemberRoles as specified in the method's parameters
                if(teamRoles.contains(oppTeam.TeamMemberRole)){
                    Opportunity opp = new Opportunity();
                    opp = allOppMap.get(oppTeam.opportunityId);
                    roleCounterMap.put(oppTeam.TeamMemberRole, counterTeamRole.get(opp).get(oppTeam.TeamMemberRole) + 1 );
                    // add to the bigger map, and map to the team Role as key
                    counterTeamRole.put(opp, roleCounterMap);
                }
            }
        }catch(Exception ex){
            // log errors
            GlobalUtility.logMessage('ERROR','countTeamRoleOnOpportunityTeamMember', 'updateOpportunity','','',ex.getMessage(),'',null,0);
        }
        return counterTeamRole;
    }
}