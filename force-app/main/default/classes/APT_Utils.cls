/**
Description: Utility class

Created By - Mausam Padhiyar
Created Date - 24th Aug,2015
 */
public without sharing class APT_Utils {
    
    public static Boolean isAutoApproval;
    public static Set<String> errorMessagesSet;
    
    private static Map<String, Schema.SObjectField> lineItemSObjectFieldsMap;
    
    /**
        This method will return error message.
     */
    public static String getErrorMessage(Exception e) {
       try {
            String exceptionType = e.getTypeName();
            String errorMessage = APT_Constants.ERRORMESSAGE_1;
            
            if(exceptionType.equalsIgnoreCase(APT_Constants.SYSTEMDMLEXCEPTION)) {
                errorMessage = e.getDmlMessage(0);
            } else if(exceptionType.equalsIgnoreCase(APT_Constants.SYSTEMLISTEXCEPTION) || exceptionType.equalsIgnoreCase(APT_Constants.SYSTEMMATHEXCEPTION) || exceptionType.equalsIgnoreCase(APT_Constants.SYSTEMNOACCESSEXCEPTION) ||
                exceptionType.equalsIgnoreCase(APT_Constants.SYSTEMNULLPOINTEREXCEPTION) || exceptionType.equalsIgnoreCase(APT_Constants.SYSTEMQUERYEXCEPTION) || exceptionType.equalsIgnoreCase(APT_Constants.SYSTEMSTRINGEXCEPTION) ||
                exceptionType.equalsIgnoreCase(APT_Constants.SYSTEMVISUALFORCEEXCEPTION) || exceptionType.equalsIgnoreCase(APT_Constants.SYSTEMTYPEEXCEPTION)) {
                
                errorMessage = e.getMessage();
            }
            
            return errorMessage;
        } catch(Exception ex) {
            system.debug('Exception-'+ex);
            return null;
        }
    }
    
    /**
        This method will return visual force page url prefix based on logged in user
     */
    public static String getVFPageUrlPrefix() {
        try {
            if((UserInfo.getUserType()).equalsIgnoreCase(APT_Constants.STRING_PARTNER) || (UserInfo.getUserType()).equalsIgnoreCase(APT_Constants.STRING_POWER_PARTNER)) {
                return APT_Constants.STRING_PRM;
            } else {
                return APT_Constants.STRING_APEX;
            }
        } catch(Exception ex) {
            system.debug('Exception-'+ex);
            return null;
        }
    }
    /**
        This method will return if logged in user is partner user or not?
     */
    public static Boolean isPartnerUser() {
        if((UserInfo.getUserType()).equalsIgnoreCase(APT_Constants.STRING_PARTNER) || (UserInfo.getUserType()).equalsIgnoreCase(APT_Constants.STRING_POWER_PARTNER)) {
            return true;
        } else {
            return false;
        }
    }
    
    /**
        This method will return approver user names list. 
     */
    public static List<String> getApproversList(String productConfigId, String proposalOwnerName) {
        List<String> approversList = new List<String>();
        errorMessagesSet = new Set<String>();
        isAutoApproval = false;
        
        DateTime currentDateTime = System.now();
        
        try {
            if(!Test.isRunningTest())
            {
                Boolean response = Apttus_Approval.ApprovalsWebService.previewApprovals(APT_Constants.PRODUCT_CONFIGURATION_OBJECT, productConfigId);   
            }   
            List<Apttus_Approval__Approval_Request__c> approvalRequestList = [Select Apttus_Approval__Assigned_To_Type__c, Apttus_Approval__Assigned_To_Id__c,
                Apttus_Approval__Assigned_To_Link__c, Apttus_Approval__Approval_Status__c 
                From Apttus_Approval__Approval_Request__c Where Apttus_CQApprov__CartId__c = : productConfigId AND CreatedDate >= :currentDateTime 
                order by Apttus_Approval__StepSequence__c];
            
            if(!approvalRequestList.isEmpty()) {
                List<Id> userIdList = new List<Id>();
                for(Apttus_Approval__Approval_Request__c request : approvalRequestList) {
                    if((request.Apttus_Approval__Approval_Status__c).equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_NOT_SUBMITTED) && ((request.Apttus_Approval__Assigned_To_Type__c).equalsIgnoreCase(APT_Constants.STRING_USER1) || 
                        (request.Apttus_Approval__Assigned_To_Type__c).equalsIgnoreCase(APT_Constants.STRING_RELATED_USER) || (request.Apttus_Approval__Assigned_To_Type__c).equalsIgnoreCase(APT_Constants.STRING_CUSTOM_USER))) {
                        userIdList.add(request.Apttus_Approval__Assigned_To_Id__c);
                    }
                }
                
                Map<Id, User> userMap = new Map<Id, User>([Select UserRoleId, UserRole.Name, Name From User Where Id IN :userIdList]);
                
                for(Apttus_Approval__Approval_Request__c request : approvalRequestList) {
                    if((request.Apttus_Approval__Approval_Status__c).equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_NOT_SUBMITTED) && ((request.Apttus_Approval__Assigned_To_Type__c).equalsIgnoreCase(APT_Constants.STRING_USER1) || 
                        (request.Apttus_Approval__Assigned_To_Type__c).equalsIgnoreCase(APT_Constants.STRING_RELATED_USER) || (request.Apttus_Approval__Assigned_To_Type__c).equalsIgnoreCase(APT_Constants.STRING_CUSTOM_USER))) {
                        User u = userMap.get(request.Apttus_Approval__Assigned_To_Id__c);
                        if(String.isNotBlank(proposalOwnerName) && proposalOwnerName.equalsIgnoreCase(u.Name )) {
                            isAutoApproval = true;
                        }
                        
                        String approver = APT_Constants.EMPTY_STRING;
                    
                        if(String.isNotBlank(u.UserRoleId)) {
                          //  approver = approver + u.UserRole.Name + ', ';
                            approver = u.UserRole.Name + APT_Constants.SEPARATOR_COMMA_SPACE;
                        }
                        
                      //  approver = approver + u.Name;
                        approver = u.Name;
                        approversList.add(approver);    
                    } else if((request.Apttus_Approval__Approval_Status__c).equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_NOT_SUBMITTED)) {
                        approversList.add(request.Apttus_Approval__Assigned_To_Link__c);
                    }
                }
                
                if(approversList.size() > 1) {
                    isAutoApproval = false;    
                }
                
                deleteApprovalRequests(approvalRequestList);
            }
        } catch(Exception e) {
            system.debug(logginglevel.error,e);
            system.debug(e);
            errorMessagesSet.add(APT_Constants.ERROR_MESSAGE_2 + APT_Constants.ERROR_MESSAGE_3);
            //errorMessagesSet.add('ERROR: ' + e.getMessage());
        }
        
        return approversList;
    }
    
    /**
        This method will delete approval request
     */
    @TestVisible private static void deleteApprovalRequests(List<Apttus_Approval__Approval_Request__c> approvalRequestList) {
        delete approvalRequestList; 
    }
    
    /**
        This method will submit approval request
     */
    @TestVisible private static void submitForApprovals(String productConfigId, String submissionComments) {
        if(!Test.isRunningTest())
        {
            if(!(String.isEmpty(submissionComments)) && String.isNotBlank(submissionComments)) {
                    Apttus_Approval.SubmissionComments comments = Apttus_Approval.ApprovalsWebService.checkIfCommentsRequired(productConfigId, APT_Constants.PRODUCT_CONFIGURATION_OBJECT);    
    
                if(comments != null) {
                    comments.setProcessComment(submissionComments);
                
                    Apttus_Approval.ApprovalsWebService.submitForApprovalsWithComments(APT_Constants.PRODUCT_CONFIGURATION_OBJECT, productConfigId, comments);
                } else {
                    Apttus_Approval.ApprovalsWebService.submitForApprovals(APT_Constants.PRODUCT_CONFIGURATION_OBJECT, productConfigId); 
                }
            } else {
                Apttus_Approval.ApprovalsWebService.submitForApprovals(APT_Constants.PRODUCT_CONFIGURATION_OBJECT, productConfigId); 
            }
        }
    }

    /**
        This method will fetch custom metadata type and save it into set
    */
    @TestVisible public static Set<string> getSinglePLINetworkTypes()
    {
        Set<string> setValues = new Set<string>();
        List<APT_ST_Custom_Settings__mdt> stCustomSettings = [SELECT APT_Single_PLI_Network_Types__c FROM APT_ST_Custom_Settings__mdt];

        if(stCustomSettings != null && stCustomSettings.size()>0 && stCustomSettings[0].APT_Single_PLI_Network_Types__c != null)
        {
            List<string> values = stCustomSettings[0].APT_Single_PLI_Network_Types__c.split(',');   
            for(string value: values)
            {
                setValues.add(value.trim());
            }
        }
        return setValues;
    }

    /**
        This method will fetch custom metadata type and save it into list
    */
    public static Map<String, Map<String, String>> getSTZoneGroupMapping(set<String> productType)
    {
        Map<String, Map<String, String>> mapSTZoneGroupMapping = new Map<String, Map<String, String>>();

        List<APT_ST_Zone_Group_Mapping__mdt> stZoneGroupMappings = [SELECT MasterLabel, APT_Zone__c, APT_Group__c FROM APT_ST_Zone_Group_Mapping__mdt WHERE MasterLabel IN :productType];
        
        for(APT_ST_Zone_Group_Mapping__mdt stZoneGroupMapping: stZoneGroupMappings)
        {
            Map<String, String> mapZoneGroup = mapSTZoneGroupMapping.get(stZoneGroupMapping.MasterLabel);

            //prepare collection of domestic data for pricing key
            if(mapZoneGroup != null && mapZoneGroup.size() > 0) 
            {
                mapZoneGroup.put(stZoneGroupMapping.APT_Zone__c, stZoneGroupMapping.APT_Group__c);
                mapSTZoneGroupMapping.put(stZoneGroupMapping.MasterLabel, mapZoneGroup);
            } 
            else 
            {
                mapZoneGroup = new Map<String, String>();
                mapZoneGroup.put(stZoneGroupMapping.APT_Zone__c, stZoneGroupMapping.APT_Group__c);
                mapSTZoneGroupMapping.put(stZoneGroupMapping.MasterLabel, mapZoneGroup);
            }
        }

        return mapSTZoneGroupMapping;
    }

    /**
        This method will fetch custom metadata type and save it into list
    */
    public static List<String> getContractTemplatesToUncheck()
    {
        List<String> contractTemplatesToUncheck = new List<String>();

        APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
        if(!String.isEmpty(r2tSystemProperties.APT_Contract_Templates_To_Uncheck__c)) {
            List<string> values = r2tSystemProperties.APT_Contract_Templates_To_Uncheck__c.split(',');   
            for(string value: values)
            {
                contractTemplatesToUncheck.add(value.trim());
            }
        }

        return contractTemplatesToUncheck;
    }

    /**
        This method will fetch custom setting Included LP Details
    */
    public static Map<String, List<String>> getIncExcLPDetails(String productId)
    {
        Map<String, List<String>> inclExclLPModel = new Map<String, List<String>>();
        List<String> incExcLPs = new List<String>();

        List<APT_Include_Exclude_Lodgment_Points__mdt> incExcLPDetails = [SELECT APT_Inc_Exc__c, APT_LP1__c 
                                                                          FROM APT_Include_Exclude_Lodgment_Points__mdt 
                                                                          WHERE APT_Product_ID__c = :productId LIMIT 1];

        if(incExcLPDetails != null && !incExcLPDetails.isEmpty() 
           && !String.isEmpty(incExcLPDetails[0].APT_LP1__c) && !String.isEmpty(incExcLPDetails[0].APT_Inc_Exc__c)) 
        {
            List<String> values = incExcLPDetails[0].APT_LP1__c.split(',');   
            for(String value: values)
            {
                incExcLPs.add(value.trim());
            }
            inclExclLPModel.put(incExcLPDetails[0].APT_Inc_Exc__c, incExcLPs);
        }

        return inclExclLPModel;
    }
}