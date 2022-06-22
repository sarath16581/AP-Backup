/**
* @author Dheeraj Mandavilli
* @date 2020-03-25
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to fectch job records from PUD_Job__c object.
* NOTE: This class is used by PUD_FutureJobsPrintView VF Page upon clicking "Print Route" from Routes Detail Page. 
* 2020-03-25 - Dheeraj Mandavilli - Created
* 2020-05-25 - Dheeraj Mandavilli - Updated SOQL to accomdate new cosmetic changes on Vf page
* 2020-06-10 - Dheeraj Mandavilli - Included Time of Print Logic.
*/

public with sharing class PUD_JobsPrintFutureControllerX {
    public Date datename { get; set; }
    public String dateval { get; set; }
    public List<PUD_Job__c> jobTemplateList { get; set; }
    public String routeRecId { get; set; }
    public String depotName { get; set; }
    public String routeName { get; set; }
    public String printtype { get; private set; }
    public Boolean adhoc { get; set; }
    public String sdate { get; set; }
    private Integer sYear = 0;
    private Integer sMonth = 0;
    private Integer sDay = 0;
    private Integer sHour = 0;
    private Integer sMins = 0;
    private Integer sSecs = 0;
    private Datetime myDate = null;


    // Constructor    
    public PUD_JobsPrintFutureControllerX(ApexPages.StandardController sc) {

        //Get Id from Url
        routeRecId = ApexPages.currentPage().getParameters().get('id');

        //Get Date String from Url
        dateval = ApexPages.currentPage().getParameters().get('date');

        //Get Date Value from Date String
        datename = Date.valueOf(dateval);

        //Print Date on Duty Board with Current date and time in "DD-MM-YYY HH:MM:SS" format
        myDate = Datetime.now();
        sYear = datename.year();
        sMonth = datename.month();
        sDay = datename.day();
        sHour = myDate.hour();
        sMins = myDate.minute();
        sSecs = myDate.second();
        sdate = sDay + '-' + sMonth + '-' + sYear + ' ' + sHour + ':' + sMins + ':' + sSecs;

        //Get Type from Url
        printtype = ApexPages.currentPage().getParameters().get('type');

        //Initialize Variables
        depotName = '';
        routeName = '';
        adhoc = false;

        //Determine the type from and call accurate methods
        if (printtype == 'Adhoc') {
            jobTemplateList = getAdhocJobRecords(routeRecId, datename);
            adhoc = true;
        } else {
            jobTemplateList = getAllJobRecords(routeRecId, datename);
        }

        //Populate Fields on Header
        for (PUD_Job__c job : jobTemplateList) {
            depotName = job.Depot__r.Name;
            routeName = job.Route_Lookup__r.Name;
        }
    }
    @TestVisible private static List<PUD_Job__c> getAdhocJobRecords(String routeId, Date dateVal) {

        List<PUD_Job__c> jobs = new List<PUD_Job__c>();
        for (PUD_Job__c job : PUDJobsSelector.newInstance().selectByRouteIdAndDate(routeId, dateVal, new Set<Object>())) {
            if (job.Booking_Record_Type__c != 'Other') {
                jobs.add(job);
            }
        }
        return jobs;
    }

    @TestVisible private static List<PUD_Job__c> getAllJobRecords(String routeId, Date dateVal) {
        return PUDJobsSelector.newInstance().selectByRouteIdAndDate(
                routeId,
                dateVal,
                new Set<Object>{
                        PUDJobsSelector.Options.WITH_DEPOT,
                        PUDJobsSelector.Options.WITH_ROUTE
                }
        );
    }
}