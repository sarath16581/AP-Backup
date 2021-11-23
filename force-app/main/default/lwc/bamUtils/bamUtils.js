import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export const noop = () => {}

export const getParamsFromURL = url => {
    const splitURL = url.split('?')
    const paramString = splitURL.length > 1 ? splitURL[1] : null
    if (paramString) {
        return paramString.split('&').reduce((acc, param) => {
            const [key, value] = param.split('=')
            acc[key] = value
            return acc
        },{})
    } 
    return {}
}

export const generateGUID = () => {
    let d = new Date().getTime()
    if (window.performance && typeof window.performance.now === "function") {
        d += performance.now() //use high-precision timer if available
    }
    const uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        const r = (d + Math.random() * 16) % 16 | 0
        d = Math.floor(d / 16)
        return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16)
    })
    return uuid
}

export const showToast = (variant, message, mode = 'dismissable') => (context) => {
    const evt = new ShowToastEvent({
        message,
        variant,
        mode,
    });
    context.dispatchEvent(evt);
}

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

export const delay = (ms) => {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    return new Promise(resolve => setTimeout(resolve, ms));
};

// Polling function that excutes the function passed into it after every interval until a timeout it reached
// the first execution of the polled function is done after an initial delay of the interval
// the function the executes will not return a value.
// By default we call the function passed into the poll function every 20 seconds for an hour
export const poll = async (fn, interval = 20000, timeout = 3600000) => {
    let timer
    const endTime = Number(new Date()) + timeout;
    const polledFunction = (resolve, reject) => {
        if (timer) {
            clearTimeout(timer);
        }
        if (Number(new Date()) < endTime) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(polledFunction, interval, resolve, reject);
        } else {
            reject(new Error(`timed out for ${fn}`));
        }
        fn();
    }
    await delay(interval)
    return new Promise(polledFunction)
}

/*  implementation of lodash get

    Gets the value at path of object. If the resolved value is undefined, 
    the defaultValue is returned in its place.
*/
export const get = (object, path, defaultVal) => {
    path = Array.isArray(path) ? path : path.split('.');
    object = object[path[0]];
    if (object && path.length > 1) {
        return get(object, path.slice(1));
    }
    return object === undefined ? defaultVal : object;
}

/*  implementation of lodash find

    Returns the value of the first element in the array that satisfies the provided testing function. Otherwise undefined is returned.
*/
export const find = (collection, predicate) => {
    if (!collection) {
        return undefined
    }
    if (typeof predicate === 'function') {
       return Array.prototype.find.call(collection, predicate)
    } else if (!!predicate && typeof predicate === 'object') {
        return Array.prototype.find.call(collection, item => {
            const predicateKeys = Object.keys(predicate)
            return  predicateKeys.length > 0 && predicateKeys.reduce((acc, key) => acc && (item[key] === predicate[key]), true)
        })
    }
    throw new Error("Invalid inputs to 'find'")
}


/*  implementation of lodash isObject

    Returns true if the input is a JS object
*/
export const isObject = (obj) => {
    return !!obj && (typeof obj === 'object' || typeof obj === 'function')
}

/*  implementation of lodash pickBy

    Creates an object composed of the object properties predicate returns truthy for.
*/
export function pickBy(sourceObject, predicate){
    if(typeof(sourceObject) !== 'object'){
        throw new TypeError;
    }

    if(typeof(predicate) === 'undefined'){
        return sourceObject;
    }

    if(typeof(predicate) !== 'function'){
        throw new TypeError;
    }

    if(Object.keys(sourceObject).length === 0){
        return sourceObject;
    }

    let returnObject = {};

    for(let key in sourceObject){
        if(predicate(sourceObject[key])){
           returnObject[key] = sourceObject[key];
        }
    }

    return Object.assign({}, returnObject);
}

export function keyBy(collection, itaratee) {
    let returnObj = {};
    let keyProducer = null;
  
    if (typeof itaratee == "function") {
      keyProducer = itaratee;
    } else {
      keyProducer = function(obj) {
        return obj[itaratee];
      };
    }
  
    for (let i = 0; i < collection.length; i++) {
      let value = collection[i];
      let key = keyProducer(value);
      returnObj[key] = collection[i];
    }
  
    return returnObj;
  }

/*  implementation of lodash isEmpty
    
    Checks if value is an empty object or collection.
*/
export const isEmpty = obj => [Object, Array].includes((obj || {}).constructor) && !Object.entries((obj || {})).length;

// the billing account label is constructed by concatanating LEGACY_ID__c, MLID__c and Name delimited by a hyphen. If either of LEGACY_ID__c or MLID__c are not populated they are not displayed.
export const generateLabelForBillingAccount = billingAccount => `${billingAccount.LEGACY_ID__c ? `${billingAccount.LEGACY_ID__c} - ` : ''}${billingAccount.MLID__c ? `${billingAccount.MLID__c} - ` : ''}${billingAccount.Name}`