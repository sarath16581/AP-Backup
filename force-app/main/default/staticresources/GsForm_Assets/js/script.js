(function(e) {
    function n(e, n, r) {
        var i = "(" + r.replace(t, "\\$1") + ")";
        return e.replace(new RegExp(i, "gi"), "<strong>$1</strong>")
        }
    function r(t, r) {
        this.el = e(t),
        this.el.attr("autocomplete", "off"),
        this.suggestions = [],
        this.data = [],
        this.badQueries = [],
        this.selectedIndex = -1,
        this.currentValue = this.el.val(),
        this.intervalId = 0,
        this.cachedResponse = [],
        this.onChangeInterval = null,
        this.onChange = null,
        this.ignoreValueChange = !1,
        this.serviceUrl = r.serviceUrl,
        this.isLocal = !1,
        this.options = {
            autoSubmit: !1,
            minChars: 1,
            maxHeight: 300,
            deferRequestBy: 0,
            width: 0,
            highlight: !0,
            params: {},
            fnFormatResult: n,
            delimiter: null,
            zIndex: 9999
        },
        this.initialize(),
        this.setOptions(r),
        this.el.data("autocomplete", this)
        }
    var t = new RegExp("(\\" + ["/", ".", "*", "+", "?", "|", "(", ")", "[", "]", "{", "}", "\\"].join("|\\") + ")", "g");
    e.fn.autocompleteSearch = function(t, n) {
        var i;
        return typeof t == "string" ? (i = this.data("autocomplete"), typeof i[t] == "function" && i[t](n)) : i = new r(this.get(0) || e("<input />"), t),
        i
    },
    r.prototype = {
        killerFn: null,
        initialize: function() {
            var t,
            n,
            r;
            t = this,
            n = Math.floor(Math.random() * 1048576).toString(16),
            r = "Autocomplete_" + n,
            this.killerFn = function(n) {
                e(n.target).parents(".autocomplete").size() === 0 && (t.killSuggestions(), t.disableKillerFn())
                },
            this.options.width || (this.options.width = this.el.width()),
            this.mainContainerId = "AutocompleteContainter_" + n,
            e('<div id="' + this.mainContainerId + '" style="position:absolute;z-index:9999;"><div class="autocomplete-w1"><div class="autocomplete" id="' + r + '" style="display:none; width:300px;"></div></div></div>').appendTo("body"),
            this.container = e("#" + r),
            this.fixPosition(),
            window.opera ? this.el.keypress(function(e) {
                t.onKeyPress(e)
                }) : this.el.keydown(function(e) {
                t.onKeyPress(e)
                }),
            this.el.keyup(function(e) {
                t.onKeyUp(e)
                }),
            this.el.blur(function() {
                t.enableKillerFn()
                }),
            this.el.focus(function() {
                t.fixPosition()
                }),
            this.el.change(function() {
                t.onValueChanged()
                })
            },
        extendOptions: function(t) {
            e.extend(this.options, t)
            },
        setOptions: function(t) {
            var n = this.options;
            this.extendOptions(t),
            n.extraWidth && (n.width += n.extraWidth);
            if (n.lookup || n.isLocal)
                this.isLocal = !0,
            e.isArray(n.lookup) && (n.lookup = {
                suggestions: n.lookup,
                data: []
                });
            e("#" + this.mainContainerId).css({
                zIndex: n.zIndex
            }).addClass(n.className),
            this.container.css({
                maxHeight: n.maxHeight + "px",
                width: n.width
            })
            },
        clearCache: function() {
            this.cachedResponse = [],
            this.badQueries = []
            },
        disable: function() {
            this.disabled = !0
        },
        enable: function() {
            this.disabled = !1
        },
        fixPosition: function() {
            var t = this.el.offset(),
            n = t.left,
            r = t.top + this.el.innerHeight();
            this.options.leftMargin && this.el.attr("id") === "header-search" && e("html").hasClass("csstransitions") && (n += this.options.leftMargin),
            this.options.topMargin && (r += this.options.topMargin),
            e("#" + this.mainContainerId).css({
                top: r + "px",
                left: n + "px"
            })
            },
        enableKillerFn: function() {
            var t = this;
            e(document).bind("click", t.killerFn)
            },
        disableKillerFn: function() {
            var t = this;
            e(document).unbind("click", t.killerFn)
            },
        killSuggestions: function() {
            var e = this;
            this.stopKillSuggestions(),
            this.intervalId = window.setInterval(function() {
                e.hide(),
                e.stopKillSuggestions()
                }, 300)
            },
        stopKillSuggestions: function() {
            window.clearInterval(this.intervalId)
            },
        onValueChanged: function() {
            this.change(this.selectedIndex)
            },
        onKeyPress: function(e) {
            if (this.disabled || !this.enabled)
                return;
            switch (e.keyCode) {
            case 27:
                this.el.val(this.currentValue),
                this.hide();
                break;
            case 9:
            case 13:
                if (this.selectedIndex === -1) {
                    this.hide();
                    return
                }
                this.select(this.selectedIndex);
                if (e.keyCode === 9)
                    return;
                break;
            case 38:
                this.moveUp();
                break;
            case 40:
                this.moveDown();
                break;
            default:
                return
            }
            e.stopImmediatePropagation(),
            e.preventDefault()
            },
        onKeyUp: function(e) {
            if (this.disabled)
                return;
            switch (e.keyCode) {
            case 38:
            case 40:
                return
            }
            clearInterval(this.onChangeInterval);
            if (this.currentValue !== this.el.val())
                if (this.options.deferRequestBy > 0) {
                var t = this;
                this.onChangeInterval = setInterval(function() {
                    t.onValueChange()
                    }, this.options.deferRequestBy)
                } else
                this.onValueChange()
            },
        onValueChange: function() {
            clearInterval(this.onChangeInterval),
            this.currentValue = this.el.val();
            var e = this.getQuery(this.currentValue);
            this.selectedIndex = -1;
            if (this.ignoreValueChange) {
                this.ignoreValueChange = !1;
                return
            }
            e === "" || e.length < this.options.minChars ? this.hide() : this.getSuggestions(e)
            },
        getQuery: function(t) {
            var n,
            r;
            return n = this.options.delimiter,
            n ? (r = t.split(n), e.trim(r[r.length - 1])) : e.trim(t)
            },
        getSuggestionsLocal: function(e) {
            var t,
            n,
            r,
            i,
            s;
            n = this.options.lookup,
            r = n.suggestions.length,
            t = {
                suggestions: [],
                data: []
                },
            e = e.toLowerCase();
            for (s = 0; s < r; s++)
                i = n.suggestions[s],
            i.toLowerCase().indexOf(e) === 0 && (t.suggestions.push(i), t.data.push(n.data[s]));
            return t
        },
        getSuggestions: function(t) {
            var n,
            r;
            n = this.isLocal ? this.getSuggestionsLocal(t) : this.cachedResponse[t],
            n && e.isArray(n.suggestions) ? (this.suggestions = n.suggestions, this.data = n.data, this.suggest()) : this.isBadQuery(t) ? this.hide() : (r = this, r.options.params.q = encodeURIComponent(t), e.ajax({
                url: this.serviceUrl,
                dataType: "jsonp",
                data: r.options.params,
                success: function(e) {
                    r.processResponse(e)
                    }
            }))
            },
        isBadQuery: function(e) {
            var t = this.badQueries.length;
            while (t--)
                if (e.indexOf(this.badQueries[t]) === 0)
                return ! 0;
            return ! 1
        },
        hide: function() {
            this.enabled = !1,
            this.selectedIndex = -1,
            this.container.hide()
            },
        suggest: function() {
            if (this.suggestions.length === 0) {
                this.hide();
                return
            }
            var t,
            n,
            r,
            i,
            s,
            o,
            u,
            a,
            f;
            t = this,
            n = this.suggestions.length,
            i = this.options.fnFormatResult,
            s = this.getQuery(this.currentValue),
            a = function(e) {
                return function() {
                    t.activate(e)
                    }
            },
            f = function(e) {
                return function() {
                    t.select(e)
                    }
            },
            this.container.hide().empty();
            for (o = 0; o < n; o++)
                u = this.suggestions[o],
            r = e((t.selectedIndex === o ? '<div class="selected"': "<div") + ' title="' + u + '">' + i(u, this.data[o], s) + "</div>"),
            r.mouseover(a(o)),
            r.click(f(o)),
            this.container.append(r);
            this.enabled = !0,
            this.container.show()
            },
        processResponse: function(e) {
            if (e.length < 2)
                return;
            var t = e[0],
            n = e[1];
            this.options.noCache || (this.cachedResponse[t] = e, n.length === 0 && this.badQueries.push(t)),
            t.toLowerCase() === this.getQuery(this.currentValue).toLowerCase() && (this.suggestions = n, this.data = [], this.suggest())
            },
        activate: function(t) {
            var n,
            r;
            return n = this.container.children(),
            this.selectedIndex !== -1 && n.length > this.selectedIndex && e(n.get(this.selectedIndex)).removeClass(),
            this.selectedIndex = t,
            this.selectedIndex !== -1 && n.length > this.selectedIndex && (r = n.get(this.selectedIndex), e(r).addClass("selected")),
            r
        },
        deactivate: function(e, t) {
            e.className = "",
            this.selectedIndex === t && (this.selectedIndex = -1)
            },
        select: function(e) {
            var t,
            n;
            t = this.suggestions[e],
            t && (this.el.val(t), this.options.autoSubmit && (n = this.el.parents("form"), n.length > 0 && n.get(0).submit()), this.ignoreValueChange = !0, this.hide(), this.onSelect(e))
            },
        change: function(t) {
            var n,
            r,
            i;
            i = this,
            n = this.suggestions[t];
            if (n) {
                var s,
                o;
                s = i.suggestions[t],
                o = i.data[t],
                i.el.val(i.getValue(s))
                } else
                s = "",
            o = -1;
            r = i.options.onChange,
            e.isFunction(r) && r(s, o, i.el)
            },
        moveUp: function() {
            if (this.selectedIndex === -1)
                return;
            if (this.selectedIndex === 0) {
                this.container.children().get(0).className = "",
                this.selectedIndex = -1,
                this.el.val(this.currentValue);
                return
            }
            this.adjustScroll(this.selectedIndex - 1)
            },
        moveDown: function() {
            if (this.selectedIndex === this.suggestions.length - 1)
                return;
            this.adjustScroll(this.selectedIndex + 1)
            },
        adjustScroll: function(e) {
            var t,
            n,
            r,
            i;
            t = this.activate(e),
            n = t.offsetTop,
            r = this.container.scrollTop(),
            i = r + this.options.maxHeight - 25,
            n < r ? this.container.scrollTop(n) : n > i && this.container.scrollTop(n - this.options.maxHeight + 25),
            this.el.val(this.getValue(this.suggestions[e]))
            },
        onSelect: function(t) {
            var n,
            r,
            i,
            s;
            n = this,
            r = n.options.onSelect,
            i = n.suggestions[t],
            s = n.data[t],
            n.el.val(n.getValue(i)),
            e.isFunction(r) && r(i, s, n.el)
            },
        getValue: function(e) {
            var t,
            n,
            r,
            i;
            return i = this,
            t = i.options.delimiter,
            t ? (n = i.currentValue, r = n.split(t), r.length === 1 ? e: n.substr(0, n.length - r[r.length - 1].length) + e) : e
        }
    }
})(jQuery),
function(e) {
    e.fn.pajinate = function(t) {
        function d(r) {
            new_page = parseInt(i.data(n), 10) - 1,
            e(r).siblings(".active_page").prev(".page_link").length == 1 ? (y(r, new_page), m(new_page)) : t.wrap_around && m(l - 1)
            }
        function v(r) {
            new_page = parseInt(i.data(n), 10) + 1,
            e(r).siblings(".active_page").next(".page_link").length == 1 ? (g(r, new_page), m(new_page)) : t.wrap_around && m(0)
            }
        function m(e) {
            var s = parseInt(i.data(r), 10),
            o = !1;
            start_from = e * s,
            end_on = start_from + s;
            var f = a.hide().slice(start_from, end_on);
            f.show(),
            u.find(t.nav_panel_id).find(".page_link a[longdesc=" + e + "]").parent().addClass("active_page " + h).siblings(".active_page").removeClass("active_page " + h),
            i.data(n, e),
            u.find(t.nav_info_id).html(t.nav_label_info.replace("{0}", start_from + 1).replace("{1}", start_from + f.length).replace("{2}", a.length)),
            b(),
            w()
            }
        function g(n, r) {
            var i = r,
            s = e(n).siblings(".active_page");
            s.siblings(".page_link").find("a[longdesc=" + i + "]").parent().css("display") === "none" && f.each(function() {
                e(this).find(".page_link").hide().slice(parseInt(i - t.num_page_links_to_display + 1, 10), i + 1).show()
                })
            }
        function y(n, r) {
            var i = r,
            s = e(n).siblings(".active_page");
            s.siblings(".page_link").find("a[longdesc=" + i + "]").parent().css("display") === "none" && f.each(function() {
                e(this).find(".page_link").hide().slice(i, i + parseInt(t.num_page_links_to_display, 10)).show()
                })
            }
        function b() {
            f.find(".page_link:visible").hasClass("last") ? f.find(".more").hide() : f.find(".more").show(),
            f.find(".page_link:visible").hasClass("first") ? f.find(".less").hide() : f.find(".less").show()
            }
        function w() {
            f.find(".last").hasClass("active_page") ? f.find(".next_link").add(".last_link").addClass("no_more " + p) : f.find(".next_link").add(".last_link").removeClass("no_more " + p),
            f.find(".first").hasClass("active_page") ? f.find(".previous_link").add(".first_link").addClass("no_more " + p) : f.find(".previous_link").add(".first_link").removeClass("no_more " + p)
            }
        var n = "current_page",
        r = "items_per_page",
        i,
        s = {
            item_container_id: ".content",
            items_per_page: 10,
            nav_panel_id: ".page_navigation",
            nav_info_id: ".info_text",
            num_page_links_to_display: 20,
            start_page: 0,
            wrap_around: !1,
            nav_label_first: "First",
            nav_label_prev: "Prev",
            nav_label_next: "Next",
            nav_label_last: "Last",
            nav_order: ["first", "prev", "num", "next", "last"],
            nav_label_info: "Showing {0}-{1} of {2} results",
            show_first_last: !0,
            abort_on_small_lists: !1,
            jquery_ui: !1,
            jquery_ui_active: "ui-state-highlight",
            jquery_ui_default: "ui-state-default",
            jquery_ui_disabled: "ui-state-disabled"
        },
        t = e.extend(s, t),
        o,
        u,
        a,
        f,
        l,
        c = t.jquery_ui ? t.jquery_ui_default: "",
        h = t.jquery_ui ? t.jquery_ui_active: "",
        p = t.jquery_ui ? t.jquery_ui_disabled: "";
        return this.each(function() {
            u = e(this),
            o = e(this).find(t.item_container_id),
            a = u.find(t.item_container_id).children();
            if (t.abort_on_small_lists && t.items_per_page >= a.size())
                return u;
            i = u,
            i.data(n, 0),
            i.data(r, t.items_per_page);
            var s = o.children().size(),
            p = Math.ceil(s / t.items_per_page),
            E = '<span class="ellipse more">...</span>',
            S = '<span class="ellipse less">...</span>',
            x = t.show_first_last ? '<li class="first_link ' + c + '"><a href="">' + t.nav_label_first + "</a></li>": "",
            T = t.show_first_last ? '<li class="last_link ' + c + '"><a href="">' + t.nav_label_last + "</a></li>": "",
            N = '<ul class="pagination">';
            for (var C = 0; C < t.nav_order.length; C++)
                switch (t.nav_order[C]) {
            case "first":
                N += x;
                break;
            case "last":
                N += T;
                break;
            case "next":
                N += '<li class="next_link ' + c + '"><a href="">' + t.nav_label_next + "</a></li>";
                break;
            case "prev":
                N += '<li class="previous_link ' + c + '"><a href="">' + t.nav_label_prev + "</a></li>";
                break;
            case "num":
                N += S;
                var k = 0;
                while (p > k)
                    N += '<li class="page_link ' + c + '"><a href="" longdesc="' + k + '">' + (k + 1) + "</a></li>",
                k++;
                N += E;
                break;
            default:
                }
            N += "</ul>",
            f = u.find(t.nav_panel_id),
            f.html(N).each(function() {
                e(this).find(".page_link:first").addClass("first"),
                e(this).find(".page_link:last").addClass("last")
                }),
            f.children(".ellipse").hide(),
            f.find(".previous_link").next().next().addClass("active_page " + h),
            a.hide(),
            a.slice(0, i.data(r)).show(),
            l = u.children(t.nav_panel_id + ":first").find(".page_link").size(),
            t.num_page_links_to_display = Math.min(t.num_page_links_to_display, l),
            f.find(".page_link").hide(),
            f.each(function() {
                e(this).find(".page_link").slice(0, t.num_page_links_to_display).show()
                }),
            u.find(".first_link a").click(function(t) {
                t.preventDefault(),
                y(e(this), 0),
                m(0)
                }),
            u.find(".last_link a").click(function(t) {
                t.preventDefault();
                var n = l - 1;
                g(e(this), n),
                m(n)
                }),
            u.find(".previous_link a").click(function(t) {
                t.preventDefault(),
                d(e(this).parent())
                }),
            u.find(".next_link a").click(function(t) {
                t.preventDefault(),
                v(e(this).parent())
                }),
            u.find(".page_link a").click(function(t) {
                t.preventDefault(),
                m(e(this).attr("longdesc"))
                }),
            m(parseInt(t.start_page, 10)),
            b(),
            t.wrap_around || w()
            })
        }
} (jQuery),
function(e, t) {
    if (typeof readyQ == "undefined")
        return;
    e.each(readyQ, function(t, n) {
        e(n)
        }),
    e.each(bindReadyQ, function(n, r) {
        e(t).bind("ready", r)
        })
    } (jQuery, document),
