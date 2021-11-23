/*
/* @author avula.jansirani@auspost.com.au
* @date 2021-02-25
* @channel Business Credit Account
* @tag Business Credit Account
* @description: common methods
* @changelog
* 2021-02-25 avula.jansirani@auspost.com.au
*
*/

export const ERROR_NO_ABN = 'Enter an ABN';
export const ERROR_NO_ACN = 'Enter an ACN';
export const ERROR_INVALID_ABN_FORMAT = 'Enter a valid ABN';
export const ERROR_INVALID_ABN_CHARACTERS = 'Enter a valid ABN';
export const ERROR_INVALID_ACN_FORMAT = 'Enter a valid ACN';
export const ERROR_INACTIVE_ABN = 'Sorry, it looks like your ABN is inactive. You won\'t be able to proceed with this online application.';
export const ERROR_INACTIVE_ACN = 'Sorry, it looks like your ACN is inactive. You won\'t be able to proceed with this online application.';
export const ERROR_NOT_FOUND_ACN = 'Sorry, we coundn\'t find your ACN. Please try again.';
export const ERROR_NOT_FOUND_ABN = 'Sorry, we coundn\'t find your ABN. Please try again.';
export const ERROR_GENERIC__ABN_ACN_SEARCH ='Sorry, we weren\'t able to search for your ABN. Please try again in a couple of minutes. If you encounter this error again, please contact us at newcreditaccount@auspost.com.au for further assistance.';
export const ERROR_INVALID_ENTITY_TYPE = 'Sorry, this online application isn\'t available for your ABN entity type. Please contact us at newcreditaccount@auspost.com.au for further assistance.';


export const EMAIL_ADDRESS_VALUE_MISSING_VALIDATION_MESSAGE = 'Enter an email address';
export const EMAIL_ADDRESS_PATTERN_MISMATCH_VALIDATION_MESSAGE = 'Enter a valid email address';

export const Enter_ESTIMATED_COST_VALUE_MISSING_VALIDATION_MESSAGE = 'Enter an estimated monthly postage costs';
export const ENTER_VALID_ESTIMATED_MONTHLY_POSTAGE_COST = 'Enter a valid estimated monthly postage cost';

export const  BUSINESS_TYPE_DETAILS__INDUSTRY_DIVISION__VALUE_MISSING_ERROR_MSG = 'Select an industry division';
export const  BUSINESS_TYPE_DETAILS__INDUSTRY_CLASS__VALUE_MISSING_ERROR_MSG = 'Select an industry class';

export const REVIEW_AUTHORIZE_TEXT ='I/We accept the business credit account terms and conditions ';
export const REVIEW_TERMS_CONDITIONS_ERROR_MESSAGE ='Please accept the terms and conditions to print or submit';

export const REVIEW_TERMS_BUSINESS_PURPOSE_TEXT ='I/We declare that the credit to be provided to me/us by Australia Post is to be applied wholly or predominantly for business purposes';

export const REVIEW_BUSINESS_PURPOSE_TERMS_CONDITIONS_ERROR_MESSAGE ='Please accept the declaration to print or submit';
export const REVIEW_BUSINESS_PRIVACY_NOTICE_TERMS_CONDITIONS_ERROR_MESSAGE ='Please accept the privacy notice to print or submit';

export const FIELD_LENGTH_100 = 100;
export const FIELD_LENGTH_40 = 40;
export const FIELD_LENGTH_30 = 30;
export const FIELD_LENGTH_32 = 32;
export const FIELD_LENGTH_48 = 48;
export const FIELD_LENGTH_80 = 80;
export const FIELD_LENGTH_10 = 10;

export const BSB_INPUT_ID = 'bsb';
export const BSB_LENGTH = 6;
export const ACCOUNT_NUMBER_INPUT_ID = 'accountNumber';
export const ACCOUNT_NUMBER_MIN_LENGTH = 6;
export const ACCOUNT_NUMBER_MAX_LENGTH = 9;

