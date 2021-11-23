global class AsyncUserApex {

    @future

    public static void AddUserToGroup(List<ID> UserIds,String varSales) {

        try {

            List<CollaborationGroupMember> cgm = new List<CollaborationGroupMember>();          
            
            Set<Id> groupIds =new Set<Id>();
        
            
            
              If (varSales=='Sales') 
            {      
            
                Map<Id, CollaborationGroup> saleschattergrps = new Map<Id, CollaborationGroup>([SELECT Id
                          FROM CollaborationGroup
                          
                           WHERE Name in ( 'Australia Post Chatter Users', 'Salesforce.com Knowledge','Product & Service Updates')]);
   
           groupIds =   saleschattergrps.keySet();           
                           
              }
              
                   If (varSales=='Startrack') 
            {      
            
                Map<Id, CollaborationGroup> startrackchattergrps = new Map<Id, CollaborationGroup>([SELECT Id
                          FROM CollaborationGroup
                          
                           WHERE Name in ( 'Australia Post Chatter Users', 'Salesforce.com Knowledge','Product & Service Updates','StarTrack Wins')]);
   
           groupIds =   startrackchattergrps.keySet();           
                           
              }    
              
              If (varSales=='SSSW') 
            {      
            
                Map<Id, CollaborationGroup> ssswchattergrps = new Map<Id, CollaborationGroup>([SELECT Id
                          FROM CollaborationGroup
                           //Where clause modified by Maumita on 14/09/2017 to incorporate REQ1222808
                             WHERE Name in ( 'Customer Service – Key Messages', 'Customer Service – Voice&Desktop Support', 'Customer Service – CX Forum','MyCustomers - System Updates', 'Your Career in the CCC', 'Customer Service - WFM', 'Customer Service - GM Updates', 'Customer Service - Consumer Channels')]);

           groupIds =   ssswchattergrps.keySet();           
                           
              }    

              If (varSales=='PON') 
            {      
            
                Map<Id, CollaborationGroup> ponchattergrps = new Map<Id, CollaborationGroup>([SELECT Id
                          FROM CollaborationGroup
                          
                           WHERE Name in ( 'Customer Service - Network User Group')]);
   
           groupIds =   ponchattergrps.keySet();           
                           
              }  

           for ( Id UserId : UserIds ) {
           
                for (ID groupid :groupIds ) 

            {  cgm.add(new CollaborationGroupMember (CollaborationGroupId = groupid , MemberId = UserId));  }

           }

           insert cgm;

        } catch (QueryException qe) {

            System.debug('QueryException in AsyncApex.AddUserToGroup is :' + qe); 

        } catch (Exception ex) {

            System.debug('Exception in AsyncApex.AddUserToGroup is :' + ex);

        }   

    }

}