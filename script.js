const menuButton = document.querySelector(".menu-toggle");
const navigation = document.querySelector(".main-nav");
const navigationLinks = document.querySelectorAll(".main-nav a");
const hashLinks = document.querySelectorAll('a[href^="#"]');
const yearElement = document.querySelector("#current-year");
const siteHeader = document.querySelector(".site-header");
const gallerySection = document.querySelector("#galeriya");
const galleryOverview = document.querySelector("[data-gallery-overview]");
const galleryAlbumsContainer = document.querySelector("[data-gallery-albums]");
const galleryDetail = document.querySelector("[data-gallery-detail]");
const galleryBackButton = document.querySelector("[data-gallery-back]");
const galleryTitle = document.querySelector("[data-gallery-title]");
const gallerySubtitle = document.querySelector("[data-gallery-subtitle]");
const galleryImagesContainer = document.querySelector("[data-gallery-images]");
const galleryLightbox = document.querySelector("[data-gallery-lightbox]");
const lightboxImage = document.querySelector("[data-lightbox-image]");
const lightboxCounter = document.querySelector("[data-lightbox-counter]");
const lightboxCloseButton = document.querySelector("[data-lightbox-close]");
const lightboxPrevButton = document.querySelector("[data-lightbox-prev]");
const lightboxNextButton = document.querySelector("[data-lightbox-next]");
const navigationSections = [...navigationLinks]
  .map((link) => document.querySelector(link.getAttribute("href")))
  .filter(Boolean);
let activeGalleryAlbum = null;
let activeLightboxIndex = 0;

const galleryAlbums = [
  {
    id: "u20-national-championship",
    title: "Национален шампионат U20",
    subtitle: "Юноши и девойки под 20 години",
    cover: "./assets/gallery/U20/u20-01.jpg",
    images: [
      "./assets/gallery/U20/u20-01.jpg",
      "./assets/gallery/U20/u20-02.jpg",
      "./assets/gallery/U20/u20-03.jpg",
      "./assets/gallery/U20/u20-04.jpg",
      "./assets/gallery/U20/u20-05.jpg",
      "./assets/gallery/U20/u20-06.jpg",
      "./assets/gallery/U20/u20-07.jpg",
      "./assets/gallery/U20/u20-08.jpg",
      "./assets/gallery/U20/u20-09.jpg",
      "./assets/gallery/U20/u20-10.jpg",
      "./assets/gallery/U20/u20-11.jpg",
      "./assets/gallery/U20/u20-12.jpg",
      "./assets/gallery/U20/u20-13.jpg",
      "./assets/gallery/U20/u20-15.jpg",
      "./assets/gallery/U20/u20-17.jpg",
      "./assets/gallery/U20/u20-18.jpg",
      "./assets/gallery/U20/u20-19.jpg",
      "./assets/gallery/U20/u20-20.jpg",
    ],
  },
];

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
  const sectionStyles = window.getComputedStyle(section);
  const contentOffset = section.classList.contains("gallery-section")
    ? parseFloat(sectionStyles.paddingTop) - 16
    : 0;
  const targetTop =
    section.id === "nachalo"
      ? 0
      : window.scrollY +
        section.getBoundingClientRect().top -
        getHeaderOffset() +
        contentOffset;

  window.scrollTo({
    top: Math.max(targetTop, 0),
    behavior: prefersReducedMotion ? "auto" : "smooth",
  });
}

function createGalleryPlaceholder(label) {
  const placeholder = document.createElement("span");
  placeholder.textContent = label;

  return placeholder;
}

function createGalleryImage(src, alt) {
  const image = document.createElement("img");
  image.src = src;
  image.alt = alt;
  image.loading = "lazy";
  image.onerror = () => {
    image.replaceWith(createGalleryPlaceholder("Снимка"));
  };

  return image;
}

function renderGalleryAlbums() {
  if (!galleryAlbumsContainer) {
    return;
  }

  galleryAlbumsContainer.innerHTML = "";

  galleryAlbums.forEach((album) => {
    const albumCard = document.createElement("button");
    albumCard.className = "gallery-album-card";
    albumCard.type = "button";
    albumCard.dataset.albumId = album.id;

    const coverImage = createGalleryImage(album.cover, album.title);
    const content = document.createElement("div");
    content.className = "gallery-album-content";
    content.innerHTML = `
      <span class="gallery-album-meta">${album.images.length} снимки</span>
      <h3>${album.title}</h3>
      <p>${album.subtitle}</p>
      <span class="gallery-album-action">Отвори албума</span>
    `;

    albumCard.append(coverImage, content);
    galleryAlbumsContainer.append(albumCard);
  });
}

