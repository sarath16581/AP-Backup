/**
 * @author Emmanuel Yap
 * @date 2021-09-10
 * @description Controller class for Print Duty Template
 * @changelog
 * 2021-09-10 - Emmanuel Yap - Created
*/

public class TDF_DutyTemplatePrintControllerY {

    private String dutyTemplateId{get;set;} 
    private List<Job_Template__c> jtlist{get;set;}
    public Route_Template__c routeTemplate{get;set;}
    public List<JobTemplateWrapper> jobTemplateList{get;set;}
    public List<BreakWrapper> breakList{get;set;}
    public String startTime{get;set;}
    public String endTime{get;set;}
    
	// Constructor    
    public TDF_DutyTemplatePrintControllerY(ApexPages.standardController sc){
        Boolean startTimeSet = false;
        //Get Id
        startTime = '';
        endTime = '';
        breakList = new List<BreakWrapper>();
        jobTemplateList = new List<JobTemplateWrapper>();
        dutyTemplateId = Apexpages.currentPage().getParameters().get('id').escapeHtml4();
        
        //Get file name for save default
        routeTemplate = TDF_RouteTemplateUtil.getRouteTemplateFromID(dutyTemplateId);
        String fileName = routeTemplate.Name;      
        Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + fileName + '.pdf');            
        
        jtlist = TDF_RouteTemplateUtil.getJobTemplateFromDutyTemplateId(dutyTemplateId);
        for(Job_Template__c jt : jtlist){
            JobTemplateWrapper wrapper =  new JobTemplateWrapper(jt);
            if(!startTimeSet){
                startTime = wrapper.arrive;
                startTimeSet = true;
            }
            endTime = wrapper.depart;
            jobTemplateList.add(wrapper);
        }
        for(Job_Template__c jt : jtlist){
            if(jt.Activity_Type__c == 'Rest Break'){
                BreakWrapper breakWrapper = new  BreakWrapper(jt);
                breakWrapper.active = breakWrapper.active + ' ' + startTime + ' - ' +endTime;
                breakList.add(breakWrapper);
            }
        }
        
    }

    public class JobTemplateWrapper {
        public Job_Template__c jt {get; set;}
        public String arrive {get; set;}
        public String location {get; set;}
        public String address {get; set;}
        public String activity {get; set;}
        public String docks {get; set;}
        public String depart {get; set;}
        public String jobInstructions {get;set;}
        public String siteInstructionNotes {get;set;}
        public String siteInstructions {get;set;}
        
        //This is the contructor method. When we create a new wrapAccount object we pass a Account that is set to the acc property. We also set the selected value to false
        public JobTemplateWrapper(Job_Template__c a) {
            jt = a;
            arrive = a.Start_Time__c;
            location = a.Location__r.Name;
            address = a.Location__r.Street__c + ' ' + a.Location__r.City__c;
            activity = a.Activity_Type__c;
            docks = a.Dock_Number__c;

            Time departTime = Time.newInstance(
                                Integer.valueOf(a.Start_Time__c.substring(0,2)),
                                Integer.valueOf(a.Start_Time__c.substring(2))
                                ,0,0);

            departTime = departTime.addMinutes(Integer.valueOf(a.Duration__c));

            depart = String.valueOf(departTime).substring(0,2) 
                   + String.valueOf(departTime).substring(3,5);
            jobInstructions = a.Job_Instructions__c;
            siteInstructionNotes = a.Location__r.Site_Instruction_Notes__c;
            siteInstructions = a.Location__r.Site_Instructions__c;
        }
    } 

    public class BreakWrapper {
        public Job_Template__c jt {get; set;}
        public String breakTime {get; set;}
        public String location {get; set;}
        public String active {get; set;}
        public String activity {get; set;}
        
        //This is the contructor method. When we create a new wrapAccount object we pass a Account that is set to the acc property. We also set the selected value to false
        public BreakWrapper(Job_Template__c a) {
            jt = a;
            breakTime = a.Start_Time__c;
            location = a.Location__r.Name;
            active = a.Route_Template__r.Active_Route_Days__c;
            activity = a.Activity_Type__c;
            Time departTime = Time.newInstance(
                                Integer.valueOf(a.Start_Time__c.substring(0,2)),
                                Integer.valueOf(a.Start_Time__c.substring(2))
                                ,0,0);

            departTime = departTime.addMinutes(Integer.valueOf(a.Duration__c));

            breakTime = a.Start_Time__c.substring(0,2) 
                      + ':' + a.Start_Time__c.substring(2) 
                      + ' - ' + String.valueOf(departTime).substring(0,2) 
                      + ':' + String.valueOf(departTime).substring(3,5);
        }
    } 
}