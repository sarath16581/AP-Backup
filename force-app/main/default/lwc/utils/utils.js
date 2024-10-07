/**
 * @author		: Sameed Khan<sameed.khan@mav3rik.com>
 * @date		: 01/05/2019
 * @description	: Utility component that provides some helper functions
--------------------------------------- History --------------------------------------------------
01.04.2019	Sameed Khan(Mav3rik)	Created
22.08.2019	Gunith Devasurendra	 Added ausPhoneNumberRegEx (REQ1886690)
13.08.2019	Gunith Devasurendra	 Added getOrEmpty(..)
21.07.2022	Mahesh Parvathaneni	 Added validateInputComponents
29.08.2022	Hasantha Liyanage	Added validatePhone
17.03.2023	Naveen Rajanna	Added isUndefinedOrNull and formatDate
17.04.2023	Sarath Burra	Added Delay
20.04.2023	Sarath Burra	Added logic for Polling using refreshApex
**/
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import LOCALE from '@salesforce/i18n/locale';

/**
 * Common Regular Expression for Australian Phone numbers.
 * Valid ones include: +61 455 562 400, (02) 4371 3164, 433-245-898, 13 13 13. See https://regex101.com/r/eiufOH/18
 */
export const ausPhoneNumberRegEx = '(^(?:\\+?(61))? ?(?:\\((?=.*\\)))?(0?[2-57-8])\\)? ?(\\d\\d(?:[- ](?=\\d{3})|(?!\\d\\d[- ]?\\d[- ]))\\d\\d[- ]?\\d[- ]?\\d{3})$)|(^13[- ]?\\d\\d[- ]?\\d\\d$)';

/**
 * Create an Empty search result
 */
export const emptySearch = {
	isEmpty: true,
}
/**
 * Create a delay
 */
export const delay = (ms) => {
	// eslint-disable-next-line @lwc/lwc/no-async-operation
	return new Promise(resolve => setTimeout(resolve, ms));
};

/*  takes in a param and if the param is an array, it returns the param unchanged,
	if it's null or undefined, an empty array is returned, otherwise the param is
	returned wrapped in an array
	*/
export const ensureArray = thing => {
	return Array.isArray(thing) ? thing : thing !== undefined && thing != null ? [thing] : []; // eslint-disable-line no-undef
}

/*  A higher-order function that returns another function, that, as long as it
	continues to be invoked, will not be triggered. The function will be called
	after it stops being called for N milliseconds. If `immediate` is passed,
	trigger the function on the leading edge, instead of the trailing.

	This is used as a performance optimization for functions that make server
	calls and are invoked continuoustly times, for instance, from user input.
	By debouncing such a function, we ensure it will only be called once after
	the last time it was invoked after waiting for the specified wait period.
	If the function is called again, within this wait period, it's delayed again.
	*/
export function debounce(func, wait, immediate) {
	var timeout;
	return function () {
		var context = this, args = arguments;
		var later = function () {
			timeout = null;
			if (!immediate) func.apply(context, args);
		};
		var callNow = immediate && !timeout;
		clearTimeout(timeout);
		// eslint-disable-next-line @lwc/lwc/no-async-operation
		timeout = setTimeout(later, wait);
		if (callNow) func.apply(context, args);
	};
}

/*  takes an array, an index and an element (or a list of elements) to insert
	in the array and inserts the element(s) at that index

	Basically, it's more readable than performing a null check on the elements
	and then calling splice on the array whenever we need to insert an element
	at a specific index.
*/
export function insertAtIndex(array, index, elems) {
	if (index > -1 && (!elems || elems !== [])) {
		array.splice(index, 0, elems);
	}
}

/*  Shows a notification in the form of a toast in salesforce. The variant
	options can be error, info, success and warning.

	This function mothod partially applies message, variant and title to create a
	ShowToastEvent and returns a function that takes in the context(thisArg), and
	fires dispatches the event
	*/
export const showNotification = (message, variant = 'info', title, mode) => {
	const evt = new ShowToastEvent({
		title: title,
		message: message,
		variant: variant,
		mode: mode,
	});
	return thisArg => {
		thisArg.dispatchEvent(evt)
	}
}

/*  implementation of lodash get

	Gets the value at path of object. If the resolved value is undefined,
	the defaultValue is returned in its place.
*/
export const get = (object, path, defaultVal) => {
	if (object === undefined) {
		return defaultVal;
	}
	path = Array.isArray(path) ? path : path.split('.');
	object = object[path[0]];
	if (object && path.length > 1) {
		return get(object, path.slice(1));
	}
	return object === undefined ? defaultVal : object;
}

/**
 * Calls #get() unless if the object has #isEmpty() which returns true
 */
export const getOrEmpty = (object, path, defaultVal) => {
	return (typeof(object.isEmpty) === 'function' && object.isEmpty === true) ? '' : get(object, path, defaultVal);
}


export const DAMAGE_MISSING_CONTENTS_ERROR_MESSAGE = 'Scroll up and select either damaged article or missing contents.';
export const REQUIRED_ERROR_MESSAGE = 'Complete this field';

