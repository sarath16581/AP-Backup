/**
* @description Domain class for sharing proposals
* @author Ken McGuire
* @group Domains
* @domain Apttus__APTS_Agreement__c
* @test APTAgreementDomain_Test
* @changelog
* 2022-12-06 - Ken McGuire - Created
*/
public inherited sharing class APTAgreementDomain extends ApplicationDomain {

    public static APTAgreementDomain newInstance(List<SObject> sObjectList) {
        return (APTAgreementDomain)ApplicationDomain.newInstance(APTAgreementDomain.class, sObjectList);
    }

    /**
     * These are the modules that the domain may use for triggers or method execution
     */
    public override void registerModules() {
        // these module will be available for domain operations and trigger execution
        registerModule(SalesRecordSharingModule.class);

    }

}