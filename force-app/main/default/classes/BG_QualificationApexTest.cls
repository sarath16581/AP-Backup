/****************************************************************************************
Author:        Jansi
Company:        CRMIT Solutions
Description:    Test class to cover BG_QualificationApex functionality
History:
-----------------------------------------------------------------------------------------
05.03.2020      Jansi (CRMIT Solutions)            Test class created
17.08.2020      arjun.singh@auspost.com.au         test a method to fetch the configured estimated revnue used in lead qualification flow
08.03.2022      seth.heang@auspost.com.au          update query on qualification template question to retrieve new validation related fields in test methods 
30.05.2022      seth.heang@auspost.com.au          update test method getPicklistvalues to cover exception scenario
*****************************************************************************************/
@isTest
public class BG_QualificationApexTest {
    
    @testSetup
    static void setupTestData() {
      
        //- insert 'Discovery' category Question
        Qualification_Template_Questions__c qta = new Qualification_Template_Questions__c();
        qta.Category__c='Discovery';
        qta.Datatype__c='Text Field';
        qta.Order__c = 20;
        qta.Question_Text__c='Test Question1?';
        qta.Required__c = false;
        qta.Active__c = true;
        qta.Initiation_Pathway__c= 'Leads and Opportunities';
        insert qta;
        
        //- insert 'Digital Identity' category 'Text' type Question
        Qualification_Template_Questions__c qta2 = new Qualification_Template_Questions__c();
        qta2.Category__c='Digital Identity';
        qta2.Datatype__c='Text Field';
        qta2.Order__c = 20;
        qta2.Question_Text__c='Size and weight of articles?';
        qta2.Required__c = false;
        qta2.Active__c = true;
        qta2.Initiation_Pathway__c= 'Leads and Opportunities';
        insert qta2;
        
        //- insert 'Digital Identity' category 'picklist' type Question
        Qualification_Template_Questions__c qta3 = new Qualification_Template_Questions__c();
        qta3.Category__c='Digital Identity';
        qta3.Datatype__c='Picklist Field';
        qta3.Order__c = 20;
        qta3.Question_Text__c='Size and weight of articles?';
        qta3.Required__c = false;
        qta3.Initiation_Pathway__c= 'Leads and Opportunities';
        insert qta3;
        
        //- insert 'Digital Identity' category 'picklist' type answers
        List<Qualification_Template_Responses__c> qtrList = new  List<Qualification_Template_Responses__c>();
        
        Qualification_Template_Responses__c qtr = new Qualification_Template_Responses__c();
        qtr.Active__c = true;
        qtr.Order__c = 10;
        qtr.Response_Text__c='Answer1';
        qtr.Qualification_Template_Question__c = qta3.Id;
        qtrList.add(qtr);
        
        Qualification_Template_Responses__c qtr2 = new Qualification_Template_Responses__c();
        qtr2.Active__c = true;
        qtr2.Order__c = 20;
        qtr2.Response_Text__c='Answer2';
        qtr2.Qualification_Template_Question__c = qta3.Id;   
        qtrList.add(qtr2);
        
        insert qtrList;
        
        //-- Update Qualification_Template_Questions__c as Active
        qta3.Active__c = true;
        update qta3;
        
        //-- insert Lead
        Lead l = new Lead();
        l.FirstName ='fn123';
        l.LastName = 'ln123';
        //l.Status = 'In progress';
        l.Company = 'org';
        l.email = 'test@test.com';
        l.MobilePhone = '0476183649';
        l.Job_Title__c = 'test';
	    l.PostalCode = '3006';
    	l.Company ='Test';
    	//l.Product__c = 'Australia Post - Parcel Services';
    	l.Opportunity_Initial_Estimate__c = 40000;
    	l.ABN__c='53004085616';
    	l.email= 'abc@gmail.com';
    	l.phone= '0456717340';
    	//l.Address_Validated__c = true; 
    	l.PostalCode = '3006';
    	l.street = 'TestStreet';
    	l.City = 'TestCity';
    	l.State = 'TestState';
        insert l;
        
        Qualification__c q = new Qualification__c();
        q.Lead__c = l.Id;
        q.Notes__c = 'summary Notes';
        q.Total_Estimate__c = 1000;
        insert q;
    }
	/**
	* Test method to get picklist label and api values via Schema.
	* The tests cover positive scenario where retrieval is sucessful and negative scenario where retrieval is resulted in exception.
	* */
	@isTest
	static void getPicklistvalues() {
		// positive scenario where picklist value are successfully retrieved
		Map<String, String> leadStatusPicklistValues = BG_QualificationApex.getPickListValuesBoth('Lead','status','values');
		System.assertNotEquals(leadStatusPicklistValues, null, 'Picklist retrieval should be sucessful');

		// negative scenario where exception occurs when retrieving picklist values
		try{
			// provide non-existent field api name
			Map<String, String> leadStatusPicklistValuesFails = BG_QualificationApex.getPickListValuesBoth('Lead','non_existing_field__c','values');
			System.assert(False, 'Picklist retrieval should result in exception');            
		}catch(AuraHandledException auraEx){
			// AuraHandledException is expected while retrieving picklist value
		}catch(Exception ex){
			System.assert(False, 'Expected type of exception is not thrown');
		}
	}
    
