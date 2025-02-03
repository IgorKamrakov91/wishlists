const FloatingBar = {
  mounted() {
    const bar = this.el;
    let lastScroll = 0;
    let ticking = false;

    const updateBar = () => {
      const currentScroll = window.scrollY;
      const foldersContainer = document.getElementById('folders-container');

      if (foldersContainer) {
        const foldersBottom = foldersContainer.offsetTop + foldersContainer.offsetHeight;

        if (currentScroll > foldersBottom) {
          // Show bar when scrolled past the folders section
          bar.style.transform = 'translateY(0)';
          bar.style.opacity = '1';
        } else {
          // Hide bar when in folders section
          bar.style.transform = 'translateY(-100%)';
          bar.style.opacity = '0';
        }

        lastScroll = currentScroll;
      }
      ticking = false;
    };

    window.addEventListener('scroll', () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          updateBar();
        });
        ticking = true;
      }
    }, { passive: true });

    // Initial check
    updateBar();
  }
};

export default FloatingBar;