$(".related-shop a").click(function() {
    omnitureOnClickTracking("ap-shop-search-result-" + $.trim($(this).text()))
    }),
$(".l-competition a").click(function() {
    var e = $(this),
    t = e.closest(".l-competition"),
    n = $.trim(t.find("dd").eq(0).text()),
    r = $.trim(t.find("dd").eq(1).text());
    omnitureOnClickTracking("ap-campaign-landing-competition-start-date-" + n + "-end-date-" + r + "-button-" + $.trim(e.text()))
    }),
$(".skip-link").click(function(e) {
    e.preventDefault();
    var t = $(this),
    n = t.siblings(".skip-link");
    n.focus()
    }),
$(function() {
    var e = $("<div></div>");
    e.css({
        borderWidth: "1px",
        borderStyle: "solid",
        borderTopColor: "red",
        borderRightColor: "green",
        position: "absolute",
        top: "-999px"
    }),
    $.browser.msie && parseInt($.browser.version, 10) < 8 ? e.addClass("high-contrast-test") : e.css("backgroundImage", "url(data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAEBMgA7)"),
    $("body").append(e);
    var t = e.css("backgroundImage");
    $.support.highContrast = e.css("borderTopColor") == e.css("borderRightColor") || t != null && (t == "none" || t == "url(invalid-url:)"),
    $.support.highContrast && $("html").addClass("highcontrast"),
    e.remove()
    });
