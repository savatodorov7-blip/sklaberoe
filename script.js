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
const galleryStickyBackButton = document.querySelector("[data-gallery-sticky-back]");
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

const galleryManifestPath = "./assets/gallery/gallery-manifest.json";
const fallbackGalleryAlbums = [
  {
    id: "kids-athletics",
    title: "Детска атлетика",
    subtitle: "Моменти от тренировките",
    cover: "./assets/gallery/kids-athletics/kids-03.jpg",
    images: [
      "./assets/gallery/kids-athletics/kids-01.jpg",
      "./assets/gallery/kids-athletics/kids-02.jpg",
      "./assets/gallery/kids-athletics/kids-03.jpg",
      "./assets/gallery/kids-athletics/kids-04.jpg",
    ],
  },
  {
    id: "training-process",
    title: "Тренировъчен процес",
    subtitle: "Подготовка и развитие на нашите атлети",
    cover: "./assets/gallery/Тренировъчен процес/training-01.jpg",
    images: [
      "./assets/gallery/Тренировъчен процес/training-01.jpg",
      "./assets/gallery/Тренировъчен процес/training-02.jpg",
      "./assets/gallery/Тренировъчен процес/training-03.jpg",
    ],
  },
  {
    id: "competitions",
    title: "Състезания",
    subtitle: "Моменти от състезателния сезон",
    cover: "./assets/gallery/competitions/competition-01.jpg",
    images: [
      "./assets/gallery/competitions/competition-01.jpg",
      "./assets/gallery/competitions/competition-02.jpg",
      "./assets/gallery/competitions/competition-03.jpg",
      "./assets/gallery/competitions/competition-04.jpg",
      "./assets/gallery/competitions/competition-05.jpg",
      "./assets/gallery/competitions/competition-06.jpg",
      "./assets/gallery/competitions/competition-07.jpg",
      "./assets/gallery/competitions/competition-08.jpg",
    ],
  },
  {
    id: "kids-day",
    title: "Клубен живот",
    subtitle: "Събития и моменти от живота на клуба",
    cover: "./assets/gallery/club-life/club-01.jpg",
    images: [
      "./assets/gallery/club-life/club-01.jpg",
      "./assets/gallery/club-life/club-02.jpg",
      "./assets/gallery/club-life/club-03.jpg",
      "./assets/gallery/club-life/club-04.jpg",
      "./assets/gallery/club-life/club-05.jpg",
      "./assets/gallery/club-life/club-06.jpg",
      "./assets/gallery/club-life/club-07.jpg",
      "./assets/gallery/club-life/club-08.jpg",
      "./assets/gallery/club-life/club-09.jpg",
      "./assets/gallery/club-life/club-10.jpg",
      "./assets/gallery/club-life/club-11.jpg",
      "./assets/gallery/club-life/club-12.jpg",
      "./assets/gallery/club-life/club-13.jpg",
    ],
  },
];
let galleryAlbums = fallbackGalleryAlbums;

function isValidGalleryImagePath(path) {
  return (
    typeof path === "string" &&
    path.startsWith("./assets/gallery/") &&
    /\.(?:jpe?g|png|webp)$/i.test(path)
  );
}

function getAlbumsFromManifest(manifest) {
  if (!manifest || !Array.isArray(manifest.albums)) {
    throw new Error("Gallery manifest has no albums array.");
  }

  const manifestAlbums = new Map(
    manifest.albums.map((album) => [album?.id, album])
  );

  return fallbackGalleryAlbums.map((fallbackAlbum) => {
    const manifestAlbum = manifestAlbums.get(fallbackAlbum.id);
    const hasValidImages =
      Array.isArray(manifestAlbum?.images) &&
      manifestAlbum.images.length > 0 &&
      manifestAlbum.images.every(isValidGalleryImagePath);
    const hasValidCover =
      isValidGalleryImagePath(manifestAlbum?.cover) &&
      manifestAlbum.images.includes(manifestAlbum.cover);

    if (!hasValidImages || !hasValidCover) {
      throw new Error(`Invalid gallery manifest album: ${fallbackAlbum.id}`);
    }

    return {
      ...fallbackAlbum,
      cover: manifestAlbum.cover,
      images: manifestAlbum.images,
    };
  });
}

async function loadGalleryManifest() {
  try {
    const response = await fetch(galleryManifestPath, { cache: "no-cache" });

    if (!response.ok) {
      throw new Error(`Gallery manifest request failed: ${response.status}`);
    }

    galleryAlbums = getAlbumsFromManifest(await response.json());
    renderGalleryAlbums();
  } catch (error) {
    console.warn("Gallery manifest unavailable; using fallback images.", error);
  }
}

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

