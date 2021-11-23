/****************************************************************************************
Author:         paul.stamer@auspost.com.au
Description:    Test Class for opportunity team members
History:
-----------------------------------------------------------------------------------------
28.10.2016  	paul.stamer@auspost.com.au			created
25-06-2018      heguang.miao@coroma.com.au	        Updated [TDO-95] Optimise test cases.
12-10-2020      seth.heang@auspost.com.au	        Repurpose Test scenarios for Product Specialist and Solution Consultant flag on Opportunity
*****************************************************************************************/

@isTest
private class OpportunityTeamUtil_Test {

    @testSetup
    static void testDataSetup() {

        User holdingUser = [SELECT Id from User where Name = 'Holding User'];

        //create an organsation
        Account acc = new Account();
        acc.name = 'Test org';
        insert acc;

        //create an opportunity
        Opportunity opp = new Opportunity();
        opp.OwnerId = holdingUser.Id;
        opp.Name = 'Test opp BDD';
        opp.Account = acc;
        opp.Offering_Type__c = 'Product';
        opp.StageName = 'Identify';
        opp.CloseDate = Date.today();
        opp.Type = 'Existing Customer';
        insert opp;
    }

    /**
     * Helper method that refreshes given Opportunity object
     *
     * @param original the original opportunity
     *
     * @return refreshed opportunity
     */
    static Opportunity refreshOpportunity(Opportunity original) {
        Opportunity opp = [
                SELECT
                        Id, Has_Product_Specialist__c,Has_Solution_Consultant__c, OwnerId
                FROM
                        Opportunity
                WHERE Id = :original.Id
        ];
        return opp;
    }

    /**
     * SCENARIO: Insert OpportunityTeamMember with role as 'Product Specialist' or 'Solution Consultant'
     */
    @isTest
    static void handleTeamMembers_normalInsertion() {

        User holdingUser = [SELECT Id from User where Name = 'Holding User'];

        Opportunity opp = [
                SELECT
                        Id, Name, StageName, CloseDate, Has_Product_Specialist__c, Has_Solution_Consultant__c, OwnerId
                FROM
                        Opportunity
                limit 1
        ];

        Opportunity opp2 = new Opportunity();
        opp2 = opp.clone(false,true);

        test.startTest();
        insert opp2;
        // Adding team members to the opportunity as a Product Specialist
        OpportunityTeamMember oppteammemberPS = new OpportunityTeamMember();
        oppteammemberPS.OpportunityId = opp.Id;
        oppteammemberPS.UserId = opp.OwnerId;
        oppteammemberPS.TeamMemberRole = 'Product Specialist';

        // Note: This will fire OpportunityTeamListener, which calls OpportunityUtility.handleTeamMembers
        insert oppteammemberPS;
        
        OpportunityTeamMember oppTeamMemberSC = new OpportunityTeamMember();
        oppTeamMemberSC.OpportunityId = opp2.Id;
        oppTeamMemberSC.UserId = opp2.OwnerId;
        oppTeamMemberSC.TeamMemberRole = 'Solution Consultant';

        insert oppTeamMemberSC;
        test.stopTest();

        opp = refreshOpportunity(opp);
        opp2 = refreshOpportunity(opp2);
        System.assertEquals(true, opp.Has_Product_Specialist__c,
                'OpportunityTeamUtil_handleTeamMembers_normalInsertion : Product Specialist flag should be true on new insertion');
        System.assertEquals(true, opp2.Has_Solution_Consultant__c,
                'OpportunityTeamUtil_handleTeamMembers_normalInsertion : Solution Consultnat flag should be true on new insertion');
    }