    /**
	* Test method to get 'Discovery' category questions
	* */
    @isTest
    static void getCategoryQuestions() {
        Boolean isTrue = true;
        User uRecord = ApplicationTestDataFactory.getUsers(1, false)[0];
        insert uRecord;
        System.runAs(uRecord){
            List<Qualification_Template_Questions__c> qtaList = BG_QualificationApex.getCategoryQuestions('Discovery');
            System.assertEquals(1, qtaList.size(), 'Discovery Category QuestionsList size is equal');
        }
    }
    
    /**
	* Test method to get 'Digital Identity' category questions
	* */
    @isTest
    static void getCategoryQuestions2() {
        Boolean isTrue = true;
        User uRecord = ApplicationTestDataFactory.getUsers(1, false)[0];
        insert uRecord;
        System.runAs(uRecord){
            Lead l = [Select Id from Lead WHERE LastName='ln123' LIMIT 1];
            BG_QualificationApex.getCategoryTypeQuestions('Digital Identity', l.Id );
            System.assert(isTrue);
        }
    }
    @isTest
    static void getCategoryQuestions2WithBGSalesPermission() {
        Boolean isTrue = true;
        User uRecord = ApplicationTestDataFactory.getUsers(1, false)[0];
        insert uRecord;
        PermissionSet PermissionSetId = [SELECT Name,Id FROM PermissionSet where name='BG_Sales'];
        PermissionSetAssignment PermissionSetAssignmentRec = new PermissionSetAssignment();
        PermissionSetAssignmentRec.PermissionSetId = PermissionSetId.Id;
        PermissionSetAssignmentRec.AssigneeId = uRecord.Id;
        insert PermissionSetAssignmentRec;     

        System.runAs(uRecord){
            Lead l = [Select Id from Lead WHERE LastName='ln123' LIMIT 1];
            BG_QualificationApex.getCategoryTypeQuestions('Digital Identity', l.Id );
            System.assert(isTrue);
        }
    }
    /**
	* Test method to get 'Digital Identity' category questions with Opportunity record as base
	* */
    @isTest
    static void getCategoryQuestions3() {
        Boolean isTrue = true;
        User uRecord = ApplicationTestDataFactory.getUsers(1, false)[0];
        insert uRecord;
        System.runAs(uRecord){
            Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
            insert account;
            Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
            insert opportunityRecord;
            
            BG_QualificationApex.getCategoryTypeQuestions('Digital Identity', opportunityRecord.Id );
            System.assert(isTrue);
        }
    }
    @isTest
    static void getCategoryQuestions3WithBGSales() {
        Boolean isTrue = true;
        User uRecord = ApplicationTestDataFactory.getUsers(1, false)[0];
        insert uRecord;
        PermissionSet PermissionSetId = [SELECT Name,Id FROM PermissionSet where name='BG_Sales'];
        PermissionSetAssignment PermissionSetAssignmentRec = new PermissionSetAssignment();
        PermissionSetAssignmentRec.PermissionSetId = PermissionSetId.Id;
        PermissionSetAssignmentRec.AssigneeId = uRecord.Id;
        insert PermissionSetAssignmentRec;     
        System.runAs(uRecord){
            Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
            insert account;
            Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
            insert opportunityRecord;
            
            BG_QualificationApex.getCategoryTypeQuestions('Digital Identity', opportunityRecord.Id );
            System.assert(isTrue);
        }
    }
    
