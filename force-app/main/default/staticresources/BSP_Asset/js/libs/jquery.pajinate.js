(function(e){e.fn.pajinate=function(t){function d(r){new_page=parseInt(i.data(n),10)-1,e(r).siblings(".active_page").prev(".page_link").length==1?(y(r,new_page),m(new_page)):t.wrap_around&&m(l-1)}function v(r){new_page=parseInt(i.data(n),10)+1,e(r).siblings(".active_page").next(".page_link").length==1?(g(r,new_page),m(new_page)):t.wrap_around&&m(0)}function m(e){var s=parseInt(i.data(r),10),o=!1;start_from=e*s,end_on=start_from+s;var f=a.hide().slice(start_from,end_on);f.show(),u.find(t.nav_panel_id).find(".page_link a[longdesc="+e+"]").parent().addClass("active_page "+h).siblings(".active_page").removeClass("active_page "+h),i.data(n,e),u.find(t.nav_info_id).html(t.nav_label_info.replace("{0}",start_from+1).replace("{1}",start_from+f.length).replace("{2}",a.length)),b(),w()}function g(n,r){var i=r,s=e(n).siblings(".active_page");s.siblings(".page_link").find("a[longdesc="+i+"]").parent().css("display")==="none"&&f.each(function(){e(this).find(".page_link").hide().slice(parseInt(i-t.num_page_links_to_display+1,10),i+1).show()})}function y(n,r){var i=r,s=e(n).siblings(".active_page");s.siblings(".page_link").find("a[longdesc="+i+"]").parent().css("display")==="none"&&f.each(function(){e(this).find(".page_link").hide().slice(i,i+parseInt(t.num_page_links_to_display,10)).show()})}function b(){f.find(".page_link:visible").hasClass("last")?f.find(".more").hide():f.find(".more").show(),f.find(".page_link:visible").hasClass("first")?f.find(".less").hide():f.find(".less").show()}function w(){f.find(".last").hasClass("active_page")?f.find(".next_link").add(".last_link").addClass("no_more "+p):f.find(".next_link").add(".last_link").removeClass("no_more "+p),f.find(".first").hasClass("active_page")?f.find(".previous_link").add(".first_link").addClass("no_more "+p):f.find(".previous_link").add(".first_link").removeClass("no_more "+p)}var n="current_page",r="items_per_page",i,s={item_container_id:".content",items_per_page:10,nav_panel_id:".page_navigation",nav_info_id:".info_text",num_page_links_to_display:20,start_page:0,wrap_around:!1,nav_label_first:"First",nav_label_prev:"Prev",nav_label_next:"Next",nav_label_last:"Last",nav_order:["first","prev","num","next","last"],nav_label_info:"Showing {0}-{1} of {2} results",show_first_last:!0,abort_on_small_lists:!1,jquery_ui:!1,jquery_ui_active:"ui-state-highlight",jquery_ui_default:"ui-state-default",jquery_ui_disabled:"ui-state-disabled"},t=e.extend(s,t),o,u,a,f,l,c=t.jquery_ui?t.jquery_ui_default:"",h=t.jquery_ui?t.jquery_ui_active:"",p=t.jquery_ui?t.jquery_ui_disabled:"";return this.each(function(){u=e(this),o=e(this).find(t.item_container_id),a=u.find(t.item_container_id).children();if(t.abort_on_small_lists&&t.items_per_page>=a.size())return u;i=u,i.data(n,0),i.data(r,t.items_per_page);var s=o.children().size(),p=Math.ceil(s/t.items_per_page),E='<span class="ellipse more">...</span>',S='<span class="ellipse less">...</span>',x=t.show_first_last?'<li class="first_link '+c+'"><a href="">'+t.nav_label_first+"</a></li>":"",T=t.show_first_last?'<li class="last_link '+c+'"><a href="">'+t.nav_label_last+"</a></li>":"",N='<ul class="pagination">';for(var C=0;C<t.nav_order.length;C++)switch(t.nav_order[C]){case"first":N+=x;break;case"last":N+=T;break;case"next":N+='<li class="next_link '+c+'"><a href="">'+t.nav_label_next+"</a></li>";break;case"prev":N+='<li class="previous_link '+c+'"><a href="">'+t.nav_label_prev+"</a></li>";break;case"num":N+=S;var k=0;while(p>k)N+='<li class="page_link '+c+'"><a href="" longdesc="'+k+'">'+(k+1)+"</a></li>",k++;N+=E;break;default:}N+="</ul>",f=u.find(t.nav_panel_id),f.html(N).each(function(){e(this).find(".page_link:first").addClass("first"),e(this).find(".page_link:last").addClass("last")}),f.children(".ellipse").hide(),f.find(".previous_link").next().next().addClass("active_page "+h),a.hide(),a.slice(0,i.data(r)).show(),l=u.children(t.nav_panel_id+":first").find(".page_link").size(),t.num_page_links_to_display=Math.min(t.num_page_links_to_display,l),f.find(".page_link").hide(),f.each(function(){e(this).find(".page_link").slice(0,t.num_page_links_to_display).show()}),u.find(".first_link a").click(function(t){t.preventDefault(),y(e(this),0),m(0)}),u.find(".last_link a").click(function(t){t.preventDefault();var n=l-1;g(e(this),n),m(n)}),u.find(".previous_link a").click(function(t){t.preventDefault(),d(e(this).parent())}),u.find(".next_link a").click(function(t){t.preventDefault(),v(e(this).parent())}),u.find(".page_link a").click(function(t){t.preventDefault(),m(e(this).attr("longdesc"))}),m(parseInt(t.start_page,10)),b(),t.wrap_around||w()})}})(jQuery);