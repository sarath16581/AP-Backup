/**
* @description Domain class for sharing SAP Contracts
* @author Ken McGuire
* @group Domains
* @domain APT_SAP_Contracts__c
* @test APTSAPContractsDomain_Test
* @changelog
* 2022-12-01 - Ken McGuire - Created
*/
public inherited sharing class APTSAPContractsGenericDomain extends ApplicationDomain {

	public static APTSAPContractsGenericDomain newInstance(List<SObject> sObjectList) {
		return (APTSAPContractsGenericDomain)ApplicationDomain.newInstance(APTSAPContractsGenericDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(SalesRecordSharingModule.class);

    }
}