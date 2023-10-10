/**************************************************
Type:       Trigger for Task Object
Purpose:    Update associated Account with Last Activity Date
History:
--------------------------------------------------
19.10.2011  Carl Vescovi(Australia Post contractor)  Created
08.11.2011  Carl Vescovi  Added the before trigger logic
02.01.2014  Louis Wang (Bluewolf)  Removed concept of Partner / Individual, such that standard Account-Contact is reestablished
14 Jan 2016  Christopher Henschke  Added call to updateAssociatedCaseMilestones method for First Agent Response
8 Sep 2017  Adrian Recio  Included idetifyWorkDay method call to populate workday assignment based on assigned to field
11 Sep 2017  Adrian Recio  Removed overlong uncessary debug logs
02 Oct 2017  Angelo Rivera  Minor Work MWT0004521 - Added method that updates Case Owner and Status depending on task update
2018-12-01  nathan.franklin@auspost.com.au  Add tracking of Case Activities for First Customer Response tracking
2020-08-12  Suman Gunaganti (STP-2550) Moved case milestone update logic to after update section.
**************************************************/
trigger TaskTrigger on Task (before insert, before update, after insert, after update) {

     system.debug('Task trigger: ' + SystemSettings__c.getInstance().Disable_Triggers__c);

    if (!SystemSettings__c.getInstance().Disable_Triggers__c) 
    {       
        if(trigger.isInsert){
            if(trigger.isBefore){    
                // Adrian Recio / Populate work day value 
                // 8/9/2017
                ActivityUtil.identifyWorkDay(trigger.new,new List<Event>());
                system.debug('Task: isInsert & isBefore');
            }
            
            if(trigger.isAfter){
                ActivityUtil.updateLastActivityFromTask(trigger.new);
                ActivityUtil.sendSMSForTasks(trigger.new);

                ActivityUtil.updateAssociatedCaseMilestones(trigger.new);

                //Suman G: 16/12/2020: update sales first activity on Lead
                ActivityUtil.updateLeadFirstActivityFromTask(trigger.new);

                // Added for Minor Work MW0002852 Post call web survey for Voice Contact Centre
                // It will call checkTaskNPSVoiceSurvey method to pass all inserted tasks to validate
                // and identified all qualified tasks using business criterias for NPS Voice Survey
                // and send information to TIBCO
                NPSVoiceSurveyUtil.checkTaskNPSVoiceSurvey(trigger.new,null);
                
                // Given agent make an outbound call to contact customer
                // And cases are under customer centre
                // Then create CaseActivity record for SLA Reporting
                SLAReportingUtility.generateCaseActivity(trigger.new);
                system.debug('Task: isInsert & isAfter');
            }
        }

        if(trigger.isUpdate){
            if(trigger.isBefore){
                // Adrian Recio / Populate work day value 
                // 8/9/2017
                ActivityUtil.identifyWorkDay(trigger.new,new List<Event>());
                system.debug('Task: isUpdate & isBefore');
            }
            
            if(trigger.isAfter){
                ActivityUtil.updateLastActivityFromTask(trigger.new);
                StarTrackTaskHandler.updateTasksRelatedCaseRecord(trigger.new);
                // Added for Minor Work MW0002852 Post call web survey for Voice Contact Centre
                // It will call checkTaskNPSVoiceSurvey method to pass all updated tasks to validate
                // and identified all qualified tasks using business criterias for NPS Voice Survey
                // and send information to TIBCO
                NPSVoiceSurveyUtil.checkTaskNPSVoiceSurvey(trigger.new,trigger.oldMap);
                system.debug('Task: isUpdate & isAfter');
				CSQUtilities.updatePickUpLocation(trigger.oldMap, trigger.newMap);
            }
        } 
    }
}