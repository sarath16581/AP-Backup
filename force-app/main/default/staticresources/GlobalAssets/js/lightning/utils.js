/**************************************************
Description:    A group of functions to assist with easier more streamlined lighting development

History:
--------------------------------------------------
2018-02-15	nathan.franklin@auspost.com.au	Created
**************************************************/
window.AP_LIGHTNING_UTILS = {

	/**
	 * Invokes a server side controller and returns a promise object
	 */
	getPromiseDelivery: function(cmp, func, params) {
		var self = this;
		return new Promise($A.getCallback(function(resolve, reject) {
			self.invokeController(cmp, func, params, resolve, reject);
		}));
	},

	/**
	 * Invokes a server side controller and returns a promise object.
	 *
	 * Optionally use waitingQueueId (waitingQueueComponent) to manage the hiding ans showing of the waiting icon.
	 */
	invokeController: function(cmp, func, params, callback, errorCallback, isStorable, waitingQueueComponent) {
		var action = cmp.get('c.' + func);
		action.setParams(params);

		if(isStorable)
			action.setStorable();

		// set waiting on
		try {
			if(waitingQueueComponent != null)
				waitingQueueComponent.startWait();
		} catch(ex) { }

		action.setCallback(this, function(response) {
			// no longer valid
			if(!cmp.isValid())
				return;

			// set waiting off
			try {
				if(waitingQueueComponent != null)
					waitingQueueComponent.stopWait();
			} catch(ex) { }

			var state = response.getState();
			if (state === "SUCCESS") {
				callback(response.getReturnValue());
			} else if (state === "ERROR") {
				var errors = response.getError();
				console.log('Error: ' + func, errors);
				if(errorCallback)
					errorCallback(errors);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	/**
    *   Promise wrapper function to call asynchronous functions
    */
    helperPromise : function(cmp,hlpr,paramObj, helperFunction) {
        return new Promise($A.getCallback(function(resolve, reject) {
            helperFunction(cmp,hlpr,paramObj, resolve, reject);
        }));
    },
    /**
    * Return a array of fields by recursively travesing to the end of object chain
    */
    flattenObject : function(propName, obj){
        var flatObject = [];
        if(typeof obj == 'object'){
            for(var prop in obj){
                //if this property is an object, we need to flatten again
                var propIsNumber = isNaN(propName);
                var preAppend = propIsNumber ? propName+'.' : '';
                if(typeof obj[prop] == 'object') {
                    var tmpObj = this.flattenObject(preAppend+prop,obj[prop]);
                    var tmpObjPrev = flatObject;

                    flatObject[preAppend+prop] = Object.assign(tmpObjPrev, this.flattenObject(preAppend+prop,obj[prop]) );
                } else {
                    flatObject[preAppend+prop] = obj[prop];
                }
            }
        } else {
             flatObject[propName] = obj;
        }
        return flatObject;
    },
    /**
    * Flatten the table return , ie: if there is a nested sturcture, bring it all to one level .
    * Eg: custonObject__r : bring all fields in __r object , to the topmost level. and create flatened structure
    */
    flattenQueryResult : function(listOfObjects){
        var rowsObj = [];
        var obj  = [];
        if( listOfObjects && !Array.isArray(listOfObjects) ){
            listOfObjects = [listOfObjects];
        }

        for(var i = 0; i < listOfObjects.length; i++){
            obj = listOfObjects[i];
            var flatObj = {};
            for(var prop in obj){
                if(!obj.hasOwnProperty(prop)){
                    continue;
                }
                if(Array.isArray(obj[prop])){
                    var flatObj2 = {};
                    for(var j = 0; j < obj[prop].length; j++){
                        obj2 = listOfObjects[j];
                        for(var prop2 in obj2){
                            flatObj2  =  Object.assign(flatObj2,this.flattenObject(prop2,obj2[prop2]));
                        }
                    }
                     flatObj = Object.assign(flatObj2,flatObj);
                } else {
                  flatObj = Object.assign(flatObj,this.flattenObject(prop,obj[prop]));
                }
            }
            listOfObjects[i] = flatObj ;
        }
        return listOfObjects;
    }
};