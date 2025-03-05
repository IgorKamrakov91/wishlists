const ScrollButtons = {
  mounted() {
    let scrollInterval = null;
    const SCROLL_INTERVAL = 50;

    const getCardHeight = () => {
      const card = document.querySelector('[data-card-id]');
      if (!card) return 300;

      const cardRect = card.getBoundingClientRect();
      const computedStyle = window.getComputedStyle(card);
      const marginBottom = parseInt(computedStyle.marginBottom);

      return cardRect.height + marginBottom;
    };

    const scroll = (direction) => {
      const scrollDistance = getCardHeight() / 2;
      window.scrollBy({
        top: direction === 'up' ? -scrollDistance : scrollDistance,
        behavior: 'auto'
      });
    };

    const startScroll = (direction) => {
      if (scrollInterval) return;

      const button = this.el.querySelector(`[data-direction="${direction}"]`);
      button.classList.add('active');

      scroll(direction);

      scrollInterval = setInterval(() => scroll(direction), SCROLL_INTERVAL);
    };

    const stopScroll = (direction) => {
      if (scrollInterval) {
        clearInterval(scrollInterval);
        scrollInterval = null;
      }

      if (direction) {
        const button = this.el.querySelector(`[data-direction="${direction}"]`);
        button.classList.remove('active');
      } else {
        this.el.querySelectorAll('.scroll-button').forEach(button => {
          button.classList.remove('active');
        });
      }
    };

    const handleTouchStart = (e) => {
      e.preventDefault();
      const button = e.target.closest('.scroll-button');
      if (!button) return;

      startScroll(button.dataset.direction);
    };

    const handleTouchEnd = (e) => {
      const button = e.target.closest('.scroll-button');
      if (button) {
        stopScroll(button.dataset.direction);
      }
    };
    const handleMouseDown = (e) => {
      const button = e.target.closest('.scroll-button');
      if (!button) return;

      button.classList.add('scale-95', 'active');
      startScroll(button.dataset.direction);
    };

    const handleMouseUp = (e) => {
      const button = e.target.closest('.scroll-button');
      if (button) {
        button.classList.remove('scale-95', 'active');
      }
      stopScroll();
    };

    const handleMouseLeave = () => {
      stopScroll();
      this.el.querySelectorAll('.scroll-button').forEach(button => {
        button.classList.remove('scale-95', 'active');
      });
    };

    const updateButtonsVisibility = () => {
      const upButton = this.el.querySelector('[data-direction="up"]');
      const downButton = this.el.querySelector('[data-direction="down"]');

      if (upButton) {
        upButton.style.opacity = window.scrollY < 100 ? "0" : "1";
        upButton.style.pointerEvents = window.scrollY < 100 ? "none" : "auto";
      }

      if (downButton) {
        const isAtBottom = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 100;
        downButton.style.opacity = isAtBottom ? "0" : "1";
        downButton.style.pointerEvents = isAtBottom ? "none" : "auto";
      }
    };

    this.el.addEventListener('touchstart', handleTouchStart, { passive: false });
    this.el.addEventListener('touchend', handleTouchEnd);
    this.el.addEventListener('touchcancel', handleTouchEnd);

    this.el.addEventListener('mousedown', handleMouseDown);
    this.el.addEventListener('mouseup', handleMouseUp);
    this.el.addEventListener('mouseleave', handleMouseLeave);

    window.addEventListener('scroll', updateButtonsVisibility, { passive: true });
    window.addEventListener('resize', updateButtonsVisibility, { passive: true });

    this.destroyCallback = () => {
      stopScroll();
      this.el.removeEventListener('touchstart', handleTouchStart);
      this.el.removeEventListener('touchend', handleTouchEnd);
      this.el.removeEventListener('touchcancel', handleTouchEnd);
      this.el.removeEventListener('mousedown', handleMouseDown);
      this.el.removeEventListener('mouseup', handleMouseUp);
      this.el.removeEventListener('mouseleave', handleMouseLeave);
      window.removeEventListener('scroll', updateButtonsVisibility);
      window.removeEventListener('resize', updateButtonsVisibility);
    };

    updateButtonsVisibility();
  },

  destroyed() {
    if (this.destroyCallback) {
      this.destroyCallback();
    }
  }
};

export default ScrollButtons;
