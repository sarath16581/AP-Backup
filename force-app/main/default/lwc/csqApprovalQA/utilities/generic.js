/**
 * @author Paul Perry
 * 
 * Couple of generic helper methods
 * - UIToasts: user notifications
 * - ASyncTask: notification handler for one-off async tasks / promises for other depending processes
 * - EventTracker: offers observing ongoing async tasks / promises for other depending processes
 */


/**
 * Toast helper class for displaying formatted UI notifications
 * - Formats Api error messages provided as object
 *
 * Example use case: 
 * 	Display succes or exception message with the response error after invoking updateRecord
 *  or getRecords or AuraHandledException from backend controller
 */
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const formatApiError = (error) => {
	return [
		error.message,
		error.body?.message,
		...(error.body?.pageErrors || [ ]),
		...Object.values(error.body?.fieldErrors || { })
	].filter(
		item => !!item
	).reduce(
		(res, err) => (res ? `${res}; ` : '') + `${typeof err === 'object' ? err.message : err}`, ''
	);
}

/**
 * Generic helper methods to display toast messages
 */
class UIToasts {
	/**
	 * Displays a notification leveraging LWC Toasts
	 * @param {*} thisArg reference to 'this' from the main LWC component 
	 * @param {*} title Toast param
	 * @param {*} message Toast message
	 * @param {*} messageData Toast message Data
	 * @param {*} variant Toast variant
	 * @param {*} mode Toast mode
	 * @returns Promise
	 */
	static showToast = ({ thisArg, title, message, messageData, variant, mode }) => 
		// Wrapped in async setTimeout callback to work around issue where the Toast doesn't show
		Promise.resolve(setTimeout(
			() => thisArg.template.dispatchEvent(
				new ShowToastEvent({
					title, messageData, variant, mode,
					message : typeof message === 'object'
						? formatApiError(message)
						: message
				})
			), 0
		));

	/**
	 * Displays a success notification leveraging LWC Toasts
	 * @param {*} thisArg reference to 'this' from the main LWC component 
	 * @param {*} title Toast param defaults to "Success" if not provided
	 * @param {*} message Toast message
	 * @param {*} messageData Toast message Data
	 * @param {*} mode Toast mode
	 * @returns Promise
	 */
	static showToastSuccess = ({ thisArg, title = 'Success', message, messageData, mode }) =>
		UIToasts.showToast({
			variant : 'success',
			thisArg, title, message, messageData, mode
		});

	/**
	 * Displays an error notification leveraging LWC Toasts
	 * @param {*} thisArg reference to 'this' from the main LWC component 
	 * @param {*} title Toast param defaults to "Error" if not provided
	 * @param {*} message Toast message
	 * @param {*} messageData Toast message Data
	 * @param {*} mode Toast mode
	 * @returns Promise
	 */
	static showToastError = ({ thisArg, title = 'Error', message, messageData, mode }) =>
		UIToasts.showToast({
			variant : 'error',
			thisArg, title, message, messageData, mode
		});
}

/*
 * ASyncTask helper class to track on-off async processes or state changes
 * - Supports multiple observers where more than one process has a
 *   dependancy on something to complete
 * 
 * Example use case: 
 * 	renderedCallback or disconnectedCallback which indicate when the component is
 * 	ready to interact with the DOM or when it shouldn't
 */
const TASK_STATUS = {
	Pending : undefined,
	Resolved : 'resolved',
	Rejected : 'rejected' 
};

/**
 * Class that tracks a one-off task where subscribers get notified on the task's outcome
 */
class ASyncTask {
	constructor() {
		this.observers = [];
	}

	/**
	 * Subscribe to this ASync task
	 * @returns promise
	 */
	get promise() {
		return new Promise(
			(res, rej) => {
                return this._status
                    ? this._fulfill({ res, rej })
                    : this.observers.push({ res, rej });
            }
		);
	}

	/**
	 * Get the status
	 * @returns the current status: 'resolved', 'rejected' or undefined (pending)
	 */
	get status() {
		return this._status;
	}

	/**
	 * Gets the last known result
	 * @returns the last resolved or rejected response
	 */
	get result() {
		return this._result;
	}
	
	/**
	 * Complete pending task with provided result
	 * @param result notify all subscribers with presented result
	 */
	resolve(result) {
		this._result = result;
		this._notify(TASK_STATUS.Resolved);
	}

	/**
	 * Fail pending task with provided error result
	 * @param result notify all subscribers with presented result
	 */
	reject(error) {
		this._result = error;
		this._notify(TASK_STATUS.Rejected);
	}

	_notify(value) {
		this._status = value;
		this.observers.map(
			obsvr => this._fulfill(obsvr)
		);
		// Clear list of observers as promises have been fulfilled
		this.observers = [];
	}

	_fulfill(obsvr) {
		const callback = this._status === TASK_STATUS.Resolved
			? obsvr.res
			: obsvr.rej;
	
		try {
			callback(this._result);
		} catch (ex) {
            // Exception occurred within consuming method
			console.error(ex);
		}
	}
}


/*
 * EventTracker is similar to ASyncTask but where the latter is designed
 * for one-off events, this class caters for ongoing change events
 * 
 * Example use case: 
 * 	A wired getRecord method will be invoked everytime the LWC framework gets
 * 	notified in case of record changes. Observing its state would invoke provided
 *  callback methods each time this happens which can be tied up UI updates 
 */
const ERR_INVALID_FUNC_PARAMETER = 'Invalid parameter provided. Expected argument typeof function, got: ';

/**
 * Class that routes events to subscribers
 */
class EventTracker extends ASyncTask {
	constructor(...args) {
		super(...args);
		this._hooks = [];
	}

	/**
	 * Subscribe to this EventTracker object hooking event handlers
	 * @param {*} onchange event handler that gets invoked on changes 
	 * @param {*} onerror event handler that gets invoked on errors 
	 */
	addCallback({ onchange, onerror }) {
		[onchange, onerror].filter(
			a => a && typeof a !== 'function'
		).map(
			a => { throw new Error(`${ERR_INVALID_FUNC_PARAMETER} ${a}`) }
		);

		this._hooks.push({ onchange, onerror });
		this._hookEvent({ onchange, onerror })
	}

	_notify(value) {
		// Perform notifications
		super._notify(value);
		// Return to pre broadcast state to listen for next event
		delete this._result;
		delete this._status;
		this._reHookEvents();
	}

	_reHookEvents() {
		this._hooks.map(
			hook => this._hookEvent(hook)
		);
	}

	_hookEvent({ onchange, onerror }) {
		this.promise.then(
			res => onchange && onchange(res)
		).catch(
			err => onerror && onerror(err)
		);
	}
}

export { UIToasts, ASyncTask, EventTracker }