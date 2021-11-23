if(!OPNET_ARXS){
   var OPNET_ARXS={startJS:Number(new Date()),
   clientId:'BBB432DD1981A9AC',appId:100230,
   collector:'webmetrics.auspost.com.au',
   collectorHttpPort:8100, collectorHttpsPort:8900,
   sv:'0302',
   ajax:true, sync:true,
   ajaxResponseTime:true};
   (function(){
      var w=window,l=w.addEventListener,m=w.attachEvent,
      d=document,s='script',t='load',o=OPNET_ARXS,
      z='-0b2c4d73f58414c86c7384150be8ca44',
      r=(('https:'===d.location.protocol)?
      'https://953c27ce3b34cfb8cc56'+z+'.ssl':
      'http://fb3f316d487bcc59f7ec'+z+'.r88')+
      '.cf1.rackcdn.com/opnet_browsermetrix.c.'+
      (o.ajax?'ajax.js':'js'),p=('onpagehide' in w),e=p?'pageshow':t,
      j=d.createElement(s),x=d.getElementsByTagName(s)[0],
      h=function(y){o.ldJS=new Date();o.per=y?y.persisted:null;},
      i=function(){o.ld=1;};o.cookie=d.cookie;d.cookie=
      '_op_aixPageId=0; path=/; expires='+(new Date(0)).toGMTString();
      o.cookieAfterDelete=d.cookie;j.async=1;j.src=r;
      if(l){l(e,h,false);if(p){l(t,i,false);}}else if(m)
      {m('on'+e,h);if(p){m('on'+t,i);}}
      if(o.sync){d.write('<'+s+' src=\''+r+'\'></'+s+'>');}
      else{x.parentNode.insertBefore(j,x);}
   })();}