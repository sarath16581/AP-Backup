public class ctrlMyPostDeliveries {

    @TestVisible public static List<MyPostPreferences__x> prefs = new List<MyPostPreferences__x>();
    public Account acc {get;set;}
    @TestVisible public static MyPostPreferences__x deliPref{get;set;}
    private static String Above = 'Has Difficulty Reaching Above 1.5m';
    private static String Below = 'Has Difficulty Reaching Below 0.5m';
    private static String Both = 'Has Difficulty Reaching Above 1.5m and Below 0.5m';
    private static String Non = 'No Height Restrictions';
    Public String Message {get; set;}
    Public String Img {get ; set;}
    public ctrlMyPostDeliveries(ApexPages.StandardController stdController){

        //this.prefs = new List<MyPostPreferences__x>();
        this.acc = [select Id, APCN__pc from Account where Id = :stdController.getId()];
        if(acc.APCN__pc != null){
        prefs.addAll(new List<MyPostPreferences__x>([select APCN__c, HeightLessThan15M__c, HeightMoreThan05M__c, SafeDropInstruction__c, ParcelLockerRegistered__c from MyPostPreferences__x where APCN__c =: acc.APCN__pc]));
        //List<MyPostPreferences__x> temp = new List<MyPostPreferences__x>([select APCN__c, HeightLessThan15M__c, HeightMoreThan05M__c, SafeDropInstruction__c, ParcelLockerRegistered__c from MyPostPreferences__x where APCN__c =: acc.APCN__pc]);
            if(prefs.size() != 0){
                deliPref= prefs[0];
                if(deliPref.HeightLessThan15M__c == 'Y'){
                    if(deliPref.HeightMoreThan05M__c == 'Y'){
                        Message = Both;
                        Img = 'above-and-below.png';
                    }
                    else if(deliPref.HeightMoreThan05M__c == 'N'){
                        Message = Above;
                        Img = 'above.png';
                    }
                }
                else if(deliPref.HeightLessThan15M__c == 'N'){
                    if(deliPref.HeightMoreThan05M__c == 'Y'){
                        Message = Below;
                        Img = 'below.png';
                    }
                    else if(deliPref.HeightMoreThan05M__c == 'N'){
                        Message = Non;
                        Img = 'no-difficulty.png';
                    }
                }
                else{
                    Message = 'Never Set';
                    Img = 'N-A.png';
                }
            }
    	}
        
    }   
}