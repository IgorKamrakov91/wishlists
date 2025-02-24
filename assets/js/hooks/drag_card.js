const DragCard = {
  mounted() {
    this.initializeDrag();
  },

  updated() {
    this.initializeDrag();
  },

  initializeDrag() {
    this.el.addEventListener('dragstart', (e) => {
      console.log('Drag started with card ID:', this.el.dataset.cardId);
      this.el.dataset.draggingToDelete = 'false';
      this.el.classList.add("dragging");

      e.dataTransfer.setData('application/json', JSON.stringify({
        cardId: this.el.dataset.cardId,
        type: 'card'
      }));
      e.dataTransfer.effectAllowed = 'move';
      this.showFloatingBar();
      this.el.classList.add("opacity-50");
    });

    this.el.addEventListener('dragend', () => {
      this.el.classList.remove("dragging");
      this.hideFloatingBar();
      this.el.classList.remove("opacity-50");
    });

    this.el.addEventListener("touchstart", (e) => this.handleTouchStart(e));
    this.el.addEventListener("touchmove", (e) => this.handleTouchMove(e));
    this.el.addEventListener("touchend", (e) => this.handleTouchEnd(e));
  },

  handleTouchStart(e) {
    const touch = e.touches[0];
    this.touchStartX = touch.clientX;
    this.touchStartY = touch.clientY;
    this.dragging = false;
    this.el.dataset.draggingToDelete = 'false';
  },

  handleTouchMove(e) {
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
  },

  handleTouchEnd(e) {
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
