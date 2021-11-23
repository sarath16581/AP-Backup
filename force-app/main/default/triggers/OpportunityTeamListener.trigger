/*****************************************************************************************
    @description: Provide opportunity business development driver and supply chain optimisation driver for reporting purpose. Requested by Jason Gould and AVP
    @author: Eric Shen   created on 23/09/2015  
History:
-----------------------------------------------------------------------------------------
23.09.2015  	Eric Shen			                created
12-10-2020      seth.heang@auspost.com.au	        Repurpose Test scenarios for Product Specialist and Solution Consultant flag on Opportunity
*****************************************************************************************/
trigger OpportunityTeamListener on OpportunityTeamMember (after delete, after insert, after update) {
    if(trigger.isAfter){
        //scenario of creating a new opportunity team member or update opportunity team member
        if (trigger.isInsert) {
            //OpportunityTeamUtil.handleTeamMembers(Trigger.new,null);
            
          	/* Invoke the queable class to perform counts of team member roles and update Product Specialist
                   and Solution Consultant flag on parent Opportunity */
            System.enqueueJob(new OpportunityTeamUtil (Trigger.New));
        }
        //scenario of updating a opportunity team member
        if (trigger.isupdate){
            //OpportunityTeamUtil.handleTeamMembers(Trigger.new,Trigger.oldMap);
			List<OpportunityTeamMember> oppMemberList = new List<OpportunityTeamMember>();

            // Loop all new changes and specially check for changes in TeamMemberRole field value and add into a list
            for(OpportunityTeamMember newOpp : Trigger.New){
                if(trigger.oldMap.get(newOpp.id).TeamMemberRole != newOpp.TeamMemberRole){
                    oppMemberList.add(newOpp);
                }
            }

            if(!oppMemberList.isEmpty()){
                /* Invoke the queable class to perform counts of team member roles and update Product Specialist
                   and Solution Consultant flag on parent Opportunity */
                System.enqueueJob(new OpportunityTeamUtil (oppMemberList));
            }
        }
    
        //scenario of deleting a opportunity team member
        if (trigger.isdelete) {
            //OpportunityTeamUtil.handleTeamMembers(null,Trigger.oldMap);
            
            /* Invoke the queable class to perform counts of team member roles and update Product Specialist
                   and Solution Consultant flag on parent Opportunity */
            System.enqueueJob(new OpportunityTeamUtil (Trigger.oldMap.values()));
        }
        
    }

}