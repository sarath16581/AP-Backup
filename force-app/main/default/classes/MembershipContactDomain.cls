/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : 
* @test : MembershipContactDomain_Test
* @changelog :
*/

public  inherited sharing class MembershipContactDomain extends ApplicationDomain {
public static MembershipContactDomain newInstance(List<SObject> sObjectList) {
      return (MembershipContactDomain)ApplicationDomain.newInstance(MembershipContactDomain.class, sObjectList);
   }

   /**
    * These are the modules that the domain may use for triggers or method execution
    */
   public override void registerModules() {
      // these module will be available for domain operations and trigger execution
      // each module will register their trigger entry points
      // additionally, each module will specify a list of fields that it monitors changes for.
      
       registerModule(MembershipContactModule.class);
   }



   /**
    * Trigger instantiation context
    */
   public virtual class Constructor implements ApplicationDomain.IConstructable {
      public ApplicationDomain construct(List<SObject> sObjectList) {
         return MembershipContactDomain.newInstance(sObjectList);
      }
   }
}