const DragCard = {
  mounted() {
    this.initializeDrag();
  },

  updated() {
    this.initializeDrag();
  },

  initializeDrag() {
    this.cleanup();

    this.dragStartHandler = (e) => {
      console.log('Drag started with card ID:', this.el.dataset.cardId);
      this.el.dataset.draggingToDelete = 'false';
      this.el.classList.add("dragging");

      e.dataTransfer.setData('application/json', JSON.stringify({
        cardId: this.el.dataset.cardId,
        type: 'card'
      }));
      e.dataTransfer.setData('application/x-card-id', this.el.dataset.cardId);
      e.dataTransfer.effectAllowed = 'move';
      this.showFloatingBar();
      this.el.classList.add("opacity-50");
    };

    this.dragEndHandler = () => {
      this.el.classList.remove("dragging");
      this.hideFloatingBar();
      this.el.classList.remove("opacity-50");
    };

    this.touchStartHandler = (e) => {
      const touch = e.touches[0];
      this.touchStartX = touch.clientX;
      this.touchStartY = touch.clientY;
      this.dragging = false;
      this.el.dataset.draggingToDelete = 'false';
    };

    this.touchMoveHandler = (e) => {
      if (!this.dragging) {
        const touch = e.touches[0];
        const deltaX = touch.clientX - this.touchStartX;
        const deltaY = touch.clientY - this.touchStartY;

        if (Math.abs(deltaX) > 10 || Math.abs(deltaY) > 10) {
          this.dragging = true;
          this.el.classList.add("opacity-50");
          this.showFloatingBar();

          if (!this.ghost) {
            this.ghost = this.el.cloneNode(true);
            this.ghost.style.position = "fixed";
            this.ghost.style.pointerEvents = "none";
            this.ghost.style.opacity = "0.8";
            this.ghost.style.width = `${this.el.offsetWidth}px`;
            document.body.appendChild(this.ghost);
          }
        }
      }

      if (this.dragging) {
        e.preventDefault();
        const touch = e.touches[0];

        if (this.ghost) {
          this.ghost.style.left = `${touch.clientX - this.el.offsetWidth / 2}px`;
          this.ghost.style.top = `${touch.clientY - this.el.offsetHeight / 2}px`;
        }

        const folders = document.querySelectorAll('.drag-target');
        let foundFolder = null;

        folders.forEach(folder => {
          const rect = folder.getBoundingClientRect();
          if (touch.clientX >= rect.left && touch.clientX <= rect.right &&
            touch.clientY >= rect.top && touch.clientY <= rect.bottom) {
            foundFolder = folder;
          }
        });

        if (foundFolder) {
          folders.forEach(f => f.querySelector('.drag-area')?.classList.remove('opacity-50'));
          foundFolder.querySelector('.drag-area')?.classList.add('opacity-50');
          this.currentFolder = foundFolder;
        } else {
          folders.forEach(f => f.querySelector('.drag-area')?.classList.remove('opacity-50'));
          this.currentFolder = null;
        }
      }
    };

    this.touchEndHandler = (e) => {
      if (this.dragging) {
        this.el.classList.remove("opacity-50");
        this.hideFloatingBar();

        if (this.ghost) {
          this.ghost.remove();
          this.ghost = null;
        }

        if (this.currentFolder) {
          this.pushEvent("card_dropped", {
            card_data: {
              cardId: this.el.dataset.cardId,
              type: 'card'
            },
            folder_id: this.currentFolder.dataset.folderId
          });

          this.currentFolder.querySelector('.drag-area')?.classList.remove('opacity-50');
        }
      }

      this.dragging = false;
      this.currentFolder = null;
    };

    this.el.addEventListener('dragstart', this.dragStartHandler);
    this.el.addEventListener('dragend', this.dragEndHandler);
    this.el.addEventListener('touchstart', this.touchStartHandler);
    this.el.addEventListener('touchmove', this.touchMoveHandler);
    this.el.addEventListener('touchend', this.touchEndHandler);
  },

  cleanup() {
    if (this.dragStartHandler) {
      this.el.removeEventListener('dragstart', this.dragStartHandler);
    }
    if (this.dragEndHandler) {
      this.el.removeEventListener('dragend', this.dragEndHandler);
    }
    if (this.touchStartHandler) {
      this.el.removeEventListener('touchstart', this.touchStartHandler);
    }
    if (this.touchMoveHandler) {
      this.el.removeEventListener('touchmove', this.touchMoveHandler);
    }
    if (this.touchEndHandler) {
      this.el.removeEventListener('touchend', this.touchEndHandler);
    }

    if (this.ghost) {
      this.ghost.remove();
      this.ghost = null;
    }
  },

  destroyed() {
    this.cleanup();
  },

  showFloatingBar() {
    const bar = document.getElementById("floating-folders-bar");
    if (bar) {
      bar.style.transform = "translateY(0)";
      bar.style.opacity = "1";
    }
  },

  hideFloatingBar() {
    const bar = document.getElementById("floating-folders-bar");
    if (bar) {
      bar.style.transform = "translateY(-100%)";
      bar.style.opacity = "0";
    }
  }
};

export default DragCard;
