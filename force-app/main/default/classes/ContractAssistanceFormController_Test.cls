/**************************************************************************************
Description:    Test class to cover ContractAssistanceFormController functionality
History:
---------------------------------------------------------------------------------------
2017-12-07  Clint D'Silva  Created
2018-06-26  TDO-72 : rahul.kapoor@coroma.com.au  Refactored comments and indentation,
            added assertEquals and assertNotEquals, added create test data setup method
            and removed dataCreation test method.
2020-06-02  Shashwat.a.nath@accenture.com Updated the method testUpdateOpportunityDriver to assign PS with permission to bypass the classic opportunity creation restriction 
            to the running user
***************************************************************************************/
@isTest
public class ContractAssistanceFormController_Test {
    /*****************************************************************************************
    *  Scenario:
    *      Setup method to create test data.
    ******************************************************************************************/
    @testSetup
    static void createTestData(){
        list<RecordType> RecTypeLst = [SELECT id, developername, sobjecttype
                                       FROM recordtype
                                       WHERE sobjecttype IN ('Account', 'Task')
                                       AND developername IN ('Business_Account', 'Sales_Task')];

        Map<string,RecordType> RecTypeBysObjNameDevName = new Map<string,RecordType>();

        for(RecordType rec: RecTypeLst ){
            if(!RecTypeBysObjNameDevName.containsKey(rec.sobjecttype  + rec.developername) ){
                RecTypeBysObjNameDevName.put(rec.sobjecttype  + rec.developername,rec );
            }
        }

        id profileIdVal = [SELECT Id FROM Profile WHERE Name = 'Coverage Sales'].Id;
        id roleid = [select id, name from UserRole where name='CEO/Reporting'].id;

        Id commercialTeamQueueID = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Commercial Team' LIMIT 1].Id;

        //Create a User.
        User opUser = TestUtility.createUser('opUser',profileIdVal,roleid);

        insert opUser;
        
        // Query your permission set name from Organization to bypass the validation.
        List<PermissionSet>  psList = new List<PermissionSet>();
        psList = [SELECT Id FROM PermissionSet WHERE Name = 'ValidationRuleBypassClassicRestrictions' LIMIT 1];
       
        // Assign the above inserted user for the above Permission Set.
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = opUser.Id;
        psa.PermissionSetId = psList[0].id;
        insert psa;

        //Create a Seller User.
        User sellerUser = TestUtility.createUser('seller',profileIdVal,roleid);

        insert sellerUser;

        //Create a Commercial User.
        User commercialUser = TestUtility.createUser('commerci',profileIdVal,roleid);

        insert commercialUser;

        //Fetch a group.
        Group grp=[select Id from Group Where DeveloperName='CommercialTeam'];

        //Fetch a group member.
        GroupMember gm= new GroupMember(GroupId = grp.id, UserOrGroupId = commercialUser.id );
        upsert gm;

        Opportunity opp;
        ContractAssistanceForm__c caf;

        //Run as Op User.
        system.runAs(opUser) {
            //Create a Account.
            Account acc = new account(recordtypeid = RecTypeBysObjNameDevName.get('AccountBusiness_Account').id,name ='TestAccount', ownerid = opUser.id );
            insert acc;

            //Create a Opportunity.
            opp = new opportunity(name='opp1',type='Existing Customer', offering_type__c='Solutions', stageName='Identify' ,closeDate = date.today() , accountid = acc.id,ownerid = opUser.id );
            insert opp;
        }

        //Run as sellerUser.
        system.runAs(sellerUser) {
            //Create Contract Assistance Form.
            caf = new ContractAssistanceForm__c(Opportunity__c = opp.id
            ,Status__c = 'New'
            , Specific_Terms_and_Clauses__c = '2 free text'
            , Related_Contract_Tender__c = '3 free text'
            , DateOpened__c = date.today()
            , Contract_start_date__c = date.today()
            , Initial_Contract_Term__c = '1'
            , Site_of_Services__c = 'AP Site'
            , AP_IP__c = '5 free text'
            , Customer_IP__c = '6 free text'
            , New_IP__c = '7 free text'
            , Third_Party_Involvement__c = '10 free text'
            , Business_Consultation__c  = '12 free text'
            , Previous_Legal_Involvement__c = '9 free text'
            , Comments__c = 'Comments__c'
            , Product_Manager_s__c = '11 free text'
            , Documents_Attached__c = false
            , ownerid = sellerUser.id
            ,OpportunityOwner__c = opp.ownerid
            );
            insert caf;
            caf.Renewal_Date__c = date.today().addYears(1);
            ContractAssistanceForm__c cafOld =  caf;
        }

        //Run as commercialUser.
        system.runAs(commercialUser) {
            //Create a Task.
            id TaskRecordTypeID = RecTypeBysObjNameDevName.get('TaskSales_Task').id;
            task tsk1 = new Task(recordtypeid = TaskRecordTypeID
            , subject = 'sub1'
            , Type = 'Reminder'
            , category__c = 'Sales'
            , status = 'Completed'
            , priority = 'Normal'
            , whatid = caf.id
            );
            insert tsk1;
        }
    }

