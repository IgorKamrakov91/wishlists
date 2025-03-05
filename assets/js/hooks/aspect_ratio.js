const AspectRatioHook = {
  mounted() {
    this.setAspectRatio();
  },

  updated() {
    this.setAspectRatio();
  },

  setAspectRatio() {
    const img = this.el;

    if (img.complete) {
      this.updateRatio(img);
    } else {
      img.onload = () => this.updateRatio(img);
    }
  },

  updateRatio(img) {
    const container = img.closest('[data-card-id]');
    if (container) {
      const ratio = img.naturalWidth / img.naturalHeight;

      // Сохраняем соотношение сторон как атрибут данных
      container.dataset.aspectRatio = ratio;

      this.updateCardSize(container, ratio);
    }
  },

  updateCardSize(container, ratio) {
    container.style.setProperty('--card-aspect-ratio', `${ratio}`);

    if (ratio > 1.5) {
      container.style.gridColumn = 'span 2';
      container.style.gridRow = 'span 1';
    } else if (ratio < 0.7) {
      container.style.gridColumn = 'span 1';
      container.style.gridRow = 'span 2';
    } else {
      container.style.gridColumn = 'span 1';
      container.style.gridRow = 'span 1';
    }
  }
};

export default AspectRatioHook;
