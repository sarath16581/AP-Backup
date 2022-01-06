/***********************************************************************
 * Copyright Genesys Laboratories. All Rights Reserved
 ************************************************************************/

/**
 * Methods to work out an interaction life-cycle.
 */
define(['util', 'config', 'agent/voice', 'agent/email', 'agent/chat', 'agent/preview'],
            function (util, config, voice, email, chat, preview) {
    var log_prefix = "agent/session: ";
    console.log(log_prefix + "Initializing");

    /**
     * Handle an event from Genesys
     * @param message
     */
    var onGenesysMessage = function (message) {
        console.log(log_prefix + 'onGenesysMessage - ' + message.channel);

        switch (message.channel) {
            case '/v2/me/calls':
                voice.onMessage(message.data);
                /* "data":{
                        "notificationType":"StatusChange",
                        "call":{
                            "id":"NR0O3ITJ5P0TP0HCUNKM9PPH4K00000D",
                            "state":"Established",
                            "callUuid":"NR0O3ITJ5P0TP0HCUNKM9PPH4K00000D",
                            "deviceUri":"http://demosrv.genesyslab.com:8089/api/v2/devices/bb7aeea8-bcf1-4b56-a4e7-013e1ee5391d",
                            "participants":[],
                            "ani":"5125",
                            "dnis":"8012",
                            "callType":"Inbound",
                            "capabilities":[],
                            "userData":{
                                "acw_time":"40"
                            },
                            "duration":"6",
                            "mute":"Off",
                            "recordingState":"Stopped",
                            "supervisorListeningIn":false,
                            "monitoredUserMuted":false,
                            "monitoring":false,
                            "uri":"http://demosrv.genesyslab.com:8089/api/v2/me/calls/NR0O3ITJ5P0TP0HCUNKM9PPH4K00000D",
                            "path":"/calls/NR0O3ITJ5P0TP0HCUNKM9PPH4K00000D",
                            "case":[]
                        },
                        "phoneNumber":"7001",
                        "messageType":"CallStateChangeMessage",
                        "metrics":{} */
                break;

            case '/v2/me/emails':
                email.onMessage(message.data);

                /* "data":{
                     "referenceId":32,
                     "messageType":"EmailStateChangeMessage",
                     "email":{
                         "state":"Processing",
                         "userData":{},
                         "id":"000XJaBEC1HH000P",
                         "receivedDate":"2016-03-15 23:38:42.000+1000",
                         "suggestedQueueUris":[],
                         "assignedTo":"voladipo",
                         "revelantResponseTemplateGroups":[],
                         "subject":"aa",
                         "contactId":"0008Va76MGEC000Q",
                         "from":"thompson@demosrv.genesyslab.com",
                         "to":["info@premier.com"],
                         "body":"<HTML><HEAD></HEAD>\r\n<BODY dir=ltr>\r\n<DIV dir=ltr>\r\n<DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">\r\n<DIV>aaa</DIV></DIV></DIV></BODY></HTML>\r\n",
                         "mime":"text/html",
                         "bodyAsPlainText":"aaa",
                         "emailType":"Inbound",
                         "capabilities":[
                             "Reply",
                             "ReplyAll",
                             "Transfer",
                             "AddComment",
                             "AttachUserData",
                             "UpdateUserData",
                             "DeleteUserData",
                             "SetDisposition",
                             "SetInFocus",
                             "Complete"
                         ]
                     },
                     "notificationType":"StatusChange"
                 },"
                 */
                break;

            case '/v2/me/chats':
                /*data":{
                     "messageType":"ChatStateChangeMessage",
                     "chat":{
                         "state":"Invited",
                         "userData":{},
                         "id":"000XJaBEC1HH000S",
                         "uri":"http://demosrv.genesyslab.com:8089/api/v2/chats/000XJaBEC1HH000S",
                         "receivedDate":"2016-03-16 09:55:18.000+1000",
                         "participants":[],
                         "chatType":"Inbound",
                         "capabilities":[
                             "Accept",
                             "Reject"
                         ]
                     },
                     "notificationType":"StatusChange"
                     },
                 "channel":"/v2/me/chats" */
                chat.onMessage(message.data);
                break;

            case '/v2/me/outbound':
                /*
                 "data":{
                    "notificationType":"StatusChanged",
                    "record":{
                        "id":"d17d0be3-f15f-439f-8464-6d5e55063f67",
                        "state":"ReadyToCall",
                        "phone":"4105550951",
                        "customFields":{
                            "GSW_CAMPAIGN_GROUP_DESCRIPTION":"",
                            "daily_till":86399,
                            "chain_n":0,
                            "tier":"Bronze",
                            "type":"",
                            "phone1":"7876847377",
                            "days_past_due":45,
                            "GSW_CPN_DIGITS":"Survey",
                            ...
                        },
                        "uri":"http://demosrv.genesyslab.com:8089/api/v2/outbound-records/d17d0be3-f15f-439f-8464-6d5e55063f67",
                            "path":"/outbound-records/d17d0be3-f15f-439f-8464-6d5e55063f67"
                    },
                    "messageType":"OutboundRecordMessage" */
                message.data.record.userData = message.data.record.customFields; // make it compatible with other media
                preview.onMessage(message.data);
                break;
        }
    };

    var initialize = function() {
        util.getInstance('genesys.message').subscribe(onGenesysMessage);
        console.log(log_prefix + "Initialized");
    };

    return {
        initialize: initialize
    };
});