    /*****************************************************************************************
    *  Scenario:
    *      Test the CAF Buttons ReSubmit.
    ******************************************************************************************/
    static testMethod void testCAFButtonsReSubmit() {
        //Fetch Commercial User.
        User commercialUser = [SELECT Id, alias FROM User WHERE alias='commerci'];

        //Fetch Op User.
        User opUser = [SELECT Id, alias FROM User WHERE alias='opUser'];

        //Fetch Seller User.
        User sellerUser = [SELECT Id, alias FROM User WHERE alias='seller'];

        ContractAssistanceForm__c caf;
        //Run as Seller User.
        system.runAs(sellerUser) {
            //Fetch Contract Assistance Form.
            caf = [SELECT Id, ownerid, Status__c, RejectionReason__c
                   FROM ContractAssistanceForm__c];
        }

        //Below method sets the page context for your unit test method.
        PageReference pageRef = Page.ContractAssistanceFormButtons;
        ContractAssistanceFormController controller;
        ApexPages.StandardController stdCtrl;
        Test.setCurrentPage(pageRef);

        //Run as commercialUser to update ContractAssistanceForm.
        system.runAs(commercialUser) {
            User usr = commercialUser;
            caf.ownerid = usr.Id;
            update caf;
            caf.Status__c = 'Rejected';
            caf.RejectionReason__c = 'Contact Legal Team';
            update caf;
        }

        //Run as opUser to Set parameters in current page.
        system.runAs(opUser) {
            //Set parameters in current page.
            ApexPages.currentPage().getParameters().put('opt', 'resub');
            ApexPages.currentPage().getParameters().put('id', caf.Id);
            stdCtrl = new ApexPages.StandardController(caf);
            //Initialize the controller constructor.
            controller = new ContractAssistanceFormController(stdCtrl);
            //Call autoRun method from Controller.
            controller.autoRun();

            System.assertNotEquals('New', caf.Status__c,
                    'ContractAssistanceFormController_Test_testCAFButtonsReSubmit : Opportunity has not be re-submitted');
        }

        //Below method sets the page context for your unit test method.
        pageRef = null;
        pageRef = Page.ContractAssistanceFormButtons;
        Test.setCurrentPage(pageRef);
        //Set parameters in current page.
        ApexPages.currentPage().getParameters().put('opt', 'usr');
        Account acc;

        //Run as opUser to fetch account.
        system.runAs(opUser) {
            //Fetch Account.
            acc = [SELECT Id, ownerid, name FROM Account WHERE name ='TestAccount'];
        }
        stdCtrl = new ApexPages.StandardController(acc);
        controller = new ContractAssistanceFormController(stdCtrl);
        //Call onReSubmit method from Controller.
        string sMsg = controller.onReSubmit();

        System.assertEquals(ContractAssistanceFormController.ERR_MSG_NO_BASE_OBJ, sMsg,
                'ContractAssistanceFormController_Test_testCAFButtonsReSubmit : No Commercial Team Request Record');
    }

