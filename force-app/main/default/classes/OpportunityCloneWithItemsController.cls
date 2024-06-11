/********************************************************************************************
Type:       Button Initiated Apex Class (Added to all Opportunity Page Layouts)
Purpose:    Clone the Opportunity Record with or without opportunity product items.
            This class is used instead of the standard clone function so that fields can be
            programatically modified upon cloning.  It also avoids an unique key issue when
            copying Opportunity Product Records which have a matching ProductClass value
            (duplicate classification, start and end date. See fields "ProductClass" and "ProdClassFieldUpdate").

History:
  22-Jul-2013     Haider Raza         Initial Creation
  28-Aug-2013     Clinton McIntyre    Added header.  Updated code to null "Commit to close by" field.
                                      Side note - recommend combining functions to remove duplication of
                                      code across the two methods.
  27-May-2015     Clinton McIntyre    Added "with sharing" to classes as part of security audit.
  11-Nov-2015     Eric Shen            Null business development and supply chain optimisation driver fields during clone.
  13-Nov-2015     Kalpita T            Added values to revenue start and end date for opportunity line item
  24-Feb-2021     Naseer Abbasi       Omitted field 'Closing Owner Role' while cloning opportunity  
  09-Mar-2021     Seth Heang           STP-2793 - Decommission "Business_Development_Driver__c" field
  14-Apr-2021     Neha Mehta          INC1659920-REQ2459600 Update some opportuniy field values to null after cloning
  02-Sep-2022     Talib Raza          REQ2938280: Set Opp fields to false
*********************************************************************************************/

