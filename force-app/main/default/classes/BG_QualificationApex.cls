/****************************************************************************************
Author:        Jansi
Company:        CRMIT Solutions
Description:   The qualification functionality class
History:
-----------------------------------------------------------------------------------------
20.02.2020      Jansi (CRMIT Solutions)             created
17.08.2020      arjun.singh@auspost.com.au          Added a method to fetch the configured estimated revnue used in lead qualification flow
07.03.2022      seth.heang@auspost.com.au           Added new fields to Qualification Template Question query and update search filter from Category API name to Category Label
20.05.2022      seth.heang@auspost.com.au           Fix CNA mapping to Lead.products__c and refactor the method retrieving picklist value and label via Schema
*****************************************************************************************/
public class BG_QualificationApex {
	/**
	 * @description Aura Method call to return a map of the picklist value and picklist label of inputted Sobject and picklist field
	 * @param		String sObjectApiName: specify sObject API name
	 * @param		String fieldApiName: specify picklist field API name
	 * @param		String valuesOrApiNames: specify if API name or Label is passed
	 * @return		Map<String,String>
	 */
	@AuraEnabled
	public static Map<String, String> getPickListValuesBoth(String sObjectApiName, String fieldApiName, String valuesOrApiNames){
		Map<String, String> picklistValuesMap = new Map<String, String>();
		try{
			// get picklist value and label from Schema via below method
			picklistValuesMap = getPickListValuesFromSchema(sObjectApiName, fieldApiName, true);
		}catch(Exception e){
			String errMsg = 'Error occurred while retrieving picklist values' + e.getMessage()+ ' at ' + e.getStacktraceString();
			AuraHandledException ex = new AuraHandledException(errMsg);
			ex.setMessage(errMsg);
			throw ex;
		}
		return picklistValuesMap; 
	}
    @AuraEnabled
    public static String getExistingResponseId(String recordId){
        String SelectString = 'Select Id From ';
        String WhereString = ' Where ' ;
        String fieldName ; 
        String ObjectName = String.valueOf(id.valueOf(recordId).getsobjecttype());
        String qualId ;
        if(ObjectName == 'Lead'){
            fieldName = 'Lead__c';
        }else{
            fieldName = 'Opportunity__c';
        }
        String soqlString = SelectString + 'Qualification__c' + WhereString + fieldName + '=' + '\'' + recordId + '\'' + ' order by createdDate Desc'; 
        list<Qualification__c> quaList = database.query(soqlString);
        if(!quaList.isEmpty()){
            qualId = quaList[0].Id;
        }
        return qualId;
    }
    /**
    * Fetch pre qualified Active questions from Metadata for a reporttype
    * */
    @AuraEnabled
    public static List<Qualification_Template_Questions__c> getCategoryQuestions(String category){
        List<Qualification_Template_Questions__c> categoryQuestions = new List<Qualification_Template_Questions__c>();
		Boolean hasBGSalesPermissionFlag = hasBGSalesPermissionSetAssigned();
        if(hasBGSalesPermissionFlag){
            categoryQuestions =
            [SELECT  Category__c,Datatype__c,Order__c,
             Question_Text__c,Related_Response__c,Related_Response__r.Name
             FROM Qualification_Template_Questions__c 
             WHERE toLabel(Category__c)=:category AND Related_Response__c = NULL ORDER BY Order__c ASC];
        }else{
            categoryQuestions =
            [SELECT  Category__c,Datatype__c,Order__c,
             Question_Text__c,Related_Response__c,Related_Response__r.Name
             FROM Qualification_Template_Questions__c 
             WHERE toLabel(Category__c)=:category AND Account_Manager_Only__c= false AND Related_Response__c = NULL ORDER BY Order__c ASC];
        }        
        return categoryQuestions;
    }
    @AuraEnabled
    public static List<CategoryQuestionWrapper> getRelatedQuestions(String parentUniqueKey, String selectedAnswer){
        
        List<String>selectedAnswerList = new List<String>();
        Object selectedAnswerObject =  (Object)System.JSON.deserializeUntyped(selectedAnswer);
        if(selectedAnswerObject instanceof String){
            selectedAnswerList.add((String)selectedAnswerObject);
        }else if(selectedAnswerObject instanceof List<object>){
            for(object objVar : (List<object>)selectedAnswerObject){
                String strVar = (String) objVar;
                selectedAnswerList.add(strVar);
            }
        }
        List<CategoryQuestionWrapper> categoryQuestionsList = new List<CategoryQuestionWrapper>();
        for( Qualification_Template_Questions__c categoryQuestions :
            [SELECT  toLabel(Category__c),Datatype__c,Order__c,Help_Text__c,APT_Applicable_Validation__c,Validation_Message__c,Min_Value__c,Max_Value__c,
             Question_Text__c, Required__c, Name,Related_Response__r.Qualification_Template_Question__r.Name,Related_Response__c,Related_Response__r.Name
             FROM Qualification_Template_Questions__c 
             WHERE Related_Response__r.Qualification_Template_Question__r.Name=:parentUniqueKey AND Related_Response__r.Response_Text__c IN :selectedAnswerList ORDER BY Order__c ASC]){
                categoryQuestionsList.add(new CategoryQuestionWrapper(categoryQuestions,categoryQuestions.Category__c, parentUniqueKey )); 
             }     
        return categoryQuestionsList;
    }
    /**
    * Get the given field picklist values/apinames for given object
    * **/
    @AuraEnabled
    public static List<CategoryQuestionWrapper> getCategoryTypeQuestions(String categoryName ,String recordIdStr){
        List<CategoryQuestionWrapper> categoryQueWrapperList= null;
        categoryQueWrapperList = new CategoryQuestionWrapperList(categoryName, recordIdStr).categoryQuestionsList;
        return new CategoryQuestionWrapperList(categoryName, recordIdStr).categoryQuestionsList;
    }
    public class CategoryQuestionWrapperList{ 
        @AuraEnabled public String category{get; set;}
        @AuraEnabled public String recordIdStr{get; set;}
        @AuraEnabled public List<CategoryQuestionWrapper> categoryQuestionsList{get; set;}
        CategoryQuestionWrapperList(String category, String recordIdStr){
            this.category = category;
            this.categoryQuestionsList = new List<CategoryQuestionWrapper> ();
            Boolean hasBGSalesPermissionFlag = hasBGSalesPermissionSetAssigned();
            String ObjectName = String.valueOf(id.valueOf(recordIdStr).getsobjecttype());
            Boolean isConvertedOpportunity = false;
            
            String select_Query = ' SELECT Category__c,Datatype__c,Order__c,Question_Text__c, Required__c, Name,Help_Text__c,APT_Applicable_Validation__c,Validation_Message__c,Min_Value__c,Max_Value__c,Related_Response__c,Related_Response__r.Name,Related_Response__r.Qualification_Template_Question__r.name FROM Qualification_Template_Questions__c WHERE ';
            String accountManager_Filter = ' AND Account_Manager_Only__c = false ' ;
            // Update category check from API name to Label Name
            String category_Filter = 'toLabel(Category__c) =' + '\'' + category + '\'';
            String active_Filter = ' AND Active__c = TRUE ';
            String lead_Filter = 'AND Initiation_Pathway__c IN (' + '\'' + 'Leads' + '\'' + ',' + '\'' + 'Leads and Opportunities' + '\'' +')' ;
            String opportunity_Filter = ' AND Initiation_Pathway__c IN (' + '\'' + 'Opportunities' + '\'' + ',' + '\'' + 'Leads and Opportunities' + '\'' +')' ;
            String orderby_Filter = ' ORDER BY Order__c ASC NULLS FIRST' ;
            String Final_Query ;

            if(ObjectName == 'Opportunity'){
                Opportunity oppRecord = [Select Id, Lead_ID__c From Opportunity Where Id =: id.valueOf(recordIdStr)];
                if(oppRecord.Lead_ID__c != null){
                    isConvertedOpportunity = true;
                }
            }


            if(hasBGSalesPermissionFlag){
                if(ObjectName == 'Lead'){
                    Final_Query = select_Query + category_Filter + active_Filter + lead_Filter + orderby_Filter;
                    for(Qualification_Template_Questions__c qta : Database.query(Final_Query)){
						if(qta.Related_Response__c != null){
							this.categoryQuestionsList.add(new CategoryQuestionWrapper(qta,category,qta.Related_Response__r.Qualification_Template_Question__r.name));      
						}else{
							this.categoryQuestionsList.add(new CategoryQuestionWrapper(qta,category,null)); 
						}
                    }
                    
                }else if(ObjectName == 'Opportunity'){
                    if(isConvertedOpportunity){
                        Final_Query = select_Query + category_Filter + active_Filter + lead_Filter + orderby_Filter;
                    }else{
                        Final_Query = select_Query + category_Filter + active_Filter + opportunity_Filter + orderby_Filter;
                    }
                    
                    for(Qualification_Template_Questions__c qta : Database.query(Final_Query)){
                        if(qta.Related_Response__c != null){
							this.categoryQuestionsList.add(new CategoryQuestionWrapper(qta,category,qta.Related_Response__r.Qualification_Template_Question__r.name));      
						}else{
							this.categoryQuestionsList.add(new CategoryQuestionWrapper(qta,category,null)); 
						}
                    }                    
                }                                            
            }else{
                if(ObjectName == 'Lead'){                    
                    Final_Query = select_Query + category_Filter + active_Filter + accountManager_Filter + lead_Filter + orderby_Filter;
                    for(Qualification_Template_Questions__c qta : Database.query(Final_Query)){
                        if(qta.Related_Response__c != null){
							this.categoryQuestionsList.add(new CategoryQuestionWrapper(qta,category,qta.Related_Response__r.Qualification_Template_Question__r.name));      
						}else{
							this.categoryQuestionsList.add(new CategoryQuestionWrapper(qta,category,null)); 
						}
                    }
                }else if(ObjectName == 'Opportunity'){
                    
                    if(isConvertedOpportunity){
                        Final_Query = select_Query + category_Filter + active_Filter + accountManager_Filter + lead_Filter + orderby_Filter;
                    }else{
                        Final_Query = select_Query + category_Filter + active_Filter + accountManager_Filter + opportunity_Filter + orderby_Filter;
                    }
                    for(Qualification_Template_Questions__c qta : Database.query(Final_Query)){
                        if(qta.Related_Response__c != null){
							this.categoryQuestionsList.add(new CategoryQuestionWrapper(qta,category,qta.Related_Response__r.Qualification_Template_Question__r.name));      
						}else{
							this.categoryQuestionsList.add(new CategoryQuestionWrapper(qta,category,null)); 
						}
                    } 
                }                                            
            }            
            
        }
    }
    
