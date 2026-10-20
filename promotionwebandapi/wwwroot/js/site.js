document.querySelectorAll(".nav-toggle").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelector(".nav-links")?.classList.toggle("is-open");
  });
});

/**
 * Shared submit-button loading helper, reused across the app instead of every
 * page hand-rolling its own disable/spinner/text-swap logic.
 * Pages that already manage their own AJAX loading state (e.g. Customer/Shopkeeper
 * ChangePassword) should mark their <form> with data-managed-loading="true" so the
 * global auto-handler below leaves them alone.
 */
window.setButtonLoading = function setButtonLoading(button, isLoading, loadingText) {
  if (!button) return;
  if (isLoading) {
    if (button.dataset.originalHtml === undefined) {
      button.dataset.originalHtml = button.innerHTML;
    }
    button.disabled = true;
    button.classList.add("btn-loading");
    var text = loadingText || button.getAttribute("data-loading-text") || "প্রসেস হচ্ছে...";
    button.innerHTML = '<span class="btn-spinner" aria-hidden="true"></span>' + text;
  } else {
    button.disabled = false;
    button.classList.remove("btn-loading");
    if (button.dataset.originalHtml !== undefined) {
      button.innerHTML = button.dataset.originalHtml;
    }
  }
};

// Auto-apply loading state to every plain (non-AJAX-managed) form submit in the app,
// so registrations/edits/deletes/approvals etc. all get disable+spinner feedback and
// duplicate-submission protection without each page having to wire it up individually.
document.addEventListener(
  "submit",
  function (event) {
    var form = event.target;
    if (!(form instanceof HTMLFormElement)) return;
    if (form.hasAttribute("data-managed-loading")) return;

    var submitter =
      event.submitter ||
      form.querySelector('button[type="submit"]:not([disabled]), input[type="submit"]:not([disabled])');
    if (!submitter || submitter.disabled) return;

    window.setButtonLoading(submitter, true);
  },
  true
);
