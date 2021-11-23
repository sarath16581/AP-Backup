/**************************************************
History:
--------------------------------------------------
2019-03-18  gunith.devasurendra@auspost.com.au  Removed Dashcord references
**************************************************/

// one time code to remove social contacts attached to Social Account

//sProcessMode = Process1  // First time processing, decouple social contact from persona and case and mark for deletion
//sProcessMode = Process2  // check for other relationships, if no then del contact else set Contact.OtherStreet2__c = '<Error>RelationshipError:ReleatinshipTblname.Columname

//oneTimeRemoveSocialContact(string sProcessMode, boolean bemptyRecycleBin, String qFilter)
//oneTimeRemoveSocialContact b = new oneTimeRemoveSocialContact('Process1' , false,'and id = \'003900000264PsbAAE\' ');


/*
 *
 *
Field OtherStreet2__c is used to keep track of social contacts that cannot be deleted.
//main query
query =  select id, firstname , lastname , OtherStreet2__c from contact where accountid = '0019000001MRvVGAA1'  and (not OtherStreet2__c like  '<Error>%') order by name
select id, firstname , lastname , OtherStreet2__c,name from contact where accountid = \''  + getDefaultAccountId() + '\'  and (not OtherStreet2__c like  \'<Error>%\')  '  + qFilter  + ' order by name

//case having social account
select id, contactid,accountid,account.name from case where contactid = '0039000001wpf27AAA'

select id , OtherStreet2__c from contact where id = '0039000001wpf27AAA'

accountid = 0019000001MRvVGAA1

contact: 0039000001wpf27AAA

select count(id) from contact where accountid = '0019000001MRvVGAA1'
// count :182036

oneTimeRemoveSocialContact b = new oneTimeRemoveSocialContact(false,'and id = \'003900000264PsbAAE\' ');
oneTimeRemoveSocialContact b = new oneTimeRemoveSocialContact(false,'and id = \'0039000001wpf27AAA\' ');
database.executebatch(b);
parm(emptyRecycle bin, query)

oneTimeRemoveSocialContact b = new oneTimeRemoveSocialContact(true,'');
database.executebatch(b,60);

//list<contact> scope = [select id, firstname , lastname from contact where accountid = : oneTimeRemoveSocialContact.getDefaultAccountId() limit 1] ;
//b.execCode(null,scope);

validation errors for
Addressee Address
reference id
type
Product Category
Product Sub Category

*/
//
global class oneTimeRemoveSocialContact implements Database.Batchable<sObject>{

    global final String Query;
    global final boolean emptyRecycleBin;
    global final string processMode;

    public static string  getDefaultAccountId() {
        string accountName = system.label.socialAccountName;
        string accountId = null;

        try {
            accountId =  [select Id from account where name = :accountName limit 1].Id;
            System.debug('** accountId ==>'+accountId);
        }
        catch(exception e) {}
        return accountId;
    }


    global oneTimeRemoveSocialContact(string sProcessMode, boolean bemptyRecycleBin, String qFilter,string slimit){
        //Field OtherStreet2__c is used to keep track of social contacts that cannot be deleted. this ifield is updated with <Error> if cannot be deleted
        emptyRecycleBin = bemptyRecycleBin;
        processMode = sProcessMode;
        string q;
        if(sProcessMode ==  'Process1'){
            q = 'select id, firstname , lastname , OtherStreet2__c,name from contact where accountid = \''  + getDefaultAccountId() + '\'  and (not OtherStreet2__c like  \'<Error>%\')  '  + qFilter  + ' order by name' +  slimit ;
        }
        if(sProcessMode ==  'Process2'){
            q = 'select id, firstname , lastname , OtherStreet2__c,name from contact where accountid = \''  + getDefaultAccountId() + '\'  and (OtherStreet2__c =  \'<ReadyForDelete>\')  '  + qFilter  + ' order by name' ;
        }
        Query=q;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execCode(Database.BatchableContext BC, List<Contact> scope){
        id socialAccountId = getDefaultAccountId();
        Map<id,socialPersona> spByPersonaId = new Map<id,socialPersona>([select id, name , parentid from socialPersona   where parentid in : scope  ]) ;
        map<id,list<socialPersona>> SPbyContactID = new map<id,list<socialPersona>>();
        map<id,Contact> contactById = new map<id,Contact>();
        Map<id,socialPost> SPtToAddbyPersona = new  Map<id,socialPost>();
        Map<id,Contact> contactToDel = new Map<id,Contact>();
        for(contact con : scope){
            contactById.put(con.id, con);
        }
        for(Contact con : scope){
            SPbyContactID.put(con.id, new list<socialPersona>() );
        }
        // create new dummy social post to reparent persona
        for(socialPersona sp : spByPersonaId.values() ){
            if(SPbyContactID.containsKey(sp.parentid)) {
                SPbyContactID.get(sp.parentid).add(sp);
                Contact con = contactById.get(sp.parentid);
                socialPost spt = new  socialPost(name = 'DPP ' + con.FirstName + ' ' + con.lastName , Content = 'Dummy Parent Post for Social Persona with id:'  + ' ' + sp.id  )   ;
                SPtToAddbyPersona.put(sp.id,spt) ;
            }  else {
                // error no data
            }
        }
        insert SPtToAddbyPersona.values();

        //ReParent SocialPersona
        map<id, socialPersona> reparentSP = new  map<id, socialPersona>();
        for(String idBySp : SPtToAddbyPersona.keySet()  ){
            socialPersona sp = spByPersonaId.get(idBySp);
            id contactToReplaceId = sp.parentid;
            sp.parentid = SPtToAddbyPersona.get(sp.id).id;
            contactToDel.put(contactById.get(contactToReplaceId).id ,contactById.get(contactToReplaceId));
            reparentSP.put(sp.id,sp);
        }
        update  reparentSP.values();

        // Remove all case links to contacts that will be deleted
        map<id,id> conIDByCaseIDToDel = new  map<id,id>();
        map<id,contact> conMap = new map<id,contact>(scope);


        map<id,Case> socialCaseByID = new Map<id,Case>([select id , contactid, accountid,Bypass_Data_enforcement__c from case where contactid in : scope ]);
        for(Case cas : socialCaseByID.values()  ){
            if(cas.contactid != null){
                cas.Bypass_Data_enforcement__c = true;
                conIDByCaseIDToDel.put(cas.id,cas.contactid );
            }

            cas.contactid = null;
            if(cas.accountid == socialAccountId ){cas.accountid = null;}
        }

        //update  socialCaseByID.values();
        // get list of all ontact to delete
        map<id,Contact> delSocialContact = new  map<id,Contact>(scope);
        list<id> remFromDel = new  list<id>();


        id conId;


        list<Case> caseToUpd = socialCaseByID.values();
        List<Database.SaveResult> updateResults = Database.Update(caseToUpd, false);
        for(Integer i=0;i<updateResults.size();i++){
            /*if (updateResults.get(i).isSuccess()){
                conId = conIDByCaseIDToDel.get(updateResults.get(i).getId());
                delSocialContact.put(conId, conMap.get(conId));
            }
            else*/
            if (!updateResults.get(i).isSuccess()){
                conId = conIDByCaseIDToDel.get(caseToUpd[i].id);
                if(conId != null){remFromDel.add(conId); }

                // DML operation failed
                Database.Error error = updateResults.get(i).getErrors().get(0);
                String failedDML = error.getMessage();
                //arudate.get(i);//failed record from the list
                system.debug('Failed ID'+ updateResults.get(i).getId() + ' , message=' +  failedDML);
            }

        }

        map<id,Contact> cannotDelById = new map<id,Contact>();
        //only social contacts that have been  successfully decoupled from case can be deleted and other contacts not associated to cases can be deleted
        // remove social contacts from list that have errors in cases linked to them

        for(id conIdval : remFromDel){
            if(delSocialContact.containsKey(conIdval) ){
                cannotDelById.put(conIdval,delSocialContact.get(conIdval) );
                delSocialContact.get(conIdval).OtherStreet2__c = '<Error>Case';
                delSocialContact.remove(conIdval)  ;
                system.debug('contact id to remove=' + conIdval);
            }
        }

        // cross check to ensure only deleteing replaced/reparented Contacts

        // list<SocialPersona> testSPLst = [select id from SocialPersona where parentid in : scope ];
        map<id,SocialPersona> testSPLstById = new map<id,SocialPersona>([select id , parentid from SocialPersona where parentid in : delSocialContact.keySet() ]);

        // do not delete contact if attached to Social Persona
        for(SocialPersona spTmp: testSPLstById.values()){
            if(delSocialContact.containsKey(spTmp.parentid) ){
                cannotDelById.put(spTmp.parentid,delSocialContact.get(spTmp.parentid) );
                delSocialContact.get(spTmp.parentid).OtherStreet2__c = '<Error>Persona';
                delSocialContact.remove(spTmp.parentid)  ;

            }
        }

        update cannotDelById.values();

        /*
        delete delSocialContact.values();
        if(emptyRecycleBin){
            system.debug('Empty Recycle bin true');
            Database.emptyRecycleBin(delSocialContact.values());
        }
        */
        //flag for deletion
        for(contact conDel : delSocialContact.values()){
            conDel.OtherStreet2__c = '<ReadyForDelete>';
        }
        Update delSocialContact.values();

    }

    // check for  any relationships that have cascade del  = true , if yes , do not delete contact else delete contact
    global void execProcess2(Database.BatchableContext BC, List<Contact> scope){
        list<contact> contactLst = scope;
        map<id,contact> contactById = new Map<id,contact>(contactLst);
        map<id,contact> contactByIdError = new Map<id,contact>();


        list<APR_Contact__c> aprConLst =  [select id, Contact__c from APR_Contact__c where Contact__c in :contactLst];
        list<Asset> AssetLst =  [select id, ContactId from Asset where ContactId in :contactLst] ;
        list<DMAPP__Political_Map_Contact_Last_Modification__c> polMapLst = [select id, DMAPP__Contact__c from DMAPP__Political_Map_Contact_Last_Modification__c where DMAPP__Contact__c in :contactLst] ;
        list<Note> noteLst = [select id, ParentId from Note where ParentId = :contactLst];

        list<Attachment> Attachmentlst = [select id, ParentId from Attachment where ParentId  in :contactLst];
        List<Task> TaskLst = [select id,WhoId  from Task  where WhoId   in :contactLst];
        List<Event> EventLst = [select id,WhoId  from Event where WhoId   in :contactLst];
       // List<Opportunity> OpportunityLst = [select id,KeyContact__c  from Opportunity where KeyContact__c   in :contactLst]; //What to do if the lookup record is deleted?	Clear the value of this field.

        list<socialPersona> spLst =  [select id, ParentId from SocialPersona where ParentId = :contactLst];

        for(APR_Contact__c val: aprConLst){
            contactById.get(val.Contact__c).OtherStreet2__c = '<Error>RelationshipError:APR_Contact__c.Contact__c';
            contactByIdError.put(val.Contact__c, contactById.get(val.Contact__c));
        }

        for(Asset val: AssetLst){
            contactById.get(val.ContactId).OtherStreet2__c = '<Error>RelationshipError:Asset.ContactId';
            contactByIdError.put(val.ContactId, contactById.get(val.ContactId));
        }

        for(DMAPP__Political_Map_Contact_Last_Modification__c val: polMapLst){
            contactById.get(val.DMAPP__Contact__c).OtherStreet2__c = '<Error>RelationshipError:DMAPP__Political_Map_Contact_Last_Modification__c.DMAPP__Contact__c';
            contactByIdError.put(val.DMAPP__Contact__c, contactById.get(val.DMAPP__Contact__c));
        }

        for(Note val: noteLst){
            contactById.get(val.ParentId).OtherStreet2__c = '<Error>RelationshipError:Note.ParentId';
            contactByIdError.put(val.ParentId, contactById.get(val.ParentId));
        }

        for(Attachment val: AttachmentLst){
            contactById.get(val.ParentId).OtherStreet2__c = '<Error>RelationshipError:Attachment.ParentId';
            contactByIdError.put(val.ParentId, contactById.get(val.ParentId));
        }

        for(Task val: TaskLst){
            if( val.whoid != null){
            	contactById.get(val.WhoId).OtherStreet2__c = '<Error>RelationshipError:Task.WhoId';
                contactByIdError.put(val.WhoId, contactById.get(val.WhoId));
            }
            
        }

        for(Event val: EventLst){
            contactById.get(val.WhoId).OtherStreet2__c = '<Error>RelationshipError:Event.WhoId';
            contactByIdError.put(val.WhoId, contactById.get(val.WhoId));
        }

       /* for(Opportunity val: OpportunityLst){
            contactById.get(val.ContractId).OtherStreet2__c = '<Error>RelationshipError:Opportunity.ContractId';
            contactByIdError.put(val.ContractId, contactById.get(val.ContractId));
            contactById.Remove(val.ContractId);
        }
*/

        for(SocialPersona val: spLst){
            contactById.get(val.ParentId).OtherStreet2__c =  '<Error>RelationshipError:SocialPersona.ParentId';
            contactByIdError.put(val.ParentId, contactById.get(val.ParentId));
        }

        for(string s :  contactByIdError.keyset()){
            if(contactById.containsKey(s)){
            	contactById.Remove(s);	    
            }	    
        }

        id  conId ;
        list<Contact> conToDel = contactById.values();
        List<Database.DeleteResult> delResults = Database.Delete(conToDel, false);
        for(Integer i=0;i<delResults.size();i++){
            if (!delResults.get(i).isSuccess()){
                contact conErrObj = contactById.get(conToDel[i].id);
                if(conErrObj != null){
                    Database.Error error = delResults.get(i).getErrors().get(0);
                    String failedDML = error.getMessage();
                    conErrObj.OtherStreet2__c = '<Error>DeleteError:' + failedDML;
                    contactByIdError.put(conErrObj.id, conErrObj);
                    contactById.remove(conErrObj.id);
                }
            }

        }
        if(emptyRecycleBin){
            system.debug('Empty Recycle bin true');
            Database.emptyRecycleBin(conToDel);
        }
        update contactByIdError.values();

    }

    global void execute(Database.BatchableContext BC, List<Contact> scope){
        system.debug('in execute Data Skew ' + processMode + 'process completed' );
        if(processMode ==  'Process1') {
            execCode(BC, scope);
        } else if(processMode ==  'Process2'){
            execProcess2(BC, scope);
        }

    }

    global void finish(Database.BatchableContext BC){
        system.debug('in finish Data Skew ' + processMode + 'process completed' );
        //oneTimeRemoveSocialContact(string sProcessMode, boolean bemptyRecycleBin, String qFilter);
        if(processMode ==  'Process1' ){
            oneTimeRemoveSocialContact b = new oneTimeRemoveSocialContact('Process2' , false,'','');
            database.executeBatch(b);
        }
    }
}