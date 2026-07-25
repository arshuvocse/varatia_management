$(function () {
  $(".nav-toggle").on("click", function () {
    const $button = $(this);
    const expanded = $button.attr("aria-expanded") === "true";

    $button.attr("aria-expanded", !expanded);
    $(".nav-links").toggleClass("is-open");
  });

  $(".nav-links a").on("click", function () {
    $(".nav-links").removeClass("is-open");
    $(".nav-toggle").attr("aria-expanded", "false");
  });

  $(".service-card").on("mouseenter focusin", function () {
    $(".service-card").removeClass("active");
    $(this).addClass("active");
  });

  $(".lead-form").on("submit", function (event) {
    event.preventDefault();

    const name = $.trim($(this).find("[name='name']").val());
    const service = $(this).find("[name='service']").val();

    $(".form-message").text(`${name || "আপনার"} ${service} রিকোয়েস্ট গ্রহণ করা হয়েছে।`);
    this.reset();
  });

  $(".chat-launcher").on("click", function () {
    const isOpen = $(".live-chat").toggleClass("is-open").hasClass("is-open");
    $(this).attr("aria-expanded", isOpen);
  });

  $(".chat-close").on("click", function () {
    $(".live-chat").removeClass("is-open");
    $(".chat-launcher").attr("aria-expanded", "false");
  });

  $(".chat-quick button").on("click", function () {
    $(".chat-form input").val($(this).text()).trigger("focus");
  });

  $(".chat-form").on("submit", function (event) {
    event.preventDefault();

    const $input = $(this).find("input");
    const message = $.trim($input.val());

    if (!message) return;

    addChatMessage(message, "user");
    $input.val("");

    setTimeout(function () {
      addChatMessage("ধন্যবাদ। আমাদের সাপোর্ট টিম আপনার মেসেজ পেয়েছে। দ্রুত যোগাযোগ করা হবে।", "support");
    }, 600);
  });

  function addChatMessage(message, type) {
    const $bubble = $("<div>", {
      class: `chat-bubble ${type}`,
      text: message
    });

    $(".chat-messages").append($bubble);
    $(".chat-messages").scrollTop($(".chat-messages")[0].scrollHeight);
  }
});
