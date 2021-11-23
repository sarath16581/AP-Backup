/* temporary logic to allow users to take ownership of opptys */


public without sharing class takeOwnershipControllerExtension {

    private Opportunity o;
    public Id aId;
    
    
    
    public takeOwnershipControllerExtension(ApexPages.StandardController controller) {
        this.o = (Opportunity)Controller.getRecord();
        aid = o.AccountId;
        
    }

    
    public PageReference go(){
            
            String aName = [ Select id, Name from Account where id =:aId limit 1].Name;
            
            if (aName == 'Temporary Customer') {
                Opportunity oUpdate = [Select id, OwnerId from Opportunity where id =:o.id limit 1];
                oUpdate.OwnerId = Userinfo.getUserId();
                update oUpdate;
            }
            PageReference ret = new PageReference('/'+o.id);
            ret.setRedirect(true);
            return ret;
    }
    
    public static testmethod void testController() {
        
        Id orgRT = [Select id from RecordType where SobjectType = 'Account' and IsPersonType = false limit 1].id;
        String stg = [Select MasterLabel from OpportunityStage where IsWon = false and IsClosed = false and IsActive = true limit 1].MasterLabel;
        
        String p = [select id from Profile where name ='Coverage Sales' limit 1].id;
        User u1 = new User(Alias = 'st', Email='standarduser@testorg.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p,TimeZoneSidKey='America/Los_Angeles', UserName='st' + System.currentTimeMillis() + '@testorg.com');
        User u2 = new User(Alias = 'st2', Email='standarduser2@testorg.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p,TimeZoneSidKey='America/Los_Angeles', UserName='st2' + System.currentTimeMillis() + '@testorg.com');
        insert u1;
        insert u2;
        
        Account a1 = new Account(name = 'org 1', recordtypeid = orgRT, ownerId = u2.id);
        Account a2 = new Account(name = 'Temporary Customer', recordtypeid = orgRT, ownerid = u2.id);
        insert a1;
        insert a2;
        
        Opportunity o = new Opportunity( name = 'test oppty', AccountId = a1.id, StageName = stg, Amount = 10000, ownerId = u2.id, closedate = date.today());
        insert o;
        
        Test.startTest();
        //System.runAs(u1) { // a standard user
            // try to transfer ownership via controller when not a temp customer organisation oppty
            PageReference testpage = Page.takeOwnership;
            Test.setCurrentPageReference(testpage);
            ApexPages.standardcontroller sc = new ApexPages.standardcontroller(o);
            takeOwnershipControllerExtension controller = new takeOwnershipControllerExtension(sc);
            controller.o.AccountId = a2.id;
            controller.go();
            Opportunity oo = [Select id, AccountId from opportunity where id =:o.id limit 1];
            System.assertEquals(oo.AccountId, a1.id); // shouldnt have changed ownership
        //}
        
        o.AccountId = a2.id;
        update o;
        
        // now is on temp customer record, so should be allowed to change ownership
        System.runAs(u1) { // a standard user
            // try to transfer ownership via controller when a temp customer organisation oppty
            PageReference testpage2 = Page.takeOwnership;
            Test.setCurrentPageReference(testpage2);
            ApexPages.standardcontroller sc2 = new ApexPages.standardcontroller(o);
            takeOwnershipControllerExtension controller2 = new takeOwnershipControllerExtension(sc2);
            controller2.o.AccountId = a1.id;
            controller2.go();
            System.assertEquals(o.AccountId, a1.id); // should have changed ownership
        }
        
        
        Test.stopTest();
        
        
    }
    
}