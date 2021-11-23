/**
* @description Domain class to handle Customer Resolutions Credit Approvals
* @author Ranjeewa Silva
* @date 2021-05-13
* @group Domains
* @changelog
* 2021-05-13 - Ranjeewa Silva - Created.
*/
public inherited sharing class CustomerResCreditApprovalsDomain extends ApplicationDomain {

    public static final String APPROVAL_STEP_STATUS_PENDING = 'Pending';
    public static final String APPROVAL_STEP_STATUS_APPROVED = 'Approved';

    public static CustomerResCreditApprovalsDomain newInstance(List<SObject> sObjectList) {
        return (CustomerResCreditApprovalsDomain)ApplicationDomain.newInstance(CustomerResCreditApprovalsDomain.class, sObjectList);
    }

    /**
	 * These are the modules that the domain may use for triggers or method execution
	 */
    public override void registerModules() {
        // these module will be available for domain operations and trigger execution
        registerModule(CustomerResCreditApproversModule.class);
    }

    /**
	 * Trigger instantiation context
	 */
    public virtual class Constructor implements ApplicationDomain.IConstructable {
        public ApplicationDomain construct(List<SObject> sObjectList) {
            return CustomerResCreditApprovalsDomain.newInstance(sObjectList);
        }
    }

}