var AUSPOST = function(e) {
    return $(document).ready(function() {
        var e = $("#alert"),
        t,
        n;
        if (e.length === 0)
            return;
        t = e.find(".hide"),
        n = e.attr("data-alert-id"),
        (typeof localStorage == "undefined" || localStorage.getItem("hiddenAlert_" + n) !== "hidden") && setTimeout(function() {
            e.slideDown(100)
            }, 1e3),
        t.click(function(t) {
            t.preventDefault(),
            localStorage.setItem("hiddenAlert_" + n, "hidden"),
            e.slideUp(100)
            })
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return $(document).ready(function() {
        $(".mod-baynote").each(function() {
            var t = $(this),
            n = t.attr("id"),
            r;
            r = function() {
                if (n === "bn-zone1-shop")
                    t.find(".ca-item").length > 0 ? (e.ctaLink(), t.show(), e.carousel(), e.linkIcons(), t.find(".ca-item a").click(function(e) {
                    var t = $.trim($(this).closest(".ca-item").find(".bn-prod-title").text()),
                    n = "ap-recommendations-shop-carousel-" + t;
                    omnitureOnClickTracking(n)
                    })) : t.find(".bn-no-results").length === 0 && setTimeout(r, 100);
                else {
                    var i = t.find("#bn-zone2-shop li, #bn-zone2-shop .bn-no-results").length > 0,
                    s = t.find("#bn-zone2-pages li, #bn-zone2-pages .bn-no-results").length > 0; ! i && !s ? setTimeout(r, 100) : t.find("#bn-zone2-shop li, #bn-zone2-pages li").length > 0 && (e.ctaLink(), t.show(), e.linkIcons(), t.find("#bn-zone2-shop a").click(function(e) {
                        var n = $.trim(t.find("h2:eq(0)").text()),
                        r = $.trim($(this).closest("li").find(".bn-prod-title").text()),
                        i = "ap-recommendations-" + n + "-shop-product-" + r;
                        omnitureOnClickTracking(i)
                        }), t.find("#bn-zone2-pages a").click(function(e) {
                        var n = $.trim(t.find("h2:eq(0)").text()),
                        r = $.trim($(this).text()),
                        i = "ap-recommendations-" + n + "-auspost-global-" + r;
                        omnitureOnClickTracking(i)
                        }))
                    }
            },
            r()
            })
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return $.browser.msie && parseInt($.browser.version, 10) < 9 && $(document).ready(function() {
        $(".breadcrumb li:last-child").addClass("last-child")
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return e.carousel = function() {
        $(document).ready(function() {
            $(".fn-carousel").each(function() {
                var e = $(this).removeClass("fn-carousel"),
                t = e.find("> .ca-item"),
                n = e.find(".ca-controls"),
                r = n.find(".ca-previous"),
                i = n.find(".ca-next"),
                s,
                o,
                u = 0,
                a = 0,
                f;
                if (t.length < 2)
                    return;
                e.addClass("sl-hideoverflow"),
                t.each(function(e, t) {
                    var n = $(this),
                    r;
                    e === 0 ? u = n.height() : (n.addClass("sl-offscreen"), r = n.height(), r > u && (u = r), n.removeClass("sl-offscreen").hide())
                    }),
                e.removeClass("sl-hideoverflow"),
                t.css("height", u + "px"),
                f = function(e) {
                    t.hide(),
                    t.eq(a).show()
                    },
                s = function() {
                    a -= 1,
                    a < 0 && (a = t.length - 1),
                    f(a)
                    },
                o = function() {
                    a += 1,
                    a >= t.length && (a = 0),
                    f(a)
                    },
                r.find("span").mousedown(function(e) {
                    e.preventDefault(),
                    e.stopPropagation(),
                    s()
                    }).click(function(e) {
                    e.preventDefault(),
                    e.stopPropagation()
                    }),
                i.find("span").mousedown(function(e) {
                    e.preventDefault(),
                    e.stopPropagation(),
                    o()
                    }).click(function(e) {
                    e.preventDefault(),
                    e.stopPropagation()
                    }),
                r.click(function(e) {
                    e.preventDefault(),
                    s()
                    }),
                i.click(function(e) {
                    e.preventDefault(),
                    o()
                    }),
                n.show()
                })
            })
        },
    e.carousel(),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return e.ctaLink = function() {
        $(document).ready(function() {
            $(".cta-link").each(function() {
                var e = $(this),
                t,
                n;
                if (!e.hasClass("cta-link-js")) {
                    if (e.find("*").length > 0)
                        return;
                    t = $.trim(e.text()),
                    n = t.lastIndexOf(" "),
                    t = t.substr(0, n + 1) + '<span class="last-word">' + t.substr(n + 1) + "</span>",
                    e.html(t).addClass("cta-link-js")
                    }
            })
            })
        },
    e.ctaLink(),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return $(document).ready(function() {
        $(".fn-expando-collapso").each(function() {
            var e,
            t,
            n = $(this).removeClass("fn-expando-collapso"),
            r = n.find("> h3"),
            i = n.find("> .rich-text"),
            s = r.find(".ec-expand"),
            o = r.find(".ec-collapse");
            e = function() {
                i.hide(),
                n.addClass("is-expanded"),
                i.slideDown(200)
                },
            t = function() {
                n.removeClass("is-expanded"),
                i.show(),
                i.slideUp(200)
                },
            r.click(function(r) {
                n.hasClass("is-expanded") ? t() : e()
                }),
            s.click(function(t) {
                t.preventDefault(),
                t.stopPropagation(),
                e(),
                s.hide(),
                o.show().focus()
                }),
            o.click(function(e) {
                e.preventDefault(),
                e.stopPropagation(),
                t(),
                o.hide(),
                s.show().focus()
                })
            })
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    var t = "https://auspost-cx-prod.widget.custhelp.com/euf/rightnow/RightNow.Client.js",
    n = "https://auspost-cx-prod.widget.custhelp.com/ci/ws/get",
    r,
    i;
    return r = function() {
        var e = [],
        n = !1,
        r = typeof RightNow != "undefined",
        i,
        s;
        return s = function() {
            var t,
            n;
            if (typeof RightNow != "undefined") {
                r = !0;
                for (t = 0, n = e.length; t < n; t += 1)
                    e[t]()
                } else
                setTimeout(s, 250)
            },
        function(o) {
            if (r) {
                o();
                return
            }
            e.push(o),
            n || (n = !0, i = document.createElement("script"), i.src = t, $("body").append(i), s())
            }
    } (),
    i = function(t) {
        var r = t.data("rightnow-options") || {},
        i = t.closest(".rn-related-faqs, .l-faqs"),
        s;
        s = function() {
            if (t.find(".rn_List").length === 0) {
                setTimeout(s, 250);
                return
            }
            t.find(".rn_Item").length > 0 && i.show(),
            e.linkIcons(),
            t.find(".rn_Item a").click(function(e) {
                var t = $(this),
                n;
                t.parents(".right-panel").length > 0 ? n = "ap-related-faq-module-sidebar-" + $.trim(t.text()) : n = "ap-related-faq-module-body-content-" + $.trim(t.text()),
                omnitureOnClickTracking(n)
                })
            },
        RightNow.Client.Controller.addComponent(r, n),
        RightNow.Client.Controller.init(),
        s()
        },
    $(document).ready(function() {
        $(".rn_faqs").length > 0 && r(function() {});
        var e = function(e) {
            if (e.parents(".tab.hidden").length > 0 || e.data("faqsInitialised") === "initialised")
                return;
            e.data("faqsInitialised", "initialised"),
            r(function() {
                i(e)
                })
            };
        $(".rn_faqs").each(function() {
            e($(this))
            }),
        $("body").on("change.tabs.AUSPOST", function(t) {
            var n = $(t.target);
            n.find(".rn_faqs").each(function() {
                e($(this))
                })
            }),
        $(".search-faqs a").click(function() {
            omnitureOnClickTracking("ap-faq-search-result-" + $.trim($(this).text()))
            })
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return $(".input-group").each(function() {
        var e = $(this),
        t = $("> .input > :first-child", e),
        n = 0;
        t.each(function() {
            var e = $(this).height();
            e > n && (n = e)
            }),
        t.css("height", n + "px")
        }),
    $(".inline-error-symbol").each(function() {
        var e = $(this),
        t = e.parents(".input"),
        n = t.find(":input").eq(0),
        r = t.offset(),
        i = n.offset();
        e.css("top", i.top - r.top + 4 + "px"),
        t.data("has-input-error-symbol", !0)
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return $(document).ready(function() {
        $(".inline-cta").each(function() {
            var e = $(this),
            t = e.find("> a"),
            n = e.find("> p");
            e.hasClass("inline-cta-js") || (e.addClass("inline-cta-js"), t.length > 0 && n.length > 0 && n.css("padding-right", t.outerWidth(!0) + "px"))
            })
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    var t = [/auspost\.com\.au$/, /postbillpay\.com\.au$/, /fx4you\.com$/],
    n = function(e, t, n) {
        var r,
        i = ".link-icons-disabled, .searchResultsList .metadata, .toolModuleWrapper";
        if (e.filter(i).length > 0 || e.parents(i).length > 0)
            return;
        if (e.children().length === 1 && e.text() === "" && e.children("img").length === 1)
            return;
        r = e.find(".link-icon"),
        r.length === 0 && (r = $('<span class="link-icon"></span>').appendTo(e)),
        r.text(r.text() + n),
        e.addClass(t)
        };
    return e.linkIcons = function() {
        $("a:not(.link-pdf, .link-external)").each(function() {
            var e = $(this),
            r = e.attr("href");
            if (!r)
                return;
            r.substr(0, 4) === "http" && function() {
                var i,
                s,
                o,
                u;
                i = r.indexOf("/", r.indexOf("//") + 2),
                i !== -1 ? s = r.substr(0, i) : s = r;
                for (o = 0, u = t.length; o < u; o += 1)
                    if (s.match(t[o]))
                    return;
                n(e, "link-external", " (External link)")
                } (),
            r.substr(r.length - 4, 4) === ".pdf" && n(e, "link-pdf", " (PDF)")
            })
        },
    $(document).ready(function() {
        e.linkIcons()
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    function n(t) {
        var n = "",
        o,
        u = t.find("entry");
        if (u.length > 2) {
            for (o = 0; o < 3; o += 1)
                story = $(u[o]),
            n += '<li><span class="date">' + i(story.children("published").text()) + "</span>",
            n += '<a href="' + story.children("link").attr("href") + '">' + story.children("title").text() + "</a></li>";
            $(".news-feed ul").append(n),
            e.linkIcons(),
            $(".news-feed a").click(function() {
                var e = $(this),
                t;
                e.parents(".right-panel").length > 0 ? t = "ap-business-lounge-business-feed-sidebar-" + $.trim(e.text()) : t = "ap-business-lounge-business-feed-body-content-" + $.trim(e.text()),
                omnitureOnClickTracking(t)
                }),
            s()
            } else
            r()
        }
    function r() {
        var e = $("p.load-error:eq(0)").text();
        $(".news-feed ul").replaceWith('<p class="load-error-visible">' + e + "</p>"),
        s()
        }
    function i(e) {
        var t = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
        n = /^^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z/,
        r,
        i = new Date;
        return e && n.test(e) ? (r = e.match(n), i.setUTCFullYear(parseInt(r[1], 10)), i.setUTCMonth(parseInt(r[2], 10) - 1), i.setUTCDate(parseInt(r[3], 10)), i.setUTCHours(parseInt(r[4], 10), parseInt(r[5], 10), parseInt(r[6], 10)), i.getDate() + " " + t[i.getMonth()] + " " + i.getFullYear()) : e || ""
    }
    function s() {
        $(".news-feed").length > 0 && (dPos = $(".news-feed").position(), dHeight = $(".region-1").height(), $(".region-1").append('<div class="bf-divider" />'), $(".bf-divider").css({
            left: dPos.left + "px",
            top: "-7px",
            height: dHeight - 14 + "px"
        }).show())
        }
    var t = $(".news-feed").data("feedUrl");
    return t ? ($(document).ready(function() {
        $.ajax({
            url: t,
            dataType: "xml",
            success: function(e) {
                n($(e))
                },
            error: function() {
                r()
                }
        })
        }), e) : e
} (AUSPOST),
AUSPOST = function(e) {
    return $(".paged-list").length === 0 || $(".paged-list li").length <= 10 ? ($(".paged-list li").show(), e) : ($(document).ready(function() {
        $(".l-media-releases").pajinate({
            items_per_page: 10,
            nav_label_prev: "Previous",
            item_container_id: ".paged-list",
            nav_panel_id: ".pagination-holder",
            num_page_links_to_display: 10,
            show_first_last: !1
        })
        }), e)
    } (AUSPOST),
AUSPOST = function(e) {
    return $(document).ready(function() {
        $(".fn-placeholder").each(function() {
            var e = $(this).removeClass("fn-placeholder"),
            t = e.attr("id"),
            n,
            r;
            if (!t)
                return;
            n = $('label[for="' + t + '"]'),
            r = $.trim(n.text());
            if (n.length === 0 || !r)
                return;
            e.data("placeholder", r),
            e.val() || e.val(r),
            e.focus(function() {
                e.val() === r && e.val("")
                }),
            e.blur(function() {
                e.val() === "" && e.val(r)
                })
            })
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return $(document).ready(function() {
        var e = "/apps/search-autocomplete.html",
        t = {
            max: 5,
            access: "p",
            format: "os"
        },
        n = $("html").hasClass("no-csstransitions") ? 188: 248,
        r = $("#primary-nav"),
        i = $("#header-search"),
        s = $("#error-search"),
        o = $('#inlineSearch input[type="text"]');
        $(".search-field").each(function() {
            var e = $(this),
            t = e.find('input[type="text"]'),
            n = e.find("#header-search").length > 0;
            t.focus(function() {
                n && r.addClass("is-compressed"),
                e.addClass("is-focused")
                }).blur(function() {
                n && r.removeClass("is-compressed"),
                e.removeClass("is-focused")
                })
            }),
        $.fn.autocompleteSearch && (o && o.autocompleteSearch({
            serviceUrl: e,
            params: t,
            extraWidth: 38,
            topMargin: 13,
            onSelect: function() {
                o.closest("form").submit()
                }
        }), s && s.autocompleteSearch({
            serviceUrl: e,
            params: t,
            extraWidth: 38,
            topMargin: 13,
            onSelect: function() {
                s.closest("form").submit()
                }
        }), i.autocompleteSearch({
            serviceUrl: e,
            params: t,
            width: n,
            leftMargin: -61,
            extraWidth: 2,
            topMargin: 11,
            onSelect: function() {
                i.closest("form").submit()
                }
        })),
        $(".featured-results a").click(function() {
            omnitureOnClickTracking("ap-featured-search-result-" + $.trim($(this).text()))
            })
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    var t = 6e3,
    n = 500;
    return e.slideshow = function() {
        $(document).ready(function() {
            $(".fn-slideshow").each(function() {
                var e = $(this).removeClass("fn-slideshow"),
                r = e.find("> .sl-item"),
                i = e.data("slideshow-settings") || {},
                s,
                o,
                u = 0,
                a = !1,
                f = !1,
                l,
                c;
                if (r.length < 2)
                    return;
                e.addClass("sl-hideoverflow"),
                r.not(r.eq(0)).addClass("sl-offscreen").show(),
                setTimeout(function() {
                    r.filter(".sl-offscreen").removeClass("sl-offscreen").hide(),
                    e.removeClass("sl-hideoverflow")
                    }, 100),
                function() {
                    var t = $('<div class="sl-l-progress"></div>'),
                    n = $('<ol class="sl-progress"></ol>');
                    i.controlsLabel && t.append('<p class="visuallyhidden">' + i.controlsLabel + "</p>"),
                    r.each(function(e, t) {
                        var r = $('<a href="#"></a>'),
                        s;
                        i.controlLabel && (s = $("<span>" + i.controlLabel.replace("#", e + 1) + "</span>"), r.append(s)),
                        e === 0 && r.addClass("sl-current"),
                        n.append($("<li></li>").append(r))
                        }),
                    t.append(n),
                    e.append(t),
                    s = e.find(".sl-progress a")
                    } (),
                l = function(e) {
                    clearTimeout(c),
                    a = !0,
                    typeof e != "number" && (e = u += 1, e >= r.length && (e = 0));
                    var i = s.eq(e),
                    o = r.eq(e);
                    s.removeClass("sl-current"),
                    i.addClass("sl-current"),
                    o.hide().removeClass("sl-offscreen").css({
                        zIndex: "3"
                    }).fadeIn(n, function() {
                        $.browser.msie && parseInt($.browser.version, 10) < 9 && this.style.removeAttribute("filter"),
                        r.not(o).hide(),
                        o.css({
                            zIndex: "2"
                        }),
                        a = !1,
                        u = e,
                        f || (c = setTimeout(l, t))
                        })
                    },
                o = function(e) {
                    f = !0,
                    clearTimeout(c);
                    if (a || e.hasClass("sl-current"))
                        return;
                    l(e.parent().index())
                    },
                s.find("span").mousedown(function(e) {
                    e.preventDefault(),
                    e.stopPropagation(),
                    o($(this).parent())
                    }).click(function(e) {
                    e.preventDefault(),
                    e.stopPropagation()
                    }),
                s.click(function(e) {
                    e.preventDefault(),
                    o($(this))
                    }),
                e.hover(function(e) {
                    clearTimeout(c)
                    }, function() {
                    f || (c = setTimeout(l, t))
                    }),
                e.focusin(function() {
                    clearTimeout(c)
                    }).focusout(function() {
                    f || (c = setTimeout(l, t))
                    }),
                c = setTimeout(l, t)
                })
            })
        },
    e.slideshow(),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return e.tables = function() {
        $(".rich-text table > thead:empty").remove(),
        $.browser.msie && parseInt($.browser.version, 10) < 9 && $("table:not(.tables-js)").each(function() {
            var e = $(this);
            e.find("tr:nth-child(odd)").addClass("nth-child-odd"),
            e.find("tr:nth-child(even)").addClass("nth-child-even")
            })
        },
    $(document).ready(function() {
        e.tables()
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    if ($(".fn_tabs").length === 0 || $(".lt-ie8").length > 0)
        return e;
    var t = 200,
    n = 200,
    r = 60,
    i = $(".lt-ie9").length > 0;
    return $(".fn_tabs").each(function() {
        var e = $(this),
        s = e.data("tabs-settings") || {};
        e.removeClass("fn_tabs").prepend('<div class="nav-container"><ul class="nav ' + (s.direction || "horizontal") + ' clearfix" role="navigation"></ul></div>'),
        s.footerLinks && e.append('<ul class="tabs-back-next"></ul>'),
        !e.is(".tabs-is-solid") && !e.is(".tabs-vertical") && e.addClass("tabs-is-white");
        var o = e.find(".nav"),
        u = null,
        a = !1,
        f;
        s.footerLinks && (f = e.find(".tabs-back-next"));
        var l = function(e) {
            f.find("li").attr("class", "is-disabled");
            var t = $("div.tab" + e).next().attr("id"),
            n = $("div.tab" + e).prev().attr("id");
            t && f.find("a[href=#" + t + "]").parent().removeClass("is-disabled").addClass("bn-next"),
            n && f.find("a[href=#" + n + "]").parent().removeClass("is-disabled").addClass("bn-back")
            },
        c = function(e, t) {
            s.footerLinks && (i ? (f.hide(), l(e)) : f.fadeOut(n, function() {
                l(e)
                })),
            u === null ? t() : e != u.id ? ($(u.listItem).removeClass("active"), i ? ($(u.tab).addClass("hidden"), t()) : $(u.tab).stop().animate({
                opacity: 0
            }, n, function() {
                $(u.tab).addClass("hidden"),
                t()
                })) : a = !1
        },
        h = function() {
            var n = e.data("maxHeight") + o.height() + r;
            o.find("li").each(function(n) {
                var r = $(this),
                o = r.find("a"),
                l = o.attr("href"),
                h;
                l = l.substring(l.indexOf("#"), l.length),
                h = function() {
                    if (a === !1) {
                        a = !0;
                        var e = function() {
                            a = !1,
                            u = {
                                id: l,
                                tab: $(l),
                                listItem: r
                            },
                            $(l).trigger("change.tabs.AUSPOST")
                            };
                        r.addClass("active"),
                        i ? c(l, function() {
                            $(l).removeClass("hidden"),
                            e(),
                            s.footerLinks && f.show()
                            }) : c(l, function() {
                            $(l).stop().removeClass("hidden").animate({
                                opacity: 1
                            }, t, function() {
                                e()
                                }),
                            s.footerLinks && f.fadeIn(t)
                            })
                        }
                },
                o.find("span").mousedown(function(e) {
                    e.preventDefault(),
                    e.stopPropagation(),
                    h()
                    }).click(function(e) {
                    e.preventDefault(),
                    e.stopPropagation()
                    }),
                o.click(function(e) {
                    e.preventDefault(),
                    h()
                    });
                if (e.find(".tab.active").length > 0 && $(l).hasClass("active") || e.find(".tab.active").length === 0 && n === 0)
                    u = {
                    id: l,
                    tab: $(l),
                    listItem: r
                },
                r.addClass("active")
                })
            };
        e.data("maxHeight", 0);
        var p = e.find(".tab").length;
        e.find(".tab.reddot-hover-active, .tab .reddot-hover-active").eq(0).closest(".tab").addClass("active"),
        e.find(".tab.active").length === 0 && window.location.hash && (e.find(".tab" + window.location.hash).addClass("active"), $("html, body").animate({
            scrollTop: e.offset().top
        }, 150)),
        e.find(".tab").each(function(t) {
            var n = $(this),
            r = n.attr("id"),
            u = n.find(".tab-name").length > 0,
            a = n.find(".tab-name").remove().text() || n.find("> h2, > h3").eq(0).text(),
            l = e.find(".tab.active").length > 0,
            c = l && n.hasClass("active") || !l && t === 0 ? !0: !1,
            d = $("<li><a href='#" + r + "'><span>" + a + "</span></a></li>");
            if (e.hasClass("tabs-is-solid") || e.hasClass("tabs-is-white"))
                p === 4 || p === 1 ? d.css("width", "25%") : d.css("width", Math.floor(e.width() / p)); ! u && !s.headingVisible && n.find("> h2, > h3").eq(0).addClass("visuallyhidden"),
            o.append(d),
            s.footerLinks && f.append('<li class="is-disabled"><a href="#' + r + '">' + a + "</a></li>"),
            n.data("tabTitle", a);
            var v = n.height();
            n.data("tabHeight", v),
            v > e.data("maxHeight") && e.data("maxHeight", v),
            c || (n.addClass("hidden"), i || n.animate({
                opacity: 0
            }, 0)),
            t == p - 1 && (h(), o.find("li:first-child").addClass("first-child"), o.find("li:last-child").addClass("last-child"))
            });
        var d = e.find("> .tabs");
        e.hasClass("tabs-vertical") && d.css("min-height", o.height()),
        e.hasClass("tabs-is-white") && o.find("> li a span").css("min-height", o.height() - 24),
        s.footerLinks && (l(u.id), f.find("a").click(function() {
            var t = $(this).attr("href");
            return $(".nav a[href=" + t + "] span").mousedown(),
            $("html, body").animate({
                scrollTop: e.offset().top
            }, 150),
            !1
        }))
        }),
    $(".tabs-is-solid .primary-cta, .tabs-is-solid .secondary-cta").click(function() {
        var e = $(this),
        t = e.closest(".tab"),
        n = "ap-tab-" + t.data("tabTitle") + "-cta-button-" + $.trim(e.text());
        omnitureOnClickTracking(n)
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return $(document).ready(function() {
        var e = $("#tracking-number"),
        t = e.parent();
        e.focus(function() {
            t.addClass("is-focused")
            }).blur(function() {
            t.removeClass("is-focused")
            })
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return $(document).ready(function() {
        $(".fn-validation").each(function() {
            var e = $(this).removeClass("fn-validation"),
            t = e.parents(".promotions-offers").length > 0,
            n;
            $(".input", e).each(function() {
                var e = $(this),
                t = e.data("validation") || {};
                t.required = $(".error-message", e).text(),
                e.data("validation", t)
                }),
            n = function(e, t) {
                var n = $("input, select, textarea", e),
                r = e.data("validation") || {},
                i = n.val(),
                s;
                e.removeClass("has-error"),
                n.is('[type="radio"], [type="checkbox"]') && (i = n.filter(":checked").val()),
                s = function(n) {
                    var i,
                    s = e.find(".error-message"),
                    o;
                    t && t.preventDefault(),
                    e.data("has-input-error-symbol") || function() {
                        var t = e.find(".inline-error-symbol"),
                        n = e.find(":input").eq(0),
                        r = e.offset(),
                        i = n.offset();
                        t.length === 0 && (t = $("<div />").addClass("inline-error-symbol").appendTo(e)),
                        t.css("top", i.top - r.top + 4 + "px"),
                        e.data("has-input-error-symbol", !0)
                        } (),
                    i = function(e) {
                        return typeof e == "string" ? e: typeof e == "object" && e.message ? e.message: null
                    },
                    s.length > 0 && (o = i(r[n]) || r.required || "", s.text(o)),
                    e.addClass("has-error")
                    };
                if (e.is(".required"))
                    if (typeof i == "undefined" || i === "" || n.data("placeholder") && i === n.data("placeholder").toString())
                    return s("	");
                if ((n.is('[type="email"]') || n.is(".email-textbox")) && !i.match(/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i))
                    return s("email");
                if (r.numbersAndSymbols && !i.match(/^[0-9\(\)\s\+-]+$/i))
                    return s("numbersAndSymbols");
                if (r.numeric && !i.match(/^[0-9]+$/i))
                    return s("numeric");
                if (r.length && i.length !== r.length.length)
                    return s("length")
                },
            e.submit(function(r) {
                var i = $(".input", e),
                s,
                o = $(".form-errors", e).hide(),
                u = o.find("ul").empty();
                i.each(function() {
                    n($(this), r)
                    }),
                o.length === 0 && (o = $('<div class="form-errors hidden"><h3>The following errors have occurred:</h3><ul></ul></div>'), u = o.find("ul"), e.prepend(o)),
                i.filter(".has-error-invalidated").each(function() {
                    var e = $(this),
                    t = $('<a href="#">' + $(this).find(".error-message").html() + "</a>");
                    t.click(function(t) {
                        t.preventDefault(),
                        $("body,html").animate({
                            scrollTop: e.offset().top
                        }, 500, function() {
                            e.find(":input").focus()
                            })
                        }),
                    u.append($("<li></li>").append(t))
                    }),
                i.filter(".has-error").length > 0 && (t ? i.filter(".has-error").eq(0).find(":input").eq(0).focus() : (o.removeClass("hidden").show().focus(), $("body,html").animate({
                    scrollTop: o.offset().top
                }, 500, function() {
                    o.find("a:eq(0)").focus()
                    })))
                })
            })
        }),
    e
} (AUSPOST),
AUSPOST = function(e) {
    return $(document).ready(function() {
        $(".video-player").each(function() {
            function o(t, r, i, o) {
                $("> div, .vp-wrapper, object", e).remove(),
                $(".screenreader-link", e).after('<div id="' + n.HTMLid + '" class="vp-wrapper"></div>'),
                s ? swfobject.embedSWF(n.path, n.HTMLid, n.width, n.height, "9", null, o, n.params, null) : $(".vp-wrapper", e).html('<iframe class="youtube-player" type="text/html" width="' + n.width + '" height="' + n.height + '" src="http://www.youtube.com/embed/' + i + '" frameborder="0" title="Video player"> </iframe>'),
                t.hide(),
                r.show(),
                $(".vp-wrapper", e).focus()
                }
            var e = $(this),
            t = e.find(".vp-wrapper, object").attr("id"),
            n = APvid[t],
            r = e.find(".audio-video"),
            i = e.find(".original-video"),
            s = e.find("iframe").length === 0;
            r.click(function(e) {
                e.preventDefault(),
                o(r, i, n.audio.videoid, n.audioFlashvars)
                }),
            i.click(function(e) {
                e.preventDefault(),
                o(i, r, n.videoid, n.originalFlashvars)
                })
            })
        }),
    e
} (AUSPOST);