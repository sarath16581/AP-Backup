/**
* Controller for the QueueManagement page
* @author LMancilla
* Bluewolf
* September 22 2014
//28.10.2015    paul.stamer@auspost.com.au INC0628513 return the queues not public groups
**/
public with sharing class QueueManagementController{
    public String               criteriaSelectedValue   {get;set;}
    public List<String>         selectedLeftValue       {get;set;}
    public List<String>         selectedRightValue      {get;set;}
    public String               searchText              {get;set;}
    public List<SelectOption>   leftSelectOptions       {get;set;}
    public List<SelectOption>   rightSelectOptions      {get;set;}
    public String               selectedSearchResult    {get;set;}
    public List<SelectOption>   searchResults           {get;set;}
    public Boolean              showLimitWarning        {get;set;}

    private static String DYN_QUERY                     ='SELECT ID, Name FROM ';
    //to avoid hitting collection limit
    private static String ORDER_BY_CLAUSE               =' ORDER BY Name ASC LIMIT 1000';

    public QM__c agentprofile;

    /**
    * Default Constructor
    **/
    public QueueManagementController(){
        criteriaSelectedValue = 'User';
        showLimitWarning = false;
        agentprofile = QM__c.getInstance();
    }


    /**
    * Retrieves the list of available users/queues
    */
    public void queryNames(){
        showLimitWarning = false;
        String tmpQuery='';

        if(searchText!=null){
            if(criteriaSelectedValue=='User')
                tmpQuery =DYN_QUERY+' User WHERE IsActive=true AND Profile.Name =: agentProf AND Name LIKE \'%'+searchText+'%\''+ORDER_BY_CLAUSE;
            else
                    if(criteriaSelectedValue=='Queue')
                        //tmpQuery=DYN_QUERY+' Group WHERE Name LIKE \'%SSSW%\''+ORDER_BY_CLAUSE; //Paul Stamer INC0628513
                        tmpQuery=DYN_QUERY+' Group WHERE Type = \'Queue\' AND Name LIKE \'%SSSW%\''+ORDER_BY_CLAUSE; //Paul Stamer INC0628513

            searchResults=new List<SelectOption>();
            searchResults=populateListData(tmpQuery,'Name');
            if(searchResults.size()>0){
                selectedSearchResult=searchResults[0].getValue();
                fillLists();
            }
        }
    }

    /**
    * If QUEUE retrieve all users that have SSSW profile; Else Retieve all SSSW queues the user is a not a member of
    **/
    private void queryLeftValues(){
        List<sObject> queryResult;
        String tmpQuery='';

        if(selectedSearchResult!=null){
            if(criteriaSelectedValue=='Queue')
                tmpQuery=DYN_QUERY+' User WHERE IsActive=true AND Profile.Name =: agentProf  AND Name LIKE \'%'+searchText+'%\' AND ID NOT IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.Type = \'Queue\' and GroupId = \''+selectedSearchResult+'\')'+ORDER_BY_CLAUSE;
            else
                    if(criteriaSelectedValue=='User')
                        tmpQuery=DYN_QUERY+' Group WHERE Name LIKE \'%SSSW%\' AND ID NOT IN (SELECT GroupId FROM GroupMember WHERE Group.Type = \'Queue\' AND UserOrGroupId=\''+selectedSearchResult+'\')'+ORDER_BY_CLAUSE;

            leftSelectOptions=new List<SelectOption>();
            Schema.sObjectField field=criteriaSelectedValue=='Queue'? Schema.GroupMember.UserOrGroupId:Schema.Group.Name;
            leftSelectOptions=populateListData(tmpQuery,'Name');
            System.debug('@QueueManagementController queryLeftValues leftSelectOptions: ' + leftSelectOptions);
        }
    }
    /**
    * If QUEUE retrieve all users that have SSSW profile; Else Retieve all SSSW queues the user is  a member of
    **/
    private void queryRightValues(){

        String tmpQuery='';

        if(selectedSearchResult!=null){
            if(criteriaSelectedValue=='Queue')
                tmpQuery=DYN_QUERY+' User WHERE IsActive=true AND Profile.Name =: agentProf  AND ID IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.Type = \'Queue\' and GroupId = \''+selectedSearchResult+'\')'+ORDER_BY_CLAUSE;
            else
                    if(criteriaSelectedValue=='User')
                        tmpQuery=DYN_QUERY+' Group WHERE Name LIKE \'%SSSW%\' AND ID IN (SELECT GroupId FROM GroupMember WHERE Group.Type = \'Queue\' AND UserOrGroupId=\''+selectedSearchResult+'\')'+ORDER_BY_CLAUSE;

            rightSelectOptions=new List<SelectOption>();
            rightSelectOptions=populateListData(tmpQuery,'Name');
            System.debug('@QueueManagementController queryRightValues rightSelectOptions: ' + rightSelectOptions);
        }
    }

    /**
    * Populates the left and right select lists
    */
    public void fillLists(){
        queryLeftValues();
        queryRightValues();
    }

    /**
    * Queries the DB and retrieves the values for the left and right select lists
    * @param query The query to execute
    * @param additionalFieldToGet Retrieves this field dynamically and assigns it to the select option label
    * @return List<SelectOption> - The list of values for the picklists
    **/
    private List<SelectOption> populateListData(String query, String additionalFieldToGet){
        String agentProf = agentprofile.Profile__c;
        System.debug('** query ==>'+ query);
        List<sObject> queryResult=Database.query(query);
        //Query limits to 1000 so if the size is 1000, it means not all results are returned. Warning is issued to user.
        if(queryResult.size()==1000){
            showLimitWarning = true;
        }
        List<SelectOption> listData=new List<SelectOption> ();

        for(sObject so:queryResult){
            listData.add(new SelectOption((String)so.get('ID'),(String)so.get(additionalFieldToGet)));
        }

        return listData;
    }

    /**
    * Re-initialize variables and clear data
    **/
    public PageReference clearAllData(){
        rightSelectOptions=new List<SelectOption>();
        leftSelectOptions=new List<SelectOption>();
        searchResults=new List<SelectOption>();
        showLimitWarning = false;
        if(criteriaSelectedValue=='Queue') queryNames();

        return null;
    }

    /**
    * Moves items form the left list to the right list (Assign)
    **/
    public void addItems(){
        SelectOption copySO=null;
        Integer j=leftSelectOptions.size();

        for(String value:selectedLeftValue ){
            for(Integer i=0;i<leftSelectOptions.size();i++){
                if(value==leftSelectOptions.get(i).getValue()){
                    copySO=leftSelectOptions.get(i);
                    leftSelectOptions.remove(i);
                    rightSelectOptions.add(copySO);
                    --j;
                }
            }
        }
    }

    /**
    * Moves items form the right list to the left list (Renove)
    **/
    public void removeItems(){
        SelectOption copySO=null;
        Integer j=leftSelectOptions.size();

        for(String value:selectedRightValue ){
            for(Integer i=0;i<rightSelectOptions.size();i++){
                if(value==rightSelectOptions.get(i).getValue()){
                    copySO=rightSelectOptions.get(i);
                    rightSelectOptions.remove(i);
                    leftSelectOptions.add(copySO);
                    --j;
                }
            }
        }

    }

    /**
    * Returns the list of items to insert/delete. Compares the left list and the right list and determines
    * which records should be created or deleted
    * @param ids The list of recird IDs to evaluate (groups or users)
    * @param mode Working mode (i.e. Insert, Delete)
    * @return List<GroupMember> The list of records to insert/delete
    **/
    private List<GroupMember> getItemsToChange(Set<ID> ids, String mode){
        boolean found=false;
        List<GroupMember> ans=new List<GroupMember>();
        List<GroupMember> existingItems= new List<GroupMember> ();
        ID idToSearch=null;

        if(criteriaSelectedValue=='Queue'){
            existingItems=[SELECT ID,UserOrGroupId,GroupId FROM GroupMember WHERE GroupId=:selectedSearchResult AND UserOrGroupId IN: ids];
        }
        else{
            existingItems=[SELECT ID,UserOrGroupId,GroupId FROM GroupMember WHERE UserOrGroupId =:selectedSearchResult AND GroupId IN: ids];
        }

        for(GroupMember gm:existingItems){

            idToSearch=criteriaSelectedValue=='Queue'?gm.UserOrGroupId:gm.GroupId;
            if(ids.contains(idToSearch)){
                found=true;
            }

            if(found&&mode=='Delete'){
                ans.add(gm);
                found=false;
            }
            else{
                if(!found&&mode=='Insert'){
                    found=false;
                    if(criteriaSelectedValue=='Queue'){
                        ans.add(new GroupMember(GroupId=selectedSearchResult,UserOrGroupId=idToSearch));
                    }
                    else{
                        ans.add(new GroupMember(GroupId=idToSearch,UserOrGroupId=selectedSearchResult));
                    }
                }
            }
        }
        if(mode=='Insert'&&ans.size()==0){
            for(SelectOption val:rightSelectOptions){
                if(criteriaSelectedValue=='Queue'){
                    ans.add(new GroupMember(GroupId=selectedSearchResult,UserOrGroupId=val.getValue()));
                }
                else{
                    ans.add(new GroupMember(GroupId=val.getValue(),UserOrGroupId=selectedSearchResult));
                }
            }
        }

        return ans;
    }


    /**
    * Saves the changes to the user memberships
    **/
    public void save(){
        SavePoint sp=Database.setSavePoint();

        List<GroupMember> existing=new List<GroupMember>();
        List<GroupMember> newItems=new List<GroupMember>();
        List<GroupMember> deleteItems=new List<GroupMember>();
        boolean found=false;
        Set<ID> idList=new Set<ID>();

        try{
            if(leftSelectOptions!=null) {
                for(SelectOption val:leftSelectOptions) idList.add(val.getValue());
                deleteItems=getItemsToChange(idList,'Delete');
            }

            idList=new Set<ID>();

            if(rightSelectOptions!=null){
                for(SelectOption val:rightSelectOptions) idList.add(val.getValue());
                newItems=getItemsToChange(idList,'Insert');
            }

            if(newItems.size()>0||deleteItems.size()>0){
                insert newItems;
                delete deleteItems;
                fillLists();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Changes Saved'));
            }
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'An error has ocurred: '+e));
            Database.rollBack(sp);
            System.debug(LoggingLevel.ERROR,'QueManagementController: '+e);
        }
    }

}