const DragAndDrop = {
  mounted() {
    const setupDropTarget = (folder) => {
      let dragCounter = 0;

      folder.addEventListener("dragenter", e => {
        e.preventDefault();
        dragCounter++;
        if (dragCounter === 1) {
          folder.classList.add("drag-over");
        }
      });

      folder.addEventListener("dragover", e => {
        e.preventDefault();
      });

      folder.addEventListener("dragleave", e => {
        e.preventDefault();
        dragCounter--;
        if (dragCounter === 0) {
          folder.classList.remove("drag-over");
        }
      });

      folder.addEventListener("drop", e => {
        e.preventDefault();
        dragCounter = 0;
        folder.classList.remove("drag-over");

        const cardId = e.dataTransfer.getData("application/x-card-id");
        const folderId = folder.dataset.folderId;
        const isOwner = folder.dataset.owner === "true";

        console.log("Drop event:", { cardId, folderId, isOwner });

        if (!isOwner) {
          return;
        }

        if (cardId && folderId && !folder.dataset.processing) {
          folder.dataset.processing = "true";
          this.pushEvent("assign_card", {
            card_id: cardId,
            folder_id: folderId
          });

          setTimeout(() => {
            delete folder.dataset.processing;
          }, 500);
        }
      });
    };

    // Make cards draggable
    const cards = document.querySelectorAll('[data-card-id]');
    cards.forEach(card => {
      card.addEventListener("dragstart", e => {
        const cardId = e.target.closest('[data-card-id]').dataset.cardId;
        e.dataTransfer.setData("application/x-card-id", cardId);
        e.target.classList.add("opacity-50", "scale-105");
      });

      card.addEventListener("dragend", e => {
        e.target.classList.remove("opacity-50", "scale-105");
      });
    });

    // Handle all folder drop zones
    const folders = document.querySelectorAll('[data-folder-id]');
    folders.forEach(setupDropTarget);
  }
};

export default DragAndDrop;