    /**
     * SCENARIO: Delete OpportunityTeamMember with role as 'Product Specialist' or 'Solution Consultant'
     */
    @isTest
    static void handleTeamMembers_normalDeletion() {

        User holdingUser = [SELECT Id from User where Name = 'Holding User'];

        Opportunity opp = [
                SELECT
                        Id, Name, StageName, CloseDate, Has_Product_Specialist__c, Has_Solution_Consultant__c, OwnerId
                FROM
                        Opportunity
                limit 1
        ];

        Opportunity opp2 = new Opportunity();
        opp2 = opp.clone(false,true);
        insert opp2;

        // Adding team members to the opportunity as a Product Specialist
        OpportunityTeamMember oppteammemberPS = new OpportunityTeamMember();
        oppteammemberPS.OpportunityId = opp.Id;
        oppteammemberPS.UserId = opp.OwnerId;
        oppteammemberPS.TeamMemberRole = 'Bid Management';

        // Note: This will fire OpportunityTeamListener, which calls OpportunityUtility.handleTeamMembers
        insert oppteammemberPS;

        OpportunityTeamMember oppteammemberPS2 = new OpportunityTeamMember();
        oppteammemberPS2.OpportunityId = opp.Id;
        oppteammemberPS2.UserId = UserInfo.getUserId();
        oppteammemberPS2.TeamMemberRole = 'Product Specialist';
        insert oppteammemberPS2;

        //delete oppteammemberPS;
        OpportunityTeamMember oppTeamMemberSC = new OpportunityTeamMember();
        oppTeamMemberSC.OpportunityId = opp2.Id;
        oppTeamMemberSC.UserId = opp2.OwnerId;
        oppTeamMemberSC.TeamMemberRole = 'Bid Management';
        insert oppTeamMemberSC;

        OpportunityTeamMember oppTeamMemberSC2 = new OpportunityTeamMember();
        oppTeamMemberSC2.OpportunityId = opp2.Id;
        oppTeamMemberSC2.UserId = UserInfo.getUserId();
        oppTeamMemberSC2.TeamMemberRole = 'Solution Consultant';
        insert oppTeamMemberSC2;
        

        test.startTest();

        delete oppteammemberPS2;
        delete oppTeamMemberSC2;
        test.stopTest();
        opp = refreshOpportunity(opp);
        opp2 = refreshOpportunity(opp2);
        System.assertEquals(false, opp.Has_Product_Specialist__c,
                'OpportunityTeamUtil_handleTeamMembers_normalDeletion : Product Specialist flag should be false on deletion');
        System.assertEquals(false, opp2.Has_Solution_Consultant__c,
                'OpportunityTeamUtil_handleTeamMembers_normalDeletion : Solution Consultnat flag should be false on deletion');
    }



    
    /**
     * SCENARIO: At least one role already exists for 'Product Specialist' or 'Solution Consultant' for OpportunityTeamMember under one opportunity
     *           One of the team members with the above role, is added to the same opportunity
     */
    @isTest
    static void handleTeamMembers_MultipleRolesAddition() {
        
        Opportunity opp = [
                SELECT
                        Id, Has_Product_Specialist__c, Has_Solution_Consultant__c, OwnerId
                FROM
                        Opportunity
                LIMIT 1
        ];

        //adding team members to the opportunity as a Business Development Driver
        OpportunityTeamMember oppteammemberPS = new OpportunityTeamMember();
        oppteammemberPS.OpportunityId = opp.Id;
        oppteammemberPS.UserId = opp.OwnerId;
        oppteammemberPS.TeamMemberRole = 'Product Specialist';
        insert oppteammemberPS;

        //adding another team members to the opportunity as a Business Development Driver
        OpportunityTeamMember oppteammemberPS2 = new OpportunityTeamMember();
        oppteammemberPS2.OpportunityId = opp.Id;
        oppteammemberPS2.UserId = UserInfo.getUserId();
        oppteammemberPS2.TeamMemberRole = 'Bid Management';
        insert oppteammemberPS2;

        //adding team members to the opportunity as a Supply Chain Optimisation Driver
        OpportunityTeamMember oppTeamMemberSC = new OpportunityTeamMember();
        oppTeamMemberSC.OpportunityId = opp.Id;
        oppTeamMemberSC.UserId = opp.OwnerId;
        oppTeamMemberSC.TeamMemberRole = 'Solution Consultant';
        insert oppTeamMemberSC;

        //adding another team members to the opportunity as a Supply Chain Optimisation Driver
        OpportunityTeamMember oppTeamMemberSC2 = new OpportunityTeamMember();
        oppTeamMemberSC2.OpportunityId = opp.Id;
        oppTeamMemberSC2.UserId = UserInfo.getUserId();
        oppTeamMemberSC2.TeamMemberRole = 'Bid Management';
        insert oppTeamMemberSC2;

        test.startTest();
        oppTeamMemberSC2.TeamMemberRole = 'Solution Consultant';
        update oppTeamMemberSC2;
        
        oppteammemberPS2.TeamMemberRole = 'Product Specialist';
        update oppteammemberPS2;
        test.stopTest();


        opp = refreshOpportunity(opp);
        System.assertEquals(true, opp.Has_Product_Specialist__c,
                'OpportunityTeamUtil_handleTeamMembers_MultipleRolesAddition : Product Specialist flag should be true on update');
        opp = refreshOpportunity(opp);
        System.assertEquals(true, opp.Has_Solution_Consultant__c,
                'OpportunityTeamUtil_handleTeamMembers_MultipleRolesAddition : Solution Consultant flag should be true on update');

    }

