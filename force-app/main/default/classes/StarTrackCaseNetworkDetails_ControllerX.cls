/**
 ** Description: Controller for StarTrackCaseNetworkDetails page
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: OCT.9.2015
 ** History:--------------------------------------------
 **         OCT.9.2015 David Catindoy - Created
 **/
public class StarTrackCaseNetworkDetails_ControllerX {
    
    public Case caseRecord {get; set;}
    public Article__c con {get; set;}
    public Map<Id, Set<Id>> depotMap {get; set;}
    public Boolean manyReturnedDepot {get; set;}
    public String selectedDepot {get; set;}
    public Boolean noReturnedDepot {get; set;}
    public String errorMessage {get; set;}
    
    public StarTrackCaseNetworkDetails_ControllerX(ApexPages.StandardController controller) {
        if(!Test.isRunningTest()){
            controller.addFields(new List<String>{'Id', 'Network__c', 'ArticleTest__c'});
        }
        caseRecord = (Case) controller.getRecord();
        selectedDepot = '';  
        errorMessage = StarTrack_Error_Messages__c.getValues('Depot Not Found').Value__c;
        manyReturnedDepot = false;
        noReturnedDepot = false;
        depotMap = new Map<Id, Set<Id>>();
        if(caseRecord.ArticleTest__c != null){
            con = [ SELECT Id, Receiver_Suburb__c, Network__c,
                ReceiverPostcode__c, Service_Type__c
                FROM Article__c
                WHERE Id = :caseRecord.ArticleTest__c
                LIMIT 1];
        }
        if(caseRecord.Network__c == null){
            noReturnedDepot = true;
        }
        if(caseRecord.ArticleTest__c != null && caseRecord.Network__c == null){
            depotMap = StarTrackUtil.queryPostCodeMapping(new List<Article__c>{con}, new List<Case>());
            if(depotMap.containsKey(con.Id)){
                if(depotMap.get(con.Id).size() > 1){
                    manyReturnedDepot = true;
                    noReturnedDepot = false;
                }
            }
        }
    }
    
     public List<SelectOption> getDepotValues() {
        Set<Id> ids = depotMap.get(con.Id);
        List<SelectOption> options = new List<SelectOption>();
        List<Network__c> listOfDepot = [SELECT Id, Name
                                        FROM Network__c
                                        WHERE Id IN :ids];
                                        
        options.add(new SelectOption('', '--None--'));
        for(Network__c depot : listOfDepot){
            options.add(new SelectOption(depot.Id, depot.Name));
        }
        return options;
    }
    
    public PageReference saveDepot(){
        con.Network__c = selectedDepot;
        con.Update_Related_Cases__c = true;
        try{
            System.debug(con);
            update con;
            System.debug(con);
        } catch(DMLException e){
            System.debug(e.getMessage());
        }
        
        
        PageReference redirectPage = Page.StarTrackCaseNetworkDetails;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('Id', caseRecord.Id);
        return redirectPage;
    }

}