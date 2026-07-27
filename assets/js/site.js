/* meshkov.page — rail drawer, home filmstrip, series view toggle. */

(function () {
  "use strict";

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---------------------------------------------------------------
     Rail drawer (below 1024px the rail is hidden behind the top bar)
     --------------------------------------------------------------- */

  function initRail() {
    var toggle = document.querySelector("[data-rail-toggle]");
    var rail = document.getElementById("rail");
    if (!toggle || !rail) return;

    function setOpen(open) {
      rail.classList.toggle("is-open", open);
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
      toggle.textContent = open ? "Close" : "Menu";
      document.body.style.overflow = open ? "hidden" : "";
    }

    toggle.addEventListener("click", function () {
      setOpen(!rail.classList.contains("is-open"));
    });

    rail.addEventListener("click", function (e) {
      if (e.target.closest("a")) setOpen(false);
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && rail.classList.contains("is-open")) {
        setOpen(false);
        toggle.focus();
      }
    });
  }

  /* ---------------------------------------------------------------
     Home — featured frames crossfade, driven by the filmstrip
     --------------------------------------------------------------- */

  function initHome() {
    var home = document.querySelector("[data-home]");
    if (!home) return;

    var frames = Array.prototype.slice.call(home.querySelectorAll(".frame"));
    var thumbs = Array.prototype.slice.call(home.querySelectorAll(".strip__item"));
    if (frames.length === 0) return;

    var current = 0;
    var timer = null;

    /* A portrait photograph gets the side panel, a landscape one goes full
       bleed. Measured from the file itself so the data stays free of it. */
    function classify(frame) {
      var img = frame.querySelector(".frame__img");
      if (!img) return;
      var apply = function () {
        if (!img.naturalWidth || !img.naturalHeight) return;
        frame.classList.add(
          img.naturalWidth >= img.naturalHeight ? "is-landscape" : "is-portrait"
        );
      };
      if (img.complete) apply();
      else img.addEventListener("load", apply, { once: true });
    }

    frames.forEach(classify);

    function show(index) {
      var next = ((index % frames.length) + frames.length) % frames.length;
      frames[current].classList.remove("is-active");
      frames[current].setAttribute("aria-hidden", "true");
      current = next;
      frames[current].classList.add("is-active");
      frames[current].removeAttribute("aria-hidden");

      thumbs.forEach(function (thumb, i) {
        if (i === current) {
          thumb.setAttribute("aria-current", "true");
          thumb.scrollIntoView({
            behavior: reduceMotion ? "auto" : "smooth",
            block: "nearest",
            inline: "nearest",
          });
        } else {
          thumb.removeAttribute("aria-current");
        }
      });
    }

    function start() {
      if (reduceMotion || frames.length < 2) return;
      stop();
      timer = window.setInterval(function () {
        show(current + 1);
      }, 7000);
    }

    function stop() {
      if (timer !== null) {
        window.clearInterval(timer);
        timer = null;
      }
    }

    thumbs.forEach(function (thumb, i) {
      thumb.addEventListener("click", function () {
        show(i);
        start();
      });
    });

    document.addEventListener("keydown", function (e) {
      if (e.target.closest("input, textarea, select")) return;
      if (e.key === "ArrowLeft") {
        show(current - 1);
        start();
      } else if (e.key === "ArrowRight") {
        show(current + 1);
        start();
      }
    });

    home.addEventListener("mouseenter", stop);
    home.addEventListener("mouseleave", start);
    home.addEventListener("focusin", stop);

    document.addEventListener("visibilitychange", function () {
      if (document.hidden) stop();
      else start();
    });

    show(0);
    start();
  }

  /* ---------------------------------------------------------------
     Series — grid / full-frame toggle
     --------------------------------------------------------------- */

  function initSeriesView() {
    var view = document.querySelector("[data-series-view]");
    if (!view) return;

    var buttons = Array.prototype.slice.call(view.querySelectorAll("[data-view-set]"));

    buttons.forEach(function (button) {
      button.addEventListener("click", function () {
        var mode = button.getAttribute("data-view-set");
        view.setAttribute("data-view", mode);
        buttons.forEach(function (other) {
          var on = other === button;
          other.setAttribute("aria-pressed", on ? "true" : "false");
          other.classList.toggle("btn--on", on);
        });
      });
    });
  }

  function init() {
    initRail();
    initHome();
    initSeriesView();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