    public class CategoryQuestionWrapper{
        
        @AuraEnabled public String questionName {get; set;}
        @AuraEnabled public String dataType {get; set;}
        @AuraEnabled public Decimal order {get; set;}
        @AuraEnabled public List<String> answers {get; set;}
        @AuraEnabled public Map<String, String> answerNextQuestion{get; set;}
        @AuraEnabled public String selectedAnswer {get; set;}
        @AuraEnabled public Boolean isRequired {get; set;}
        @AuraEnabled public String uniqueKey {get; set;}
        @AuraEnabled public String parentUniqueKey {get; set;}
        @AuraEnabled public Decimal minValue {get; set;}
        @AuraEnabled public Decimal maxValue {get; set;}
        @AuraEnabled public String validationMessage {get; set;}
        @AuraEnabled public String applicableValidationType {get; set;}
        @AuraEnabled public String helpText {get; set;}
        @AuraEnabled public Map<String, String> answerMap {get; set;}
        @AuraEnabled public List<CategoryQuestionWrapper> relatedQuestionsList {get; set;}
        @AuraEnabled public String relatedResponseId {get; set;}
        
        public CategoryQuestionWrapper(){}
        public CategoryQuestionWrapper(Qualification_Template_Questions__c qta, String category, String parentUniqueKey){
            this.questionName = qta.Question_Text__c;
            this.dataType = qta.Datatype__c;
            this.order = qta.Order__c;
            this.isRequired = qta.Required__c;
            this.uniqueKey = qta.Name;
            this.minValue = qta.Min_Value__c;
            this.maxValue = qta.Max_Value__c;
            this.helpText = qta.Help_Text__c;
            this.validationMessage = qta.Validation_Message__c;
            this.applicableValidationType = qta.APT_Applicable_Validation__c;
            this.parentUniqueKey = parentUniqueKey;
            if(qta.Related_Response__c != null){
                this.relatedResponseId = qta.Related_Response__r.Name;
            }
            
            if(qta.Datatype__c == 'Picklist Field' || qta.Datatype__c == 'Multiselect Field' || qta.Datatype__c == 'Radio Button'){
                this.answers = new List<String>();
                this.answerMap = new Map<String,String>();
                for(Qualification_Template_Responses__c qtAns :[SELECT Id,
                                                                Response_Text__c,Next_Question__c,Order__c,
                                                                Qualification_Template_Question__c
                                                                FROM Qualification_Template_Responses__c 
                                                                WHERE Qualification_Template_Question__r.Question_Text__c=:this.questionName AND 
                                                                      Qualification_Template_Question__r.name =: this.uniqueKey AND
                                                                      Active__c = true AND   
                                                                      toLabel(Qualification_Template_Question__r.Category__c) = :category ORDER BY Order__c ASC]){
                                                                    this.answers.add(qtAns.Response_Text__c);      
                                                                    this.answerMap.put(qtAns.Response_Text__c, qtAns.Id);
                                                                    
                                                                }
																
				List<CategoryQuestionWrapper> CategoryQuestionWrapperListVar = new List<CategoryQuestionWrapper>();												
				for(Qualification_Template_Questions__c relatedQuestion:[SELECT Id,Question_Text__c,  Datatype__c, Order__c, Required__c, Name,Min_Value__c,Max_Value__c,Validation_Message__c,APT_Applicable_Validation__c,Help_Text__c,
																			(SELECT Id,
																				Response_Text__c,Next_Question__c,Order__c,
																				Qualification_Template_Question__c FROM Qualification_Template_Responses__r)
																		 FROM Qualification_Template_Questions__c
																		 WHERE Related_Response__r.Qualification_Template_Question__r.Question_Text__c=:this.questionName AND 
																		 toLabel(Related_Response__r.Qualification_Template_Question__r.Category__c) = :category ORDER BY Order__c ASC]){
																			 CategoryQuestionWrapper CategoryQuestionWrapperVar = new CategoryQuestionWrapper();
																			 CategoryQuestionWrapperVar.questionName = relatedQuestion.Question_Text__c;
																			 CategoryQuestionWrapperVar.dataType = relatedQuestion.Datatype__c;
																			 CategoryQuestionWrapperVar.order = relatedQuestion.Order__c;
																			 CategoryQuestionWrapperVar.isRequired = relatedQuestion.Required__c;
																			 CategoryQuestionWrapperVar.uniqueKey = relatedQuestion.Name;
																			 CategoryQuestionWrapperVar.minValue = relatedQuestion.Min_Value__c;
																			 CategoryQuestionWrapperVar.maxValue = relatedQuestion.Max_Value__c;
																			 CategoryQuestionWrapperVar.validationMessage = relatedQuestion.Validation_Message__c;
																			 CategoryQuestionWrapperVar.applicableValidationType = relatedQuestion.APT_Applicable_Validation__c;
																			 CategoryQuestionWrapperVar.helpText = relatedQuestion.Help_Text__c;
																			 List<String> answersTemp = new List<String>();
																			 Map<String,String> answerMapTemp = new Map<String,String>();
																			 for(Qualification_Template_Responses__c qtRelatedAns: relatedQuestion.Qualification_Template_Responses__r){
																				 answersTemp.add(qtRelatedAns.Response_Text__c);
																				 answerMapTemp.put(qtRelatedAns.Response_Text__c, qtRelatedAns.Id);
																			 }
																			 CategoryQuestionWrapperVar.answers = answersTemp;
																			 CategoryQuestionWrapperVar.answerMap = answerMapTemp;
																			 CategoryQuestionWrapperListVar.add(CategoryQuestionWrapperVar);
				}
				
				
				this.relatedQuestionsList = CategoryQuestionWrapperListVar;
                                                             
            }
        }
    }