export const EMAIL_REG_EXP_PATTERN = /[a-zA-Z\-0-9._%+-]+@[a-zA-Z\-0-9.-]+\.[a-zA-Z]{2,}$/;

//-- The below message will set if 'input' required field value is missing
const DEFAULT_VALUE_MISSING_VALIDATION_MESSAGE = 'Please fill in this field';

export const isNumericInput = (event) => {
    const key = event.keyCode;
    return (event.shiftKey != true &&  //[Jansi:] Added "event.shiftKey condition to prevent special chars allowed like #, $
         ((key >= 48 && key <= 57) || // Allow number line
        (key >= 96 && key <= 105)) // Allow number pad
    );
};

export const isModifierKey = (event) => {
    const key = event.keyCode;
    return ( key === 35 || key === 36) || // Allow Shift, Home, End  //[Jansi:] commented "event.shiftKey === true ||" check to prevent special chars allowed like #, $.
        (key === 8 || key === 9 || key === 13 || key === 46) || // Allow Backspace, Tab, Enter, Delete
        (key > 36 && key < 41) || // Allow left, up, right, down
        (
            // Allow Ctrl/Command + A,C,V,X,Z
            (event.ctrlKey === true || event.metaKey === true) &&
            (key === 65 || key === 67 || key === 86 || key === 88 || key === 90)
        )
};


export const formatPhone = (inputRaw) => {
    // by default, return as is
    let sFormat = inputRaw.replace(/\D/g,'');
    const inputMobile = inputRaw.replace(/\D/g,'').substring(0,2); // First two digits to find mobile or landline
    const input = inputRaw.replace(/\D/g,'').substring(0,10); // First ten digits of input only

    if( inputMobile === '04'){
        //this.phoneMaxLength = 12;
        const zip = input.substring(0,4);
        const middle = input.substring(4,7);
        const last = input.substring(7,10);

        if(input.length > 7){sFormat = `${zip} ${middle} ${last}`;}
        else if(input.length > 4){sFormat = `${zip} ${middle}`;}
        else if(input.length > 0){sFormat = `${zip}`;}
    }else{
        //this.phoneMaxLength = 14;
        const zip = input.substring(0,2);
        const middle = input.substring(2,6);
        const last = input.substring(6,10);

        if(input.length > 6){sFormat = `(${zip}) ${middle} ${last}`;}
        else if(input.length > 2){sFormat = `(${zip}) ${middle}`;}
        else if(input.length > 0){sFormat = `${zip}`;}
    }
    return sFormat;
}

export const formatAmount = (inputRaw) => {
    let sFormat = inputRaw.replace(/\D/g,'');
    
    if(sFormat.length > 4){
        let sHead = sFormat.substring(0, 2);
        let sTail = sFormat.substring(2, 5);
        return '$' + sHead + ',' + sTail;
    }
    if(sFormat.length > 3){
        let sHead = sFormat.substring(0, 1);
        let sTail = sFormat.substring(1, 4);
        return '$' + sHead + ',' + sTail;
    }

    return '$' + sFormat;
}


//-- report the errors for given input elements
export const reportAllCmpValidity = (inputComponents) => {
    const inputsArray = Array.isArray(inputComponents)? [inputComponents] : [...inputComponents];
    inputsArray.forEach(inputCmp => inputCmp.reportValidity())
}

//-- check and report the errors for given input elements
export const checkAllCmpValidity = (inputComponents, isGenInputCmp = true) => {
    const inputsArray = inputComponents ? [...inputComponents] : [];
    return inputsArray.reduce((validSoFar, inputCmp) => {
        if (isGenInputCmp)
            checkCustomValidity(inputCmp);
        else
            inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
    }, true)
}


