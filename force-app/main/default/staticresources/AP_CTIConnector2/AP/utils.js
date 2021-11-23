/**************************************************
Description:	General utility methods for various AP CTI functions

History:
--------------------------------------displa
------------
2018-08-20	nathan.franklin@auspost.com.au	Created
2019-09-04	gunith.devasurendra@auspost.com.au For outgoing call, the response is HTML encoded twice. Removed one layer of encoding. (INC1446801)
**************************************************/
define(['config'],
	function(config) {
		var log_prefix = 'AP/utils: ';

		var getCaseAttachmentActionData = function(voiceInteractionId, caseObj) {
			var actionData = {
				id: voiceInteractionId,
				SF_UserId: config.USER_ID
			};

			var BusinessResultDisplay = unescapeHTML(caseObj.Type) + ' > ' + unescapeHTML(caseObj.ProductCategory__c) + ' > ' + unescapeHTML(caseObj.ProductSubCategory__c) + ' > ' + unescapeHTML(caseObj.EnquirySubType__c);

			// populate the parameters that are sent back to Workspace from the case found in Service Cloud
			// this will convert the Case sobject record into Workspace params
			var keys = Object.keys(config.CASE_MAPPING_OUTCOMES);
			for(var i=0;i<keys.length;i++) {
				actionData[keys[i]] = caseObj[config.CASE_MAPPING_OUTCOMES[keys[i]]];
			}

			// special parameter
			actionData.BusinessResultDisplay = BusinessResultDisplay;

			return actionData;
  		};

		var isAnonymousPhoneNumber = function(ani) {
			return ['unavailable', '0anonymous', 'anonymous'].includes(ani);
		}

		/**
		 * Map the CTI vars to the mappings defined on the call center configuration for Case
		 */
		var getCaseMappingValues = function(payload) {
			// NOTE: CASE_MAPPINGS set in AP_CTIConnector.page
			console.log(log_prefix, 'getCaseMappingValues - start', config.CASE_MAPPINGS, payload);
			var mappedValues = mapValues(config.CASE_MAPPINGS, payload);
			console.log(log_prefix, 'mappedValues', mappedValues);
			return mappedValues;
		};

		/**
		 * Map the CTI vars to the mappings defined on the call center configuration for Case
		 * This expects a payload of a Case record to convert back to params for use to attach data back to workspace
		 */
		var getCaseMappingValuesReversed = function(payload) {
			// NOTE: CASE_MAPPINGS set in AP_CTIConnector.page
			console.log(log_prefix, 'getCaseMappingValuesReversed - start', config.CASE_MAPPINGS, payload);
			var mappedValues = mapValuesReverse(config.CASE_MAPPINGS, payload);
			console.log(log_prefix, 'mappedValuesReversed', mappedValues);
			return mappedValues;
		};

		/**
		 * Map the CTI vars to the mappings defined on the call center configuration for Task
		 */
		var getTaskMappingValues = function(payload) {
			// NOTE: TASK_MAPPINGS set in AP_CTIConnector.page
			return mapValues(config.TASK_MAPPINGS, payload);
		};

		/**
		 * Provides underlining mapping functionality
		 */
		var mapValues = function(mappings, values) {
			var output = {};

			$.each(mappings, function (sfdcField, workspaceField) {
				var value = values[workspaceField];
				if(!isEmpty(value)) {
					output[sfdcField] = value;
				}
			});

			return output;
  		};

  		/**
  		 * Does the reverse of mapValues
  		 */
  		var mapValuesReverse = function(mappings, values) {
			var output = {};

			$.each(mappings, function (sfdcField, workspaceField) {
				var value = values[sfdcField];
				if(!isEmpty(value)) {
					output[workspaceField] = value;
				}
			});

			return output;
		};

  		var isEmpty = function(val) {
			// test results
			//---------------
			// []		true, empty array
			// {}		true, empty object
			// null	  true
			// undefined true
			// ''		true, empty string
			// ''		true, empty string
			// 0		 false, number
			// true	  false, boolean
			// false	 false, boolean
			// Date	  false
			// function  false

			if (val === undefined)
				return true;

			if (typeof (val) == 'function' || typeof (val) == 'number' || typeof (val) == 'boolean' || Object.prototype.toString.call(val) === '[object Date]')
				return false;

			if (val == null || val.length === 0)		// null or 0 length array
				return true;

			if (typeof(val) == 'object') {
				// empty object
				var r = true;

				for (var f in val)
					r = false;

				return r;
			}

			return false;
		};

		var getCtiOption = function(settings, section, optionName, defValue) {
			var value = settings['/' + section + '/' + optionName];
			if (value) {
				console.log('getOption', section, optionName, value);
				return value;
			} else {
				console.log('getOption', section, optionName, '(default)', defValue);
				return defValue;
			}
		};

		return {
			isAnonymousPhoneNumber: isAnonymousPhoneNumber,
			getCaseAttachmentActionData: getCaseAttachmentActionData,
			getCaseMappingValuesReversed: getCaseMappingValuesReversed,
			getCaseMappingValues: getCaseMappingValues,
			getTaskMappingValues: getTaskMappingValues,
			isEmpty: isEmpty,
			getCtiOption: getCtiOption
  		};
	}
);