    @AuraEnabled
    public static String submitResponse(
        String leadId, String opportunityId, 
        String disCoveryQuestion, String selectedProducts,
        Map <String,Object> selectedProdQuestionsMap, 
        Map<String, Object> productEstimateMap,
        Map<String, Object> productNotesMap,
        Decimal totalEstimatedRevenue,
        String summaryNotes,
        String primaryProduct,
        String existingQualification,
        String status){
            List<Qualification_Response_Detail__c> existingQualificationList = new List<Qualification_Response_Detail__c>();// This is existing qualification Response Details . existingQualificationList variable has list of Qualification_Response_Detail__c.
            if(existingQualification != null){
                existingQualificationList = ( List<Qualification_Response_Detail__c>)System.JSON.deserialize(existingQualification, List<Qualification_Response_Detail__c>.class);
            }
            String qualId=  new QuestionWrapper().
                insertQualificationDetails(leadId, 
                                           opportunityId,
                                           disCoveryQuestion,
                                           ( List<String>)System.JSON.deserialize(selectedProducts, List<String>.class),
                                           selectedProdQuestionsMap,
                                           productEstimateMap, productNotesMap,totalEstimatedRevenue,summaryNotes,primaryProduct,existingQualificationList);
            if(leadId != null){
                updateLeadDetails(leadId, selectedProducts, primaryProduct,totalEstimatedRevenue, status ); 
            }else if(opportunityId != null){
                updateOpportunityDetails(opportunityId, status, selectedProducts);
            }
            
            if(existingQualificationList != null && !existingQualificationList.isEmpty() && selectedProducts != null && status =='Completed'){
                Id qualificationRecordId = existingQualificationList[0].Qualification_Category_Detail__r.Qualification__c;
                deleteUnSelectedProductCategory(qualificationRecordId, ( List<String>)System.JSON.deserialize(selectedProducts, List<String>.class))   ;
            }

            return qualId;
           
        }
    
