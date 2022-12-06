@isTest
public class BGSCaseMilestone_Test {
    private static final String SSSW_AGENT_PROFILE = 'SSSW - Service Agent';
    private static final String BGS_ENTITLEMENT_PROCESS = 'Standard Entitlement BGS - VIC';

    testMethod
        public static void testBGSCases()
    {
        Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_AGENT_PROFILE LIMIT 1];
        System.runAs(TestUtility.createUser('Wayne',prof.id,null))
        {
            // Setup the Entitlement Organisation
            Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
            Account bgsEntitlement = TestUtility.createBusinessAccount(BGSConstants.BGS_ENTITLEMENT_STANDARD,
                    accRecTypeMap.get('Organisation').getRecordTypeId());
            // HACK: due to SSSW code expecting an Account with the following name
            Account ssswEntAccount = TestUtility.createBusinessAccount(SSSWConstants.ENTITLEMENT_ACC,
                    accRecTypeMap.get('Organisation').getRecordTypeId());
            List<Account> insertAccounts = new List<Account> {bgsEntitlement, ssswEntAccount};
            Database.insert(insertAccounts);

            // Create the Entitlement as part of the Organisation
            SlaProcess sla = [SELECT Id, Name, IsActive, IsVersionDefault
            FROM SlaProcess
            WHERE IsVersionDefault = true
            AND Name =: BGS_ENTITLEMENT_PROCESS
            LIMIT 1 ];

            // create each of the Entitlement Time Zones
            List<String> entNames = new List<String> {
                    BGSConstants.BGS_ENTITLEMENT_VIC,
                    BGSConstants.BGS_ENTITLEMENT_NSW,
                    BGSConstants.BGS_ENTITLEMENT_QLD,
                    BGSConstants.BGS_ENTITLEMENT_WA,
                    BGSConstants.BGS_ENTITLEMENT_SA,
                    BGSConstants.BGS_ENTITLEMENT_NT,
                    BGSConstants.BGS_ENTITLEMENT_ACT,
                    BGSConstants.BGS_ENTITLEMENT_TAS
            };
            List<String> mailingStates = new List<String>{
                    'VIC', 'NSW', 'QLD', 'WA', 'SA', 'NT', 'ACT', 'TAS'
            };

            // create a Contact per state to test the routing
            List<Contact> caseContacts = new List<Contact>();
            // the Entitlement records
            List<Entitlement> entitlements = new List<Entitlement>();
            for(Integer i = 0; i < mailingStates.size(); ++i)
            {
                // create a contact per state
                String stateName = mailingStates[i];
                Contact con = TestUtility.createContact('Test' + i,'Tester','bruce@wayne.com', null);
                con.MailingState = stateName;
                con.MailingPostalCode = '3000';
                caseContacts.add(con);

                // create each state's entitlement
                String entName = entNames[i];
                Entitlement ent = TestUtility.createEntitlement(entName,
                        Date.Today(),Date.Today() + 365,
                        'Phone Support', sla.Id, bgsEntitlement.Id);
                entitlements.add(ent);
            }
            insert entitlements;
            insert caseContacts;

            Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
            Id serviceDeliveryRT = caseRecTypeMap.get(BGSConstants.SERVICE_DELIVERY_NAME).getRecordTypeId();

            // create a Case per contact to test the routing
            List<Case> testCases = new List<Case>();
            for(Contact con: caseContacts)
            {
                Case csRec = TestUtility.createCase('Enquiry', 'In Progress', 'General Enquiry', null, con.Id, serviceDeliveryRT);
                testCases.add(csRec);
            }

            // create a Service Delivery Case
            Test.startTest();
            insert testCases;
            Test.stopTest();

            // store all the cases to assert that everything's been created
            List<Id> caseIds = new List<Id>();
            for(Case csRec:testCases)
            {
                caseIds.add(csRec.Id);
            }

            // query the results

            // check that milestones have been created
            List<CaseMilestone> milestones = [SELECT Id, CaseId, MilestoneType.Name FROM CaseMileStone WHERE CaseId =: caseIds];
            System.debug('BGSCaseMilestone_Test:: Milestones' + milestones);
            System.assert(milestones.size() > 0, 'Expected Milestones to be attached to case:' + milestones);

            /*
            // check that there's a case for each entitlement
            List<Case> casesWithEntitlements = [SELECT Id, EntitlementId, Entitlement.Name FROM Case WHERE Id =: caseIds];
            Set<String> appliedEntitlements = new Set<String>();
            for(Case csResult:casesWithEntitlements)
            {
                appliedEntitlements.add(csResult.Entitlement.Name);
            }
            // finally, check that each entitlement has been applied once
            for(String entName:entNames)
            {
                System.assert(appliedEntitlements.contains(entName), entName + ' was not applied');
            }
            
             */

        }

    }
}