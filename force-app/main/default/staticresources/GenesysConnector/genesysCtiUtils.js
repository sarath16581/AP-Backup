/**
 * @description Utility methods for Genesys CTI Integration
 * @author Paul Perry
 * @date 2024-04-26
 * @changelog
 *
 */
class GenesysCTIUtils {
    /**
     * Deserialise a JSON string. A parsing error will result into an empty object
     * @param {string} serializedJSON   String containing
     * @returns (object)                Serialised object
     */
    static jsonToObj = (serializedJSON) => {
        try {
            return JSON.parse(serializedJSON);
        } catch {
            return { };
        }
    }

    /**
     * Get an array of attribute names reflecting the differences in between two objects
     * @param {*} obj1 First object to compare
     * @param {*} obj2 Second object to compare
     * @param {*} path Do not provide. Used for recursive processing
     * @returns (string[])  List of attribute names that have changed
     */
    static getDiff = (obj1, obj2, path = '') => Object.keys(obj1).reduce(
        (res, key) => {
            const val1 = obj1[key];
            const val2 = obj2?.[key];

            if (val1 !== null && typeof val1 === 'object' && val2 !== null) {
                res = res.concat(this.getDiff(
                    val1,
                    val2,
                    (path || '') + key.replace('.', '\\.') + '.'
                ));
            } else if (val1 !== val2) {
                res.push(key);
            }

            return res;
        }, [ ]
    )

    /**
     * Similar to Object.assign without overwriting sub attributes
     * @param {*} target Source values will be merged into this object
     * @param {*} source Object/Array to be merged into target object
     * @returns Merged version of the target updated with values from source
     */
    static deepCloneObj = (target = { }, source) => Object.keys(source || { }).reduce(
        (res, key) => {
            const srcVal = source[key];

            if (res[key] && typeof srcVal === 'object') {
                res[key] = this.deepCloneObj(res[key], srcVal);
            } else {
                res[key] = srcVal;
            }

            return res;
        }, target
    )

    static getObjProp = (input, fieldName) => {
        let result = null;

        if (fieldName != null && input != null && typeof input === 'object') {
            const properties = fieldName.split(/(?<!\\)(\.)+/).filter(x => x !== '.');
            const prop = properties.splice(0, 1)?.[0]?.replace('\\.', '.');

            const value = input[prop];

            if (properties.length && value && value instanceof Object) {
                result = this.getObjProp(value, properties.join('.'));
            } else if (properties.length == 0) {
                result = value;
            }
        }

        return result;
    }

    static setObjProp = (object, fieldName, value) => {
        const result = object || { };
        const path = fieldName.split(/(?<!\\)(\.)+/).filter(
			x => x !== '.'
		).map(
			x => x.replace('\\.', '.')
		);
        let r = result;

        path.forEach((path, idx, arr) => {
            if (idx == arr.length - 1) {
                r[path] = value;
            } else if (!r.hasOwnProperty(path)) {
                r[path] = { };
            }

            r = r[path];
        });

        return result;
    }

    /**
     * Promise resolving in provided timeout delay
     * @param {*} delayInMillisec   Timeout delay in milliseconds
     * @param {*} id                Unique identifier that gets return on promise resolve
     * @returns promise with provided/generated id
     */
    static timeout = (delayInMillisec, id = crypto.randomUUID()) =>
        new Promise(res => setTimeout(() => res(id), delayInMillisec));

    /**
     * Turns a 15-digit recordId into a case insensitive 18-character recordId
     * @param {*} recordId  the 15-character recordId
     * @returns 18-character recordId
     */
    static caseSafeId = (recordId) => {
        if (recordId?.length === 15) {
            for (var i = 0; i < 3; i++) {
                var f = 0;
                for (var j = 0; j < 5; j++) {
                    var c = recordId.charAt(i * 5 + j);
                    if (c >= "A" && c <= "Z") f += 1 << j;
                }

                recordId += "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345".charAt(f);
            }
        }

        return recordId;
    }

    /**
     * List of CTI events that will be transformed into a format that is easier to process
     */
    static CTIEvents = [
        'UPDATE_STATUS',
        'INTERACTION_CONNECTED',
        'INTERACTION_DISCONNECTED',
        'LOGGED_OUT',
        'ACW_REQUIRED',
        'ACW_COMPLETED',
        'INTERACTION_EVENT'
    ];

