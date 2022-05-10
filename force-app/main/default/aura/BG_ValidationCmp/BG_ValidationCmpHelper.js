({
	validateNumericValue : function(cmp,productionQuestion) {
		var answer = productionQuestion.selectedAnswer;
		// Check if it is valid number
		if(typeof answer !== 'number' && !Number(answer)){
			// 0 is a valid input
			if(parseInt(answer) === 0){
				return true;
			}
			return false;
		}
		return true;
	},
	validateMinMaxRange : function(cmp,productionQuestion) {
		// validate if the input is numeric value
		var passNumericValidation = this.validateNumericValue(cmp,productionQuestion);
		if(passNumericValidation === false){
			return false;
		}
		var minVal = productionQuestion.minValue;
		var maxVal = productionQuestion.maxValue;
		var answer = productionQuestion.selectedAnswer;
		// validate the range input if out of range
		if(answer < minVal || answer > maxVal){
			return false;
		}
		return true;
	}
})