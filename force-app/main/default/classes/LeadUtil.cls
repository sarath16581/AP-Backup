/**************************************************
Type:       Utility Class for Lead Object
Purpose:    
Used By:    LeadTrigger
History:
--------------------------------------------------
07.06.2012  M. Isidro (Cloud Sherpas)           Created
07.06.2012  Joseph Barrameda (Cloud Sherpas)    Added code that updates Owner_Employee_Number__c
03.07.2012  Joseph Barrameda (Cloud Sherpas)    Added code that updates Campaign_Name__c before Insert/Update
23.05.2014  Eric Shen (Aus Post)                Change 'Country' to 'AU' in testing class
23.02.2016  Nandan                				updated testLeadUtil method with Active__c=True for Hub_Catchment__c
13-03-2020  Jansi(avula.jansirani@crmit.com)    Added a methos updateLeadRecordType
**************************************************/
public with sharing class LeadUtil {
/*  
    public static void updateLeadHubCatchment(List<Lead> leadList){
        List<String> postcodeList = new List<String>();
        for (Lead lead : leadList){
            postcodeList.add(lead.PostalCode);          
        }
        
        List<Hub_Catchment_Reference__c> hcrList = [SELECT Post_Code__c, Hub_Catchment__c FROM Hub_Catchment_Reference__c WHERE Post_Code__c in : postcodeList];
        Map<String, String> codeHubMap = new Map<String, String>();
        for (Hub_Catchment_Reference__c hcr : hcrList){
            codeHubMap.put(hcr.Post_Code__c, hcr.Hub_Catchment__c);
        }       
        
        for (Lead lead : leadList){
            lead.Hub_Catchment__c = codeHubMap.get(lead.PostalCode); 
        }
    }
*/    
    public static void updateLeadOwnerEmployeeNumber(List<Lead> leadList){
        
            Map <Id,String> leadOwnerIDMap = new Map <Id,String>();         
            List <Id> leadOwnerIdList = new List <Id>();        
            List <Lead> leadUpdate= new List <Lead>();          
            
            for (Lead tmp: leadList){
                leadOwnerIdList.add (tmp.OwnerId);
            }
            
            for (User userLst : [Select Id, EmployeeNumber from User where ID in: leadOwnerIdList] ){
                leadOwnerIDMap.put( userLst.Id, userLst.EmployeeNumber);
            }           
            
            for (Lead tmpLead: leadList){               
                tmpLead.Owner_Employee_Number__c= leadOwnerIDMap.get(tmpLead.OwnerId);      
            }
                    
    }
    
    public static void updateCampaignName (List <Lead> leadList){
            
            List <Id> leadIdList = new List <Id>();
            List <String> leadSourceList = new List <String>();
            List <Lead> leads = new List <Lead>();
            List <Lead> leadUpdate = new List <Lead>();
            
            for (Lead tmpLead : leadList){              
                leadIdList.add (tmpLead.id); 
                leadSourceList.add (tmpLead.LeadSource);            
            }
            
            List <Campaign> campaignList = [SELECT Id,Name FROM Campaign WHERE Name in : LeadSourceList ] ;             
            for (Lead tmpLead : [SELECT id, name, leadSource, campaign_Name__c FROM Lead where Id in: leadIdList]){
                for (Campaign tmpCampaign: campaignList){
                    System.debug ('### LeadSource, Campaign Name #### = { ' + tmpLead.LeadSource + ' , ' + tmpCampaign.name + ' }');
                    if ( tmpLead.LeadSource == tmpCampaign.name ){ 
                        tmpLead.Campaign_Name__c = tmpLead.LeadSource ; 
                        leadUPdate.add ( tmpLead);
                        break;
                    }
                }
            }
                        
            if (leadUpdate != null) update leadUpdate;
    }
    
    
    //************ TEST COVERAGES **************/ 
       
    private static testMethod void testUpdateCampaign (){
            test.startTest();
            Campaign cmpgnRec = new Campaign( Name='Campaign X');
            insert cmpgnRec; 
                        
        Lead leadRec = new Lead( LastName='Lead Record', FirstName='First Name',   Email='x@x.com', Street='Street',    
                City='City',    State='State',  Country='AU',PostalCode='1000',    Parcels_per_week__c='1-9', LeadSource='Campaign X');            
        insert leadRec; 
        test.stopTest();
        }
    
    private static testMethod void testLeadUtil(){
        // create hub catchment
        Hub_Catchment_Reference__c hcr = new Hub_Catchment_Reference__c(
            Post_Code__c='2000',
            Hub_Catchment__c='Two Thousand',
			Active__c=True					// Nandan : Added active attribute to fix test class failure
        );   
        insert hcr;                 
                
        //create lead
        Lead leadRec = new Lead(
            LastName='Lead Record',
            FirstName='First Name',
            Email='x@x.com',
            Street='Street',
            City='City',
            State='State',
            Country='AU',
            PostalCode='1000',
            Parcels_per_week__c='1-9'            
        );
        insert leadRec; 
        leadRec.PostalCode = '2000';
        update leadRec;
                
        test.startTest();
        system.assertEquals('Two Thousand', [SELECT Hub_Catchment__c FROM Lead WHERE Id=:leadRec.Id].Hub_Catchment__c);
        delete leadRec;
        undelete leadRec;      
        system.assertEquals('Two Thousand', [SELECT Hub_Catchment__c FROM Lead WHERE Id=:leadRec.Id].Hub_Catchment__c);
        test.stopTest();
    }
    
        static testMethod void testUpdateOwnerEmpNumber(){
            test.startTest();           
            List <Lead> ldList = new List<Lead>();              
            Lead LD;  
            Integer ctr=0;          
            for (ctr=0; ctr<5; ctr++){
                LD=new Lead();
                LD.FirstName = 'Tom';
                LD.LastName = 'Cruise' + ctr ; 
                LD.Email = 'tomcruise' + ctr + '@yahoo.com'; 
                LD.status='Not Verified';               
                LD.Parcels_per_week__c = '1-9';
                LD.Street='11th';
                LD.City = 'NY';
                LD.State= 'NY';
                LD.PostalCode='789000';
                LD.OwnerId= '00590000000ils5AAA';           
                ldList.add (LD);
            }
        insert ldList;          
            for (Lead tmp : ldList){
                tmp.OwnerId = '00590000000ils6AAA' ;
            }                       
            
            System.assertEquals (Ld.OwnerID,'00590000000ils6AAA');
            //System.assertEquals('XYZ 11',[Select StageName from Lead where StageName='XYZ 11'].StageName);
            test.stopTest();
        }  
    
    //--[Jansi:13-03-2020]; Update Lead recordType
    public static void updateLeadRecordType (List<Lead> leadList){
        List<RecordType> recordTypeList = [SELECT Id, DeveloperName FROM RecordType where SobjectType ='Lead' and DeveloperName IN('Standard','BG_Standard')];
        String standardRecTypeId;
        String bgStandardRecTypeId;
        
        for(RecordType recType:recordTypeList){
            if(recType.DeveloperName == 'Standard'){
                standardRecTypeId = recType.Id;
            }else if(recType.DeveloperName == 'BG_Standard'){
                bgStandardRecTypeId = recType.Id;
            }
        }
        
        if(standardRecTypeId != null && bgStandardRecTypeId != null){
            for (Lead leadrec : leadList){
                if(leadrec.RecordTypeId !=null && leadrec.RecordTypeId == standardRecTypeId){
                    leadrec.RecordTypeId = bgStandardRecTypeId;
                }
            }
        }
    }
    
}