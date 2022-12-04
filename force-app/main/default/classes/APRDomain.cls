/**
* @description Domain class for sharing APR records
* @author Ken McGuire
* @group Domains
* @domain APR__c
* @test APRDomain_Test
* @changelog
* 2022-12-05 - Ken McGuire - Created
*/
public  inherited sharing class APRDomain extends ApplicationDomain {
    
    public static APRDomain newInstance(List<SObject> sObjectList) {
        return (APRDomain)ApplicationDomain.newInstance(APRDomain.class, sObjectList);
    }

    /**
     * These are the modules that the domain may use for triggers or method execution
     */
    public override void registerModules() {
        // these module will be available for domain operations and trigger execution
        registerModule(SalesRecordSharingModule.class);
    }

}