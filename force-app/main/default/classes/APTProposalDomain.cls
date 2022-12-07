/**
* @description Domain class for sharing proposals
* @author Ken McGuire
* @group Domains
* @domain Apttus_Proposal__Proposal__c
* @test APTProposalDomain_Test
* @changelog
* 2022-12-01 - Ken McGuire - Created
*/
public inherited sharing class APTProposalDomain extends ApplicationDomain {

    public static APTProposalDomain newInstance(List<SObject> sObjectList) {
        return (APTProposalDomain)ApplicationDomain.newInstance(APTProposalDomain.class, sObjectList);
    }

    /**
     * These are the modules that the domain may use for triggers or method execution
     */
    public override void registerModules() {
        // these module will be available for domain operations and trigger execution
        registerModule(SalesRecordSharingModule.class);

    }

}