    /**
     * SCENARIO: At least two roles exists for 'Product Specialist' or 'Solution Consultant' for OpportunityTeamMember under one opportunity
     *           One of the team members with the above role, is deleted from the same opportunity
     */
    @isTest
    static void handleTeamMembers_MultipleRolesDeduction() {

        Opportunity opp = [
                SELECT
                        Id, Name, StageName, CloseDate, Has_Product_Specialist__c, Has_Solution_Consultant__c, OwnerId
                FROM
                        Opportunity
                LIMIT 1
        ] ;

        Opportunity opp2 = new Opportunity();
        opp2 = opp.clone(false,true);
        insert opp2;

        //adding team members to the opportunity as a Business Development Driver
        OpportunityTeamMember oppteammemberPS = new OpportunityTeamMember();
        oppteammemberPS.OpportunityId = opp.Id;
        oppteammemberPS.UserId = opp.OwnerId;
        oppteammemberPS.TeamMemberRole = 'Product Specialist';
        insert oppteammemberPS;

        //adding another team members to the opportunity as a Business Development Driver
        OpportunityTeamMember oppteammemberPS2 = new OpportunityTeamMember();
        oppteammemberPS2.OpportunityId = opp.Id;
        oppteammemberPS2.UserId = UserInfo.getUserId();
        oppteammemberPS2.TeamMemberRole = 'Bid Management';
        insert oppteammemberPS2;

        //adding team members to the opportunity as a Supply Chain Optimisation Driver
        OpportunityTeamMember oppTeamMemberSC = new OpportunityTeamMember();
        oppTeamMemberSC.OpportunityId = opp2.Id;
        oppTeamMemberSC.UserId = opp.OwnerId;
        oppTeamMemberSC.TeamMemberRole = 'Solution Consultant';
        insert oppTeamMemberSC;

        //adding another team members to the opportunity as a Supply Chain Optimisation Driver
        OpportunityTeamMember oppTeamMemberSC2 = new OpportunityTeamMember();
        oppTeamMemberSC2.OpportunityId = opp2.Id;
        oppTeamMemberSC2.UserId = UserInfo.getUserId();
        oppTeamMemberSC2.TeamMemberRole = 'Bid Management';
        insert oppTeamMemberSC2;

        oppteammemberPS2.TeamMemberRole = 'Product Specialist';
        update oppteammemberPS2;

        oppTeamMemberSC2.TeamMemberRole = 'Solution Consultant';
        update oppTeamMemberSC2;

        test.startTest();
        delete oppteammemberPS2;
        delete oppTeamMemberSC2;
        test.stopTest();

        opp = refreshOpportunity(opp);
        opp2 = refreshOpportunity(opp2);
        System.assertEquals(true, opp.Has_Product_Specialist__c,
                'OpportunityTeamUtil_handleTeamMembers_MultipleRolesDeduction : Product Specialist flag should be true on delete as there is still one remaining product specialist role');
        System.assertEquals(true, opp2.Has_Solution_Consultant__c,
                'OpportunityTeamUtil_handleTeamMembers_MultipleRolesDeduction : Solution Consultant flag should be true on delete as there is still one remaining Solution Consultant role');

    }

    