    /**
     * Transform the original event into a format that is easier to process
     * @param {string} eventName Name of the event
     * @param {*} event     Event Details
     * @returns (object) Transformed event object
     */
    static extractEventDetail(eventName, event) {
        const result = { eventName };

        if (this.CTIEvents.includes(eventName)) {
            if (event.message && typeof event.message === 'string') {
                event = this.jsonToObj(event.message);
                result.message = event.message;
            }

            if (eventName === 'INTERACTION_EVENT') {
                result.category = event.data.category;

                if (result.category === 'add') {
                    // first event for this calll. Don't include changes attribute
                    result.detail = event.data.data;
                } else if (result.category === 'change') {
                    result.detail = event.data.data.new;
                    result.changes = this.getDiff(event.data.data.new, event.data.data.old);

                    if (result.changes.length) {
                        result.old = result.changes.reduce((res, item) => {
                            const propName = item.split('.')[0];
                            let oldVal = event.data.data.old[propName];

                            if (oldVal === undefined) {
                                oldVal = null;
                            }

                            if (!res.hasOwnProperty(propName)) {
                                res = Object.assign(res, { [propName] : oldVal })
                            }

                            return res;
                        }, { });
                    }
                }

                return result;
            }
        }

        this.deepCloneObj(result, event);
        return result;
    }

    /**
     * Returns true in case the number provided meets the criteria for anonymous caller ID
     * @param {string} ani
     * @returns (boolean) Whether or not the provided number is an anonymous caller ID
     */
    static isAnonymousPhoneNumber = function(ani) {
        return ['unavailable', '0anonymous', 'anonymous'].includes(ani);
    }

    /**
     * Returns an array containing the divider and remainder of provided values
     * @param {*} Number to process
     * @param {*} Divider
     * @returns integer[] [mod, div]
     */
    static divmod = (x, y) => [Math.floor(x / y), x % y];

    /**
     * Formats a number with leading zeros: (16,3) => '016'
     * @param {*} number to format
     * @param {*} number of digits
     * @returns (string) formatted value in string format
     */
    static leadingZeros = (number, len) => {
        const result = `${number}`;
        return '0'.repeat((len - result.length) > 0 ? len - result.length : 0) + result;
    }

	/**
     * Formats a date value into string format YYYY-MM-DD HH:mm:ss
     * @param {*} d Date instance
     * @returns (string) formatted date value in string format
     */
    static formatDate = (d) => [
		[
			d.getFullYear(),
			GenesysCTIUtils.leadingZeros(d.getMonth() + 1, 2),
			GenesysCTIUtils.leadingZeros(d.getDate(), 2)
		].join('-'), [
			GenesysCTIUtils.leadingZeros(d.getHours(), 2),
			GenesysCTIUtils.leadingZeros(d.getMinutes(), 2),
			GenesysCTIUtils.leadingZeros(d.getSeconds(), 2)
		].join(':')
	].join(' ');

    /**
     * Generate a timestamp in milliseconds
     * @returns (Integer) Number of millisecs elapsed since midnight at the beginning of January 1, 1970, UTC
     */
    static timeStamp = () => new Date().getTime();

    static get monitorActive() {
        return !!GenesysCTIUtils.getStorageProp('GenesysMonitor.monitorActive');
    }

    static set monitorActive(value) {
        return GenesysCTIUtils.setStorageProp('GenesysMonitor.monitorActive', value);
    }

    static get mockActive() {
        return !!GenesysCTIUtils.getStorageProp('GenesysMonitor.MockActive');
    }

    static set mockActive(value) {
        return GenesysCTIUtils.setStorageProp('GenesysMonitor.MockActive', value);
    }

    static get mockParams() {
        const newVal = GenesysCTIUtils.getStorageProp('GenesysMonitor.MockParams', false);

        // only serialise when changed
        if (newVal != this.currentMockParams) {
            this.currentMockParams = newVal;
            this.currentMockObj = GenesysCTIUtils.jsonToObj(newVal);

            if (!this.currentMockObj) {
                GenesysCTIUtils.mockActive = false;
            }
        }

        return this.currentMockObj;
    }