//-- check and report a input cmp validity
export const checkCustomValidity = (inputCmp, valMissingErrorMsg = DEFAULT_VALUE_MISSING_VALIDATION_MESSAGE) => {

    if (!inputCmp.validity.valid) {
        //-- if 'required' field value is missing then setting 'custom validation message'(overriding standard error message)
        if (inputCmp.validity.valueMissing) {
            if (inputCmp.dataset && inputCmp.messageWhenValueMissing) {  // if defined error message at 'input element level' for attribute ' message-when-value-missing' then showing
                inputCmp.setCustomValidity(inputCmp.messageWhenValueMissing);
            } else if (inputCmp.label) {
                if (inputCmp.tagName && (inputCmp.tagName).toLowerCase() == 'lightning-combobox' ||
                    (inputCmp.tagName).toLowerCase() == 'lightning-radio-group') {
                    inputCmp.setCustomValidity("Select a " + (inputCmp.label).toLowerCase());    // generic combo box and radio group error messages
                } else {
                    inputCmp.setCustomValidity("Enter a " + (inputCmp.label).toLowerCase());
                }
            }
            else
                inputCmp.setCustomValidity(valMissingErrorMsg);
        } else {
            inputCmp.setCustomValidity('');
        }
    }
    
    if(inputCmp.type=='tel' && inputCmp.value){//value exists and it is telephone
      // check custom pattern phone number
      validatePhoneCustomPattern(inputCmp, inputCmp.value);
    }
    else if(inputCmp.dataset.id === BSB_INPUT_ID)
    {
        validateBSB(inputCmp);
    }
    else if(inputCmp.dataset.id === ACCOUNT_NUMBER_INPUT_ID)
    {
        validateAccountNumber(inputCmp);
    }

    inputCmp.reportValidity();

}

const validateBSB = (inputCmp) => {
    // default to attribute validation
    if(!inputCmp.value)
        return;
    let bsbTrimmed = inputCmp.value.replace(/\D/g, '');
    if(bsbTrimmed.length !== BSB_LENGTH)
        inputCmp.setCustomValidity('Enter a valid BSB');
    else
        inputCmp.setCustomValidity('');
}

const validateAccountNumber = (inputCmp) => {
    if(!inputCmp.value)
        return;
    let accTrimmed = inputCmp.value.replace(/\D/g, '');
    if(accTrimmed.length < ACCOUNT_NUMBER_MIN_LENGTH || accTrimmed.length > ACCOUNT_NUMBER_MAX_LENGTH)
        inputCmp.setCustomValidity('Enter a valid account number');
    else
        inputCmp.setCustomValidity('');
}

const validatePhoneCustomPattern = (inputCmp, phone) => {
    phone = phone.replace(/\D/g, '');
    const phoneRegex = /[0][2 3 4 7 8]{1}[0-9]{8}/ ;///(0)[2-57-8][0-9]+/;
    let validPhone = phone.match(phoneRegex);

    if (!validPhone)
        inputCmp.setCustomValidity('Enter a valid phone number');
    else
        inputCmp.setCustomValidity('');
}

/**
 * 
 * @param {*} sourceStr The source string in which content is replace
 * @param {*} replaceStr  replaced string content
 * @param {*} startTag strat word to start the replacement
 * @param {*} endTag end word to start the replacement
 */
export const replaceHTML = (sourceStr, replaceStr, startTag, endTag) => {
    try{
        var replacedStr;

        var indexOfStartTag = sourceStr.indexOf(startTag);
        var indexOfEndTag = sourceStr.indexOf(endTag);
        var endTagLen = endTag.length;
    
        var subStrToReplace = sourceStr.substring(indexOfStartTag, indexOfEndTag + endTagLen);
    
        replacedStr = sourceStr.replace(subStrToReplace, replaceStr);
        return replacedStr;
    }catch(ex){
        return sourceStr;
    }

}

export const formatAddress = (address) => {
    if (address)
        return (address.line1 ? address.line1 + ' ' : '') +
            (address.line2 && address.line2 != '' ? address.line2 + ' ' : '') +
            (address.city ? address.city + ' ' : '') +
            address.state + ' ' +
            address.postcode;//+ ' ' +
    // address.countryName;
    else
        return '';
}