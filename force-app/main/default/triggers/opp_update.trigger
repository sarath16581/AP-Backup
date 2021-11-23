/******
Purpose: allocating competitor score which is used by the data quality score of each opportunity

-------------------------------------------

14.04.2014 Eric Shen    remove DML action inside a loop after putting a reset statement

11.07.2014 Eric Shen    update new competitor name selection from account id to a pick list field Competitor_Name__c



*****/


trigger opp_update on Competitor__c (after update, after insert, after delete) {
    Set<Id> Opp_Ids = new Set<Id>();
    Integer i=0, cn=0, ct=0, cs=0, ca=0;
    String s='', sn='', st='', ss='', sa='';
    //this is to add all opps to this list before the for loop is finished, to avoid having a DML inside a loop
    List <Opportunity> oppUpdate = new List <Opportunity>();
    
    if(Trigger.isDelete)
    {
        for(Competitor__c c : trigger.old)
            Opp_Ids.add(c.OpportunityId__c);
    }
    else
    {
        for(Competitor__c c : trigger.new)
            Opp_Ids.add(c.OpportunityId__c);
    }
        
    system.debug('test');
     //remove as the competitor change
    //for(Opportunity o : [SELECT Id, Hidden_Competitor_Score__c , (SELECT Competitor_Type__c, AccountId__c, 
   //                                     Competitive_Status__c, Competitive_Advantage__c FROM Competitors__r) cid
    //                                    FROM Opportunity WHERE Id IN : Opp_Ids])
      //Change made to include a max of 12% for the hidden competitor score   
      for(Opportunity o : [SELECT Id, Hidden_Competitor_Score__c , (SELECT Competitor_Type__c,Competitor_Name__c, 
                                        Competitive_Status__c, Competitive_Advantage__c FROM Competitors__r) cid
                                        FROM Opportunity WHERE Id IN : Opp_Ids])
    
    {
        for(Competitor__c d : o.Competitors__r)
        {
            if(!String.isBlank (d.Competitive_Advantage__c)) 
                ca += 1; 
            if(!String.isBlank (d.Competitor_Type__c ))
                ct += 1;
            if(!String.isEmpty(String.valueof(d.Competitor_Name__c)))
                cn += 1;
            if((!String.isEmpty(d.Competitive_Status__c)))
                cs +=1;   
            ss+=d.Competitive_Status__c;
        }
        if(ca>0)
            i+=3;
        else
            s+='Competitive Advantage-';            
        if(ct>0)
            i+=4;
        else
            s+='Competitor Type-';            
        if(cn>0)
            i+=2;
        else
            s+='Competitor-';            
        if(cs>0)
            i+=3;
        else
            s+='Competitive Status-';            

        system.debug('test');
         
        o.Hidden_Competitor_Score__c = i;        
        o.Hidden_Competitor_Score_Description__c = s;
    
         oppUpdate.add(o);
        //reset counter i to fix the overinflated score issue
        i = 0;
    } 
   //update opportunities after the competitors scores all added
     if (!oppUpdate.isEmpty())  
        update oppUpdate;
}