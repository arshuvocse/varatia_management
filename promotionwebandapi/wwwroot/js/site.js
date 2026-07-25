document.querySelectorAll(".nav-toggle").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelector(".nav-links")?.classList.toggle("is-open");
  });
});
