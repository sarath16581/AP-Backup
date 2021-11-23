/**
* @description Domain class to handle Customer Resolutions credit approver configuration capability
* @author Ranjeewa Silva
* @date 2021-05-13
* @group Domains
* @domain CustomerResolutions
* @changelog
* 2021-05-13 - Ranjeewa Silva - Created.
*/

public inherited sharing class CustomerResCreditApprovalMatrixDomain extends ApplicationDomain {

    public static final String DEFAULT_PRODUCT_FAMILY = 'default';
    public static final String DEFAULT_PRODUCT_SUB_CATEGORY = 'default';

    public static CustomerResCreditApprovalMatrixDomain newInstance(List<SObject> sObjectList) {
        return (CustomerResCreditApprovalMatrixDomain)ApplicationDomain.newInstance(CustomerResCreditApprovalMatrixDomain.class, sObjectList);
    }

    /**
	 * These are the modules that the domain may use for triggers or method execution
	 */
    public override void registerModules() {
        // these module will be available for domain operations and trigger execution
        registerModule(CustomerResCreditApprovalMatrixModule.class);
    }

    /**
	 * Trigger instantiation context
	 */
    public virtual class Constructor implements ApplicationDomain.IConstructable {
        public ApplicationDomain construct(List<SObject> sObjectList) {
            return CustomerResCreditApprovalMatrixDomain.newInstance(sObjectList);
        }
    }
}