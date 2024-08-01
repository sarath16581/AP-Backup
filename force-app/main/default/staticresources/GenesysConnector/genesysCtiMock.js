class GenesysCTIMock {
	/**
     * Sequence of mock events captured during an actual test call.
     * These can be extended with mock parameters and used for call simulations
     * @attrib eventName (string)       The name of the event
     * @attrib message (string)         The eventdetail as received during the original call
     * @attrib timeSinceLast (integer)  The number of millisecs since the last event
     */
    static mockEvents = [
        {
            "eventName": "UPDATE_STATUS",
            "message": {
                "message": "{\"reason\":\"status_updated\",\"status\":\"ON_QUEUE\",\"id\":\"e08eaf1b-ee47-4fa9-a231-1200e284798f\"}"
            },
            "timeSinceLast": 1
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"add\",\"data\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":false,\"isDisconnected\":false,\"isDone\":false,\"state\":\"ALERTING\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false}}}"
            },
            "timeSinceLast": 254
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":false,\"isDisconnected\":false,\"isDone\":false,\"state\":\"ALERTING\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":false,\"isDisconnected\":false,\"isDone\":false,\"state\":\"ALERTING\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 396
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":false,\"isDisconnected\":false,\"isDone\":false,\"state\":\"ALERTING\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":false,\"isDisconnected\":false,\"isDone\":false,\"state\":\"ALERTING\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 1162
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":false,\"isDisconnected\":false,\"isDone\":false,\"state\":\"ALERTING\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 774
        },
        {
            "eventName": "INTERACTION_CONNECTED",
            "message": {
                "message": "{\"reason\":\"connected\",\"interactionId\":\"e4e03b73-784b-435e-a30a-a527e20801c8\"}"
            },
            "timeSinceLast": 6
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 140
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 10
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 36
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 47
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 26
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 30
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 29
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 1185
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 831
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 743
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 839
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"HELD\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 9
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"HELD\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"HELD\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 1737
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"HELD\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 13
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"none\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 1636
        },
        {
            "eventName": "INTERACTION_EVENT",
            "message": {
                "message": "{\"reason\":\"interaction\",\"data\":{\"category\":\"change\",\"data\":{\"old\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"none\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"},\"new\":{\"id\":\"e4e03b73-784b-435e-a30a-a527e20801c8\",\"connectedTime\":\"2024-04-09T04:19:42.719Z\",\"phone\":\"tel:+61431598408\",\"name\":\"Mobile Number, Australia\",\"isConnected\":true,\"isDisconnected\":false,\"isDone\":false,\"state\":\"CONNECTED\",\"isCallback\":false,\"isDialer\":false,\"isChat\":false,\"isEmail\":false,\"isMessage\":false,\"isVoicemail\":false,\"remoteName\":\"Mobile Number, Australia\",\"recordingState\":\"active\",\"securePause\":false,\"displayAddress\":\"+61431598408\",\"queueName\":\"Salesforce Voice\",\"ani\":\"+61431598408\",\"calledNumber\":\"+61364098722\",\"totalIvrDurationSeconds\":7,\"totalAcdDurationSeconds\":4,\"direction\":\"Inbound\",\"isInternal\":false,\"startTime\":\"2024-04-09T04:19:30.967Z\"}}}}"
            },
            "timeSinceLast": 11
        },
        {
            "eventName": "INTERACTION_DISCONNECTED",
            "message": {
                "message": "{\"reason\":\"disconnected\",\"interactionId\":\"e4e03b73-784b-435e-a30a-a527e20801c8\"}"
            },
            "timeSinceLast": 15048
        },
        {
            "eventName": "ACW_REQUIRED",
            "message": {
                "message": "{\"reason\":\"acw_required\",\"interactionId\":\"e4e03b73-784b-435e-a30a-a527e20801c8\"}"
            },
            "timeSinceLast": 1
        },
        {
            "eventName": "ACW_COMPLETED",
            "message": {
                "message": "{\"reason\":\"acw_completed\",\"interactionId\":\"e4e03b73-784b-435e-a30a-a527e20801c8\"}"
            },
            "timeSinceLast": 2759
        }
    ];
}