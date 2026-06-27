const menuButton = document.querySelector(".menu-toggle");
const navigation = document.querySelector(".main-nav");
const navigationLinks = document.querySelectorAll(".main-nav a");
const hashLinks = document.querySelectorAll('a[href^="#"]');
const yearElement = document.querySelector("#current-year");
const siteHeader = document.querySelector(".site-header");
const navigationSections = [...navigationLinks]
  .map((link) => document.querySelector(link.getAttribute("href")))
  .filter(Boolean);

function getHeaderOffset() {
  return siteHeader.offsetHeight + 16;
}

function setActiveNavigation(sectionId) {
  navigationLinks.forEach((link) => {
    const isActive = link.getAttribute("href") === `#${sectionId}`;

    if (isActive) {
      link.setAttribute("aria-current", "page");
    } else {
      link.removeAttribute("aria-current");
    }
  });
}

function updateActiveNavigation() {
  const activationPoint = window.scrollY + getHeaderOffset() + 80;
  let activeSection = navigationSections[0];

  navigationSections.forEach((section) => {
    if (section.offsetTop <= activationPoint) {
      activeSection = section;
    }
  });

  if (window.innerHeight + window.scrollY >= document.body.scrollHeight - 2) {
    activeSection = navigationSections[navigationSections.length - 1];
  }

  setActiveNavigation(activeSection.id);
}

function scrollToSection(section) {
  const prefersReducedMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)"
  ).matches;
  const targetTop =
    section.id === "nachalo"
      ? 0
      : window.scrollY + section.getBoundingClientRect().top - getHeaderOffset();

  window.scrollTo({
    top: Math.max(targetTop, 0),
    behavior: prefersReducedMotion ? "auto" : "smooth",
  });
}

function closeMenu() {
  menuButton.setAttribute("aria-expanded", "false");
  menuButton.setAttribute("aria-label", "Отвори навигацията");
  navigation.classList.remove("is-open");
  document.body.classList.remove("menu-open");
}

menuButton.addEventListener("click", () => {
  const isOpen = menuButton.getAttribute("aria-expanded") === "true";

  menuButton.setAttribute("aria-expanded", String(!isOpen));
  menuButton.setAttribute(
    "aria-label",
    isOpen ? "Отвори навигацията" : "Затвори навигацията"
  );
  navigation.classList.toggle("is-open", !isOpen);
  document.body.classList.toggle("menu-open", !isOpen);
});

hashLinks.forEach((link) => {
  link.addEventListener("click", (event) => {
    const targetSection = document.querySelector(link.getAttribute("href"));

    if (!targetSection) {
      return;
    }

    event.preventDefault();
    setActiveNavigation(targetSection.id);
    scrollToSection(targetSection);
    history.pushState(null, "", link.getAttribute("href"));

    if (navigation.classList.contains("is-open")) {
      closeMenu();
    }
  });
});

window.addEventListener("resize", () => {
  if (window.innerWidth > 900) {
    closeMenu();
  }

  updateActiveNavigation();
});

window.addEventListener("scroll", updateActiveNavigation, { passive: true });

updateActiveNavigation();
yearElement.textContent = new Date().getFullYear();
