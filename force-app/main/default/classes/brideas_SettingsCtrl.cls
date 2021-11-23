public with sharing class brideas_SettingsCtrl {

    public List<SelectOption> zonesOptions {get; set;}
    public List<SelectOption> ideaStatusesOption {get;set;}
    public String selectedZone {get; set;}
    public String statusToChange {get;set;} //maybe 'statusUpdateFrom' is better name?
    public String nextStatus {get;set;} //maybe 'statusUpdateTo' is better name?
    public String limitForStatus {get;set;} //maybe 'statusUpdateThreshold' is better name?
    public Boolean isStatusUpdateEnabled {get;set;} //maybe 'enableStatusUpdate' is better name?
    public Map<String,String> allStatusColors {get;set;}
    public String forbiddenWords {get;set;}
    public Map<String, String> reputationPoints {get; set;}
    public List<User> moderators {get; set;}
    public String selectedFeaturedCategory {get; set;}
    public List<SelectOption> featuredCategoryOptions {get;set;}
    public String surveyURL {get; set;}
    /*Below code is added on 16-08-2018 to give the capability to store featured category image url 
      and render the image on Ideas List page as part of Communities changes.*/
    public String featuredCategoryImageURL {get; set;}

    public brideas_SettingsCtrl() {
        Schema.DescribeSObjectResult settingsObjDescribe = brideas_MetadataType__mdt.sObjectType.getDescribe();
        Schema.DescribeSObjectResult communityObjDescribe = Community.sObjectType.getDescribe();

        if (!communityObjDescribe.isAccessible() || !settingsObjDescribe.isAccessible()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You don\'t have appropriate permissions to edit this settings'));
            return;
        }

        initSettingsValues();

    }

    public void initSettingsValues() {
        selectedZone = ' ';
        zonesOptions = new List<SelectOption>();
        ideaStatusesOption = new List<SelectOption>();
        isStatusUpdateEnabled = false;
        limitForStatus = '';
        statusToChange= '';
        nextStatus = '';
        forbiddenWords = '';
        selectedFeaturedCategory = '';
        surveyURL = '';
        /*Below code is added on 16-08-2018 to give the capability to store featured category image url 
          and render the image on Ideas List page as part of Communities changes.*/
        featuredCategoryImageURL = '';
        featuredCategoryOptions = new List<SelectOption>{new SelectOption(' ', ' ')};

        zonesOptions.add(new SelectOption(' ', ' '));
        ideaStatusesOption.add(new SelectOption(' ', ' '));

        for (Community zone : [SELECT Id, Name FROM Community LIMIT 50]) {
            zonesOptions.add(new SelectOption(zone.Name, zone.Name));
        }

        if (zonesOptions.size() <= 1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,
                    'Current Organization doesn\'t have any Ideas Zone setup. Please create Ideas Zone to continue'));
        }

        try {
            for (brideas_MetadataType__mdt setting: [SELECT DeveloperName, Value__c FROM brideas_MetadataType__mdt LIMIT 100]) {
                if (setting.DeveloperName == 'community') {
                    selectedZone = setting.Value__c;
                } else if (setting.DeveloperName == 'status_colors') {
                    allStatusColors = prepareStatusColorsSettings(setting.Value__c);
                } else if (setting.DeveloperName == 'featured_category') {
                    selectedFeaturedCategory = setting.Value__c;
                } else if(setting.DeveloperName == 'reputation_points') {
                    reputationPoints = (Map<String,String>)JSON.deserializeStrict(setting.Value__c, Map<String,String>.class);
                } else if (setting.DeveloperName == 'forbidden_words') {
                    forbiddenWords = setting.Value__c;
                } else if (setting.DeveloperName == 'survey_url') {
                    surveyURL = setting.Value__c;
                /*Below code is added on 16-08-2018 to give the capability to store featured category image url 
                  and render the image on Ideas List page as part of Communities changes.*/
                } else if (setting.DeveloperName == 'featured_category_image_url') {
                    featuredCategoryImageURL = setting.Value__c;
                }
            }

        } catch (Exception e) {
            System.debug('brideas_SettingsCtrl: ' + e.getMessage());
        }

        Schema.DescribeFieldResult statusFieldDescrine = Schema.Idea.Status.getDescribe();
        List<Schema.PicklistEntry> picklistValues = statusFieldDescrine.getPicklistValues();

        for (Schema.PicklistEntry picklistItem : picklistValues) {
            ideaStatusesOption.add(new SelectOption(picklistItem.getLabel(), picklistItem.getValue()));
        }

        Map<String, String> statusUpdateSettings = brideas_Helper.getStatusUpdateSettings();

        if (statusUpdateSettings != null) {
            isStatusUpdateEnabled = Boolean.valueOf(statusUpdateSettings.get('active'));
            limitForStatus = statusUpdateSettings.get('threshold');
            statusToChange = statusUpdateSettings.get('original_status');
            nextStatus = statusUpdateSettings.get('new_status');
        }

        Schema.DescribeFieldResult fieldResult = Idea.Categories.getDescribe();
        List<Schema.PicklistEntry> categoryPicklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry picklistItem : categoryPicklistEntries) {
            featuredCategoryOptions.add(new SelectOption(picklistItem.getLabel(), picklistItem.getValue()));
        }

        this.moderators = new List<User>([SELECT Name, Email FROM User WHERE IdeasModerator__c = true LIMIT 100]);

    }

    public PageReference saveSettings() {
        Decimal threshold = 0;

        if (String.isBlank(selectedZone)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Failed to save. Ideas Zone can not be empty'));
            return null;
        }

        try {

            if (String.isNotBlank(limitForStatus)) {
                threshold = Decimal.valueOf(limitForStatus);
            }

            String statusUpdateSetting = '{"active":' + isStatusUpdateEnabled + ',"threshold":' + String.valueOf(threshold) + ',' +
                                                                                    '"original_status":"' + statusToChange + '",' +
                                                                                    '"new_status":"' + nextStatus + '"}';

            Map<String,String> recordsNewValuesMap = new Map<String, String>();

            recordsNewValuesMap.put('status_update', statusUpdateSetting);
            recordsNewValuesMap.put('community', selectedZone);
            recordsNewValuesMap.put('forbidden_words', forbiddenWords);
            recordsNewValuesMap.put('status_colors', JSON.serialize(allStatusColors));
            recordsNewValuesMap.put('reputation_points', JSON.serialize(reputationPoints));
            recordsNewValuesMap.put('featured_category', selectedFeaturedCategory);
            recordsNewValuesMap.put('survey_url', surveyURL);
            /*Below code is added on 16-08-2018 to give the capability to store featured category image url 
              and render the image on Ideas List page as part of Communities changes.*/
            recordsNewValuesMap.put('featured_category_image_URL', featuredCategoryImageURL);

            brideas_Helper.updateCustomMetadataValue(recordsNewValuesMap);

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Settings saved successfully'));

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Failed to save ' + e.getMessage()));
            System.debug('brideas_SettingsCtrl::saveSettings: ' + e.getMessage());

            return null;
        }

        return ApexPages.currentPage();
    }

    private Map<String,String> prepareStatusColorsSettings(String settingValue) {
        Map<String, String> statusColorsData = new Map<String, String>();
        List<String> statusLabels = new List<String>();

        Map<String,String> statusColorsSettingsMap = (Map<String,String>)JSON.deserializeStrict(settingValue, Map<String,String>.class);

        Schema.DescribeFieldResult fieldResult = Idea.Status.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {
            statusLabels.add(f.getLabel());
        }

        statusLabels.sort();

        for (String sl: statusLabels) {
            if (statusColorsSettingsMap.containsKey(sl)) {
                statusColorsData.put(sl, statusColorsSettingsMap.get(sl));
            } else {
                statusColorsData.put(sl, '#000000');
            }
        }

        return statusColorsData;
    }

}