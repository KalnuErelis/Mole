const copyButtons = document.querySelectorAll("[data-copy]");
const scrollButtons = document.querySelectorAll("[data-scroll]");

const setButtonState = (button, message) => {
  const original = button.textContent;
  button.textContent = message;
  button.disabled = true;
  setTimeout(() => {
    button.textContent = original;
    button.disabled = false;
  }, 1400);
};

copyButtons.forEach((button) => {
  button.addEventListener("click", async () => {
    const value = button.getAttribute("data-copy");
    if (!value) return;
    try {
      await navigator.clipboard.writeText(value);
      setButtonState(button, "Copied");
    } catch (error) {
      setButtonState(button, "Select & copy");
    }
  });
});

scrollButtons.forEach((button) => {
  button.addEventListener("click", () => {
    const target = button.getAttribute("data-scroll");
    if (!target) return;
    const section = document.querySelector(target);
    if (!section) return;
    section.scrollIntoView({ behavior: "smooth", block: "start" });
  });
});
