global class CalcRevByOrgBatch implements Database.Batchable<sObject>, Database.Stateful{

/*------------------------------------------------------------  
Author:        Mathanan Yogaratnam
Company:       Salesforce.com
Description:   Batchable class for calculating the summary values and populating the Revenue by Organisation object
                - Retrieve the records from the Target and Revenue object that had been updated in the window specified in the custom setting as query locator
                - Invokes the CalcRevOrg class to calculate the revenue by org for each of the organisations in the T&R recs
                - Logs any errors in the Application Log object
                - Logs completion message in Application Log object
        
Test Class:
History
<Date>      <Authors Name>     <Brief Description of Change>
27-03-2014  Mathanan Yogaranam  Initial Release
23-05-2014  Mathanan Yogaratnam Specified additional custom setting (start offset for calculation window). 
                                This was introduced to overcome query timeout issues experienced in production.
                                The addtional parameter helps narrow the scope of the query and return fewer results.
------------------------------------------------------------*/

    global Integer num_of_tr_recs; //number of T&R revenue records evaluated
    global Integer num_of_revOrg_rec_created; //number of output Revenue by Org records created
    global Integer num_of_revOrg_rec_updated; //number of output Revenue by Org records updated
    
    global Integer num_of_revOrg_rec_create_errors; //number of output Revenue by Org records error on create
    global Integer num_of_revOrg_rec_update_errors; //number of output Revenue by Org records error on update
    global DateTime jobStartDateTime;
    
    global DateTime calcWindowStartTime;
    global DateTime calcWindowEndTime;
    BatchJobSettings__c settings;
    

    global Database.querylocator start(Database.BatchableContext BC){

        //initialise variables
        num_of_tr_recs = 0; 
        num_of_revOrg_rec_created = 0; 
        num_of_revOrg_rec_updated = 0; 
    
        num_of_revOrg_rec_create_errors = 0; 
        num_of_revOrg_rec_update_errors = 0; 
    
        settings = BatchJobSettings__c.getInstance();
            
        jobStartDateTime = DateTime.now();
        
        //changes made on 23-05-2014
        calcWindowEndTime = DateTime.now().addDays(-1*integer.valueof(settings.OrgRevCalcWindowOffset__c));
        calcWindowStartTime = calcWindowEndTime.addDays(-1*integer.valueof(settings.OrgRevCalcWindow__c));
        
        
        //query where matching active seniors card with same last names are retrieved
        String query = 'SELECT Name, Id, Organisation__c' 
            +' FROM Budget_and_Revenue__c where SystemModStamp <= :calcWindowEndTime and SystemModStamp > :calcWindowStartTime'
            + ' order by  Organisation__c';


        System.debug(Logginglevel.DEBUG, 'Query Statement length: ' + query.length());
        System.debug(Logginglevel.DEBUG, 'Query: ' + query);
        
        return Database.getQueryLocator(query);   

    }
    
    global void execute(Database.BatchableContext BC, List<Budget_and_Revenue__c> scope){
    
        System.Debug('CalcRevByOrgBatch Execute. Scope size: ' + scope.size());
        //set up cal class instance
        CalcRevByOrg calc = new CalcRevByOrg(scope);
        
        //execute calculations
        calc.calcAndUpdateRevOrg();
        
        //check for update errors and update log
        if (calc.RevOrgUpdateError){
            
            GlobalUtility.logMessage('Error', 'CalcRevByOrgBatch', 'execute()', BC.getJobId(), 'AsyncApexJob Id', calc.erroredUpdateRecsString, '',null , 0);           
            
        }
        
        //check for create errors and update log    
        if (calc.RevOrgCreateError){
            
            GlobalUtility.logMessage('Error', 'CalcRevByOrgBatch', 'execute()', BC.getJobId(), 'AsyncApexJob Id', calc.erroredCreateRecsString, '',null , 0);           
            
        }
        
        //update counters
        num_of_tr_recs += calc.num_of_tr_recs;
        num_of_revOrg_rec_created += calc.num_of_revOrg_rec_created;
        num_of_revOrg_rec_updated += calc.num_of_revOrg_rec_updated;
        num_of_revOrg_rec_create_errors += calc.num_of_revOrg_rec_create_errors;
        num_of_revOrg_rec_update_errors += calc.num_of_revOrg_rec_update_errors;
    
    }
    
    global void finish(Database.BatchableContext BC){
    
        //******************Log the results of the batch in Application Log**********************
        
        String jobmsg;
        String logtype;

        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                                TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id = :BC.getJobId()];
                                
                                
        if (num_of_revOrg_rec_create_errors == 0 && num_of_revOrg_rec_update_errors == 0 && jobInfo.NumberOfErrors == 0 ){

            logType = 'Info';
            jobmsg = 'CalcRevByOrgBatch Job Success\n';
        }else{
            logType = 'Warning';
            jobmsg = 'CalcRevByOrgBatch Job Completed with errors\n';
        }

        jobmsg += 'Job Id: ' + jobInfo.Id + ' Start Time: ' + jobStartDateTime + + ' End Time: '+ DateTime.now() +'\n';
        jobmsg += 'Asyncjob parameters Status: ' + jobInfo.Status + ' Job Batches Processed: ' + jobInfo.JobItemsProcessed + ' Total Batches Processed: ' + jobInfo.TotalJobItems + ' Number Of Errored batches: ' +jobInfo.NumberOfErrors + '\n';
        jobmsg += 'Submitted by user: ' + UserInfo.getName() + '\n\n';
        
        //added 23-05-2014
        jobmsg += 'Custom setting OrgRevCalcWindowOffset__c: ' + settings.OrgRevCalcWindowOffset__c + '\n';
        jobmsg += 'Custom setting OrgRevCalcWindow__c: ' + settings.OrgRevCalcWindow__c + '\n';
        jobmsg += 'calcWindowEndTime: ' + calcWindowEndTime + '\n';
        jobmsg += 'calcWindowStartTime: ' + calcWindowStartTime + '\n\n';
        
        jobmsg += 'DML Statements: ' + Limits.getDmlStatements() + ' Limit: ' + Limits.getLimitDMLStatements() + '\n';
        jobmsg += 'DML Rows: ' + Limits.getDmlRows() + ' Limit: ' + Limits.getLimitDMLRows() + '\n';
        jobmsg += 'SOQL Operations : ' +  Limits.getQueries() + ' Limit: ' + Limits.getLimitQueries() + '\n';
        jobmsg += 'Heap size: ' +  Limits.getHeapSize() + ' Limit: ' + Limits.getLimitHeapSize() + '\n';
        jobmsg += 'CPU Time: ' + Limits.getCpuTime() + ' Limit: ' + Limits.getLimitCpuTime() + '\n\n';

        jobmsg += 'Number of Target and Revenue Records assessed: ' + num_of_tr_recs + '\n';
        jobmsg += 'Number of Revenue by Org Records created: ' + num_of_revOrg_rec_created + '\n';
        jobmsg += 'Number of Revenue by Org Records errored on create: ' + num_of_revOrg_rec_create_errors + '\n';
        jobmsg += 'Number of Revenue by Org Records updated: ' + num_of_revOrg_rec_updated + '\n';
        jobmsg += 'Number of Revenue by Org Records errored on update: ' + num_of_revOrg_rec_update_errors + '\n';
        
        long jobExecTime = 0;
        jobExecTime = DateTime.now().getTime() - jobStartDateTime.getTime();

        GlobalUtility.logMessage(logType, 'CalcRevByOrgBatch', 'finish()', jobInfo.Id, 'AsyncApexJob Id', jobmsg.left(32768), '', null, jobExecTime); //32768 is max length for long text field
                
    }
        
}