function openGalleryAlbum(albumId) {
  const album = galleryAlbums.find((galleryAlbum) => galleryAlbum.id === albumId);

  if (
    !album ||
    !galleryOverview ||
    !galleryDetail ||
    !galleryTitle ||
    !gallerySubtitle ||
    !galleryImagesContainer
  ) {
    return;
  }

  galleryTitle.textContent = album.title;
  gallerySubtitle.textContent = album.subtitle;
  galleryImagesContainer.innerHTML = "";

  album.images.forEach((imageSrc, imageIndex) => {
    const imageCard = document.createElement("article");
    imageCard.className = "gallery-item";
    imageCard.dataset.imageIndex = imageIndex;
    imageCard.append(createGalleryImage(imageSrc, album.title));
    galleryImagesContainer.append(imageCard);
  });

  galleryOverview.hidden = true;
  galleryDetail.hidden = false;
  setActiveNavigation("galeriya");

  if (gallerySection) {
    scrollToSection(gallerySection);
  }

  activeGalleryAlbum = album;
}

function closeGalleryAlbum() {
  if (!galleryOverview || !galleryDetail) {
    return;
  }

  galleryDetail.hidden = true;
  galleryOverview.hidden = false;
  setActiveNavigation("galeriya");

  if (gallerySection) {
    scrollToSection(gallerySection);
  }

  activeGalleryAlbum = null;
  closeLightbox();
}

function updateLightboxImage() {
  if (
    !activeGalleryAlbum ||
    !galleryLightbox ||
    !lightboxImage ||
    !lightboxCounter
  ) {
    return;
  }

  const imageSrc = activeGalleryAlbum.images[activeLightboxIndex];

  lightboxImage.src = imageSrc;
  lightboxImage.alt = activeGalleryAlbum.title;
  lightboxCounter.textContent = `${activeLightboxIndex + 1} / ${
    activeGalleryAlbum.images.length
  }`;
}

function openLightbox(imageIndex) {
  if (!activeGalleryAlbum || !galleryLightbox) {
    return;
  }

  activeLightboxIndex = imageIndex;
  updateLightboxImage();
  galleryLightbox.hidden = false;
  document.body.classList.add("lightbox-open");
  lightboxCloseButton?.focus();
}

function closeLightbox() {
  if (!galleryLightbox) {
    return;
  }

  galleryLightbox.hidden = true;
  document.body.classList.remove("lightbox-open");
}

function showPreviousImage() {
  if (!activeGalleryAlbum) {
    return;
  }

  activeLightboxIndex =
    (activeLightboxIndex - 1 + activeGalleryAlbum.images.length) %
    activeGalleryAlbum.images.length;
  updateLightboxImage();
}

function showNextImage() {
  if (!activeGalleryAlbum) {
    return;
  }

  activeLightboxIndex =
    (activeLightboxIndex + 1) % activeGalleryAlbum.images.length;
  updateLightboxImage();
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

galleryAlbumsContainer?.addEventListener("click", (event) => {
  const albumCard = event.target.closest(".gallery-album-card");

  if (!albumCard) {
    return;
  }

  openGalleryAlbum(albumCard.dataset.albumId);
});

galleryBackButton?.addEventListener("click", closeGalleryAlbum);

galleryImagesContainer?.addEventListener("click", (event) => {
  const imageCard = event.target.closest(".gallery-item");

  if (!imageCard || !imageCard.querySelector("img")) {
    return;
  }

  openLightbox(Number(imageCard.dataset.imageIndex));
});

lightboxCloseButton?.addEventListener("click", closeLightbox);
lightboxPrevButton?.addEventListener("click", showPreviousImage);
lightboxNextButton?.addEventListener("click", showNextImage);

galleryLightbox?.addEventListener("click", (event) => {
  const clickedOutsideImage =
    event.target !== lightboxImage &&
    !event.target.closest("button");

  if (event.target === galleryLightbox || clickedOutsideImage) {
    closeLightbox();
  }
});

document.addEventListener("keydown", (event) => {
  if (!galleryLightbox || galleryLightbox.hidden) {
    return;
  }

  if (event.key === "Escape") {
    event.preventDefault();
    closeLightbox();
  }

  if (event.key === "ArrowLeft") {
    event.preventDefault();
    showPreviousImage();
  }

  if (event.key === "ArrowRight") {
    event.preventDefault();
    showNextImage();
  }
});

window.addEventListener("resize", () => {
  if (window.innerWidth > 900) {
    closeMenu();
  }

  updateActiveNavigation();
});

window.addEventListener("scroll", updateActiveNavigation, { passive: true });

renderGalleryAlbums();
updateActiveNavigation();
yearElement.textContent = new Date().getFullYear();
