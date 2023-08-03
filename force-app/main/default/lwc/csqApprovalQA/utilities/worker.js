/**
 * @author Paul Perry
 * 
 * Simple worker class processing all async tasks within an action list
 *  Keeps going until a task fails or all tasks in provided sequemce have been completed
 */

export default class TaskWorker {
	/**
	 * Constructor for TaskWorker
	 * @param {*} actions array of action difinitions
	 * 		@param actions.action function: method that can be invoked
	 * @param {*} actionList map of actions by name returning next action and params
	 * 		@param actionList.nextTask object
	 * 		@param actionList.nextTask.nextAction function type of action (method that can be invoked)
	 * 		@param actionList.nextTask.args arguments to be provided to the function in nextAction
	 * @param {*} onerror callback providing error information
	 * @param {*} onstatus callback providing status information
	 */
	constructor({ actions, actionList, onerror, onstatus }) {
		const reportStatus = args => onstatus && Promise.resolve(onstatus({
			timestamp : (new Date()).getTime(),
			...args
		}));

		const reportError = args => onerror && Promise.resolve(onerror(args));

		const actionWorker = ({ action, args }) => {
			Promise.resolve(
				actions[action](args)
			).then(result => {
				if (actionList[action]) {
					const nextTask = {
						args : { },
						...actionList[action](result)
					};

					reportStatus({
						status : nextTask?.action ? 'working' : 'done',
						lastcompleted: { action, args },
						nextTask
					});

					if (nextTask.action) {
						return actionWorker(nextTask);
					}
				}

				return null;
			}).catch(reportError);
		}

		this.kickOff = () => actionWorker(actionList[undefined]());
		this.resumeAt = ({ action, args }) => actionWorker({ action, args });
	}

	/**
	 * Initiate the task sequence starting with the first task in the list
	 * @returns void
	 */
	run = () => this.kickOff();
	
	/**
	 * Resume the task sequence starting with provided action and arguments
	 * @returns void
	 */
	resume = ({ action, args }) => this.resumeAt({ action, args });
}