    public class QuestionWrapper{
        
        @AuraEnabled public String leadId {get; set;}
        @AuraEnabled public String opportunityId {get; set;}
        @AuraEnabled public Decimal totalEstimate {get; set;}
        @AuraEnabled public String notes {get; set;}
        @AuraEnabled public List<QualificationCategoryDetail> qualifCatList {get; set;}
        
        
        private  String insertQualificationDetails(
            String leadId, String opportunityId, String disCoveryQuestions,
            List<String> selectedProducts, Map <String,Object> selectedProdQuestionsMap,
            Map <String,Object> productEstimateMap, Map<String, Object> productNotesMap,
            Decimal totalEstimatedRevenue,String summaryNotes, String primaryProduct, List<Qualification_Response_Detail__c> existingQualificationList){ 
                this.leadId = leadId;
                this.opportunityId = opportunityId;
                //--[1.] Insert 'Qualification' object record
                Qualification_Response_Detail__c existingQualification;
                if(existingQualificationList != null && !existingQualificationList.isEmpty()){
                    existingQualification = existingQualificationList[0];
                }
                String qualId;
                if(this.leadId != null){
                    qualId = insertQualification
                    (this.leadId,'Lead',totalEstimatedRevenue,summaryNotes,primaryProduct,existingQualification); 
                }else{
                    qualId = insertQualification
                    (this.opportunityId,'Opportunity',totalEstimatedRevenue,summaryNotes,primaryProduct,existingQualification); 
                }
                List<Sobject> sojectList = new  List<Sobject>();
                //--[2.] insert 'Discovery' QCD and its QRD records
                if(disCoveryQuestions != null){
                    List<CategoryQuestionWrapper> catQueWrapperList =  (List<CategoryQuestionWrapper>)
                        System.JSON.deserialize(disCoveryQuestions, List<CategoryQuestionWrapper>.class);
                     //---Can change to QRD object
                    String qcdId = insertQCDObjectRecord('Discovery', qualId, null, null, existingQualification);
                    for(CategoryQuestionWrapper cqw: catQueWrapperList){
                        sojectList.addAll( new QualificationCategoryDetail().buildQC(qcdId,qualId ,cqw ));
                        
                    }
                    Map<String ,Qualification_Response_Detail__c> responseMap = new Map<String ,Qualification_Response_Detail__c>();
                    if(existingQualificationList != null){
                        for(Qualification_Response_Detail__c res : existingQualificationList){
                            responseMap.put(res.Question_Unique_Key__c, res);
                        }
                        for(sObject resVar : sojectList){
                            String uniqueId = (String)resVar.get('Question_Unique_Key__c');
                            if(responseMap.containsKey(uniqueId)){
                                resVar.put('Id', string.valueOf(responseMap.get(uniqueId).Id));
                            }
                        }
                    }
                   
                }
                if(!sojectList.isEmpty()){
                    try{
                        //--insert Discovery Type questions
                        upsert  sojectList;
                    }catch(Exception ex){
                        System.debug('ex====='+ex);
                    }
                }    
                //--[3.]Insert Product Category and its Questions
                
                if(selectedProdQuestionsMap != null && selectedProducts !=null){
                    insertProductCategories(selectedProducts, selectedProdQuestionsMap,qualId,productEstimateMap,productNotesMap, existingQualificationList);
                }
                return qualId;
            }
        
    }
    
