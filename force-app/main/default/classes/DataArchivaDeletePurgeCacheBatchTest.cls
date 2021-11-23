/**
 * @description To cover code coverage for DataArchivaDeletePurgeCacheBatch
 * @author naveen.rajanna@auspost.com.au
 * @since 2021-10-26 
 */
@isTest 
public class DataArchivaDeletePurgeCacheBatchTest 
{
    static testMethod void testMethod1() 
    {
        List<Case> caseList = new List<Case>();
        for(Integer i=0 ;i <10;i++) {
            caseList.add(
              new Case(
                    Subject = 'This is a test case '+i
                )
            );
        }
        insert caseList;
        
        List<CEPARC__DataArchiva_Purge_Cache__c> pcacheList= new List<CEPARC__DataArchiva_Purge_Cache__c>();
        for(Integer i=0 ;i <10;i++)
        {
            pcacheList.add(
              new CEPARC__DataArchiva_Purge_Cache__c(
                    CEPARC__Object_Name__c = 'Case',
                    CEPARC__Id_Indexed__c = caseList[i].id,
                    CEPARC__Index_1__c = caseList[i].CaseNumber,
                    CEPARC__Index_2__c = null
                )
            );
        }
        insert pcacheList;
        
        Test.startTest();
            DataBase.executeBatch(new DataArchivaDeletePurgeCacheBatch());
        Test.stopTest();
    }
}