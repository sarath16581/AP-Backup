({
	cutText: function (text, maxLengthParam) {
		var resultText,
			lastWordPos,
			maxLength = parseInt(maxLengthParam, 10);

		if (typeof text !== 'string' || maxLength < 1) {
			return '';
		}

		if (text.length <= maxLength) {
			return text;
		}

		resultText = text.substr(0, maxLength);
		lastWordPos = resultText.lastIndexOf(' ');

		if (lastWordPos > 0) {
			resultText = resultText.substr(0, lastWordPos);
		}

		return resultText;
	}

})