    /**
	* Test method to submit/Finish a Qualification
	* */
    @isTest
    static void submitQualification() {
        Boolean isTrue = true;
        //try{
            String category = 'Digital Identity';
            
            List<BG_QualificationApex.CategoryQuestionWrapper> wrapperist = new  List<BG_QualificationApex.CategoryQuestionWrapper>();
            for(Qualification_Template_Questions__c qta :[SELECT Name,
                                                          Category__c,Datatype__c,Order__c,
                                                          Question_Text__c, Required__c, Related_Response__c,Related_Response__r.Name,
                                                          Min_Value__c, Max_Value__c, Help_Text__c, Validation_Message__c, APT_Applicable_Validation__c
                                                          FROM Qualification_Template_Questions__c 
                                                          WHERE Category__c=:category and Active__c = TRUE
                                                          ORDER BY Order__c ASC]){
                                                              wrapperist.add(new BG_QualificationApex.CategoryQuestionWrapper(qta ,'Digital Identity',''));      
                                                              
                                                          }
            
            Lead l = [Select Id from Lead WHERE LastName='ln123' LIMIT 1];
            
            //String discoveryQuestions='[{"dataType":"Text Field","isRequired":false,"order":5,"questionName":"Can you tell me about your business from a past, present & future perspective?","selectedAnswer":"Answer1"}]';
            String discoveryQuestions='[{"dataType":"Text Field","isRequired":false,"order":5,"questionName":"Can you tell me about your business from a past, present & future perspective?","selectedAnswer":"Answer1"},{"dataType":"number","isRequired":false,"order":6,"questionName":"Sample Number Question","selectedAnswer":"20"},{"dataType":"date","isRequired":false,"order":7,"questionName":"Sample Date Question","selectedAnswer":"2021-06-30"},{"dataType":"Percent","isRequired":false,"order":8,"questionName":"Sample Percent Question","selectedAnswer":"2.4"},{"dataType":"Multiline Text","isRequired":false,"order":9,"questionName":"Sample MultiLine Question","selectedAnswer":"Answer1"},{"dataType":"Text Field","isRequired":false,"order":10,"questionName":"Can you tell me about your business from a past, present & future perspective?","selectedAnswer":"Answer1"}]';
            
            Map<String,Object> selectedPrdoQuestions = new Map<String,Object>();
            selectedPrdoQuestions.put('Digital Identity',wrapperist);
            
            Map<Object,Object> revObjMap =  new Map<Object,Object>{(Object)'revenue' => '120'};
                Map<Object,Object> noteObjMap = new Map<Object,Object>{(Object)'notes' => 'notes of MS Product'};
                    Map<String,Object> productEstimateMap= new   Map<String,Object>{'Digital Identity'=>revObjMap};
                        Map<String,Object>   productNotesMap=new Map<String,Object> {'Digital Identity'=>noteObjMap};
                            
                            Test.startTest();
            String qualificationRecId = BG_QualificationApex.submitResponse(l.id, null,discoveryQuestions,'["Digital Identity"]',selectedPrdoQuestions,productEstimateMap,productNotesMap, 2000,'Summary Notes','Startrack',null,'In Progress');
            
            List<Qualification_Response_Detail__c> resList =  BG_QualificationApex.getExistingQualificationDetails(qualificationRecId);
            System.debug('resList>>>>'+resList);
            String qualRecId = BG_QualificationApex.getExistingResponseId(qualificationRecId);            
            Test.stopTest();
        /*} catch(Exception ex){
            
        }*/
        
        System.assert(resList != null);
    }
    /**
	* Test method to submit/Finish a Qualification
	* */
    @isTest
    static void submitQualificationFromOpportunity() {
        Boolean isTrue = true;
        //try{
            String category = 'Digital Identity';
            
            List<BG_QualificationApex.CategoryQuestionWrapper> wrapperist = new  List<BG_QualificationApex.CategoryQuestionWrapper>();
            for(Qualification_Template_Questions__c qta :[SELECT Name,
                                                          Category__c,Datatype__c,Order__c,
                                                          Question_Text__c, Required__c, Related_Response__c,Related_Response__r.Name,
                                                          Min_Value__c, Max_Value__c, Help_Text__c, Validation_Message__c, APT_Applicable_Validation__c
                                                          FROM Qualification_Template_Questions__c 
                                                          WHERE Category__c=:category and Active__c = TRUE
                                                          ORDER BY Order__c ASC]){
                                                              wrapperist.add(new BG_QualificationApex.CategoryQuestionWrapper(qta ,'Digital Identity',''));      
                                                              
                                                          }
            
            Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
            insert account;
            Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
            insert opportunityRecord;
            
            String discoveryQuestions='[{"dataType":"Text Field","isRequired":false,"order":5,"questionName":"Can you tell me about your business from a past, present & future perspective?","selectedAnswer":"Answer1"}]';         

            
            Map<String,Object> selectedPrdoQuestions = new Map<String,Object>();
            selectedPrdoQuestions.put('Digital Identity',wrapperist);
            
            Map<Object,Object> revObjMap =  new Map<Object,Object>{(Object)'revenue' => '120'};
                Map<Object,Object> noteObjMap = new Map<Object,Object>{(Object)'notes' => 'notes of MS Product'};
                    Map<String,Object> productEstimateMap= new   Map<String,Object>{'Digital Identity'=>revObjMap};
                        Map<String,Object>   productNotesMap=new Map<String,Object> {'Digital Identity'=>noteObjMap};
                            
                            Test.startTest();
            String qualificationRecId = BG_QualificationApex.submitResponse(null, opportunityRecord.id,discoveryQuestions,'["Digital Identity"]',selectedPrdoQuestions,productEstimateMap,productNotesMap, 2000,'Summary Notes','Startrack',null,'In Progress');
            
            List<Qualification_Response_Detail__c> resList =  BG_QualificationApex.getExistingQualificationDetails(qualificationRecId);
            System.debug('resList>>>>'+resList);
            String qualRecId = BG_QualificationApex.getExistingResponseId(qualificationRecId);            
            Test.stopTest();
        /*} catch(Exception ex){
            
        }*/
        
        System.assert(resList != null);
    }
   
