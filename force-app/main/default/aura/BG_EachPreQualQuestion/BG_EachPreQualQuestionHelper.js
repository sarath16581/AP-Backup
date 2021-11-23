({
    buildList: function (cmp, inputList) {
        var items = [];
        for(var i=0; i<inputList.length;i++){
            var item = {
                "label": inputList[i],
                "value": inputList[i],
            };
            
            items.push(item);
        }
        
       /* items.sort(function(a, b){
            var x = a.label.toLowerCase();
            var y = b.label.toLowerCase();
            if (x < y) {return -1;}
            if (x > y) {return 1;}
            return 0;
        }); */
        return items;
    },
    buildListFromStr: function (cmp, str) {
        var inputList = str.split(',');
        var items = [];
        for(var i=0; i<inputList.length;i++){
            items.push(inputList[i]);
        }
        return items;
    },
   checkAllValid:function(cmp, event){
        var inputCmpFields = cmp.find('field');
        var allValid;
        if(Array.isArray(inputCmpFields)){
            allValid = this.asArray(inputCmpFields).reduce(function (validSoFar, inputCmp) {
                
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
            
            }, true);
            
        }else{
            inputCmpFields.reportValidity();
            allValid = inputCmpFields.checkValidity();
        }
        return allValid;
    } ,
    reportAllInValid:function(cmp, event){
        var inputCmpFields = cmp.find('field');
        if(Array.isArray(inputCmpFields)){
            var allValid = this.asArray(inputCmpFields).reduce(function (validSoFar, inputCmp) {
                if(inputCmp != 'undefined'){
                    inputCmp.reportValidity();
                }
            }, true);
        }else{
            inputCmpFields.reportValidity();
        }
    } ,
    asArray: function(x) {
        if (Array.isArray(x)) return x;
        else return x ? [x] : [];
    },
    getRelatedQuestions : function(cmp, evt){
        var parentUniqueKey = evt.getParam('ParentQuestionUniqueKey');
        var selectedAnswer = evt.getParam('selectedAnswer');
        var relatedResponseIds = new Set();
            var action = cmp.get('c.getRelatedQuestions');
            action.setParams({ "parentUniqueKey" : parentUniqueKey,
                                "selectedAnswer" : JSON.stringify(selectedAnswer)
                            });
            action.setCallback(this, function(response) {
                if (response.getState() == "SUCCESS") {
                    var relatedQuestionsVar = response.getReturnValue();
                    var numberOfRelatedQuestions;
                    if(relatedQuestionsVar.length > 0){
                        cmp.set("v.relatedQuestions", relatedQuestionsVar);
                        var selectedPrdtVar = cmp.get("v.selectedProductRelatedQuestions."+cmp.get('v.product'));
                        if(selectedPrdtVar){
                            cmp.set("v.selectedProductRelatedQuestions."+cmp.get('v.product'),relatedQuestionsVar);
                        }                        
                        cmp.set("v.showRelatedQuestion", true);
                        numberOfRelatedQuestions =relatedQuestionsVar.length ; 
                        relatedQuestionsVar.forEach(el=>{
                            relatedResponseIds.add(el.relatedResponseId);
                        })
                       
                    }else{
                        cmp.set("v.relatedQuestions", '');
                        cmp.set("v.showRelatedQuestion", false); 
                        numberOfRelatedQuestions = 0;          
                    }
                    var selectedOptionValue= cmp.get('v.multiSelectAnswerList');
                    var temp;
                    if(selectedOptionValue.length > 0){
                        for(var i=0; i<selectedOptionValue.length ; i++){
                            if(i==0)
                                temp = selectedOptionValue[i];
                            else
                                temp = temp + ',' +selectedOptionValue[i];
                        }
                        cmp.set("v.catQuestion.selectedAnswer",temp);
                    }else{
                        cmp.set("v.catQuestion.selectedAnswer",selectedAnswer);    
                    }
                    var GenEvent = cmp.getEvent("RelatedQuestionOrderEvt");
                    GenEvent.setParam("ParentQuestionUniqueKey", parentUniqueKey);
                    GenEvent.setParam("relatedQuestions", relatedQuestionsVar);
                    GenEvent.setParam("relatedResponseIds", relatedResponseIds);
                    GenEvent.fire();
                }
                else if (response.getState() == "INCOMPLETE") {
                    console.log("Response Incomplete");
                }else if (response.getState() == "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                            
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
    }
})