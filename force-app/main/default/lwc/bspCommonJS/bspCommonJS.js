/*
 * @author Jansi(avula.jansirani@crmit.com)
 * @date 24/07/2020
 * @description common js methods for BSP community
 * --------------------------------------- History --------------------------------------------------
    24/07/2020		avula.jansirani@crmit.com		Initial updation to lightning uplift
    11/01/2021      swati.mogadala@auspost.com.au   REQ2370764 Adding PNG as an accepted format for file uploads in bsp
*/


import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

//-- The below message will set if 'input' required field value is missing
const valueMissingErrorMsg = 'Please fill in this field';

//-- The top generic error message
const topGenericErrorMessage = 'Please enter the required information.';

//-- The file accepted formats
//-- REQ2370764- Added png as a format
const acceptedFileFormats = '.jpg, .pdf,.doc,.docx,.jpeg,.png';//' ['.jpg', '.pdf','.doc','.docx','.jpeg',.png', ];

//-- The toast message
const showToastMessage = (title, message, variant = 'info', mode = 'dismissable') => {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode
    });
    return event;
}

//-- report the errors for given input elements
const reportAllValidity = (inputComponents) => {
    //const inputsArray = inputComponents ? [...inputComponents] : [];
    const inputsArray = Array.isArray(inputComponents)? inputComponents : [...inputComponents];
    inputsArray.forEach(inputCmp => inputCmp.reportValidity())
}

//-- check and report the errors for given input elements
const checkAllValidity = (inputComponents, isGenInputCmp = true) => {
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
const checkCustomValidity = (inputCmp, valMissingErrorMsg = valueMissingErrorMsg) => {
    
    if (!inputCmp.validity.valid) {
        //-- if 'required' field value is missing then setting 'custom validation message'(overriding standard error message)
        if (inputCmp.validity.valueMissing) {
            inputCmp.setCustomValidity(valMissingErrorMsg);
        } else {
            inputCmp.setCustomValidity('');
        }
    }
    inputCmp.reportValidity();

}

const reloadPage = (isLoadWithCache) => {
    //window.location.reload(isLoadWithCache); 
    window.location.href = window.location.href;
}

const replaceAddressString = (input, relaceStr, replaceWithStr) => {
    if(input){
        return input.replace(relaceStr, replaceWithStr);
    }
    return '';
}

const scrollToHeight = (inputs) => {
    if(inputs && inputs.length > 0){
        inputs[0].scrollIntoView(true);  //[Jansi: added this line to fix in IE11, the scrolling issue]
        /*let cmpOffset = inputs[0].offsetTop;
        cmpOffset = cmpOffset > 10 ? cmpOffset - 10 : cmpOffset;
        window.scroll({
            top:cmpOffset, 
            left:0, 
            behavior: 'smooth'
        });*/
    }
}

/*
const parseStringToAddressObj = (sAddress) => {
    let arrAddress = sAddress.split(',');
    let line2 = '';
    if (arrAddress.length == 5)
        line2 = arrAddress[1];

    // postcode
    let arrPostcode = arrAddress[arrAddress.length -2].split(' ');

    let objAddress = {
        addressLine1: arrAddress[0],
        addressLine2: line2,
        city: arrAddress[arrAddress.length - 3],
        state: arrPostcode[0],
        postcode: arrPostcode[1],
        countrycode: arrAddress[arrAddress.length - 1],
        dpid: ''
    };
    return objAddress;
}

function navigateToHome(){
    NavigationMixin[NavigationMixin.Navigate]({
        type: 'comm__namedPage',
        attributes: {
            name: 'Home'
        }
    });
}

function navigateToEnquiryDetail(caseNumber){
    NavigationMixin[NavigationMixin.Navigate]({
        type: 'comm__namedPage',
        attributes: {
            name: 'BSP_Enquiry_Details__c'
        },
        state: {
            enquiryNumber: caseNumber
        }
    });
}
*/

function convertToFormattedDateStr(dateStr) { //Expected is '20-Nov-201912:00 AM' format
    var newStr = dateStr;
    try {
        if (dateStr) {
            var tempArray = dateStr.split('-');
            newStr = tempArray[0] + '/' + getMonth(tempArray[1]) + '/' + tempArray[2].substring(0, 4)
                + (tempArray[2].substring(4) ? (' ' + tempArray[2].substring(4)) : '');
        }
    } catch (ex) {}

    return newStr;
}

function getMonth(monthStr) {// expected 3 chars like'Aug' or 'Jun'
    if (monthStr) {
        if (monthStr.toLowerCase() == 'jan') return '01';
        else if (monthStr.toLowerCase() == 'feb') return '02';
        else if (monthStr.toLowerCase() == 'mar') return '03';
        else if (monthStr.toLowerCase() == 'apr') return '04';
        else if (monthStr.toLowerCase() == 'may') return '05';
        else if (monthStr.toLowerCase() == 'jun') return '06';
        else if (monthStr.toLowerCase() == 'jul') return '07';
        else if (monthStr.toLowerCase() == 'aug') return '08';
        else if (monthStr.toLowerCase() == 'sep') return '09';
        else if (monthStr.toLowerCase() == 'oct') return '10';
        else if (monthStr.toLowerCase() == 'nov') return '11';
        else if (monthStr.toLowerCase() == 'dec') return '12';
        else return monthStr;
    }
    else return monthStr;
}

export {
    reportAllValidity,
    checkAllValidity,
    valueMissingErrorMsg,
    topGenericErrorMessage,
    showToastMessage,
    checkCustomValidity,
    acceptedFileFormats,
    reloadPage,
    convertToFormattedDateStr,
    replaceAddressString,
    scrollToHeight
};