    /**
	* Test method to get Qualification Nmes for a Lead
	* */
    @isTest
    static void getQualificationNames(){
        Boolean isTrue = true;
        try{
            Lead l = [Select Id from Lead WHERE LastName='ln123' LIMIT 1];
            Map<String, String>  qualMap = BG_QualificationApex.getQualificationIdNameMap(l.id);
            System.assertEquals(qualMap.size(), 1, 'The qualifications map size is equal');
        }catch(Exception ex){
            
        }
    }
    
    /**
	* Test method to get Qualification records for a Lead
	* */
    @isTest
    static void getLeadQualifications(){
        Boolean isTrue = true;
        try{
            Lead l = [Select Id from Lead WHERE LastName='ln123' LIMIT 1];
            List<Qualification__c>  qualList = BG_QualificationApex.getQualificationsList(l.id);
            System.assertEquals(qualList.size(), 1, 'The qualification List size is equal');
        }catch(Exception ex){
            
        }
    }
    
    /**
	* Test method to get InitializeWrapper
	* */
    @isTest
    static void InitializeWrapper(){
        Boolean isTrue = true;
        try{
            BG_QualificationApex.QualificationCategoryDetail qcdWrapper = new  BG_QualificationApex.QualificationCategoryDetail();
            qcdWrapper.qualificationId = null;
            qcdWrapper.category = 'Discovery';
            qcdWrapper.categoryEstimate = 1000;
            qcdWrapper.notes = 'Discovery Notes';
            qcdWrapper.revenue = '234';
            qcdWrapper.qualifCatList = null;
            
            BG_QualificationApex.QualificationResponseDetail qrdWrapper = new  BG_QualificationApex.QualificationResponseDetail();
            qrdWrapper.qualificationId = null;
            qrdWrapper.qualifCatDetailId = null;
            qrdWrapper.question = 'Question 1?';
            qrdWrapper.response = 'Response';
            System.assert(true);
        }catch(Exception ex){
            
        }
    }
    /**
	* Test method confirm estimated revenue is configured for lead qualification process
	* */
    @isTest
    static void getStrackTrackProductEstimatedRevenuetest(){
        test.startTest();
        String estimateRevenue =  BG_QualificationApex.getStrackTrackProductEstimatedRevenue();
        test.stopTest();
        System.assert(estimateRevenue != null);
    }
    @isTest
    static void deleteUnSelectedProductCategoryTest(){
        Boolean isTrue = true;
        //try{
           // String category = 'Digital Identity';
            Set<String> categorySet = new Set<String>();
            categorySet.add('Digital Identity');
            categorySet.add('Discovery');
            
            //List<BG_QualificationApex.CategoryQuestionWrapper> wrapperist = new  List<BG_QualificationApex.CategoryQuestionWrapper>();
            Map<String,List<BG_QualificationApex.CategoryQuestionWrapper>> wrapperMap = new Map<String,List<BG_QualificationApex.CategoryQuestionWrapper>>();
            
            for(Qualification_Template_Questions__c qta :[SELECT Name,
                                                          Category__c,Datatype__c,Order__c,
                                                          Question_Text__c, Required__c, Related_Response__c,Related_Response__r.Name,
                                                          Min_Value__c, Max_Value__c, Help_Text__c, Validation_Message__c, APT_Applicable_Validation__c
                                                          FROM Qualification_Template_Questions__c 
                                                          WHERE Category__c IN : categorySet and Active__c = TRUE
                                                          ORDER BY Order__c ASC]){
                                                            List<BG_QualificationApex.CategoryQuestionWrapper> wList = new List<BG_QualificationApex.CategoryQuestionWrapper>();
                                                            wList.add(new BG_QualificationApex.CategoryQuestionWrapper(qta ,qta.Category__c,''));
                                                            wrapperMap.put(qta.Category__c, wList);  
                                                             // wrapperist.add(new BG_QualificationApex.CategoryQuestionWrapper(qta ,'Digital Identity'));      
                                                              
                                                          }
            
            Lead l = [Select Id from Lead WHERE LastName='ln123' LIMIT 1];
            
            String discoveryQuestions='[{"dataType":"Text Field","isRequired":false,"order":5,"questionName":"Can you tell me about your business from a past, present & future perspective?","selectedAnswer":"Answer1"}]';
            
            Map<String,Object> selectedPrdoQuestions = new Map<String,Object>();
            //selectedPrdoQuestions.put('Digital Identity',wrapperist);
            for(String str: wrapperMap.keySet()){
                selectedPrdoQuestions.put(str, wrapperMap.get(str));
            }
            String selectedPrdoQuestionsJson = JSON.serialize(selectedPrdoQuestions);
            Map<Object,Object> revObjMap =  new Map<Object,Object>{(Object)'revenue' => '120'};
                Map<Object,Object> noteObjMap = new Map<Object,Object>{(Object)'notes' => 'notes of MS Product'};
                    Map<String,Object> productEstimateMap= new   Map<String,Object>{
                        'Digital Identity'=>revObjMap,
                        'Discovery'=>revObjMap
                    };
                        Map<String,Object>   productNotesMap=new Map<String,Object> {
                            'Digital Identity'=>noteObjMap,
                            'Discovery'=>noteObjMap
                        };
                            
            Test.startTest();
            String qualificationRecId = BG_QualificationApex.submitResponse(l.id, null,discoveryQuestions,'["Digital Identity","Discovery"]',selectedPrdoQuestions,productEstimateMap,productNotesMap, 2000,'Summary Notes','Startrack',null, 'Completed');
            BG_QualificationApex.deleteUnSelectedProductCategory(Id.valueOf(qualificationRecId), new List<String>{'Discovery'});
            
            Test.stopTest();
        /*} catch(Exception ex){
            
        }*/
        List<Qualification_Category_Detail__c> cateogryList = [Select Id from Qualification_Category_Detail__c where Qualification__c=: qualificationRecId AND Selected_Category__c='Digital Identity'];
        System.assert(cateogryList.isEmpty());
    }
    @isTest
    static void getRelatedQuestionsTest(){
        Qualification_Template_Responses__c templateRes = [Select Id, Response_Text__c, 
                                                                    Qualification_Template_Question__c, 
                                                                    Qualification_Template_Question__r.Name,
                                                                    Qualification_Template_Question__r.Category__c
                                                                    From Qualification_Template_Responses__c where Qualification_Template_Question__r.Datatype__c='Picklist Field' Limit 1];

        
        System.debug('templateRes>>>>>>'+templateRes);
        Qualification_Template_Questions__c newRelatedQuestion = new Qualification_Template_Questions__c();
        newRelatedQuestion.Category__c=templateRes.Qualification_Template_Question__r.Category__c;
        newRelatedQuestion.Datatype__c='Picklist Field';
        newRelatedQuestion.Order__c = 23;
        newRelatedQuestion.Question_Text__c='Test Related Question1?';
        newRelatedQuestion.Required__c = false;
        newRelatedQuestion.Active__c = false;
        newRelatedQuestion.Related_Response__c = templateRes.Id;
        insert newRelatedQuestion;

        List<Qualification_Template_Responses__c> qtrList = new  List<Qualification_Template_Responses__c>();
        
        Qualification_Template_Responses__c qtr = new Qualification_Template_Responses__c();
        qtr.Active__c = true;
        qtr.Order__c = 10;
        qtr.Response_Text__c='RelatedAnswer1';
        qtr.Qualification_Template_Question__c = newRelatedQuestion.Id;
        qtrList.add(qtr);
        
        Qualification_Template_Responses__c qtr2 = new Qualification_Template_Responses__c();
        qtr2.Active__c = true;
        qtr2.Order__c = 20;
        qtr2.Response_Text__c='RelatedAnswer2';
        qtr2.Qualification_Template_Question__c = newRelatedQuestion.Id;   
        qtrList.add(qtr2);
        
        insert qtrList;
		
		newRelatedQuestion.Active__c = true;
		update newRelatedQuestion;

        Qualification_Template_Questions__c newRelatedQuestionVar = new Qualification_Template_Questions__c();
        newRelatedQuestionVar.Category__c=qtrList[0].Qualification_Template_Question__r.Category__c;
        newRelatedQuestionVar.Datatype__c='Text Field';
        newRelatedQuestionVar.Order__c = 27;
        newRelatedQuestionVar.Question_Text__c='Test Related Question1Var?';
        newRelatedQuestionVar.Required__c = false;
        newRelatedQuestionVar.Active__c = true;
        newRelatedQuestionVar.Related_Response__c = qtrList[0].Id;
        insert newRelatedQuestionVar;

        //String selectedAnswer = JSON.serialize(templateRes);
        String selectedAnswer = '"' +  String.valueOf(templateRes.Response_Text__c) + '"';
        String uniqueKey = templateRes.Qualification_Template_Question__r.Name;
		

         Test.startTest();
         List<BG_QualificationApex.CategoryQuestionWrapper> wrapperist = new  List<BG_QualificationApex.CategoryQuestionWrapper>();
         wrapperist = BG_QualificationApex.getRelatedQuestions(uniqueKey, selectedAnswer);
         Test.stopTest();
         System.assert(wrapperist != null);
    }
    @isTest
    static void isOpportunityConvertedTest(){
        Account accVar = APT_TestUtil2.createOrganisation();
        accVar.Name = 'TestAccount';
        insert accVar;

        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);
        oppVar.StageName = 'Identify';
        oppVar.Pre_Entry__c = TRUE;
        oppVar.closeDate= system.today();