    private static void insertProductCategories(
        List<String> selectedProducts, Map <String,Object> selectedProdQuestionsMap,
        String qualId,  Map <String,Object> productEstimateMap,
        Map <String,Object> productNotesMap, List<Qualification_Response_Detail__c> existingQualificationList){
            List<Sobject> sojectList = new  List<Sobject>();  //---Can change to QRD object
            for(String product : selectedProducts){
                Decimal prodCatRevenue ;
                Object revenueVar = (Object)(( Map<Object, Object>)productEstimateMap.get(product)).get('revenue');
                String revenueString ;
                Decimal revenueDecimal ;
                Boolean isDecimal = false;
                if(revenueVar != null){
                    if(revenueVar instanceof String){
                        revenueString = (String)revenueVar;
                    }else if(revenueVar instanceof Decimal){
                        revenueDecimal = (Decimal)revenueVar;
                        isDecimal = true;
                    }
                }
                
                if(isDecimal && revenueDecimal != null){
                    prodCatRevenue = revenueDecimal;
                }else if(revenueString != null) {
                    prodCatRevenue = Decimal.valueOf(revenueString);
                }
                    
                String prodCatNotes = (String)( ( Map<Object, Object>)productNotesMap.get(product)).get('notes');
                Qualification_Response_Detail__c existingQualification;
                if(existingQualificationList!= null && !existingQualificationList.isEmpty()){
                    existingQualification = existingQualificationList[0];
                }
                 
             String qcdId = insertQCDObjectRecord(product, qualId, prodCatRevenue, prodCatNotes, existingQualification);
                if(selectedProdQuestionsMap.containsKey(product)){
                    List<CategoryQuestionWrapper> catQueWrapperList = (List<CategoryQuestionWrapper>)System.JSON.deserialize(JSON.serialize(selectedProdQuestionsMap.get(product)), List<CategoryQuestionWrapper>.class);
                    for(CategoryQuestionWrapper cqw: catQueWrapperList){
                        sojectList.addAll( new QualificationCategoryDetail().buildQC(qcdId,qualId ,cqw ));
                    }
                }
                Map<String ,Qualification_Response_Detail__c> responseMap = new Map<String ,Qualification_Response_Detail__c>();
                if(existingQualificationList != null){ 
                for(Qualification_Response_Detail__c res : existingQualificationList){
                        responseMap.put(res.Question_Unique_Key__c, res);
                    }
                    for(sObject resVar : sojectList){
                        String uniqueId = (String)resVar.get('Question_Unique_Key__c');
                        if(responseMap.containsKey(uniqueId)){
                            resVar.put('Id', responseMap.get(uniqueId).Id);
                        }
                    }
                }
                
            }
            try{
                //--insert all Product Type questions
                if(sojectList.size() > 0)
                    upsert  sojectList;
            }catch(Exception ex){
                System.debug('ex====='+ex);
            }
        }
    
    private static String  insertQCDObjectRecord(String category, String qualId, Decimal prodCatRevenue, String prodCatNotes, Qualification_Response_Detail__c existingQualification){
        Qualification_Category_Detail__c qcd =  new Qualification_Category_Detail__c();
        Id discoveryCategoryId ; 
        Map<String,Qualification_Category_Detail__c> responseWithCategoryMap = new Map<String,Qualification_Category_Detail__c>();
        if(existingQualification != null){
            for(Qualification_Category_Detail__c CategoryVar : [Select Id, Selected_Category__c from Qualification_Category_Detail__c where Qualification__c=: existingQualification.Qualification_Category_Detail__r.Qualification__c ]){
                responseWithCategoryMap.put(CategoryVar.Selected_Category__c, CategoryVar);  
            }          
        }
        if(responseWithCategoryMap.containsKey(category)){
                discoveryCategoryId = responseWithCategoryMap.get(category).Id;
        }
        qcd.put('Qualification__c', qualId);
        qcd.put('Selected_Category__c', category);
        if(prodCatRevenue !=null)
            qcd.put('Category_Estimate__c', prodCatRevenue); 
        
        if(prodCatNotes !=null)
            qcd.put('Notes__c', prodCatNotes); 
        if(discoveryCategoryId != null){
            qcd.put('Id', discoveryCategoryId); 
        }     
        //insert qcd;
        upsert qcd;
        return qcd.id;
    }
    
    public class QualificationCategoryDetail{
        
        @AuraEnabled public String qualificationId {get; set;}
        @AuraEnabled public String category {get; set;}
        @AuraEnabled public Decimal categoryEstimate {get; set;}
        @AuraEnabled public String notes {get; set;}
        @AuraEnabled public String revenue {get; set;}
        @AuraEnabled public List<QualificationResponseDetail> qualifCatList {get; set;}
        
        private  List<Sobject>  buildQC(String qcdId, String qualId, CategoryQuestionWrapper cqw){
            List<Sobject> sojectList = new  List<Sobject>();
            
            sojectList.add(new QualificationResponseDetail().buildQS( qualId,  qcdId, cqw ));
            return sojectList;
        }
        
    }
    public class QualificationResponseDetail{
        
        @AuraEnabled public String qualificationId {get; set;}
        @AuraEnabled public String qualifCatDetailId {get; set;}
        @AuraEnabled public String question {get; set;}
        @AuraEnabled public String response {get; set;}
        