    /**
     * SCENARIO: A OpportunityTeamMember changes its old role to 'Product Specialist' or Solution Consultant
     */
    @isTest
    static void handleTeamMembers_changingRoleToPSorSC() {

        User holdingUser = [SELECT Id from User where Name = 'Holding User'];

       

        Opportunity opp = [
                SELECT 
                        Id, Has_Product_Specialist__c, Has_Solution_Consultant__c,
                        OwnerId 
                FROM 
                        Opportunity 
                LIMIT 1] ;

        //adding another team members to the opportunity as a Business Development Driver
        OpportunityTeamMember oppteammemberPS = new OpportunityTeamMember();
        oppteammemberPS.OpportunityId = opp.Id;
        oppteammemberPS.UserId = holdingUser.Id;
        oppteammemberPS.TeamMemberRole = 'Bid Management';
        insert oppteammemberPS;

        //adding another team members to the opportunity as a Supply Chain Optimisation Driver
        OpportunityTeamMember oppTeamMemberSC = new OpportunityTeamMember();
        oppTeamMemberSC.OpportunityId = opp.Id;
        oppTeamMemberSC.UserId = UserInfo.getUserId();
        oppTeamMemberSC.TeamMemberRole = 'Bid Management';
        insert oppTeamMemberSC;

        test.startTest();
        oppteammemberPS.TeamMemberRole = 'Product Specialist';
        update oppteammemberPS;

        oppTeamMemberSC.TeamMemberRole = 'Solution Consultant';
        update oppTeamMemberSC;
        
        test.stopTest();
        opp = refreshOpportunity(opp);
        System.assertEquals(true, opp.Has_Product_Specialist__c, 
                'OpportunityTeamUtil_handleTeamMembers_changingRoleToPSorSC : Product Specialist flag should be true when newly updated role is product specialist');

        System.assertEquals(true, opp.Has_Solution_Consultant__c, 
                'OpportunityTeamUtil_handleTeamMembers_changingRoleToPSorSC : Solution Consultant flag should be true when newly updated role is Solution Consultant');
    }

    /**
     * SCENARIO: A OpportunityTeamMember changes its role from 'Product Specialist' or 'Solution Consultant' to a different roles
     */
    @isTest
    static void handleTeamMembers_changingRoleFromPSorSC() {

        User holdingUser = [SELECT Id from User where Name = 'Holding User'];

        Opportunity opp = [
                SELECT 
                        Id, Has_Product_Specialist__c, Has_Solution_Consultant__c, OwnerId
                FROM 
                        Opportunity 
                LIMIT 1] ;

        //adding another team members to the opportunity as a Business Development Driver
        OpportunityTeamMember oppteammemberPS = new OpportunityTeamMember();
        oppteammemberPS.OpportunityId = opp.Id;
        oppteammemberPS.UserId = holdingUser.Id;
        oppteammemberPS.TeamMemberRole = 'Product Specialist';
        insert oppteammemberPS;

        //adding another team members to the opportunity as a Supply Chain Optimisation Driver
        OpportunityTeamMember oppTeamMemberSC = new OpportunityTeamMember();
        oppTeamMemberSC.OpportunityId = opp.Id;
        oppTeamMemberSC.UserId = UserInfo.getUserId();
        oppTeamMemberSC.TeamMemberRole = 'Solution Consultant';
        insert oppTeamMemberSC;

        test.startTest();

        oppteammemberPS.TeamMemberRole = 'Bid Management';
        update oppteammemberPS;

        oppTeamMemberSC.TeamMemberRole = 'Bid Management';
        update oppTeamMemberSC;
        
        test.stopTest();

        opp = refreshOpportunity(opp);
        System.assertEquals(false, opp.Has_Product_Specialist__c, 
                'OpportunityTeamUtil_handleTeamMembers_changingRoleFromPSorSC : Product Specialist flag should be false when prior role of the update is product specialist');
        System.assertEquals(false, opp.Has_Solution_Consultant__c, 
                'OpportunityTeamUtil_handleTeamMembers_changingRoleFromPSorSC : Solution Consultant flag should be false when prior role of the update is Solution Consultant');
        
    }
}