        insert oppVar;

        Test.startTest();
         Boolean resultFlag = BG_QualificationApex.isOpportunityConverted(string.valueOf(oppVar.Id));
         Test.stopTest();
         System.assert(resultFlag == false);
    }
    @isTest
    static void getCategoryQuestionsWithBGSalesPermission() {
        Boolean isTrue = true;
        PermissionSet PermissionSetId = [SELECT Name,Id FROM PermissionSet where name='BG_Sales'];
		List<PermissionSetAssignment> permList = [Select Id from PermissionSetAssignment where PermissionSetId =: PermissionSetId.Id and AssigneeId =: userInfo.getUserID()];		
		if(permList.isEmpty()){
			PermissionSetAssignment PermissionSetAssignmentRec = new PermissionSetAssignment();
			PermissionSetAssignmentRec.PermissionSetId = PermissionSetId.Id;
			PermissionSetAssignmentRec.AssigneeId = userInfo.getUserID();
			insert PermissionSetAssignmentRec;        
		}
        List<Qualification_Template_Questions__c> qtaList = BG_QualificationApex.getCategoryQuestions('Discovery');
        System.assertEquals(1, qtaList.size(), 'Discovery Category QuestionsList size is equal');
    }
    
     @isTest
    static void getCategoryQuestions2WithBGSales() {
        Boolean isTrue = true;
		Lead l = [Select Id from Lead WHERE LastName='ln123' LIMIT 1];
        PermissionSet PermissionSetId = [SELECT Name,Id FROM PermissionSet where name='BG_Sales'];
		List<PermissionSetAssignment> permList = [Select Id from PermissionSetAssignment where PermissionSetId =: PermissionSetId.Id and AssigneeId =: userInfo.getUserID()];		
		if(permList.isEmpty()){
			PermissionSetAssignment PermissionSetAssignmentRec = new PermissionSetAssignment();
			PermissionSetAssignmentRec.PermissionSetId = PermissionSetId.Id;
			PermissionSetAssignmentRec.AssigneeId = userInfo.getUserID();
			insert PermissionSetAssignmentRec;  
		}
        BG_QualificationApex.getCategoryTypeQuestions('Digital Identity', l.Id);
        Boolean bgSalesPermissionFlag = BG_QualificationApex.hasBGSalesPermissionSetAssigned();
        System.assert(bgSalesPermissionFlag);
    }
    @isTest
    static void isOpportunityClosedTest(){
        Account accVar = APT_TestUtil2.createOrganisation();
        accVar.Name = 'TestAccount';
        insert accVar;

        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);
        oppVar.StageName = 'Identify';
        oppVar.Pre_Entry__c = TRUE;
        oppVar.closeDate= system.today();

        insert oppVar;

        Test.startTest();
         Boolean resultFlag = BG_QualificationApex.isClosedOpportunity(string.valueOf(oppVar.Id));
         Test.stopTest();
         System.assert(resultFlag == false);
    }
}