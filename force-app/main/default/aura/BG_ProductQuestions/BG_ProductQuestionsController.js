({
    doInit: function(cmp, event, helper) {
        var selectedPrdct = cmp.get("v.selectedProductsQuestions."+cmp.get('v.product'));        
        helper.checkOpportunityIsConverted(cmp);
        if(cmp.get("v.selectedProductsQuestions."+cmp.get('v.product')) == null){
            helper.fetchCategoryQuestions(cmp);
        }else{
            if(cmp.get("v.selectedProductsQuestions."+cmp.get('v.product')+".revenue") != null){
                cmp.set("v.estimatedRevenue",cmp.get("v.selectedProductsQuestions."+cmp.get('v.product')+".revenue"));
            }
            if(cmp.get("v.selectedProductsQuestions."+cmp.get('v.product')+".notes") != null){
                cmp.set("v.notes",cmp.get("v.selectedProductsQuestions."+cmp.get('v.product')+".notes"));
            }
            if(cmp.get('v.selectedProductsQuestions.'+cmp.get('v.product')) != null){
                cmp.set("v.productQuestions",cmp.get('v.selectedProductsQuestions.'+cmp.get('v.product')));
            }
        }
        
    },
    onchangeRevenue: function(cmp, event, helper) {
        cmp.set("v.selectedProductsQuestions."+cmp.get('v.product')+".revenue",cmp.get('v.estimatedRevenue'));
    },
    onchangeNotes: function(cmp, event, helper) {
        cmp.set("v.selectedProductsQuestions."+cmp.get('v.product')+".notes",cmp.get('v.notes'));
    },
    reportValidity : function(cmp, event, helper) {
        helper.reportAllInValid(cmp, event);
    },
    
    checkValidity: function (cmp, evt, helper) {
        var allValid =  helper.checkAllValid(cmp, evt);
        return allValid;
    },
    handleRelatedQuestionEvent : function(cmp, evt, helper){
        var ParentQuestionUniqueKey = evt.getParam('ParentQuestionUniqueKey');
        var relatedQuestionsVar = evt.getParam('relatedQuestions');
        var relatedResponseIds = evt.getParam('relatedResponseIds');
        var questionsVar = [];
        var questionSet = new Set();
        var originalQuestions =[];
        originalQuestions = cmp.get('v.productQuestions');
        var answerMap = new Map()
        var originalQuestionsMap = new Map();
        var relatedQuestionsMap = new Map();
        cmp.get('v.productQuestions').forEach(elementVar =>{
            originalQuestionsMap.set(elementVar.uniqueKey, elementVar);
        })
        relatedQuestionsVar.forEach(elemVar =>{            
            if(relatedQuestionsMap.has(elemVar.parentUniqueKey)){
                let questionTemp = [];
                questionTemp = relatedQuestionsMap.get(elemVar.parentUniqueKey);                
                questionTemp.push(elemVar);
                console.log('questionTemp>>>',questionTemp);
                relatedQuestionsMap.set(elemVar.parentUniqueKey, questionTemp);
            }else{
                let questionTemp = [];
                questionTemp.push(elemVar);
                relatedQuestionsMap.set(elemVar.parentUniqueKey, questionTemp);
            }
            
        })
        
        for(var key of originalQuestionsMap.keys()){
            var qVar = originalQuestionsMap.get(key);
            if(qVar.relatedResponseId != null){
                if(relatedResponseIds.has(qVar.relatedResponseId)){
                    questionsVar.push(qVar);
                }else if(qVar.parentUniqueKey != ParentQuestionUniqueKey){
                    questionsVar.push(qVar);
                }
            }else{
                questionsVar.push(qVar);
            }
            if(relatedQuestionsMap.has(key)){
                var relatedQuestionsTemp = relatedQuestionsMap.get(key);
                relatedQuestionsTemp.forEach(e =>{
                    if(!originalQuestionsMap.has(e.uniqueKey)){
                        questionsVar.push(e);
                    }
                })
                
            }
        }
        if(questionsVar.length >0){
            cmp.set('v.productQuestions', questionsVar);
        }
        
        var revenueTmp = cmp.get("v.selectedProductsQuestions."+cmp.get('v.product')+".revenue");
        var noteTemp = cmp.get("v.selectedProductsQuestions."+cmp.get('v.product')+".notes");
        cmp.set("v.selectedProductsQuestions."+cmp.get('v.product'),questionsVar);
        cmp.set("v.selectedProductsQuestions."+cmp.get('v.product')+".revenue", revenueTmp);
        cmp.set("v.selectedProductsQuestions."+cmp.get('v.product')+".notes", noteTemp);
    }
})