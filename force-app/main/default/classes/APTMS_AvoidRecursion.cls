/*
* Created by: Apttus Managed Services
* Created Date: 08/05/2017
* Author: Ravi Chhatrala
* Apttus Case #: 00210442
* Last Modified by: Ravi Chhatrala
* Last Modified Date: 08/05/2017
*/

/*
* This Handler class is called from 'opportunityTrigger_16112011' trigger of Opportunity object
* This class is developed to avoid recursion execution of the trigger.
*/

public Class APTMS_AvoidRecursion{
    public static boolean firstRun = true;
    public static boolean isFirstRun(){
        if(firstRun){
          firstRun = false;
          return true;
        }else{
            return firstRun;
        }
    }
}