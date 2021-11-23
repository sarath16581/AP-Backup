/**
Description:Service Layer Logic for instantiation 
History    :2019-08-05 Neha -This apex class creating instance of Interface APT_IApttusCaseAutomation
**************************************************/
public class APT_ProposalCustomUtility {

    //Define a variable to check only one Case needs to be created on Proposal for any number of Workforce verification Line items.
    private static boolean firstRun = true;

    /*This is method is used to instantiate APT_IApttusCaseAutomation interface
    * @param classNameStr Name of the method to be called from the interface
    * @param List<Apttus_Proposal__Proposal__c> will get List of Proposal
    * @param Map<Id, Apttus_Proposal__Proposal__c> will get Map of Old Proposal
     */

    public static void autoCaseCreate(String classNameStr, List<Apttus_Proposal__Proposal__c> listProposal, Map<Id, Apttus_Proposal__Proposal__c> mapProposalOld) {
        try {
            System.debug('------- APT_ProposalCustomUtility autoCaseCreate ----- ');
            Type t = Type.forName(classNameStr);
            //Check for Class Name type and Boolean variable value
            System.debug('firstRun Before if : '+firstRun);
            if (t != null && firstRun) {
                firstRun = false;
                System.debug('firstRun After if : '+firstRun);
                Object objTmp = t.newInstance();
                APT_IApttusCaseAutomation iApttusImpl;
                //check if new interface is of type APT_IApttusCaseAutomation
                if (objTmp instanceof APT_IApttusCaseAutomation) {
                    iApttusImpl = (APT_IApttusCaseAutomation) objTmp;
                    System.debug('objTmp: '+objTmp);
                }

                System.debug('--------------Inside APT_ProposalCustomUtility Class ---------');
                // if there is proposal line items found, create a case.
                if (iApttusImpl != null && listProposal != null) {
                    iApttusImpl.caseCreate(listProposal, mapProposalOld);
                }
            }
        } catch (Exception ex) {
            System.debug('Class name is not valid. Class needs to implement either APT_IApttusCaseAutomation'+ex.getLineNumber()+' '+ex.getStackTraceString());
        }


    }
}