        public  Sobject buildQS(String qualId, String qcdId, CategoryQuestionWrapper cqw){
            Sobject s = new Qualification_Response_Detail__c();

            s.put('Qualification_Category_Detail__c',qcdId);
            s.put('Question__c', cqw.questionName);
            if(cqw.dataType =='number'){
                Integer answerVal;
                if(!String.isEmpty(cqw.selectedAnswer) ){
                    answerVal = Integer.valueOf(cqw.selectedAnswer) ;
                }else{
                    answerVal = null;
                }
                s.put('Response_Number__c', answerVal);
            }else if(cqw.dataType =='date' ){
                date answerVal ;
                if(!String.isEmpty(cqw.selectedAnswer) ){
                    answerVal = date.valueOf(cqw.selectedAnswer) ;
                }else{
                    answerVal = null;
                }
                s.put('Response_Date__c', answerVal);
            }else if(cqw.dataType =='percent' ){
                Decimal answerVal ;
                if(!String.isEmpty(cqw.selectedAnswer) ){
                    answerVal = decimal.valueOf(cqw.selectedAnswer) ;
                }else{
                    answerVal = null;
                }
                s.put('Response_Percent__c', answerVal);
            }else if(cqw.dataType =='Multiline Text'){
                String answerVal = cqw.selectedAnswer;
                s.put('Response_Multiline__c', answerVal);
            }else if(cqw.dataType =='Postcode Lookup'){
                String answerVal = cqw.selectedAnswer;
                    if(!string.isEmpty(answerVal)){
                        s.put('Postcode_Mapping__c', id.valueOf(answerVal));
                    }else{
                        s.put('Postcode_Mapping__c', answerVal);
                    }
            }
            else{
                s.put('Response__c', cqw.selectedAnswer);
            }
            
            s.put('Question_Unique_Key__c', cqw.uniqueKey);
            return s;
        }
        
    }
    
    private static String insertQualification(String id, String objectName , Decimal totalEstimatedRevenue,String summaryNotes, String primaryProduct, Qualification_Response_Detail__c existingQualification){
        Qualification__c qual = new Qualification__c();
        if(objectName == 'Lead'){
            qual.Lead__c = id;
        }else{
            qual.Opportunity__c = id; 
        }
        if(totalEstimatedRevenue !=null)
            qual.Total_Estimate__c = totalEstimatedRevenue;
        if(summaryNotes !=null)
            qual.Notes__c = summaryNotes;
        if(primaryProduct !=null)
            qual.Primary_Product__c = primaryProduct;

        if(existingQualification != null){
            qual.Id = existingQualification.Qualification_Category_Detail__r.Qualification__c ;
        }   
        //insert qual;    
        upsert qual ;
        return qual.Id;
    }
    
    @AuraEnabled
    public static  Map<String, String> getQualificationIdNameMap(String leadId){
        Map<String, String> qualIdNameMap = new Map<String, String>();
        for(Qualification__c q :  [SELECT Id, Name from Qualification__c WHERE Lead__c = :leadId]){
            qualIdNameMap.put(q.id, q.Name);
        }
        return qualIdNameMap;
    }
    
