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

  // --- Top Performers Logic ---
  
  function loadDistricts() {
    $.get('/api/top-performers/districts')
      .done(function(districts) {
        const $select = $('#districtSelect');
        districts.forEach(function(district) {
          $select.append($('<option>', { value: district, text: district }));
        });
      })
      .fail(function(err) {
        console.error('Failed to load districts:', err);
      });
  }

  function loadTopPerformers(district) {
    if (!district) {
      $('#topBuyersList, #topSellersList').empty();
      return;
    }

    // Load top buyers
    $.get('/api/top-performers/buyers/' + encodeURIComponent(district))
      .done(function(buyers) {
        const $list = $('#topBuyersList');
        $list.empty();
        if (buyers && buyers.length > 0) {
          buyers.forEach(function(b, idx) {
            let rank = (idx < 3) ? ['🥇', '🥈', '🥉'][idx] : (idx + 1) + '.';
            $list.append(`<li><strong style="color:var(--primary); font-size: 1.2rem;">${rank}</strong> ${b.name} <small style="opacity:0.7">(${b.totalAmount} ৳)</small></li>`);
          });
        } else {
          $list.append('<li>কোন তথ্য পাওয়া যায়নি</li>');
        }
      });

    // Load top sellers
    $.get('/api/top-performers/sellers/' + encodeURIComponent(district))
      .done(function(sellers) {
        const $list = $('#topSellersList');
        $list.empty();
        if (sellers && sellers.length > 0) {
          sellers.forEach(function(s, idx) {
            let rank = (idx < 3) ? ['🥇', '🥈', '🥉'][idx] : (idx + 1) + '.';
            $list.append(`<li><strong style="color:var(--primary); font-size: 1.2rem;">${rank}</strong> ${s.name} <small style="opacity:0.7">(${s.totalAmount} ৳)</small></li>`);
          });
        } else {
          $list.append('<li>কোন তথ্য পাওয়া যায়নি</li>');
        }
      });
  }

  $('#districtSelect').on('change', function() {
    loadTopPerformers($(this).val());
  });

  // Initialize
  if ($('#districtSelect').length > 0) {
    loadDistricts();
  }

  // --- Bulletins Logic ---
  const $marquee = $('#bulletinMarquee');
  if ($marquee.length > 0) {
    $.get('/Home/Bulletins')
      .done(function(bulletins) {
        if (bulletins && bulletins.length > 0) {
          let html = '';
          bulletins.forEach(function(b) {
            html += `<span style="margin-right: 50px;">🌟 ${b.message} `;
            if (b.linkUrl) {
              html += `<a href="${b.linkUrl}" target="_blank" style="color: #ffeb3b; text-decoration: underline;">বিস্তারিত</a>`;
            }
            html += `</span>`;
          });
          $marquee.html(html);
        } else {
          $marquee.closest('.bulletin-banner').hide();
        }
      })
      .fail(function() {
        $marquee.closest('.bulletin-banner').hide();
      });
  }
});
