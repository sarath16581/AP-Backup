/**************************************************
  Type:         test class for opp_update trigger
  History:
  --------------------------------------------------
  11.07.2014    Eric Shen (AusPost )                disable account ID related code due to the new competitor change.
  08.06.2018: 	TDO-39 : Hasantha.Liyanage@auspost.com.au Unit tests re-written with scenario based tests.
  **************************************************/


@isTest
private class opp_update_test {

    /**
     * Setup Initial Data
     */
    @testSetup static void setupInitialData() {
        // Account
        Account account = new Account(Name = 'Test Account');
        insert account;

        // Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(
                Name = 'Test Opportunity 1',
                AccountId = account.Id,
                Offering_Type__c = 'Product',
                StageName = 'Identify',
                Probability = 3,
                CloseDate = System.today() + 2,
                Commit_to_close_by__c = Date.today(),
                Type = 'Existing Customer'));

        opportunities.add(new Opportunity(
                Name = 'Test Opportunity 2',
                AccountId = account.Id,
                Offering_Type__c = 'Product',
                StageName = 'Identify',
                Probability = 3,
                CloseDate = System.today() + 2,
                Commit_to_close_by__c = Date.today(),
                Type = 'Existing Customer'));

        opportunities.add(new Opportunity(
                Name = 'Test Opportunity 3',
                AccountId = account.Id,
                Offering_Type__c = 'Product',
                StageName = 'Identify',
                Probability = 3,
                CloseDate = System.today() + 2,
                Commit_to_close_by__c = Date.today(),
                Type = 'Existing Customer'));
        insert opportunities;

        // Competitors
        List<Competitor__c> competitors = new List<Competitor__c>();
        for (Opportunity opportunity : opportunities) {
            // If 'Test Opportunity 1'
            if ('Test Opportunity 1'.equals(opportunity.Name)) {
                for (Integer i = 0; i < 20; i++) {
                    competitors.add(new Competitor__c(
                            Competitor_Type__c = 'Competitor',
                            Competitor_Name__c = 'AaE',
                            Competitive_Status__c = 'Behind Competition',
                            Competitive_Advantage__c = 'Competitive Advantage',
                            OpportunityId__c = opportunity.Id));

                    competitors.add(new Competitor__c(
                            OpportunityId__c = opportunity.Id,
                            Competitor_Name__c = 'Competitor / Incumbent'));
                }

            } // If 'Test Opportunity 2'
            else if ('Test Opportunity 2'.equals(opportunity.Name)) {
                for (Integer i = 0; i < 20; i++) {
                    competitors.add(new Competitor__c(
                            OpportunityId__c = opportunity.Id,
                            Competitor_Name__c = 'Competitor / Incumbent'));
                }
            }
        }
        insert competitors;
    }

    /**
     * SCENARIO: Successfully add Competitors with and without values to Opportunity
     */
    @isTest static void opp_update_after_insert_competitorsWithAndWithoutValuesSuccess() {
        // Load's the Opportunity
        Opportunity opportunity = [ SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 3' ];

        Test.startTest();

        // Verify the Logic
        List<Competitor__c> competitors = new List<Competitor__c>();
        for (Integer i = 0; i < 20; i++) {
            competitors.add(new Competitor__c(
                    Competitor_Type__c = 'Competitor',
                    Competitor_Name__c = 'AaE',
                    Competitive_Status__c = 'Behind Competition',
                    Competitive_Advantage__c = 'Competitive Advantage',
                    OpportunityId__c = opportunity.Id));
            competitors.add(new Competitor__c(
                    OpportunityId__c = opportunity.Id,
                    Competitor_Name__c = 'Competitor / Incumbent'));
        }
        insert competitors;

        Test.stopTest();

        // Verify the Logic
        opportunity = [ SELECT Hidden_Competitor_Score__c, Hidden_Competitor_Score_Description__c
        FROM Opportunity
        WHERE Id = :opportunity.Id ];

        System.assertEquals(12, opportunity.Hidden_Competitor_Score__c,
                'opp_update_after_insert_competitorsWithAndWithoutValuesSuccess : Hidden Competitor Score calculation unsuccessful. Hidden Competitor Score should be 12');

        System.assertNotEquals('', opportunity.Hidden_Competitor_Score_Description__c,
                'opp_update_after_insert_competitorsWithAndWithoutValuesSuccess : Hidden Competitor Score Description calculation unsuccessful. Hidden Competitor Score Description should NOT be Empty');
    }

    /**
     * SCENARIO: Successfully update Competitors with and without values on Opportunity
     */
    @isTest static void opp_update_after_update_competitorsWithAndWithoutValuesSuccess() {
        // Load's the Opportunity
        Opportunity opportunity = [ SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1' ];

        // Load's the Competitors
        List<Competitor__c> competitors = [ SELECT Id FROM Competitor__c WHERE OpportunityId__c = :opportunity.Id ];

        Test.startTest();

        // Verify the Logic
        for (Competitor__c competitor : competitors) {
            competitor.Competitive_Advantage__c = 'Competitive Advantage Update';
        }
        update competitors;

        Test.stopTest();

        // Verify the Logic
        opportunity = [ SELECT Hidden_Competitor_Score__c, Hidden_Competitor_Score_Description__c
        FROM Opportunity WHERE Id = :opportunity.Id ];

        System.assertEquals(12, opportunity.Hidden_Competitor_Score__c,
                'opp_update_after_update_competitorsWithAndWithoutValuesSuccess : Hidden Competitor Score calculation unsuccessful. Hidden Competitor Score should be 12');

        System.assertNotEquals('', opportunity.Hidden_Competitor_Score_Description__c,
                'opp_update_after_update_competitorsWithAndWithoutValuesSuccess : Hidden Competitor Score Description calculation unsuccessful. Hidden Competitor Score Description should NOT be Empty');
    }

    /**
     * SCENARIO: Successfully delete Competitors with and without values oo Opportunity
     */
    @isTest static void opp_update_after_delete_competitorsWithAndWithoutValuesSuccess() {
        // Load's the Opportunity
        Opportunity opportunity = [ SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2' ];

        // Load's the Competitors
        List<Competitor__c> competitors = [ SELECT Id FROM Competitor__c
        WHERE OpportunityId__c = :opportunity.Id
        AND Competitor_Name__c = 'Competitor / Incumbent' ];

        Test.startTest();

        // Verify the Logic
        if (!competitors.isEmpty()) {
            delete competitors;
        }

        Test.stopTest();

        // Verify the Logic
        opportunity = [ SELECT Hidden_Competitor_Score__c, Hidden_Competitor_Score_Description__c
        FROM Opportunity
        WHERE Id = :opportunity.Id ];

        System.assertEquals(0,opportunity.Hidden_Competitor_Score__c,
                'opp_update_after_delete_competitorsWithAndWithoutValuesSuccess : Hidden Competitor Score calculation unsuccessful. Hidden Competitor Score should be 0');

        System.assertNotEquals('', opportunity.Hidden_Competitor_Score_Description__c,
                'opp_update_after_delete_competitorsWithAndWithoutValuesSuccess : Hidden Competitor Score Description calculation unsuccessful. Hidden Competitor Score Description should NOT be Empty');
    }

}