    @AuraEnabled
    public static List<Qualification__c> getQualificationsList(Id recordId){ 
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        if(sObjName != null){
            if(sObjName == 'Lead')
                return [SELECT Id, Name,Total_Estimate__c, Notes__c,CreatedBy.Name,CreatedDate  from Qualification__c WHERE Lead__c = :recordId];
            else  if(sObjName == 'Opportunity')
                return [SELECT Id, Name,Total_Estimate__c, Notes__c,CreatedBy.Name,CreatedDate  from Qualification__c WHERE Opportunity__c = :recordId];
        }
        return null; 
    }
	/**
	 * @description Method to update many fields on Opportunity record
	 * @param		String oppId: specify the Opportunity Id
	 * @param		String selectedProducts: specify product(s) selected from CNA
	 * @param		String status: specify the CNA status
	 * @return		void
	 */
	private static void updateOpportunityDetails(String oppId, String status, String selectedProducts){
		Boolean updateOpp = false;
		List<String> prodList = new List<String>();
		Map<String, String> picklistCategoryValuesMap = new Map<String, String>();

		try{
			// set picklist label as key, to retrieve its API Name value
			picklistCategoryValuesMap = getPickListValuesFromSchema('Qualification_Template_Questions__c', 'Category__c', false);
		}catch(Exception e){
			String errMsg = 'Error occurred while retrieving picklist values' + e.getMessage()+ ' at ' + e.getStacktraceString();
			AuraHandledException ex = new AuraHandledException(errMsg);
			ex.setMessage(errMsg);
			throw ex;
		}

		for(String s :( List<String>)System.JSON.deserialize(selectedProducts, List<String>.class)){
			if(s !='Discovery' && !picklistCategoryValuesMap.isEmpty()){
				// get API name from map value for the update DML
				prodList.add(picklistCategoryValuesMap.get(s));
			}
		}
		Opportunity existingOppRecord = [Select Id , CNA_Status__c, CNA_Start_Date__c, CNA_Complete_Date__c From Opportunity where Id =: oppId];

		Opportunity oppRecord = new Opportunity();
		oppRecord.Id = oppId;

		String cnaStatus = existingOppRecord.CNA_Status__c;
		if(( String.isEmpty(cnaStatus) || cnaStatus.equalsIgnoreCase('Not Started')) && status =='In Progress'){
			oppRecord.CNA_Status__c = 'In Progress';
			oppRecord.CNA_Start_Date__c = System.now();
			updateOpp = true;
		}else if (cnaStatus == 'In Progress' && status =='Completed'){
			oppRecord.CNA_Status__c = 'Completed';
			oppRecord.CNA_Complete_Date__c = System.now();
			updateOpp = true;
		}else if (cnaStatus == 'Not Started' && status =='Completed'){
			oppRecord.CNA_Status__c = 'Completed';
			oppRecord.CNA_Start_Date__c = System.now();
			oppRecord.CNA_Complete_Date__c = System.now();
			updateOpp = true;
		}
		if(prodList != null && prodList.size() > 0){  
			oppRecord.Service_Interested__c = String.join(prodList,';');
			updateOpp = true;
		}

		try{
			if(updateOpp)
				update oppRecord;
		}Catch(Exception e){
			String errMsg = 'Error occurred while updating Opporutnity' + e.getMessage()+ ' at ' + e.getStacktraceString();
			AuraHandledException ex = new AuraHandledException(errMsg);
			ex.setMessage(errMsg);
			throw ex;
		}

	}
	/**
	 * @description Method to update many fields on Lead record
	 * @param		String leadId: specify the Lead Id
	 * @param		String selectedProducts: specify product(s) selected from CNA
	 * @param		String primaryProduct: specify the primary product from CNA
	 * @param		Decimal totalEstimateValue: specify the total estimate value from CNA
	 * @param		String status: specify the CNA status
	 * @return		void
	 */
	private static void updateLeadDetails(String leadId,String selectedProducts,String primaryProduct, Decimal totalEstimateValue, String status ){
		List<String> prodList = new List<String>();
		Map<String, String> picklistCategoryValuesMap = new Map<String, String>();

		try{
			// set picklist label as key, to retrieve its API Name value
			picklistCategoryValuesMap = getPickListValuesFromSchema('Qualification_Template_Questions__c', 'Category__c', false);
		}catch(Exception e){
			String errMsg = 'Error occurred while retrieving picklist values' + e.getMessage()+ ' at ' + e.getStacktraceString();
			AuraHandledException ex = new AuraHandledException(errMsg);
			ex.setMessage(errMsg);
			throw ex;
		}
		
		for(String s :( List<String>)System.JSON.deserialize(selectedProducts, List<String>.class)){
			if(s !='Discovery' && !picklistCategoryValuesMap.isEmpty()){
				// get API name from map value for the update DML
				prodList.add(picklistCategoryValuesMap.get(s));
			}
		}
		Lead existingLeadRecord = [Select Id , CNA_Status__c, CNA_Start_Date__c, CNA_Complete_Date__c From Lead where Id =: leadId];
		Lead l = new Lead();
		l.Id = leadId;
		Boolean updateLead = false;
		/*if(primaryProduct != null && !String.isEmpty(primaryProduct)){
			l.Product__c = primaryProduct;
			updateLead = true;
		}*/
		if(prodList != null && prodList.size() > 0){  
			l.Products__c = String.join(prodList,';');
			updateLead = true;
		}
		l.Qualification_Completed__c = true;
		l.Opportunity_Initial_Estimate__c= totalEstimateValue;
		String cnaStatus = existingLeadRecord.CNA_Status__c;
		if(( String.isEmpty(cnaStatus) || cnaStatus.equalsIgnoreCase('Not Started')) && status =='In Progress'){
			l.CNA_Status__c = 'In Progress';
			l.CNA_Start_Date__c = System.now();
			updateLead = true;
		}else if (cnaStatus == 'In Progress' && status =='Completed'){
			l.CNA_Status__c = 'Completed';
			l.CNA_Complete_Date__c = System.now();
			updateLead = true;
		}else if (cnaStatus == 'Not Started' && status =='Completed'){
			l.CNA_Status__c = 'Completed';
			l.CNA_Start_Date__c = System.now();
			l.CNA_Complete_Date__c = System.now();
			updateLead = true;
		}
		try{
			if(updateLead)
				update l;
		}Catch(Exception e){
			String errMsg = 'Error occurred while updating Lead' + e.getMessage()+ ' at ' + e.getStacktraceString();
			AuraHandledException ex = new AuraHandledException(errMsg);
			ex.setMessage(errMsg);
			throw ex;
		}
	}
    /**
     * @description Return the configured estimate revenue . This will be used for lead qualification flow 
     *              to fetch the primary product and update lead primary product attribute
     */
    @AuraEnabled
    public static  String getStrackTrackProductEstimatedRevenue(){
        STP_Lead_Assignment_Settings__mdt revenueEstimate = new STP_Lead_Assignment_Settings__mdt();
        try{
            revenueEstimate = [Select Attribute_Value__c from STP_Lead_Assignment_Settings__mdt where DeveloperName = 'Star_Track_Estimated_Revenue'] ;
        }Catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'Error while getting Estimtae Revenue for Star Track product ==>'+ex.getCause());
        }
        return revenueEstimate.Attribute_Value__c ;
    }
    @AuraEnabled
    public static List<Qualification_Response_Detail__c> getExistingQualificationDetails(String qualificationRecordId){
        List<Qualification_Response_Detail__c> qualificationList = new List<Qualification_Response_Detail__c>();
        for(Qualification_Response_Detail__c responseVar :[Select Qualification_Category_Detail__c, Question__c, Response__c,Response_Number__c, Response_Date__c,Response_Percent__c,Response_Multiline__c,Postcode_Mapping__c,Postcode_Mapping__r.Name,
                                                                  Qualification_Category_Detail__r.Selected_Category__c, 
                                                                  Qualification_Category_Detail__r.Category_Estimate__c, 
                                                                  Qualification_Category_Detail__r.Notes__c, 
                                                                  Qualification_Category_Detail__r.Qualification__c,Question_Unique_Key__c,
                                                                  Qualification_Category_Detail__r.Qualification__r.Lead__c,
                                                                  Qualification_Category_Detail__r.Qualification__r.Opportunity__c,
                                                                  Qualification_Category_Detail__r.Qualification__r.Notes__c
                                                                  From  Qualification_Response_Detail__c
                                                                  Where  Qualification_Category_Detail__r.Qualification__c =: qualificationRecordId ]){
                                                                   qualificationList.add(responseVar);
                                                                }
        
        return qualificationList;
    }

    public static void deleteUnSelectedProductCategory(Id qualificationRecordId, list<String> selectedProducts){
        Set<String> selectedProductSet = new Set<String>();
        List<Qualification_Category_Detail__c> productCategoryList = new List<Qualification_Category_Detail__c>();
        List<Qualification_Response_Detail__c> productResponseList = new List<Qualification_Response_Detail__c>();
        Set<Id> categoryToDelete = new Set<Id>();
        Set<String> categoryToIgnore = new Set<String>{'Discovery','Operational Details'};
        List<Sobject> sObjectToDelete = new List<Sobject>();
        Map<String, String> activeCategoryMap = getPickListValuesBoth('Qualification_Template_Questions__c', 'Category__c', null);
        for(String selectedProduct : selectedProducts){
            selectedProductSet.add(selectedProduct);
        }

        for(Qualification_Category_Detail__c category : [Select Id, Selected_Category__c from Qualification_Category_Detail__c where Qualification__c =: qualificationRecordId AND Selected_Category__c NOT IN : categoryToIgnore]){
            if(!selectedProductSet.contains(category.Selected_Category__c) && activeCategoryMap.containsKey(category.Selected_Category__c)){
                categoryToDelete.add(category.Id);
                productCategoryList.add(category);
            }
        }
        for(Qualification_Response_Detail__c res :[Select Id from Qualification_Response_Detail__c where Qualification_Category_Detail__c IN : categoryToDelete]){
            productResponseList.add(res);
        }
        if(!productResponseList.isEmpty()){
            delete productResponseList;
        }
        if(!productCategoryList.isEmpty()){
            delete productCategoryList;
        }
    }    
    @AuraEnabled
    public static  Boolean hasBGSalesPermissionSetAssigned(){
        Boolean hasBGSalesPermission = false;

        List<PermissionSetAssignment> permissionSetAssigned = [Select Id From PermissionSetAssignment Where (PermissionSet.Name = 'BG_Sales' OR PermissionSet.Name = 'BG_Sales_User') AND AssigneeId =: userInfo.getUserID() ];
        if(!permissionSetAssigned.isEmpty()){
            hasBGSalesPermission = true;
        }
        return hasBGSalesPermission;
    }
    
    @AuraEnabled
    public static  Boolean isOpportunityConverted(String recordId){
        Boolean showEstimatedRevenue = true;
        String ObjectName = String.valueOf(id.valueOf(recordId).getsobjecttype());
        if(ObjectName == 'Opportunity'){
            Opportunity opp = [Select Id, Lead_ID__c From Opportunity Where Id=: id.valueOf(recordId)];
            if(opp.Lead_ID__c == null){
                showEstimatedRevenue = false;
            }
        }
        return showEstimatedRevenue;
    }
     @AuraEnabled
    public static  Boolean isClosedOpportunity(String recordId){
        Boolean isClosed = false;
        String ObjectName = String.valueOf(id.valueOf(recordId).getsobjecttype());
        if(ObjectName == 'Opportunity'){
            Opportunity opp = [Select Id, isClosed from Opportunity where Id =:recordId];
            if(opp.isClosed){
 				isClosed = true;               
            }
       }
        return isClosed ;
    }

	/**
	 * @description Return a map of the picklist value and picklist label of inputted Sobject and picklist field via Schema Class
	 * 				The returned map can be configured with a booleam param, to have Picklist API name as key and label as value, or vice versa
	 * @param		String sObjectApiName: specify sObject API name
	 * @param		String fieldApiName: specify picklist field API name
	 * @param		Boolean apiAsKey: specify if API name or Label is created as Key for the return map
	 * @return		Map<String,String>
	 */
	public static Map<String,String> getPickListValuesFromSchema(String sObjectApiName, String fieldApiName, Boolean apiAsKey){
		Map<String, String> picklistValuesMap = new Map<String, String>();
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sObjectApiName).getDescribe().fields.getMap();

		// Get the list of picklist values of field.
		list < Schema.PicklistEntry > picklistEntries =
			fieldMap.get(fieldApiName).getDescribe().getPickListValues();

		if(apiAsKey){
			for (Schema.PicklistEntry entry: picklistEntries) {
				picklistValuesMap.put(entry.getValue(), entry.getLabel());
				// add the category api name as key and label as value to the class variable map
			}
		}else{
			for (Schema.PicklistEntry entry: picklistEntries) {
				// add the category label as key and apiname as value to the class variable map
				picklistValuesMap.put(entry.getLabel(), entry.getValue());
			}
		}
		return picklistValuesMap; 
	}
}