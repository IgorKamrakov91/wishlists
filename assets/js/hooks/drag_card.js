const DragCard = {
  mounted() {
    this.initializeDrag();
  },

  updated() {
    this.initializeDrag();
  },

  initializeDrag() {
    this.cleanup();

    if (window.innerWidth >= 768) {
      // Desktop behavior
      this.el.addEventListener('dragstart', (e) => {
        this.el.classList.add("dragging", "opacity-50");
        e.dataTransfer.setData('application/json', JSON.stringify({
          cardId: this.el.dataset.cardId,
          type: 'card'
        }));
        e.dataTransfer.setData('application/x-card-id', this.el.dataset.cardId);
        this.showFloatingBar();
      });

      this.el.addEventListener('dragend', () => {
        this.el.classList.remove("dragging", "opacity-50");
        this.hideFloatingBar();
      });
    } else {
      // Mobile behavior
      let isDragging = false;
      let currentFolder = null;
      let startX, startY;
      let initialTouchY;
      let lastTouchY;
      let isScrolling = false;
      const DRAG_THRESHOLD = 10;
      const SCROLL_TIMEOUT = 150;
      let scrollTimeout;

      this.el.addEventListener('touchstart', (e) => {
        const touch = e.touches[0];
        startX = touch.clientX;
        startY = touch.clientY;
        initialTouchY = touch.clientY;
        lastTouchY = touch.clientY;
        isScrolling = false;
      });

      this.el.addEventListener('touchmove', (e) => {
        const touch = e.touches[0];
        const deltaX = Math.abs(touch.clientX - startX);
        const deltaY = Math.abs(touch.clientY - startY);
        const currentTouchY = touch.clientY;
        const isVerticalMovement = deltaY > deltaX;

        if (!isDragging && isVerticalMovement) {
          const verticalDelta = currentTouchY - lastTouchY;
          if (Math.abs(verticalDelta) > 5) {
            isScrolling = true;
            clearTimeout(scrollTimeout);
            scrollTimeout = setTimeout(() => {
              isScrolling = false;
            }, SCROLL_TIMEOUT);
          }
        }

        lastTouchY = currentTouchY;
        if (!isDragging && !isScrolling && deltaX > DRAG_THRESHOLD) {
          isDragging = true;
          this.el.classList.add('dragging', 'opacity-50');
          this.showFloatingBar();
          navigator.vibrate && navigator.vibrate(50);
        }

        if (isDragging) {
          e.preventDefault();
          currentFolder = this.checkFolderCollisions(touch);
        }
      }, { passive: false });

      this.el.addEventListener('touchend', () => {
        if (isDragging) {
          this.el.classList.remove('dragging', 'opacity-50');
          this.hideFloatingBar();

          if (currentFolder) {
            this.pushEvent("card_dropped", {
              card_data: {
                cardId: this.el.dataset.cardId,
                type: 'card'
              },
              folder_id: currentFolder.dataset.folderId
            });
          }
        }

        isDragging = false;
        currentFolder = null;
        isScrolling = false;
        clearTimeout(scrollTimeout);
      });

      this.el.addEventListener('touchcancel', () => {
        this.el.classList.remove('dragging', 'opacity-50');
        this.hideFloatingBar();
        isDragging = false;
        currentFolder = null;
        isScrolling = false;
        clearTimeout(scrollTimeout);
      });
    }
  },

  checkFolderCollisions(touch) {
    const folders = document.querySelectorAll('[data-folder-id]');
    let foundFolder = null;

    folders.forEach(folder => {
      const rect = folder.getBoundingClientRect();
      if (touch.clientX >= rect.left && touch.clientX <= rect.right &&
        touch.clientY >= rect.top && touch.clientY <= rect.bottom) {
        folder.classList.add('drag-over');
        foundFolder = folder;
      } else {
        folder.classList.remove('drag-over');
      }
    });

    return foundFolder;
  },

  showFloatingBar() {
    const bar = document.getElementById('floating-folders-bar');
    if (bar) {
      bar.style.transform = 'translateY(0)';
      bar.style.opacity = '1';
    }
  },

  hideFloatingBar() {
    const bar = document.getElementById('floating-folders-bar');
    if (bar) {
      bar.style.transform = 'translateY(-100%)';
      bar.style.opacity = '0';
    }
  },

  cleanup() {
    this.el.removeEventListener('dragstart', this.dragStartHandler);
    this.el.removeEventListener('dragend', this.dragEndHandler);
    this.el.removeEventListener('touchstart', this.touchStartHandler);
    this.el.removeEventListener('touchmove', this.touchMoveHandler);
    this.el.removeEventListener('touchend', this.touchEndHandler);
    this.el.removeEventListener('touchcancel', this.touchCancelHandler);
  },

  destroyed() {
    this.cleanup();
  }
};

export default DragCard;
