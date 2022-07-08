/**
* @description Domain class to handle common logic for all case types
* @author Harry Wang
* @date 2022-06-21
* @group Domain
* @domain ICPS
* @changelog
* 2022-06-21 - Harry Wang - Created
*/

public inherited sharing class ICPSDomain extends ApplicationDomain{
    public static ICPSDomain newInstance(List<SObject> sObjectList) {
        return (ICPSDomain)ApplicationDomain.newInstance(ICPSDomain.class, sObjectList);
    }
    /**
     * These are the modules that the domain may use for triggers or method execution
     */
    public override void registerModules() {
        // these module will be available for domain operations and trigger execution
        // each module will register their trigger entry points
        // additionally, each module will specify a list of fields that it monitors changes for.
        registerModule(ICPSAutomationModule.class);
    }
    /**
     * Trigger instantiation context
     */
    public virtual class Constructor implements ApplicationDomain.IConstructable {
        public ApplicationDomain construct(List<SObject> sObjectList) {
            return ICPSDomain.newInstance(sObjectList);
        }
    }
}