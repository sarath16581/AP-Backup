({
    doInit : function(cmp, event, helper) {
        var questVar = cmp.get('v.catQuestion');
        if(cmp.get('v.catQuestion.dataType') == 'Picklist Field' || cmp.get('v.catQuestion.dataType') == 'Multiselect Field' || cmp.get('v.catQuestion.dataType') == 'Radio Button'){
            cmp.set('v.options', helper.buildList(cmp,cmp.get('v.catQuestion.answers')));
        }
        if(cmp.get('v.catQuestion.selectedAnswer') != null && cmp.get('v.catQuestion.dataType') == 'Multiselect Field' ){
            var temp = cmp.get('v.catQuestion.selectedAnswer');
            cmp.set('v.multiSelectAnswerList', helper.buildListFromStr(cmp,temp));
        }
    },
    onchangeMultiselect: function(cmp, event, helper) {
        var temp;
        var selectedOptionValue= cmp.get('v.multiSelectAnswerList');
        for(var i=0; i<selectedOptionValue.length ; i++){
            if(i==0)
                temp = selectedOptionValue[i];
            else
                temp = temp + ',' +selectedOptionValue[i];
        }
        cmp.set("v.catQuestion.selectedAnswer",temp);
    },
    reportValidity : function(cmp, event, helper) {
        //helper.reportAllInValid(cmp, event);
    },
    
    checkValidity: function (cmp, evt, helper) {
        //var allValid =  helper.checkAllValid(cmp, evt);
        //return allValid;
        return true;
    },
    handleRelatedQuestionEvent: function(cmp, evt, helper){
        helper.getRelatedQuestions(cmp, evt);
    }
})