function createGalleryImage(src, alt, options = {}) {
  const { loading = "lazy", fetchPriority = "auto" } = options;
  const image = document.createElement("img");
  image.src = src;
  image.alt = alt;
  image.loading = loading;
  image.decoding = "async";
  image.setAttribute("fetchpriority", fetchPriority);
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

function openGalleryAlbum(albumId, options = {}) {
  const { updateHistory = true, scroll = true } = options;
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
    imageCard.append(
      createGalleryImage(imageSrc, album.title, { fetchPriority: "low" })
    );
    galleryImagesContainer.append(imageCard);
  });

  galleryOverview.hidden = true;
  galleryDetail.hidden = false;
  setActiveNavigation("galeriya");

  activeGalleryAlbum = album;

  if (updateHistory) {
    history.pushState({ galleryView: "album", albumId: album.id }, "", "#galeriya");
  }

  if (scroll && gallerySection) {
    scrollToSection(gallerySection);
  }
}

function closeGalleryAlbum(options = {}) {
  const { updateHistory = true, scroll = true } = options;
  if (!galleryOverview || !galleryDetail) {
    return;
  }

  closeLightbox({ updateHistory: false });
  galleryDetail.hidden = true;
  galleryOverview.hidden = false;
  setActiveNavigation("galeriya");

  activeGalleryAlbum = null;

  if (updateHistory) {
    history.replaceState(null, "", "#galeriya");
  }

  if (scroll && gallerySection) {
    scrollToSection(gallerySection);
  }
}

function resetGalleryToOverview() {
  if (!galleryOverview || !galleryDetail) {
    closeLightbox();
    activeGalleryAlbum = null;
    return;
  }

  galleryDetail.hidden = true;
  galleryOverview.hidden = false;
  activeGalleryAlbum = null;
  closeLightbox({ updateHistory: false });
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

function openLightbox(imageIndex, options = {}) {
  const { updateHistory = true } = options;
  if (!activeGalleryAlbum || !galleryLightbox) {
    return;
  }

  activeLightboxIndex = imageIndex;
  updateLightboxImage();
  galleryLightbox.hidden = false;
  document.body.classList.add("lightbox-open");
  lightboxCloseButton?.focus();

  if (updateHistory) {
    history.pushState(
      {
        galleryView: "lightbox",
        albumId: activeGalleryAlbum.id,
        imageIndex: activeLightboxIndex,
      },
      "",
      "#galeriya"
    );
  }
}

function closeLightbox(options = {}) {
  const { updateHistory = false } = options;
  if (!galleryLightbox) {
    return;
  }

  const wasOpen = !galleryLightbox.hidden;
  galleryLightbox.hidden = true;
  document.body.classList.remove("lightbox-open");

  if (wasOpen && updateHistory && activeGalleryAlbum) {
    history.replaceState(
      { galleryView: "album", albumId: activeGalleryAlbum.id },
      "",
      "#galeriya"
    );
  }
}

function closeLightboxFromUser() {
  if (history.state?.galleryView === "lightbox") {
    history.back();
    return;
  }

  closeLightbox({ updateHistory: false });
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

    const wasGalleryHistoryState = Boolean(history.state?.galleryView);

    resetGalleryToOverview();
    setActiveNavigation(targetSection.id);
    scrollToSection(targetSection);

    if (wasGalleryHistoryState) {
      history.replaceState(null, "", "#galeriya");
    }

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

galleryBackButton?.addEventListener("click", () => closeGalleryAlbum());
galleryStickyBackButton?.addEventListener("click", () => closeGalleryAlbum());

galleryImagesContainer?.addEventListener("click", (event) => {
  const imageCard = event.target.closest(".gallery-item");

  if (!imageCard || !imageCard.querySelector("img")) {
    return;
  }

  openLightbox(Number(imageCard.dataset.imageIndex));
});

lightboxCloseButton?.addEventListener("click", closeLightboxFromUser);
lightboxPrevButton?.addEventListener("click", showPreviousImage);
lightboxNextButton?.addEventListener("click", showNextImage);

galleryLightbox?.addEventListener("click", (event) => {
  const clickedOutsideImage =
    event.target !== lightboxImage &&
    !event.target.closest("button");

  if (event.target === galleryLightbox || clickedOutsideImage) {
    closeLightboxFromUser();
  }
});

document.addEventListener("keydown", (event) => {
  if (!galleryLightbox || galleryLightbox.hidden) {
    return;
  }

  if (event.key === "Escape") {
    event.preventDefault();
    closeLightboxFromUser();
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

window.addEventListener("popstate", (event) => {
  const galleryState = event.state?.galleryView;

  if (galleryState === "lightbox") {
    const albumId = event.state.albumId;
    const imageIndex = Number(event.state.imageIndex) || 0;

    if (!activeGalleryAlbum || activeGalleryAlbum.id !== albumId) {
      openGalleryAlbum(albumId, { updateHistory: false, scroll: false });
    }

    openLightbox(imageIndex, { updateHistory: false });
    return;
  }

  if (galleryLightbox && !galleryLightbox.hidden) {
    closeLightbox({ updateHistory: false });
  }

  if (galleryState === "album") {
    const albumId = event.state.albumId;

    if (!activeGalleryAlbum || activeGalleryAlbum.id !== albumId) {
      openGalleryAlbum(albumId, { updateHistory: false, scroll: false });
    }

    return;
  }

  if (activeGalleryAlbum) {
    closeGalleryAlbum({ updateHistory: false, scroll: true });
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
loadGalleryManifest();
updateActiveNavigation();
yearElement.textContent = new Date().getFullYear();
