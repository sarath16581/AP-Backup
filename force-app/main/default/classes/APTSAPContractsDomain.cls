/**
* @description Domain class to handle Account related capability
* @author George Nguyen
* @group Domains
* @domain Account
* @changelog
* 2022-05-31 - George Nguyen - Created.
* 2022-09-29 - Noel Lim - Updated - relabelled from PersonAccountDomain to AccountDomain 
*/
public inherited sharing class APTSAPContractsDomain extends ApplicationDomain {

	public static APTSAPContractsDomain newInstance(List<SObject> sObjectList) {
		return (APTSAPContractsDomain)ApplicationDomain.newInstance(APTSAPContractsDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(APTSAPContractsSharingModule.class);

	}

}