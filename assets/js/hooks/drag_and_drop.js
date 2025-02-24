const DragAndDrop = {
  mounted() {
    this.initializeDropZones();
  },

  updated() {
    this.initializeDropZones();
  },

  initializeDropZones() {
    this.cleanup();

    this.dropTargets = new Map();

    const folders = document.querySelectorAll('[data-folder-id]');
    folders.forEach(folder => {
      const handlers = this.setupDropTarget(folder);
      this.dropTargets.set(folder, handlers);
    });
  },

  setupDropTarget(folder) {
    let dragCounter = 0;

    const handlers = {
      dragenter: (e) => {
        e.preventDefault();
        dragCounter++;
        if (dragCounter === 1) {
          folder.classList.add("drag-over");
        }
      },

      dragover: (e) => {
        e.preventDefault();
      },

      dragleave: (e) => {
        e.preventDefault();
        dragCounter--;
        if (dragCounter === 0) {
          folder.classList.remove("drag-over");
        }
      },

      drop: (e) => {
        e.preventDefault();
        dragCounter = 0;
        folder.classList.remove("drag-over");

        const cardId = e.dataTransfer.getData("application/x-card-id");
        const folderId = folder.dataset.folderId;
        const isOwner = folder.dataset.owner === "true";

        if (!isOwner) return;

        if (cardId && folderId && !folder.dataset.processing) {
          folder.dataset.processing = "true";
          this.pushEvent("card_dropped", {
            card_data: {
              cardId: cardId,
              type: 'card'
            },
            folder_id: folderId
          });

          setTimeout(() => {
            delete folder.dataset.processing;
          }, 500);
        }
      }
    };

    folder.addEventListener("dragenter", handlers.dragenter);
    folder.addEventListener("dragover", handlers.dragover);
    folder.addEventListener("dragleave", handlers.dragleave);
    folder.addEventListener("drop", handlers.drop);

    return handlers;
  },

  cleanup() {
    if (this.dropTargets) {
      this.dropTargets.forEach((handlers, folder) => {
        folder.removeEventListener("dragenter", handlers.dragenter);
        folder.removeEventListener("dragover", handlers.dragover);
        folder.removeEventListener("dragleave", handlers.dragleave);
        folder.removeEventListener("drop", handlers.drop);
      });
      this.dropTargets.clear();
    }
  },

  destroyed() {
    this.cleanup();
  }
};

export default DragAndDrop;
