var controller = (function() {
	'use strict';

	var KEYCODE_ENTER = 13;

	var j$ = jQuery.noConflict();

	var my = {

		initialize: function() {
			my.wireEvents();
		},

		/**
		 * Monitor DOM actions
		 */
		wireEvents: function() {
		    //Check if the chat starts in Mobile
		    var isMobile = /iPhone|Android|iPad/i.test(navigator.userAgent);
		    console.log('isMobile: '+isMobile);
            if (isMobile) {
              my.hideExpandCollapse();
            }
			j$('#customMessageBox').on('keyup', my.textareaKeyUp);
			j$("#customMessageBox").on('keypress', my.textareaKeyPress);
            j$("#customMessageBox").on('change', my.textareaChange);
            j$(".nw_CloseControls").on('click', my.closeChat);
            j$(".nw_PrintControls").on('click', my.printChat);
            j$(".nw_expandControls").on('click', my.expandCollapseChat);

            // add aria elements
            j$('#liveAgentClientChat').on('DOMNodeInserted', my.chatLogDomNodeInserted);

            // receive end chat and save transcript events from Nuance
			//window.addEventListener("message", my.receiveMessage, false);

			// use to monitor css class changes to avoid having to tap into an undocumented API
			my.setupChatLogMutationListener();
		},

        /**
		 * This is to monitor when the status message and the alert messages show and hide
		 * We carry out specific actions based on each of these messages changing
         */
        setupChatLogMutationListener: function() {

            // callback method to work around a live agent bug where the StatusMessage class is not removed from liveAgentClientChat when the message disappears
			var statusMessageAttributesChanged = function(mutations) {
				for(var i=0;i<mutations.length;i++) {
                    var mutation = mutations[i];
                    if (mutation.type === 'attributes' && mutation.attributeName === 'style') {
                        if (!j$('#liveAgentMessageStatus').is(':visible') && j$('#liveAgentClientChat').hasClass('liveAgentStateStatusMessage')) {
                            // hack to fix up the incorrect statuses being displayed on the chatlog attribute
                            j$('#liveAgentClientChat').removeClass('liveAgentStateStatusMessage').addClass('liveAgentState');
                        }
                    }
                }
			};

			// callback function, alert messages do not change css classes, so we monitor for when the div is visible and hidden and add classes manually
            var alertMessageAttributesChanged = function(mutations) {
            	for(var i=0;i<mutations.length;i++) {
            		var mutation = mutations[i];
                    if(mutation.type === 'attributes' && mutation.attributeName === 'style') {
                        if (j$('#liveAgentMessageContainer').is(':visible')) {
                            // add a class to the chat log to make the window smaller to make room for the alert message
                            j$('#liveAgentClientChat').addClass('with-alert-message');
                        } else {
                            j$('#liveAgentClientChat').removeClass('with-alert-message');
                        }
                    }
                }
            };

            // callback method, monitor when the chat 'state' changes
            // this includes chat ended, chat waiting, chat connected etc...
            var chatLogAttributesChanged = function(mutations) {
                for(var i=0;i<mutations.length;i++) {
                    var mutation = mutations[i];
                    if(mutation.type === 'attributes' && mutation.attributeName === 'class') {
                        if (j$('#liveAgentClientChat').hasClass('liveAgentState')) { // chat is connected
							j$("#customMessageBox").prop('disabled', false);
                        } else { // any other non-connected state
                            j$("#customMessageBox").prop('disabled', true);
                            j$('.nw_UserSubmit').addClass('nw_Disabled');
                        }
                    }
                }
            };

            var MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver;

            // this is to fix a bug where liveAgentStateStatusMessage is not remove even though the status message disappears
            var statusMessageObserver = new MutationObserver(statusMessageAttributesChanged);

            // this is to control the layout when an alert message is displayed in the same design as status messages
            var alertMessageObserver = new MutationObserver(alertMessageAttributesChanged);

            // track when the css class changes on the chat log, in order to disable and enable the input box
            var chatLogObserver = new MutationObserver(chatLogAttributesChanged);

            var options = { attributes: true };
            statusMessageObserver.observe(j$('#liveAgentMessageStatus').get(0), options);
            alertMessageObserver.observe(j$('#liveAgentMessageContainer').get(0), options);
            chatLogObserver.observe(j$('#liveAgentClientChat').get(0), options);
		},

        /**
         * When a keyup event occurs on the custom chat textarea
         */
		textareaKeyUp: function(e) {
			var $el = j$(e.currentTarget);
            var text = $el.val();

            // disable custom send button when there is no text in textarea
            if(text.trim().length <= 0){
                j$('.nw_UserSubmit').addClass('nw_Disabled');
            } else {
                j$('.nw_UserSubmit').removeClass('nw_Disabled');
            }

            // push the Visitor is typing message to the agent if enter WASN'T pressed
            if(event.which !== KEYCODE_ENTER) {
                my.sendVisitorTypingState();
            }
		},

        /**
         * Whenever a new chat message is received from either the visitor or agent
         * Add accessibility attributes to the message
         */
        chatLogDomNodeInserted: function(e) {
            var element = e.target;

            //add tabindex attributes
            // NOTE: we also check parent here because when we use .wrap, another DOMNodeInserted event is fired which would end in an infinite loop
            if(j$(element).hasClass('operator') && j$(element).parent().attr('id') === 'liveAgentChatLogText'){
                //j$(element).wrap('<span aria-label="The agent said" tabindex="0"></span>');
            } else if(j$(element).hasClass('client') && j$(element).parent().attr('id') === 'liveAgentChatLogText'){
                //j$(element).wrap('<span aria-label="You said" tabindex="0"></span>');
            }

            // ensure the focus is given back to our input box so the next message can be typed.
            setTimeout(function() {
                if(j$('#customMessageBox').is(':visible'))
                    j$('#customMessageBox').focus();
            }, 20);
        },

        /**
         * When a keyup event occurs on the custom chat textarea
         */
		textareaKeyPress: function(e) {
		    // if enter was pressed on the custom textarea then we trigger the message to be sent to the agent
			if(e.which === KEYCODE_ENTER) {
                e.preventDefault();

                my.copyMessage();

                j$('.nw_UserSubmit').addClass('nw_Disabled');
            }
		},

        /**
        *When the close button is clicked
        */
        closeChat: function(e) {
            var result = window.confirm("Are you sure you want to exit your Live Chat Session?");
            if (result == true) {
                if(j$('#liveAgentClientChat').hasClass('liveAgentStateWaiting')) {
                    j$('.liveAgentCancelButton').click();
//                    j$('#waitingMessageNew').css('display','none');
                } else {
                    j$('.liveAgentEndButton').click();
                }
                //setting time out to complete cancel and end chat click
                setTimeout(function(){
                    window.parent.postMessage("exitChat", "*");
                }, 2000);
            }
        },

        /**
          *When the print button is clicked
          */
        printChat: function(e) {
            j$('.liveAgentSaveButton').click();
        },

        /**
        *When the expand/collapse button is clicked
        */
        expandCollapseChat: function(e) {
            //Toggle between classes for expand and collapse
            j$('#expandCollapse').toggleClass('bw-expand');
            j$('#expandCollapse').toggleClass('bw-collapse');
            // ----------------------------
            // PostMessage call to resize to nuance
            window.parent.postMessage("resizeChat", "*");
        },

        hideExpandCollapse: function() {
            j$('.nw_expandControls').css('padding-right','0px');
            j$('#expandCollapse').hide('bw-expand');
            //j$('.nw_PrintControls').css('right','52px')
        },

        textareaChange: function(e) {
            var $el = j$(e.currentTarget);
            var text = $el.val();

            // disable custom send button when there is no text in textarea
            if(text.trim().length <= 0){
                j$('.nw_UserSubmit').addClass('nw_Disabled');
            } else {
                j$('.nw_UserSubmit').removeClass('nw_Disabled');
            }

            // send the message 'The visior is typing'
            my.sendVisitorTypingState();
        },

        /**
         * Trigger the events that send the visitor is typing state back to agent
         */
        sendVisitorTypingState: function() {
            var text = j$("#customMessageBox").val();
            j$("#liveAgentChatTextArea").val(text);
            j$("#liveAgentChatTextArea").click();
            j$("#liveAgentChatTextArea").change();
        },

        /**
         * Sends the actual message the user was typing back to the agent.
         * Used when textarea ENTER is pressed and when the custom button is clicked.
         */
        copyMessage: function(){
			var textMessage = j$("#customMessageBox").val();
			j$("#liveAgentChatTextArea").val(textMessage);
			j$("#liveAgentChatTextArea").focus();

			// trigger a send message back to the agent
            //liveagent.chasitor.sendMessage();
            j$('.liveAgentSendButton').click();

			j$("#customMessageBox").val('');
            j$("#customMessageBox").change();
		},

        /**
         * Receives a custom postMessage from the parent window
         */
//		receiveMessage: function(event) {
//			var origin = event.origin || event.originalEvent.origin; // For Chrome, the origin property is in the event.originalEvent object.
//			if (origin === '')
//				return;
//			if (typeof event.data === 'object' && event.data.call === 'sendValue') {
//				if(event.data.value === 'endChat') {
//				    // trigger the chat to finish
//                    //liveagent.chasitor.endChat();
//                    if(j$('#liveAgentClientChat').hasClass('liveAgentStateWaiting')) {
//                        j$('.liveAgentCancelButton').click();
//                    } else {
//                        j$('.liveAgentEndButton').click();
//                    }
//                }
//                if(event.data.value === 'printChat') {
//				    // trigger the chat to save
//					j$('.liveAgentSaveButton').click();
//				}
//			}
//		}
	};

	// return a public interface
	return {
		initialize: my.initialize,
		copyMessage: my.copyMessage
	};
});