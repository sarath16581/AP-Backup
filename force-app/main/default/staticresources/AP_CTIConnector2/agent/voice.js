define(["util","config"],function(e,o){var a="agent/voice: ",l=function(o){console.log(a+o.messageType);try{if(o.messageType==="CallStateChangeMessage"&&o.notificationType==="StatusChange")switch(console.log(a+"id - "+o.call.id),console.log(a+"state - "+o.call.state),console.log(a+"call type - "+o.call.callType),o.call.mediaType="voice"+o.call.callType,o.call.dnis!==void 0&&console.log(a+"dnis - "+o.call.dnis),o.call.state){case"Established":console.log(a+"publish voice.pop"),e.getInstance("voice.pop").publish(o);break;case"Completed":console.log(a+"publish voice.ended"),e.getInstance("voice.ended").publish(o)}}catch(l){console.error(a+"ERROR - "+l.message)}},c=function(e){try{console.log(a+"dial - "+e.phoneNumber);var l={Action:"Dial",CI:o.CI,ActionData:{number:e.phoneNumber,userData:e.userData}};$.ajax({url:o.URL,data:"/request="+JSON.stringify(l),type:"GET",processData:!1,timeout:5e3,async:!1,crossDomain:!0,cache:!1,dataType:"jsonp",success:function(){e.callback&&e.callback()},error:function(l,c,s){console.error(a+o.URL+" "+c+" - "+l.status+" "+s),e.error&&e.error()}})}catch(c){console.error(a+"ERROR - "+c.message)}};return{onMessage:l,dial:c}})