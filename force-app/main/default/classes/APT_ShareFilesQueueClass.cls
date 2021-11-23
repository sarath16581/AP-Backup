/*
@Description        : Queuable class to handle insertion of contentdocumentlink records while sharing file from
					  apttus contract to sf contract. This is to avoid the too many SOQL limit exception occured when handling too
					  many files.
================================ Modification Log =============================== 
Developer Name  Date            Comments
Ramtej          27/03/2019      Created
*/
public class APT_ShareFilesQueueClass implements Queueable {
	//List of contentdocument links to be inserted into the system initialized by the calling method
    public List<ContentdocumentLink> contentDocToBeInserted {get; set;}
    
    public void execute(QueueableContext context) {
        system.debug('contentDocToBeInserted in queue '+contentDocToBeInserted.size());
        if(contentDocToBeInserted.size() > 5){
            //if the insertion list has more than 5 records split the list into 2 lists
            List<ContentdocumentLink> listToInsert = new List<ContentdocumentLink>();
            List<ContentdocumentLink> listToEnqueue = new List<ContentdocumentLink>();
            for(Integer index = 0; index < contentDocToBeInserted.size(); index++){
                if(index < 5){
                    //list containing first 5 records to insert immediately
                    listToInsert.add(contentDocToBeInserted[index]);
                }
                else{
                    //list containing rest of the records to enqueue
                    listToEnqueue.add(contentDocToBeInserted[index]);
                }
            }
            
            system.debug('listToInsert '+listToInsert);
            system.debug('listToEnqueue '+listToEnqueue);
            //insert the list with first 5 records
            if(listToInsert != null && listToInsert.size() > 0){
                system.debug('inside insert '+listToInsert);
            	insert listToInsert; 
            }
            //enqueue the rest of the records for next insertion
            if(listToEnqueue != null && listToEnqueue.size() > 0){
                system.debug('inside enqueue '+listToEnqueue);
            	APT_ShareFilesQueueClass queuableClass = new APT_ShareFilesQueueClass();
                queuableClass.contentDocToBeInserted = listToEnqueue;
                //since chaining jobs is not allowed in test class, this line is skipped for test class runs
                if(!Test.isRunningTest()){
                 	system.enqueueJob(queuableClass);    
                }                
            }            
        }
        else{
            //insert directly if the passed list has less than 5 records
            insert contentDocToBeInserted;
        }
    }
    
}