/**
 * function to validate the input elements
 * https://developer.salesforce.com/docs/component-library/bundle/lightning-input/documentation
 * @param {array} inputComponentList
 * @param {boolean} reportValidity
 * @returns {boolean}
 */
 export const validateInputComponents = (inputComponentList, reportValidity) => {
	let inputList = [];
	if (!Array.isArray(inputComponentList)) inputList.push(inputComponentList);
	else inputList = inputComponentList;
	return inputList.reduce((validSoFar, inputCmp) => {
		inputCmp.setCustomValidity('');
		if (reportValidity) {
			inputCmp.reportValidity();
			inputCmp.showHelpMessageIfInvalid();
		}
		return validSoFar && inputCmp.checkValidity();
	}, true);
};

/**
 * validating phone number fields according to the help and support UI standards
 * @param {string} phNumber
 * @returns {boolean}
 */
 export const validatePhone  = (phNumber) => {
	var isValid = false;
	if (phNumber) {
		let valTrimmed = phNumber.replace(/[\s\)\(-]+/g, '');
		if (
			valTrimmed.match(/^0\d{9}$/) ||	 // 10 character number starting with 0
			valTrimmed.match(/^\+?61\d{9}$/) || // 12 character number starting with +61
			valTrimmed.match(/^13\d{4}$/) ||	// 6 character number starting with 13
			valTrimmed.match(/^1300\d{6}$/)	 // 10 character number starting with 1300
		){
			isValid = true;
		}
	}
	return isValid;
 };

/**
 * validating email fields according to the help and support UI standards
 * @param {string} email
 * @returns {boolean}
 */
 export const validateEmail  = (email) => {
	let isValid = false;
	const regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
	if (email && email.match(regExpEmailformat)) {
		isValid = true;
	}
	return isValid;
 };

/* function checks if field is undefined or null
 * @param  field
 * @returns boolean
 */
export const checkUndefinedOrNull = (field) => {
	return (typeof field === 'undefined' || field === null);
}

// Function to refresh a page with a poll
//Executes poll based on the preset interval and uses refreshApex to reload the data
//data if its passed from a wire method needs to be the result from Wire without destructuring
//Example to poll for every 20secs for one hour it should be async (fn, interval = 20000, timeout = 3600000)
export const refreshPageWithPoll =  (refreshData,interval,timeout) => {
	return poll(reloadData, interval, timeout, refreshData);

}
//Using refreshApex to reloadData
export const reloadData=(refreshData) =>{
	return refreshApex(refreshData);

}
// Polling function that excutes the function passed into it after every interval until a timeout it reached
// the first execution of the polled function is done after an initial delay of the interval
// the function the executes will not return a value.
// by default we pass the interval and timeout from the parent
export const poll = async (fn,interval,timeout,refreshData) => {
	let timer;
	const endTime = Number(new Date()) + timeout;
	const polledFunction = (resolve, reject) => {
		if (timer) {
			clearTimeout(timer);
		}
		if (Number(new Date()) < endTime) {
			// eslint-disable-next-line @lwc/lwc/no-async-operation
			setTimeout(polledFunction, interval, resolve, reject);
		}else {
			reject(new Error(`timed out for ${fn}`));
		}
		fn(refreshData);
	}
	await delay(interval)
	return new Promise(polledFunction)
	/*promise.then((message) => {console.log(message);})
	.catch((error) => {
		return error;
	});*/
}

/**
 * function checks if field is undefined or null
 */
 export const isUndefinedOrNull = field => typeof field === 'undefined' || field === null;

/**
 * format Date to locale
 */ 
 export const formatDate = (dateToFormat) => {
	let dateTimeFormat = new Intl.DateTimeFormat(LOCALE);
	let date = new Date(dateToFormat);
	return dateTimeFormat.format(date);
}
  /**
   * Tests to see if a string is blank.
   * Blank strings include `undefined`, `null`, or `''` values.
   * By default, a string with only whitespace will be considered to be blank.
   *
   * @param {string|undefined|null} str - The string to test.
   * @param {object} [options] - Options to configure the test.
   * @param {boolean} [options.allowWhitespace] - If 'true' will not treat a string with only spaces as blank.
   *
   * @returns {boolean} Returns `true` if the field is blank, otherwise `false`.
   */
  export function isBlank(str, options) {
	const allowWhitespace = (options ?? {}).allowWhitespace === true;
	if (typeof str !== "string" && str !== undefined && str !== null) {
	  throw new TypeError(`'${typeof str}' is not a string`);
	}
	if (str == undefined || str == null) {
	  return true;
	}
	return (allowWhitespace ? str : str?.replace(/\s/g, "")) === "";
  }
  
  /**
   * Tests to see if a string is not blank.
   * Blank strings include `undefined`, `null`, or `''` values.
   * By default, a string with only whitespace will be considered to be blank.
   *
   * @param {string|undefined|null} str - The string to test.
   * @param {object} [options] - Options to configure the test.
   * @param {boolean} [options.allowWhitespace] - If 'true' will not treat a string with only spaces as blank.
   *
   * @returns {boolean} Returns `true` if the field is not blank, otherwise `false`.
   */
  export function isNotBlank(str, options) {
	return isBlank(str, options) === false;
  }