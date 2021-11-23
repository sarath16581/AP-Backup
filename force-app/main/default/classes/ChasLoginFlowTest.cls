@isTest(SeeAllData=true)
public class ChasLoginFlowTest {
    /**
* Success Case for : ChasFow
* */ 
    
    public static testMethod void testChasLoginFlow() {
        Boolean isSuccess = true; 
        
        try{
            Test.startTest();
            ChasLoginFlow.requestedCommunityIsCHAS(); 
            Test.stopTest();
        }catch(Exception e){
            System.debug('testChasLoginFlow()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess); 
    } 


   /* public static testMethod void testChasLoginFlow2() {
        Boolean isSuccess = true; 
        
        try{
            Test.startTest();
            List<List<sObject>> searchPCAList = null;
            String searchString = 'Consumer Help and Support';
            
            Network n =[ Select Id, Name from Network where Name = 'Consumer Help and Support'];
            System.debug('n='+n);
            String netWorkId=n.Id;//'0DB0k0000008OnDGAU';
            String userId = null;
            String searchQuery = 'FIND \'' + searchString + '*\' RETURNING User (id, name) WITH NETWORK IN (\''+netWorkId+'\'yyy)';
            //    'WHERE Status__c = \'Completed\' AND isDeleted__c= false )';
            // List<List<sObject>> soslResult= [FIND {Consumer Help and Support} RETURNING User (id, name) WITH NETWORK IN ('0DB0k0000008OnDGAU')];
            // 
              System.debug('searchQuery='+searchQuery);
            try{
                searchPCAList= search.query(searchQuery);
                System.debug('searchPCAList='+searchPCAList);
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getCause() );
                
            }
            if(null != searchPCAList && searchPCAList.size() > 0){
                for(List<sObject> objList : searchPCAList){
                    System.debug('objList ..='+objList);
                    for(sObject eachObject : objList){
                        userId = (String)eachObject.get('Id');
                    }
                }
            }
            System.debug('userId='+userId);
            User u = [SELECT Id from user where id=:userId];// isPortalEnabled=true LIMIT 1];
            System.runAs(u){
                
                ChasLoginFlow.requestedCommunityIsCHAS();  
            }
            
            Test.stopTest();
        }catch(Exception e){
            System.debug('testChasLoginFlow()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess); 
    } */
    

    
    /*  public static testMethod void testChasLoginFlow_success() {
Boolean isSuccess = true; 

try{

Test.startTest();
try{
PageReference pageRef = new PageReference('/HelpAndSupport/s/missing-or-lost-item?startURL=HelpAndSupport');
Test.setCurrentPage(pageRef);
ChasLoginFlow.requestedCommunityIsCHAS(); 
}catch(Exception ex){

}

Test.stopTest();

}catch(Exception e){
System.debug('testChasLoginFlow_success()::error==>'+e.getMessage());
isSuccess = false;
}
System.assert(isSuccess); 
}


public static testMethod void testChasLoginFlow_success2() {
Boolean isSuccess = true; 

try{

Test.startTest();
try{
PageReference pageRef = new PageReference('/HelpAndSupport/s/missing-or-lost-item');
Test.setCurrentPage(pageRef);
ChasLoginFlow.requestedCommunityIsCHAS(); 
}catch(Exception ex){

}

Test.stopTest();

}catch(Exception e){
System.debug('testChasLoginFlow_success2()::error==>'+e.getMessage());
isSuccess = false;
}
System.assert(isSuccess); 
}

public static testMethod void testChasLoginFlow_success3() {
Boolean isSuccess = true; 

try{

Test.startTest();
try{
ChasLoginFlow.requestedCommunityIsCHAS(); 
}catch(Exception ex){

}

Test.stopTest();

}catch(Exception e){
System.debug('testChasLoginFlow_success3()::error==>'+e.getMessage());
isSuccess = false;
}
System.assert(isSuccess); 
}


public static testMethod void testChasLoginFlow_success4() {
Boolean isSuccess = true; 

try{

Test.startTest();
try{
PageReference pageRef = new PageReference('/HelpAndSupport/s/missing-or-lost-item?startURL=abc');
Test.setCurrentPage(pageRef);
ChasLoginFlow.requestedCommunityIsCHAS(); 
}catch(Exception ex){

}

Test.stopTest();

}catch(Exception e){
System.debug('testChasLoginFlow_success4()::error==>'+e.getMessage());
isSuccess = false;
}
System.assert(isSuccess); 
}*/
    
    
    /**
* Success Case for : ChasFow
* */  
    /* public static testMethod void testChasLoginFlow_success5() {
Boolean isSuccess = true; 

try{

Test.startTest();
try{
//Network net = new Network();
//net.Name='Consumer Help and Support';
//insert net;
PageReference pageRef = new PageReference('/HelpAndSupport/s/missing-or-lost-item?startURL=abc');
Test.setCurrentPage(pageRef);
ChasLoginFlow.requestedCommunityIsCHAS(); 
}catch(Exception ex){

}

Test.stopTest();

}catch(Exception e){
System.debug('testChasLoginFlow_success5()::error==>'+e.getMessage());
isSuccess = false;
}
System.assert(isSuccess); 
}*/
}