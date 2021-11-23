public with sharing class SideBarSocialPostsCtr {


    public String PostFilterId {get; set;}
    public Map<Id,String> caseNumberMap {get; set;}
    public static Integer DEFAULT_LIST_SIZE = 10;
    public Integer pageSize {get; set;}
    public Integer noOfRecords{get; set;}
    public String error{get; set;}

    public String socPostFilterId {get;set;}
    public List<MetadataService.ListView> listViews = null;
    public List<SelectOption> listViewOptions = null;
    public Map<String,Schema.DisplayType> fieldTypeMap = null;


    public ApexPages.StandardSetController PostSetCtr {
        get{
            if(PostSetCtr == null){
                pageSize = DEFAULT_LIST_SIZE;

                readListViews();
                buildListViewOptionsList();
                String queryFilter = getQueryFilter(socPostFilterId);

                System.debug('\n\n getQueryFilter :\n'+queryFilter);

                String baseQuery =  '   SELECT Name, MessageType,Content,Handle, Posted, ParentId, Parent.Name, '+
                                    '       Provider, ReviewedStatus, AttachmentType, AttachmentUrl, '+
                                    '       PersonaId, TopicProfileName, IsOutbound  '+
                                    '   FROM SocialPost '+
                                        queryFilter+
                                    '   ORDER BY Posted DESC' + 
                                    '   LIMIT 10000';

                PostSetCtr = new ApexPages.StandardSetController(Database.getQueryLocator(baseQuery));
                PostSetCtr.setPageSize(pageSize);
                noOfRecords = PostSetCtr.getResultSize();
            }
            return PostSetCtr;
        }set;
    }

    public SideBarSocialPostsCtr(){}
    public SideBarSocialPostsCtr(ApexPages.StandardSetController c) {   }

    public List<SocialPost> getSocialPosts(){

        List<SocialPost> lp = (List<SocialPost>)PostSetCtr.getRecords();
        populateCaseNumberMap(lp);
        return lp;
    }


    private void populateCaseNumberMap(List<SocialPost> posts ){
        List<Id> lSt = new List<Id>();
        caseNumberMap = new Map<Id,String>();
        for(SocialPost post : posts){
            lSt.add(post.ParentId);
        }
        for(Case c : [Select Id, CaseNumber from Case where id in:lSt]){
            caseNumberMap.put(c.Id,c.CaseNumber);
        }
    }

    /**
    * Reset List View
    */
    public PageReference resetFilter(){
        PostSetCtr = null;
        PostSetCtr.setPageNumber(1);
        return null;
    }

    public PageReference createCases(){

        map<String,SocialPost> mPosts = new map<String,SocialPost>();
        list<SocialPost> lstToCreate = new list<SocialPost>();
        list<Id> lstPersona = new list<Id>();
        list<SocialPost> posts = getSocialPosts();
        String selectedPosts = Apexpages.currentPage().getParameters().get('selectedPosts');

        // Populate map with social posts
        for(SocialPost post : posts){
            mPosts.put(post.id,post);
        }

        // Get social posts without parent case and add to list
        for(String postId : selectedPosts.split(',')){

            if(mPosts.get(postId).ParentId == null){
                lstToCreate.add(mPosts.get(postId));
                lstPersona.add(mPosts.get(postId).PersonaId);
            }
        }

        createNewCases(lstToCreate,lstPersona);
        return null;
    }

    private void createNewCases(list<SocialPost> posts, list<Id> personaIds){

        list<Case> newCases = new list<Case>();
        map<String,Case> mCases = new map<String,Case>();
        Integer error = 0;

        //Get map of Social Personas so we can use them for case contact or case account
        Map<Id,SocialPersona> mPersona = new Map<Id,SocialPersona>([Select Id, ParentId from SocialPersona where Id in: personaIds]);

        // Create case and add to list
        for(SocialPost post : posts){
            Case newCase = new Case();
            newCase.Subject = post.Name;
            newCase.Origin = post.Provider;

            SocialPersona persona = new SocialPersona();

            if(post.PersonaId != null ){
                persona = mPersona.get(post.PersonaId);
            }else{

                String personaName = '';

                if(String.isNotBlank(post.TopicProfileName) ){
                    personaName = post.TopicProfileName.replace('@','');

                    //assuming that for each provider the name is unique
                    list<SocialPersona> lSp = [select id, ParentId from SocialPersona where name =:personaName and provider =: post.provider ];

                    if (!lSp.isEmpty())
                        persona = lSp[0];

                }else{
                    error = 1;
                }
           }

            if(error == 0){
                if(String.isNotBlank(persona.ParentId)){
                   if (persona.ParentId.getSObjectType() == Contact.sObjectType) {
                        newCase.ContactId = persona.ParentId;
                    }else if (persona.ParentId.getSObjectType() == Account.sObjectType) {
                        newCase.AccountId = persona.ParentId;
                    }

                    newCases.add(newCase);
                    mCases.put(post.Id,newCase);
               }else{
                   error = 1;
               }
            }

        }

        if(error == 0){
            insert newCases;

            // Update posts with new case data
            for(SocialPost post : posts){
                if(mCases.get(post.Id) != null){
                    post.ParentId = mCases.get(post.Id).Id;
                    // this field does not exist yet so we created a custom one
                    post.ReviewedStatus = 'Escalate';
                }else{
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Social Person could not be found, please try later.'));
               }
            }

            update posts;
            refresh();
        }else{
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Social Person could not be found, please try later.'));
       }
    }


    public PageReference ignorePosts(){

        map<String,SocialPost> mPosts = new map<String,SocialPost>();
        list<SocialPost> posts = getSocialPosts();
        list<SocialPost> lstPosts = new list<SocialPost>();
        String selectedPosts = Apexpages.currentPage().getParameters().get('selectedPosts');

        // Populate map with social posts
        for(SocialPost post : posts){
            mPosts.put(post.id,post);
        }

        // Get social posts, update and add to list
        for(String postId : selectedPosts.split(',')){
            SocialPost post = mPosts.get(postId);
            post.ReviewedStatus = 'Ignore';
            lstPosts.add(post);
        }

        update lstPosts;

        refresh();
        return null;
    }


    public PageReference removeCaseParent(){

        map<String,SocialPost> mPosts = new map<String,SocialPost>();
        list<SocialPost> posts = getSocialPosts();
        list<SocialPost> lstPosts = new list<SocialPost>();
        String selectedPosts = Apexpages.currentPage().getParameters().get('selectedPosts');

        // Populate map with social posts
        for(SocialPost post : posts){
            mPosts.put(post.id,post);
        }

        // Get social posts, update and add to list
        for(String postId : selectedPosts.split(',')){
            SocialPost post = mPosts.get(postId);
            post.ParentId = null;
            lstPosts.add(post);
        }

        update lstPosts;

        refresh();
        return null;
    }

    public PageReference updateCaseAssignment(){

        map<String,SocialPost> mPosts = new map<String,SocialPost>();
        String selectedPosts = Apexpages.currentPage().getParameters().get('selectedPosts');
        String cId = Apexpages.currentPage().getParameters().get('caseId');

        if (String.isNotBlank(cId)&& String.isNotBlank(selectedPosts)   ){
            list<SocialPost> posts = getSocialPosts();
            list<SocialPost> lstPosts = new list<SocialPost>();

            if (cId != '-1'){
            list<Case> cL = [Select Id from Case where id =:cId];
            if (!cL.isEmpty() )
                cId = cL[0].Id;
            }else{
                cId = null;
            }

            // Populate map with social posts
            for(SocialPost post : posts){
                mPosts.put(post.id,post);
            }

            // Get social posts, update and add to list
            for(String postId : selectedPosts.split(',')){
                SocialPost post = mPosts.get(postId);
                system.debug('\n=== update case on post: '+post+'\n cId :'+cId);
                post.ParentId = cId;
                lstPosts.add(post);
            }
            update lstPosts;
        }
        refresh();
        return null;
    }

    /*  list methods  */

    public Boolean hasNext {
        get {
            return PostSetCtr.getHasNext();
        }
        set;
    }
    public Boolean hasPrevious {
        get {
            return PostSetCtr.getHasPrevious();
        }
        set;
    }

    public Integer pageNumber {
        get {
            return PostSetCtr.getPageNumber();
        }
        set;
    }


    //Navigate to Prev Page
    public void prev(){
        if(PostSetCtr.getHasPrevious())
            PostSetCtr.previous();
    }

    public void first() {
        PostSetCtr.first();
    }

    public void last() {
        PostSetCtr.last();
    }

    public void previous() {
        if(PostSetCtr.getHasPrevious())
            PostSetCtr.previous();
    }

    public void next() {
        if (PostSetCtr.getHasNext())
            PostSetCtr.next();
    }

     public pageReference refresh() {
        Integer num = PostSetCtr.getPageNumber();
        PostSetCtr = null;
        getSocialPosts();
        PostSetCtr.setPageNumber(num);
        return null;
    }

     public pageReference reload() {

        PostSetCtr = null;
        getSocialPosts();
        PostSetCtr.setPageNumber(1);
        return null;
    }

    /* list views metadata*/
    /**
    * Get the standard Social Post List Views options
    *
    * @return SelectOption[] of List Views
    */
    public SelectOption[] getListViewOptions() {
        return listViewOptions;
    }

   /**
     * read the SocialPost custom object to read the listview metadata
     * only do this ones duuring its livecycle
     **/
    public void readListViews() {
        if(!System.Test.isRunningTest()) {
            if (this.listViews==null) {
                MetadataService.MetadataPort service = createService();
                this.listViews =
                            ((MetadataService.CustomObject) service.readMetadata('CustomObject',
                                new String[] { 'SocialPost' }).getRecords()[0]).listViews;



            }
        }else{

            this.listViews = new List<MetadataService.ListView>();
            system.debug('\n\n====== SideBarSocialPostsCtr_Test.test_listView :\n'+SideBarSocialPostsCtr_Test.test_listView);
            this.listViews.add(SideBarSocialPostsCtr_Test.test_listView);

        }
    }

    /**
     * Get All non private listViews and sort them by label and not API fullName
     */
    public void buildListViewOptionsList() {
        if (listViewOptions==null) {
            List<SelectOption> tmplistViewOptions = new List<SelectOption>();
            listViewOptions = new List<SelectOption>();

            // Cannot execute Websrv callout on Test classes
            if(System.Test.isRunningTest()) {
                listViewOptions.add( SideBarSocialPostsCtr_Test.test_SelectOption);
            }else {

                if (this.listViews != null){
                    for(MetadataService.ListView listView : this.listViews) {
                        tmplistViewOptions.add(new SelectOption(listView.fullName, listView.label));
                    }

                    Map<String, Selectoption> mapping = new Map<String, Selectoption>();
                    // Suffix to avoid duplicate values like same labels or values are in inbound list
                    Integer suffix = 1;
                    for (Selectoption opt : tmplistViewOptions) {
                            mapping.put((opt.getLabel().toLowerCase() + suffix++), opt);
                    }

                    List<String> sortKeys = new List<String>();
                    sortKeys.addAll(mapping.keySet());
                    sortKeys.sort();
                    // clear the original collection to rebuilt it

                    for (String key : sortKeys) {
                        listViewOptions.add(mapping.get(key));
                    }
                }
            }
            if (!listViewOptions.isEmpty())
                this.socPostFilterId = listViewOptions[0].getValue();
        }
    }


    private Map<String, list<Schema.sObjectType>> getSocialPostLookUpInfo(){


    Map<String, list<Schema.sObjectType>> userLkUp  = new Map<String, list<Schema.sObjectType>>();
    Schema.DescribeSObjectResult r = Lead.sObjectType.getDescribe();
    Map<String,Schema.SObjectField> M = r.fields.getMap();

    for(String s : M.keySet ()){
      Schema.SObjectField so  = M.get(s);
      if (String.isNotBlank(so.getDescribe().getRelationshipName())){
        Set<Schema.sObjectType> st = new Set<Schema.sObjectType>();
        st.addAll(so.getDescribe().getReferenceTo());
        if (st.contains(Schema.sObjectType.User.getSobjectType() ))
          userLkUp.put(so.getDescribe().getRelationshipName(),so.getDescribe().getReferenceTo());
      }
    }

    return userLkUp;

  }



    /**
     * Read the the selected listview filter parameters and create a where clause of it
     * @param listViewFullName String
     * @return String query filter (where clause)
     **/
    public String getQueryFilter(String listViewFullName) {
        String timeStamp='';
        String queryFilter = '';
        String operator = '';
        Integer cnt=1;
        Schema.DisplayType fType;
        String value = '';
        String fieldName;
        String filterLogic = '';
        Integer filterCnt;
        String[] valuesTmp;
        Integer valCnt;
        Boolean multi;
        Integer nullCnt=1;
        List<String> qTokens = new List<String>();
        Map<String, list<Schema.sObjectType>> userLookUps = getSocialPostLookUpInfo();

        if(System.Test.isRunningTest()) {
            listViewFullName = SideBarSocialPostsCtr_Test.listViewFullName;
        }

        if (this.listViews != null && !this.listViews.isEmpty() && String.isNotBlank(listViewFullName)){

            for(MetadataService.ListView listView : this.listViews) {
                if (listView.fullName==listViewFullName) {//
                    if (listView.filters!=null) {
                        System.debug('ListView :'+listView+'\n listView.booleanFilter :'+listView.booleanFilter);

                        filterLogic = listView.booleanFilter;   //1 OR 2
                        filterCnt = listView.filters.size();

                        if (filterLogic==null) {
                            filterLogic = '';
                            for (Integer x=1; x<=filterCnt; x++) {
                                if (x> 1)
                                    filterLogic =   filterLogic +' AND ';

                                filterLogic = filterLogic + ' ZZZxxQxxZZZ'+x+ ' ';
                                system.debug('\n\n======filterLogic['+x+'] filterLogic: '+filterLogic);
                            }
                        }else{
                          system.debug('\n\n======filterLogic[0] filterLogic: '+filterLogic);


                            for (Integer x=1; x<=filterCnt; x++) {
                                filterLogic = filterLogic.replace(''+x, 'ZZZxxQxxZZZ'+x);
                                system.debug('\n\n======filterLogic['+x+'] filterLogic: '+filterLogic);
                            }
                        }


                        system.debug('\n\n======ZZZxxQxxZZZ ['+filterCnt+']: '+filterLogic);
                        for (MetadataService.ListViewFilter lvf: listView.filters) {

                            system.debug('\n\n======lvf: \n'+lvf);

                            //prepare value depending on the
                            fType = getFieldType(lvf.field);
                            if (fType==null) {
                                fType = getFieldType(lvf.field+'Id');
                            }

                            //Parse multiple values
                            queryFilter = '(';
                            valCnt = 0;

                            if(lvf.value != null){
                                valuesTmp = lvf.value.split(',');
                            }else{
                                valuesTmp = new List<String>{'XNXUXLXL'+nullCnt};
                            }

                             system.debug('\n\n======valuesTmp: \n'+valuesTmp);
                           if (valuesTmp != null )
                            for (String val : valuesTmp) {


                                if (valCnt>0) {
                                  if(lvf.operation=='notEqual'){
                                    queryFilter += ' AND ';
                                  }else{
                                      queryFilter += ' OR ';
                                  }
                                }
                                //Parse Operator
                                if (lvf.operation=='equals') {
                                    operator = ' = ';

                                    if (fType == Schema.DisplayType.Boolean) {
                                        value = String.valueOf('1'==val);
                                    } else if (fType == Schema.DisplayType.Integer) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Double) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Picklist) {
                                      if(val.length()<=2){
                                        value = isPicklist(val, lvf.field);
                                      } else {
                                        value = '\''+val+'\'';
                                      }
                                    } else if (fType == Schema.DisplayType.Datetime) {
                                      if(val.contains(' ')){
                                        queryFilter += '(';
                                        operator = ' > ';
                                        fieldName = lvf.field;
                                      }
                                        value = dateTimeValuetoString(val,timeStamp, lvf.operation, fieldName);
                                    } else {

                                        System.debug('>>>>> valor equals ' + val);

                                        value = '\''+val+'\'';
                                    }

                                } else if(lvf.operation=='notEqual') {
                                    operator = ' != ';
                                    if (fType == Schema.DisplayType.Boolean) {
                                        value = String.valueOf('1'==val);
                                    } else if (fType == Schema.DisplayType.Integer) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Double) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Picklist) {
                                      if(val.length()<=2){
                                        value = isPicklist(val, lvf.field);
                                      } else {
                                        value = '\''+val+'\'';
                                      }
                                    } else if (fType == Schema.DisplayType.Datetime) {
                                        if(val.contains(' ')){
                                          queryFilter += '(';
                                        operator = ' > ';
                                        fieldName = lvf.field;
                                      }
                                        value = dateTimeValuetoString(val,timeStamp, lvf.operation, fieldName);
                                    } else {
                                        value = '\''+val+'\'';
                                    }

                                } else if(lvf.operation=='startsWith') {
                                    operator = ' LIKE ';
                                    value = '\''+val+'%\'';
                                } else if(lvf.operation=='contains') {
                                    operator = ' LIKE ';
                                    value = '\'%'+val+'%\'';
                                } else if(lvf.operation=='notContain') {
                                    //IBO: fix for notContain (NOT Field LIKE 'value')
                                    if (fType == Schema.DisplayType.Reference) {
                                        if (userLookUps.containsKey(lvf.field)){
                                            queryFilter += ' NOT ' +lvf.field+'.Alias';
                                        }else{
                                            queryFilter += ' NOT ' +lvf.field+'.Name';
                                        }
                                        operator = ' LIKE ';
                                        value = '\'%'+val+'%\'';
                                        }else{
                                          queryFilter += ' NOT ' +lvf.field;
                                          operator = ' LIKE ';
                                          value = '\'%'+val+'%\'';
                                        }
                                    //operator = ' NOT LIKE ';
                                    //value = '\'%'+val+'%\'';
                                } else if(lvf.operation=='lessThan') {
                                    operator = ' < ';
                                    if (fType == Schema.DisplayType.Integer) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Double) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Datetime) {
                                        value = dateTimeValuetoString(val,timeStamp, lvf.operation,fieldName);
                                    } else {
                                        value = '\''+val+'\'';
                                    }
                                } else if(lvf.operation=='greaterThan') {
                                    operator = ' > ';
                                    if (fType == Schema.DisplayType.Integer) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Double) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Datetime) {
                                        timeStamp = 'T23:59:59.000Z';
                                        value = dateTimeValuetoString(val,timeStamp, lvf.operation,fieldName);
                                    } else {
                                        value = '\''+val+'\'';
                                    }
                                } else if(lvf.operation=='lessOrEqual') {
                                    operator = ' <= ';
                                    if (fType == Schema.DisplayType.Integer) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Double) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Datetime) {
                                        value = dateTimeValuetoString(val,timeStamp, lvf.operation,fieldName);
                                    } else {
                                        value = '\''+val+'\'';
                                    }
                                } else if(lvf.operation=='greaterOrEqual') {
                                    operator = ' >= ';
                                    if (fType == Schema.DisplayType.Integer) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Double) {
                                        value = val;
                                    } else if (fType == Schema.DisplayType.Datetime) {
                                        value = dateTimeValuetoString(val,timeStamp, lvf.operation,fieldName);
                                    } else {
                                        value = '\''+val+'\'';
                                    }
                                } else if(lvf.operation=='includes') {
                                    //only multipicklist
                                    operator = ' IN ';
                                    value = '(';
                                    multi = false;
                                    for (String valmp : valuesTmp) {
                                        if (multi) {
                                            value += ' ,';
                                        }
                                        multi = true;
                                        value += '\''+valmp+'\'';
                                    }
                                    value += ')';
                                } else if(lvf.operation=='excludes') {
                                    //only multipicklist
                                    operator = ' NOT IN ';
                                    value = '(';
                                    multi = false;
                                    for (String valmp : valuesTmp) {
                                        if (multi) {
                                            value += ' ,';
                                        }
                                        multi = true;
                                        value += '\''+valmp+'\'';
                                    }
                                    value += ')';
                                } else {
                                    operator = '';
                                    value = '';
                                }

                                if (operator!='') {
                                    if (fType == Schema.DisplayType.Reference) {
                                      //IBO: fix for notContain (NOT Field LIKE 'value')

                                      if(lvf.operation=='notContain') {
                                        System.debug('************ notContain');
                                      } else {
                                      if (userLookUps.containsKey(lvf.field)){
                                            queryFilter +=  lvf.field+'.Alias';
                                        }else{
                                            queryFilter +=  lvf.field+'.Name';
                                        }
                                      }

                                    } else {
                                      //IBO: fix for notContain (NOT Field LIKE 'value')
                                      if(lvf.operation=='notContain'){
                                        System.debug('************** notContain');
                                      }else{
                                          queryFilter += lvf.field;
                                      }
                                    }
                                    queryFilter += operator;
                                    queryFilter += value;

                                } else {
                                    queryFilter += 'Id <> \'\'';
                                }
                                if(lvf.operation=='includes' || lvf.operation=='excludes') {
                                    //all split values are in the collecton for includes and excludes!
                                    break;
                                }
                                valCnt++;

                            }
                            queryFilter += ')';

                            system.debug('\n====== STEP 0  : '+filterLogic +'\ncnt:'+cnt+'\n queryFilter:'+queryFilter);

                            filterLogic = filterLogic.replace('ZZZxxQxxZZZ'+cnt, queryFilter);
                            filterLogic = filterLogic.replace('XNXUXLXL'+nullCnt, '');

                            system.debug('\n====== STEP 1  : '+filterLogic);

                            qTokens.add(filterLogic);
                            if(cnt==1) {

                            system.debug('\n====== STEP 2  : '+filterLogic);
                                filterLogic = 'WHERE ' +filterLogic;
                            }else{
                                system.debug('\n====== THIS IS PERDIDO : '+queryFilter);
                            }
                            cnt++;
                            nullCnt++;
                        }
                    }
                    break;
                }
            }
        }
        return filterLogic;

    }

    /**
     * Get the field type by field name
     *
     * @param fieldName String field Name to retrieve the type from
     * @return String field Type
     */
    private Schema.DisplayType getFieldType(String fieldName) {
        if (fieldTypeMap == null) {
            Map<String, Schema.SObjectField> fMap = Schema.SObjectType.SocialPost.fields.getMap();
            fieldTypeMap = new Map<String,Schema.DisplayType>();
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                fieldTypeMap.put(fd.getName(),fd.getType());
            }
        }
        return fieldTypeMap.get(fieldName);
    }

    /**
     * Create a metadata service to get access to the metadata
     * @return MetadataService.MetadataPort
     **/
    public MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }

    public String dateTimeValuetoString(String val, String timeStamp, String operation, String fieldName){
        String correctDate='';
        String dd,mm,dd2;
        Integer tempInt;
        List<String> yyyy;
        if(!val.contains(' ')){
            correctDate=val;
        }else{
          if(timeStamp.equals('')){
            timeStamp = 'T00:00:00.000Z';
           }
          if(operation == 'equals' || operation == 'notEqual'){
            List<String> dateList=val.split('/');
            mm=dateList[0];
            dd=dateList[1];
            tempInt=Integer.valueOf(dd);
            tempInt=tempInt+1;
            dd2=String.valueOf(tempInt);

            if(dd.length()<2){dd='0'+dd;}
            if(dd2.length()<2){dd2='0'+dd2;}
            if(mm.length()<2){mm='0'+mm;}

            yyyy=dateList[2].split(' ');
            correctDate = yyyy[0]+'-'+mm+'-'+dd+timeStamp+ ' AND '+fieldName+' < '+yyyy[0]+'-'+mm+'-'+dd2+timeStamp+')';
          }else{
            List<String> dateList=val.split('/');
            mm=dateList[0];
            dd=dateList[1];
            if(dd.length()<2){dd='0'+dd;}
            if(mm.length()<2){mm='0'+mm;}
            yyyy=dateList[2].split(' ');
            correctDate=yyyy[0]+'-'+mm+'-'+dd+timeStamp;
          }
        }
        return correctDate;

    }

    public String isPicklist(String val, String field){
        String pickValue;
        Integer i = Integer.valueOf(val);
        if('Provider'.equals(field)){
            Schema.DescribeFieldResult F = SocialPost.Provider.getDescribe();
            List<Schema.PicklistEntry> P = F.getPicklistValues();
            pickValue = '\''+p[i].getLabel()+'\'';
        }else
            if('Status'.equals(field)){
                Schema.DescribeFieldResult F = SocialPost.Status.getDescribe();
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                pickValue = '\''+p[i].getLabel()+'\'';
            }
        return pickValue;
    }

}