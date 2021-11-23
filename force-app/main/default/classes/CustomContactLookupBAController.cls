/*
Custom Search Function, created by BlueWolf.
Utilised by visualforce page 'CustomContactLookupBA'

Updated 28/5/2015 - Clinton McIntyre - Added "with sharing" as part of security audit
Updated 19/07/16 - Nathan Main - Added Account.Name and Account.Id to SOSL query.
*/


global with sharing class CustomContactLookupBAController {
  public List<Contact> contact_results{get;set;} // search results
  public List<Account> account_results{get;set;} // search results
  public List<Lead> lead_results{get;set;} // search results
  public string searchString{get;set;} // search keyword
  public static string ixnId {get;set;} // interaction id
  public string inServiceCloudConsole {get;set;}     
  
  public CustomContactLookupBAController() {
    // get the current search string
    searchString = System.currentPageReference().getParameters().get('lksrch');
    ixnId = System.currentPageReference().getParameters().get('ixnId');
    inServiceCloudConsole = System.currentPageReference().getParameters().get('inServiceCloudConsole');
    system.debug('*** CustomContactLookupBAController ixnId ' + ixnId);
    system.debug('*** CustomContactLookupBAController inServiceCloudConsole '+inServiceCloudConsole);
    system.debug('*** CustomContactLookupBAController search for '+searchString);      
      
    if(searchString != '' && searchString != null) 
        runSearch();  
  }
    
    public void checkForStrays(){
        system.debug('*** checkForStrays');
        if(inServiceCloudConsole == 'false')
        {    
            String myId = UserInfo.getUserId();
            myId = 'GenesysConnector' + myId;
            try{
                List <WorkspaceConnectorInfo__c> connectors = [SELECT objectId__c, interactionId__c From WorkspaceConnectorInfo__c WHERE genesysId__c = :myId];
                Integer listSize = connectors.size();
                if(listSize > 1)
                {
                    system.debug('*** checkForStrays ERROR found multiple connectors - ' + listSize);
                    delete connectors; 
                }
            }
            catch(QueryException e){
                system.debug('*** checkForStrays - no WorkspaceConnectorInfo__c');
            }    
        }
        else
        {
                system.debug('*** checkForStrays not needed inServiceCloudConsole');
        }
    }    
    
  @RemoteAction
  global static string setWorkspaceConnectorInfo(String objectId, String interactionId)
  {
      system.debug('*** setWorkspaceConnectorInfo objectId = '+objectId+' ,interactionId = '+interactionId);
      try{
        //create new object
        String myId = UserInfo.getUserId();
        myId = 'GenesysConnector' + myId;

        WorkspaceConnectorInfo__c myCustomObject = new WorkspaceConnectorInfo__c (
            name = 'GenesysConnector', interactionId__c = interactionId, objectId__c = objectId,genesysId__c = myId);
        //update/insert myCustomObject; 
        upsert myCustomObject genesysId__c;
        system.debug('*** myCustomObject = ' + myCustomObject );
        String urlForDetailPage = new PageReference('/' + myCustomObject.id).getUrl();
        system.debug('*** url = '+ urlForDetailPage );
        return 'success';
      }
      catch(QueryException e){
            return 'error';
      }
  }
   
  // performs the keyword search
  global PageReference search() {
    system.debug('*** search');
    runSearch();
    return null;
  }
    
  
  // prepare the query and issue the search command
  private void runSearch() {
    system.debug('*** runSearch');
    performSearch(searchString);         
  } 
  
  
    // run the search and save the records found. 
  private void performSearch(string searchString) {
    system.debug('*** performSearch for '+searchString);
    /*
    String soql = 'select id, name from contact';
    if(searchString != '' && searchString != null)
      //soql = soql +  ' where name LIKE \'%' + searchString +'%\'';
      soql = soql +  ' where phone LIKE \'%' + searchString +'%\'';      
    soql = soql + ' limit 25';
    System.debug(soql);
    return database.query(soql);
    */

    //NM 19/07/16 - Added Account.Name and Account.Id to SOSL query.
    //List<List<SObject>> objs = [FIND :searchString IN PHONE FIELDS RETURNING Contact(id,name),Account(id,name)];
    List<List<SObject>> objs = [FIND :searchString IN PHONE FIELDS RETURNING Contact(id,name, Account.Name, Account.Id)];
    Integer listSize = objs.size();
    system.debug('*** objs.size = ' + listSize);
    List<Contact> contacts = null;
    if (!objs.isEmpty()){
             contact_results= ((List<Contact>)objs[0]);
    }
    system.debug('*** contact_results= ' + contact_results);


    objs = [FIND :searchString IN PHONE FIELDS RETURNING Account(id,name)];
    listSize = objs .size();
    system.debug('*** account listSize = ' + listSize);
    List<Account> accounts = null;
    if (!objs.isEmpty()){
             account_results= ((List<Account>)objs[0]);
    }
    system.debug('*** contact_results= ' + contact_results);  
    
    objs = [FIND :searchString IN PHONE FIELDS RETURNING Lead(id,name)];
    listSize = objs.size();
    system.debug('*** lead listSize = ' + listSize);
    List<Lead> leads = null;
    if (!objs.isEmpty()){
             lead_results= ((List<Lead>)objs[0]);
    }
    system.debug('*** lead_results= ' + lead_results);      
 
  }
  
  
  // used by the visualforce page to send the link to the right dom element
  public string getFormTag() {
    return System.currentPageReference().getParameters().get('frm');
  }
    
  // used by the visualforce page to send the link to the right dom element for the text box
  public string getTextBox() {
    return System.currentPageReference().getParameters().get('txt');
  }


}