(function () {
  "use strict";

  var SUPPORTED = ["en", "tr", "de", "fr", "es", "it", "pt", "ja", "zh-Hans", "ar"];
  var DEFAULT_LANG = "en";
  var STORAGE_KEY = "budgetmeter-legal-lang";

  var body = document.body;
  var page = body.getAttribute("data-legal-page");
  var assetBase = body.getAttribute("data-asset-base") || "assets";

  function normalizeLang(code) {
    if (!code) return DEFAULT_LANG;
    var c = code.trim();
    if (SUPPORTED.indexOf(c) >= 0) return c;
    if (c.toLowerCase().indexOf("zh") === 0) return "zh-Hans";
    var short = c.split("-")[0];
    if (SUPPORTED.indexOf(short) >= 0) return short;
    return DEFAULT_LANG;
  }

  function getLang() {
    var params = new URLSearchParams(window.location.search);
    if (params.get("lang")) return normalizeLang(params.get("lang"));
    try {
      var saved = localStorage.getItem(STORAGE_KEY);
      if (saved) return normalizeLang(saved);
    } catch (e) { /* ignore */ }
    if (navigator.language) return normalizeLang(navigator.language);
    return DEFAULT_LANG;
  }

  function setLang(lang) {
    try { localStorage.setItem(STORAGE_KEY, lang); } catch (e) { /* ignore */ }
  }

  function fetchJSON(path) {
    return fetch(path).then(function (r) {
      if (!r.ok) throw new Error("Failed to load " + path);
      return r.json();
    });
  }

  function pickLocale(bundle, lang) {
    if (bundle[lang]) return bundle[lang];
    if (lang !== DEFAULT_LANG && bundle[DEFAULT_LANG]) return bundle[DEFAULT_LANG];
    var keys = Object.keys(bundle);
    return keys.length ? bundle[keys[0]] : null;
  }

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function renderSections(container, sections) {
    (sections || []).forEach(function (section) {
      if (section.heading) container.appendChild(el("h2", null, section.heading));
      (section.paragraphs || []).forEach(function (p) {
        var para = el("p");
        para.innerHTML = p;
        container.appendChild(para);
      });
      if (section.list && section.list.length) {
        var ul = el("ul");
        section.list.forEach(function (item) {
          var li = el("li");
          li.innerHTML = item;
          ul.appendChild(li);
        });
        container.appendChild(ul);
      }
    });
  }

  function buildHeader(common, lang, labels) {
    var header = document.getElementById("site-header");
    if (!header) return;

    var brand = el("a", "brand");
    brand.href = labels.homeHref || "../";
    brand.innerHTML = 'Budget<span>Meter</span>';

    var wrap = el("div", "lang-wrap");
    var btn = el("button", "lang-btn");
    btn.type = "button";
    btn.setAttribute("aria-haspopup", "listbox");
    btn.setAttribute("aria-expanded", "false");
    btn.innerHTML = "🌐 " + (common.languageNames[lang] || lang);

    var menu = el("ul", "lang-menu");
    menu.setAttribute("role", "listbox");

    SUPPORTED.forEach(function (code) {
      var item = el("li");
      var b = el("button");
      b.type = "button";
      b.textContent = common.languageNames[code] || code;
      if (code === lang) b.setAttribute("aria-current", "true");
      b.addEventListener("click", function () {
        setLang(code);
        var url = new URL(window.location.href);
        url.searchParams.set("lang", code);
        window.location.href = url.toString();
      });
      item.appendChild(b);
      menu.appendChild(item);
    });

    btn.addEventListener("click", function () {
      var open = menu.classList.toggle("open");
      btn.setAttribute("aria-expanded", open ? "true" : "false");
    });

    document.addEventListener("click", function (e) {
      if (!wrap.contains(e.target)) {
        menu.classList.remove("open");
        btn.setAttribute("aria-expanded", "false");
      }
    });

    wrap.appendChild(btn);
    wrap.appendChild(menu);

    var actions = el("div", "header-actions");
    actions.appendChild(wrap);

    header.innerHTML = "";
    header.appendChild(brand);
    header.appendChild(actions);
  }

  function buildFooter(common, lang) {
    var footer = document.getElementById("site-footer");
    if (!footer || !common.footer) return;
    var f = pickLocale(common.footer, lang);
    if (!f) return;
    footer.innerHTML = "<p>" + f.text + "</p>";
  }

  function renderHub(common, hub, lang) {
    var data = pickLocale(hub, lang);
    var main = document.getElementById("legal-content");
    if (!main || !data) return;

    document.title = data.title + " — BudgetMeter";

    var card = el("div", "card");
    card.appendChild(el("h1", null, data.title));
    if (data.intro) card.appendChild(el("p", null, data.intro));

    var list = el("ul", "nav-list");
    (data.links || []).forEach(function (link) {
      var li = el("li");
      var a = el("a");
      a.href = link.href;
      a.textContent = link.label;
      li.appendChild(a);
      list.appendChild(li);
    });
    card.appendChild(list);
    main.appendChild(card);
  }

  function renderPage(common, content, lang) {
    var data = pickLocale(content, lang);
    var main = document.getElementById("legal-content");
    if (!main || !data) return;

    document.title = data.title + " — BudgetMeter";
    document.documentElement.lang = lang === "zh-Hans" ? "zh-Hans" : lang.split("-")[0];
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";

    var card = el("div", "card");
    card.appendChild(el("h1", null, data.title));
    if (data.lastUpdated) {
      card.appendChild(el("p", "last-updated", data.lastUpdated));
    }
    renderSections(card, data.sections);
    main.innerHTML = "";
    main.appendChild(card);
  }

  var lang = getLang();
  setLang(lang);

  var labels = {
    homeHref: body.getAttribute("data-home-href") || "../"
  };

  Promise.all([
    fetchJSON(assetBase + "/i18n/common.json"),
    page === "index"
      ? fetchJSON(assetBase + "/i18n/index.json")
      : fetchJSON(assetBase + "/i18n/" + page + ".json")
  ])
    .then(function (results) {
      var common = results[0];
      var content = results[1];
      buildHeader(common, lang, labels);
      buildFooter(common, lang);
      if (page === "index") renderHub(common, content, lang);
      else renderPage(common, content, lang);
    })
    .catch(function (err) {
      console.error(err);
      var main = document.getElementById("legal-content");
      if (main) {
        main.innerHTML = "<div class=\"card\"><h1>Error</h1><p>Could not load legal content. Please try again later.</p></div>";
      }
    });
})();
