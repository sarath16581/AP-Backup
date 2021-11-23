//jQuery Override http://jqueryoverride.codeplex.com
(function(r,m){function p(a){return Object.prototype.toString.call(a).match(/^\[object (.*)\]$/)[1]}Array.prototype.indexOf||(Array.prototype.indexOf=function(a,b){b=b||0;for(var c=this.length;b<c;){if(this[b]===a)return b;++b}return-1});m.fn.override=function(a,b,c,f){if("Function"===p(a))if("String"===p(b)){if("subscribe"===b)return d.subscribeFunction(a,c);if("unsubscribe"===b)return d.unsubscribeFunction(a,c);if("restore"===b)return d.restoreFunction(a);if("wrap"===b)return d.wrapFunction(a,c)}else{if("Function"===
p(b))return d.wrapFunction(a,b)}else return this.each(function(){return"restore"===a?d.restoreElement(m(this),b,c):d.convertInline(m(this),a,b,c,f)})};var d=m.fn.override,l=d.oFunctions=[],n=d.oFunctionCount=1,j=d.oElements=[],q=d.oElementCount=1;d.getFunction=function(a){if(a.isOverride)for(var b=0;b<l.length;b++)if(l[b].isOverride===a.isOverride)return l[b]};d.addFunction=function(a){if(!a.isOverride){var b=n;n++;var c={isOverride:b,originalFunction:a,beforeFunction:[],afterFunction:[],isWrapped:!1};
l.push(c);a=function(){for(var a={cancel:!1},b=0;b<c.beforeFunction.length;b++)if(c.beforeFunction[b].call(this,a,arguments),a.cancel)return;for(var e=c.originalFunction.apply(this,arguments),b=0;b<c.afterFunction.length;b++)c.afterFunction[b].call(this,a,arguments);return e};a.isOverride=b;a.isWrapped=!1;return a}};d.wrapFunction=function(a,b){var c,d,k=function(){return 1>arguments.length?a.apply(c,d):a.apply(this,arguments)},e={isOverride:n,originalFunction:a,beforeFunction:[],afterFunction:[],
isWrapped:!0},h=function(){c=this;d=arguments;for(var a={cancel:!1},g=0;g<e.beforeFunction.length;g++)if(e.beforeFunction[g].call(this,a,arguments),a.cancel)return;for(var h=b.call(this,arguments,k),g=0;g<e.afterFunction.length;g++)e.afterFunction[g].call(this,a,arguments);return h};h.isOverride=n;h.isWrapped=!0;n++;l.push(e);return h};d.subscribeFunction=function(a,b){d.getFunction(a).beforeFunction.push(b)};d.unsubscribeFunction=function(a,b){var c=d.getFunction(a);if(b){for(var f=0;f<c.beforeFunction.length;f++)if(c.beforeFunction[f]==
b){c.beforeFunction.splice(f,1);return}for(f=0;f<c.afterFunction.length;f++)if(c.afterFunction[f]==b){c.afterFunction.splice(f,1);break}}else c.afterFunction=[],c.beforeFunction=[]};d.restoreFunction=function(a){return d.getFunction(a).originalFunction};d.getElement=function(a){if(a=a.data("override-elementCount"))for(var b=0;b<j.length;b++)if(j[b].elementCount===a)return j[b]};d.addElement=function(a,b,c,d){q++;a.data("override-elementCount",q);a={elementCount:q,attributes:[{attr:b,bindTo:c,boundFunc:d}]};
j.push(a);return a};d.convertInline=function(a,b,c,f){var k=d.getElement(a),e=m.trim(a.attr(b)+"");a.data("override-"+b,e);var h=new Function(e);"onclick"===m.trim((b+"").toLowerCase())?(a.removeAttr("onclick"),a.prop("onclick",null)):a.removeAttr("onclick");var j=function(){return 1>arguments.length?h.apply(g,l):h.apply(this,arguments)},g,l;f?(e=function(){g=this;l=arguments;return f.call(this,j,a,arguments)},a.bind(c,e)):(e=h,a.bind(c,h));void 0===k?d.addElement(a,b,c,e):k.attributes.push({attr:b,
bindTo:c,boundFunc:e})};d.restoreElement=function(a,b){if(b){var c=d.getElement(a);if(c){var f=a.data("override-"+b),k;m.each(c.attributes,function(){k=this.attr===b?this:k});a.attr(b,f);a.unbind(k.bindTo,k.boundFunc);a.removeAttr("data-override-"+b);for(var e=0;e<c.attributes.length;e++)if(c.attributes[e].attr===b){c.attributes.splice(e,1);break}}}else if(c=d.getElement(a)){for(e=0;e<c.attributes.length;e++)f=a.data("override-"+c.attributes[e].attr),a.attr(c.attributes[e].attr,f),a.unbind(c.attributes[e].attr,
c.attributes[e].boundFunc),a.removeAttr("data-override-"+c.attributes[e].attr);for(e=0;e<j.length;e++)if(j[e]===c){j.splice(e,1);return}a.removeAttr("data-override-elementCount")}}})(window,jQuery);