    /*****************************************************************************************
    *  Scenario:
    *      Test the CAF Buttons Close.
    ******************************************************************************************/
    static testMethod void testCAFButtonsClose() {
        //Fetch Commercial User.
        User commercialUser = [SELECT Id, alias FROM User WHERE alias='commerci'];

        //Fetch Op User.
        User opUser = [SELECT Id, alias FROM User WHERE alias='opUser'];

        //Fetch Seller User.
        User sellerUser = [SELECT Id, alias FROM User WHERE alias='seller'];

        ContractAssistanceForm__c caf;
        //Run as seller user to fetch Contract Assistance Form.
        system.runAs(sellerUser) {
            //Fetch Contract Assistance Form.
            caf = [SELECT Id, ownerid, Status__c, RejectionReason__c
                   FROM ContractAssistanceForm__c];
        }

        //Below method sets the page context for your unit test method.
        PageReference pageRef = Page.ContractAssistanceFormButtons;
        ContractAssistanceFormController controller;
        ApexPages.StandardController stdCtrl; 
        Test.setCurrentPage(pageRef);
         //Run as opUser to Set parameters in current page.
          system.runAs(opUser) {
            //Set parameters in current page.
            ApexPages.currentPage().getParameters().put('opt', 'cls');
            ApexPages.currentPage().getParameters().put('id', caf.Id);
            stdCtrl = new ApexPages.StandardController(caf);
            //Initialize the controller constructor.
            controller = new ContractAssistanceFormController(stdCtrl);
            //Call autoRun method from Controller.
            controller.autoRun();

            System.assertNotEquals('Closed', caf.Status__c,
                      'ContractAssistanceFormController_Test_testCAFButtonsClose : Opportunity owner could not close CAF');
        }
        stdCtrl = null;
        //Run as commercialUser to Set the parameters in the current page.
        system.runAs(commercialUser) {
            pageRef = null;
            //Below method sets the page context for your unit test method.
            pageRef = Page.ContractAssistanceFormButtons;
            Test.setCurrentPage(pageRef);

            //Set the parameters in the current page.
            ApexPages.currentPage().getParameters().put('opt', 'cls');
            ApexPages.currentPage().getParameters().put('id', caf.Id);

            //Initialize the controller constructor.
            stdCtrl = new ApexPages.StandardController(caf);
            controller = new ContractAssistanceFormController(stdCtrl);

            //Call autoRun method from Controller.
            controller.autoRun();

            //Fetch all the apex page messages.
            ApexPages.Message[] messages = ApexPages.getMessages();
            integer errCnt = messages.size() ;
            errCnt = errCnt >= 1?(errCnt - 1):0;
        }

        pageRef = null;
        pageRef = Page.ContractAssistanceFormButtons;
        //Below method sets the page context for your unit test method.
        Test.setCurrentPage(pageRef);
        //Set the parameters in the current page.
        ApexPages.currentPage().getParameters().put('opt', 'cls');
        Account acc;

        //Run as opUser to Fetch Account.
        system.runAs(opUser) {
            //Fetch Account.
            acc = [SELECT Id, ownerid, name FROM Account WHERE name ='TestAccount'];
        }
        stdCtrl = new ApexPages.StandardController(acc);
        //Initialize the controller constructor.
        controller = new ContractAssistanceFormController(stdCtrl);
        //Call onClose method from Controller.
        string sMsg = controller.onClose();

        System.assertEquals(ContractAssistanceFormController.ERR_MSG_NO_BASE_OBJ, sMsg,
                'ContractAssistanceFormController_Test_testCAFButtonsClose : No Commercial Team Request Record');
    }

    /*****************************************************************************************
    *  Scenario:
    *      Test the CAF Buttons Assign User.
    ******************************************************************************************/
    static testMethod void testCAFButtonsAssignUser() {
        //Fetch Commercial User.
        User commercialUser = [SELECT Id, alias FROM User WHERE alias='commerci'];

        //Fetch Op User.
        User opUser = [SELECT Id, alias FROM User WHERE alias='opUser'];

        //Fetch Seller User.
        User sellerUser = [SELECT Id, alias FROM User WHERE alias='seller'];

        ContractAssistanceForm__c caf;
        //Run as sellerUser to Fetch Contract Assistance Form.
        system.runAs(sellerUser) {
            //Fetch Contract Assistance Form.
            caf = [SELECT Id, ownerid, Status__c, RejectionReason__c
                   FROM ContractAssistanceForm__c];
        }

        //Below method sets the page context for your unit test method.
        PageReference pageRef = Page.ContractAssistanceFormButtons;
        ContractAssistanceFormController controller;
        ApexPages.StandardController stdCtrl;
        Test.setCurrentPage(pageRef);

        //Run as commercialUser Set the parameters in the current page.
        system.runAs(commercialUser) {
            //Set the parameters in the current page.
            ApexPages.currentPage().getParameters().put('opt', 'usr');
            ApexPages.currentPage().getParameters().put('id', caf.Id);
            //Initialize the controller constructor.
            stdCtrl = new ApexPages.StandardController(caf);
            controller = new ContractAssistanceFormController(stdCtrl);
            //Call autoRun method from Controller.
            controller.autoRun(); 

            system.assert(caf.ownerid == caf.ownerid, 'Owner has not changed to commercial team owner' ); 
            list<OpportunityLineItem> oppItmsLst =  controller.getOppPrd();
            integer cnt = controller.getOppPrdCount();     
        }

        pageRef = null;
        pageRef = Page.ContractAssistanceFormButtons;
        //Below method sets the page context for your unit test method.
        Test.setCurrentPage(pageRef);
        //Set the parameters in the current page.
        ApexPages.currentPage().getParameters().put('opt', 'usr');
        Account acc;

        //Run as opUser to Fetch Account.
        system.runAs(opUser) {
            //Fetch Account.
            acc = [SELECT Id, ownerid, name FROM Account WHERE name ='TestAccount'];
        }
        //Initialize the controller constructor.
        stdCtrl = new ApexPages.StandardController(acc);
        controller = new ContractAssistanceFormController(stdCtrl);
        //Call AssignCurrentUser method from Controller.
        string sMsg = controller.AssignCurrentUser();

        System.assertEquals(ContractAssistanceFormController.ERR_MSG_NO_BASE_OBJ, sMsg,
                'ContractAssistanceFormController_Test_testCAFButtonsAssignUser : No Commercial Team Request Record');
    }  

}