    static set mockParams(value) {
        return GenesysCTIUtils.setStorageProp('GenesysMonitor.MockParams', value);
    }

    static storeCallDetails(interactionId, details) {
        return GenesysCTIUtils.setStorageProp(`GenCTI-${interactionId}`, details, true, 'local');
    }

    static recallCallDetails(interactionId) {
        return GenesysCTIUtils.getStorageProp(`GenCTI-${interactionId}`, true, 'local');
    }

    static deleteCallDetails(interactionId) {
        // Unsetting the property in storage will delete it
        return GenesysCTIUtils.setStorageProp(`GenCTI-${interactionId}`, undefined, false, 'local');
    }

    static getStorageProp(propName, deserialise = true, storage = 'session') {
        let storageTarget = sessionStorage;

        if (storage === 'local') {
            storageTarget = localStorage;
        }

        if (!storageTarget.hasOwnProperty(propName)) {
            return null;
        }

        const value = storageTarget.getItem(propName);
        return deserialise ? GenesysCTIUtils.jsonToObj(value) : value;
    }

    static setStorageProp(propName, value, serialise = true, storage = 'session') {
        let storageTarget = sessionStorage;

        if (storage === 'local') {
            storageTarget = localStorage;
        }

        storageTarget.removeItem(propName);

        if (value === null || value === undefined) {
            return value;
        }

        if (serialise && value instanceof Object) {
            value = JSON.stringify(value);
        }

        return storageTarget.setItem(propName, value);
    }

	static logPrefix = [`%c* GenCTI *%c`, 'color:white;background-color:#dc1928;font-weight:bold', null];
}

class CallInteractionProxy {
    constructor(ctiEvent, fieldMappings) {
        const thisRef = this;
        this.fieldMappings = fieldMappings;

        this.handler = {
            get(target, key) {
                if (thisRef.actions.hasOwnProperty(key) && typeof thisRef.actions[key] === 'function') {
                    return (...args) => thisRef.actions[key].call(thisRef, ...args);
                }

                const keyName = thisRef.fieldMappings[key];

                if (keyName) {
                    return GenesysCTIUtils.getObjProp(target, keyName);
                }

                // If property not in field mappings, return undefined
                return Reflect.get(...arguments);
            },
            set(target, key, value) {
                const keyName = fieldMappings[key];

                if (keyName) {
                    GenesysCTIUtils.setObjProp(target, keyName, value);
                    return true;
                }

                // Don't allow setting properties outside of fieldMappings
                throw new Error(`Property not defined in fieldMappings: "${key}"`);
            }
        };

        this.actions = {
            toObject : (fieldMap) => {
                if (!fieldMap) {
                    fieldMap = this.fieldMappings;
                } else {
                    fieldMap = Object.keys(fieldMap).reduce(
                        (res, key) => Object.assign(res, { [key] : this.fieldMappings[fieldMap[key]] }), { }
                    );
                }

                return Object.keys(fieldMap).reduce((res, key) => {
                    let value = this.proxy[key];// GenesysCTIUtils.getObjProp(this.source, fieldMap[key]);
                    return value !== undefined
                        ? Object.assign(res, { [key] : value })
                        : res;
                }, { });
            },
            update : (ctiEvent) => {
                if (ctiEvent?.detail) {
                    GenesysCTIUtils.deepCloneObj(this.source, ctiEvent.detail);
                }
            }
        }

        this.source = { ...ctiEvent?.detail };
        this.proxy = new Proxy(ctiEvent, this.handler);
        return this.proxy;
    }
}

class AsyncTask {
    constructor(promise) {
        this.status = 'pending';
        this.actions = { };

        if (promise) {
            this.promise = Promise.resolve(promise);
            this.promise.then(
                (...args) => this.complete(...args)
            ).catch(
                (...args) => this.fail(...args)
            );
        } else {
            this.promise = new Promise((resolve, reject) => this.actions = Object.assign(
                this.actions, { resolve, reject }
            ));
        }

        this.complete = (...args) => {
            this.status = 'completed';
            this.actions.resolve(...args);
        }
        this.fail = (...args) => {
            this.status = 'failed';
            this.actions.reject(...args);
        }
    }
}