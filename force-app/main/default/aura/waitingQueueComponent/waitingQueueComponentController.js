/**************************************************
Description:
History:
--------------------------------------------------
2018-05-18  nathan.franklin@auspost.com.au  Created
**************************************************/
({
    startWait: function(cmp, ev, helper) {
		var waitingQueue = cmp.get('v.waitingQueue');

		// set the new waiting queue
		waitingQueue++;
		cmp.set('v.waitingQueue', waitingQueue);
    },

    stopWait: function(cmp, ev, helper) {
		var waitingQueue = cmp.get('v.waitingQueue');

		// set the new waiting queue
		waitingQueue--;
		cmp.set('v.waitingQueue', (waitingQueue < 0 ? 0 : waitingQueue));
    }
})