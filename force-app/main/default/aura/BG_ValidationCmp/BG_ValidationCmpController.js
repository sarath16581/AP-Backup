({
	validateResponse : function(cmp,event, helper){
		// Create an object containing validation information to be sent to parent component for display
		var passValidation = {
			status : true,
			errorMsg  : null
		};
		var discoveryCategoryQuestionsTemp= cmp.get('v.discoveryCategoryQuestions');
		var selectedProductsQuestionsTemp= cmp.get('v.selectedProductsQuestions');
		// Validate Discovery questions if exists
		if(discoveryCategoryQuestionsTemp !== null){
			discoveryCategoryQuestionsTemp.forEach(discoveryRec =>{ 
				if(discoveryRec.applicableValidationType === 'Range' && productionQuestion.hasOwnProperty('selectedAnswer')
							&& discoveryRec.selectedAnswer !== null && discoveryRec.selectedAnswer !== ''){
						// call method to validate the range input
						var validResult = helper.validateMinMaxRange(cmp,discoveryRec);
						if(validResult === false){
							passValidation = {
								status : false,
								errorMsg  : discoveryRec.validationMessage
							};
							return passValidation;
						}
					}
			});
		}
		// Validate Selected Product questions if exists
		else if(selectedProductsQuestionsTemp !== null){
			for(var key in selectedProductsQuestionsTemp){
				selectedProductsQuestionsTemp[key].forEach(productionQuestion =>{
					if(productionQuestion.applicableValidationType === 'Range' && productionQuestion.hasOwnProperty('selectedAnswer')
							&& productionQuestion.selectedAnswer !== null && productionQuestion.selectedAnswer !== ''){
						// call method to validate the range input
						var validResult = helper.validateMinMaxRange(cmp,productionQuestion);
						if(validResult === false){
							passValidation = {
								status : false,
								errorMsg  : productionQuestion.validationMessage
							};
							return passValidation;
						}
					}
				})
			}
		}
		return passValidation;
	}
})