public with sharing class OpportunityCloneWithItemsController {
 
    //added an instance varaible for the standard controller
    private ApexPages.StandardController controller {get; set;}
     // add the instance for the variables being passed by id on the url
    private Opportunity op {get;set;}
    // set the id of the record that is created -- ONLY USED BY THE TEST CLASS
    public ID newRecordId {get;set;}
    String theme;
    String query;
    Theme_Settings__c settings=Theme_Settings__c.getOrgDefaults();
    public OpportunityCloneWithItemsController(){
    }
 
    // initialize the controller
    public OpportunityCloneWithItemsController(ApexPages.StandardController controller) {
 
        //initialize the stanrdard controller
        this.controller = controller;
        // load the current record
        op = (Opportunity)controller.getRecord();
 
    }
 
    // method called from the VF's action attribute to clone the po
    public PageReference cloneWithItems() {
 
         // setup the save point for rollback
         Savepoint sp = Database.setSavepoint();
         Opportunity newOp;
         theme = UserInfo.getUiThemeDisplayed(); //Added by neha mehta for INC1659920-REQ2459600 
         try {

            // Dynamically build query string for ALL Opportunity fields
            List<String> opptyFields = new List<String>();
            opptyFields.addAll( Opportunity.sObjectType.getDescribe().fields.getMap().keySet() );
            query = 'SELECT ' + opptyFields.get(0); 
            for (Integer fieldCounter=1 ; fieldCounter < opptyFields.size() ; fieldCounter++){
                if( !opptyFields.get(fieldCounter).startsWith('eclm')
                   &&!opptyFields.get(fieldCounter).equals('geopointe__geocode__c') 
                   &&!opptyFields.get(fieldCounter).equals('LEGACY_ID__c')
                   &&!opptyFields.get(fieldCounter).equals('Opportunity_Number__c')
                                         //add exclusions for Business development driver and Supply chain optimisation driver  11-Nov-2015 Eric Shen
                   // &&!opptyFields.get(fieldCounter).equals('Business_Development_Driver__c') - Decommission this field as part of STP-2793
                   &&!opptyFields.get(fieldCounter).equals('Supply_Chain_Optimisation_Driver__c')              
                   
                
                   ){
                
                    query += ', ' + opptyFields.get(fieldCounter);
                }
            }

            // Add additional account owner field needed for processing
            query +=', Account.OwnerId ';
            query +='FROM Opportunity ';
            query +='WHERE Id = \''+op.id+'\'';



            //copy the purchase order - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
            //op = [select Id, Name, StageName, CloseDate, AccountId, Type FROM Opportunity where id =: op.id];
            op = Database.query(query);
            op.Name = 'Clone - '+op.Name;
            op.StageName = 'Identify';
            op.Probability = 3;
            // CMCINTYRE 28/08/2013 - Force to null, as excluding from query still returns result and results in copied value.
            op.Commit_to_close_by__c = null;
            //Eric Shen  11/11/2015 nullify the two fields below
            
             // op.Business_Development_Driver__c =null;  - Decommission this field as part of STP-2793
             op.Supply_Chain_Optimisation_Driver__c =null;
             
             
             newOp = op.clone(false);
             insert newOp;
 
             // set the id of the new po created for testing
             newRecordId = newOp.id;
             
             Opportunity update_opp = [SELECT Id, OwnerId, CloseDate FROM Opportunity WHERE Id = :newOp.id];

             update_opp.ECLM_Opportunity_Id_for_Contract__c=newOp.id;  
             // REQ2938280: set Opp fields to false
             update_opp.CTA_Propose_Approved__c = false;
             update_opp.CTA_Propose_Request_Exists__c = false;
             update_opp.CTA_Pursue_Approved__c = false;
             update_opp.CTA_Pursue_Request_Exists__c = false;
             
             update_opp.OwnerId = UserInfo.getUserId();
             if(update_opp.CloseDate < Date.Today() || update_opp.CloseDate == null) {
                update_opp.CloseDate = Date.Today().addDays(30);
             }

             Update update_opp;
 
             // copy over the line items - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
             List<OpportunityLineItem> items = new List<OpportunityLineItem>();
             for (OpportunityLineItem li : [Select ListPrice,OpportunityId,PricebookEntryId,Classification__c,Opportunity.CloseDate,
                                             Sub_Classification__c,Quantity,UnitPrice,Contract_Product__c  
                                             From OpportunityLineItem where OpportunityId = :op.id]) {
                  OpportunityLineItem newli = li.clone(false);
                  newli.OpportunityId = newop.id;
                  //added by kalpita to check and insert value in revenue start and end dates
                  newli.Contract_Start_Date__c = newli.Contract_Start_Date__c == null ? newop.CloseDate : newli.Contract_Start_Date__c; 
                  newli.Contract_End_Date__c = newli.Contract_End_Date__c == null ? newop.CloseDate + 365 : newli.Contract_End_Date__c;
                  //newli.Classification__c ='New Business';
                  items.add(newli);
             }
             insert items;
 
         } catch (Exception e){
             // roll everything back in case of error
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return null;
         }
         //Added by neha mehta for INC1659920-REQ2459600 Start
        if(theme.equals(settings.Theme__c)){
            return new PageReference('/lightning/r/Opportunity/'+newop.id+'/edit?navigationLocation=DETAIL&backgroundContext=/lightning/r/Opportunity/'+newop.id);
         }
        else {
            return new PageReference('/'+newop.id+'/e?retURL=%2F'+newop.id);
        }
         //Added by neha mehta for INC1659920-REQ2459600 End
        //return new PageReference('/'+newop.id+'/e?retURL=%2F'+newop.id);
        // return new PageReference('/'+newop.id);
    }
 
 
    // method called from the VF's action attribute to clone the po
    public PageReference cloneWithoutItems() {
 
        // setup the save point for rollback
        Savepoint sp = Database.setSavepoint();
        Opportunity newOp;
        
        theme = UserInfo.getUiThemeDisplayed(); //Added by neha mehta for INC1659920-REQ2459600 
        try {

            // Dynamically build query string for ALL Opportunity fields
            List<String> opptyFields = new List<String>();
            opptyFields.addAll( Opportunity.sObjectType.getDescribe().fields.getMap().keySet() );
            query = 'SELECT ' + opptyFields.get(0); 
            for (Integer fieldCounter=1 ; fieldCounter < opptyFields.size() ; fieldCounter++){
                if( !opptyFields.get(fieldCounter).startsWith('eclm')
                   &&!opptyFields.get(fieldCounter).equals('geopointe__geocode__c') 
                   &&!opptyFields.get(fieldCounter).equals('LEGACY_ID__c')
                   &&!opptyFields.get(fieldCounter).equals('Opportunity_Number__c')
               //add exclusions for Business development driver and Supply chain optimisation driver  11-Nov-2015 Eric Shen
                   // &&!opptyFields.get(fieldCounter).equals('Business_Development_Driver__c') - Decommission this field as part of STP-2793
                   &&!opptyFields.get(fieldCounter).equals('Supply_Chain_Optimisation_Driver__c')              
                   
                   ){

                    query += ', ' + opptyFields.get(fieldCounter);
                }
            }

            // Add additional account owner field needed for processing
            query +=', Account.OwnerId ';
            query +='FROM Opportunity ';
            query +='WHERE Id = \''+op.id+'\'';



              //copy the purchase order - ONLY INCLUDE THE FIELDS YOU WANT TO CLONE
             //op = [select Id, Name, StageName, CloseDate, AccountId, Type FROM Opportunity where id =: op.id];
             op = Database.query(query);
             op.Name = 'Clone - '+op.Name;
             op.StageName = 'Identify';
             op.Probability = 3;
             op.Closing_Owner_Role__c = null;
             // CMCINTYRE 28/08/2013 - Force to null, as excluding from query still returns result and results in copied value.
             op.Commit_to_close_by__c = null;
             op.Pre_Entry__c=false;
             op.Offline_Contract_Received__c=false;
             op.Is_Superseded_Opportunity__c=false;
             op.Total_Schedule_Revenue_to_Date__c=null;
             op.Opportunity_Traded_Revenue__c=null;   
             op.Monthly_Executive_Summary__c=null;
             op.Description=null;
             op.mh_Associated_Blue_Sheet__c=false;
             op.mh_Strengths__c =null;
             op.mh_Red_Flags__c =null;
             op.KeyContact__c=null;
             op.Closed_Reason__c=null;
             op.Closed_Comments__c=null;
             op.CampaignId=null;
             op.LPO_WCC__c=null;
             op.Lead_Seeker__c=false;
             op.LeadSource=null;
             op.LBP_Tier_1__c=null;
             op.LBP_Tier_2__c=null;
             op.Amount=null;
             op.Primary_Competitor_Name__c=null;
             newOp = op.clone(false); 
             insert newOp;
             
             Opportunity update_opp = [SELECT Id, OwnerId, CloseDate FROM Opportunity WHERE Id = :newOp.id];
             //Eric Shen  11/11/2015 nullify the two fields below
             update_opp.ECLM_Opportunity_Id_for_Contract__c=newOp.id; 
             
             // update_opp.Business_Development_Driver__c =null; - Decommission this field as part of STP-2793
              update_opp.Supply_Chain_Optimisation_Driver__c =null;
            
             // REQ2938280: set Opp fields to false
              update_opp.CTA_Propose_Approved__c = false;
              update_opp.CTA_Propose_Request_Exists__c = false;
              update_opp.CTA_Pursue_Approved__c = false;
              update_opp.CTA_Pursue_Request_Exists__c = false;
             
              update_opp.OwnerId = UserInfo.getUserId();
              if(update_opp.CloseDate < Date.Today() || update_opp.CloseDate == null) {
                update_opp.CloseDate = Date.Today().addDays(30);
              }

             Update update_opp;
 
          
         } catch (Exception e){
             // roll everything back in case of error
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return null;
        }
         //Added by neha mehta for INC1659920-REQ2459600 Start
         if(theme.equals(settings.Theme__c)){
            return new PageReference('/lightning/r/Opportunity/'+newop.id+'/edit?navigationLocation=DETAIL&backgroundContext=/lightning/r/Opportunity/'+newop.id+'/view');
        }
        else {
            return new PageReference('/'+newop.id+'/e?retURL=%2F'+newop.id);
        }
        //Added by neha mehta for INC1659920-REQ2459600 End
        //return new PageReference('/'+newop.id+'/e?retURL=%2F'+newop.id);
        //return new PageReference('/'+newop.id);
    } 
}