define(["util"], function () {
	var n = "SFDC/tracking: ", t = {}, a = null, e = null, o = function (n, a, e) {
		t[n] = {whatId: e ? e.AccountId || null : null, primaryTabId: a, taskTabId: null, contact: e}
	}, r = function (n) {
		return t[n] !== void 0
	}, s = function (a, e) {
		var o = t[a];
		o !== void 0 ? o.taskId = e : console.warn(n + "setTaskId-" + a + " does not exist")
	}, d = function (a, e) {
		var o = t[a];
		o !== void 0 ? o.whatId = e : console.warn(n + "setTaskTabId-" + a + " does not exist")
	}, i = function (a, e) {
		var o = t[a];
		o !== void 0 ? o.taskTabId = e : console.warn(n + "setTaskTabId-" + a + " does not exist")
	}, u = function (a, e) {
		var o = t[a];
		o !== void 0 ? o.caseId = e : console.warn(n + "setCaseId-" + a + " does not exist")
	}, c = function (n) {
		n.ixn !== void 0 && (t[n.ixn.id] = {params: n})
	}, l = function (a) {
		var e = t[a];
		return e !== void 0 ? e.contact : (console.warn(n + "getContact-" + a + " does not exist"), null)
	}, I = function (a) {
		var e = t[a];
		return e !== void 0 ? e.taskId : (console.warn(n + "getTaskId-" + a + " does not exist"), null)
	}, v = function (a) {
		var e = t[a];
		return e !== void 0 ? e.whatId : (console.warn(n + "getWhatId-" + a + " does not exist"), null)
	}, T = function (a) {
		var e = t[a];
		return e !== void 0 ? e.primaryTabId : (console.warn(n + "getPrimaryTabId-" + a + " does not exist"), null)
	}, f = function (a) {
		var e = t[a];
		return e !== void 0 ? e.taskTabId : (console.warn(n + "getTaskTabId-" + a + " does not exist"), null)
	}, g = function (a) {
		var e = t[a];
		return e !== void 0 ? e.caseId : (console.warn(n + "getCaseId-" + a + " does not exist"), null)
	}, b = function (a) {
		var e = t[a];
		return e !== void 0 && e.params !== void 0 ? e.params : (console.warn(n + "getParams-" + a + " does not exist"), null)
	}, k = function (n) {
		delete t[n]
	}, m = function () {
		t = {}
	}, w = function (t) {
		a = t.id;
		var o = t.objectId;
		if (o.length === 15) {
			for (var r = "", s = 0; 3 > s; s++) {
				for (var d = 0, i = 0; 5 > i; i++) {
					var u = o.charAt(s * 5 + i);
					"A" > u || u > "Z" || (d += 1 << i)
				}
				r += "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345".charAt(d)
			}
			e = o + r
		} else e = null;
		console.log(n + "primaryTabFocused - " + a + ", " + e)
	}, x = function () {
		return a
	}, C = function () {
		return e
	}, getCustom = function(id) {
		var track = t[id];

		if (track !== undefined) {
			return track.custom;
		} else {
			return null;
		}
	}, setCustom = function(id, custom) {
		var track = t[id];

		if (track !== undefined) {
			track.custom = custom;
		} else {
			console.warn(log_prefix + "setCustom-" + id + " does not exist");
		}
	}, getCallType = function(id) {
		var track = t[id];

		if (track !== undefined) {
			return track.callType;
		} else {
			return null;
		}
	}, setCallType = function(id, callType) {
		var track = t[id];

		if (track !== undefined) {
			track.callType = callType;
		} else {
			console.warn(log_prefix + "setCallType-" + id + " does not exist");
		}
	}, getCallbackStatus = function(id) {
        var track = t[id];

        if (track !== undefined) {
            return track.callbackStatus;
        } else {
            return null;
        }
    }, setCallbackStatus = function(id, callbackStatus) {
        var track = t[id];

        if (track !== undefined) {
            track.callbackStatus = callbackStatus;
        } else {
            console.warn(log_prefix + "setCallbackStatus-" + id + " does not exist");
        }
    };
	return {
		add: o,
		exists: r,
		setTaskId: s,
		setWhatId: d,
		setTaskTabId: i,
		setCaseId: u,
		setParams: c,
		getContact: l,
		getTaskId: I,
		getWhatId: v,
		getPrimaryTabId: T,
		getTaskTabId: f,
		getCaseId: g,
		getParams: b,
		remove: k,
		reset: m,
		primaryTabFocused: w,
		getCurrentPrimaryTabId: x,
		getCurrentPrimaryTabObjectId: C,
		getCustom: getCustom,
		setCustom: setCustom,
		getCallType: getCallType,
        setCallType: setCallType,
        getCallbackStatus: getCallbackStatus,
        setCallbackStatus: setCallbackStatus
	}
});