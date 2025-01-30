const DragAndDrop = {
  mounted() {
    // Make cards draggable
    const cards = this.el.querySelectorAll('[data-card-id]');
    cards.forEach(card => {
      card.addEventListener("dragstart", e => {
        const cardId = e.target.closest('[data-card-id]').dataset.cardId;
        console.log('Drag start - Card ID:', cardId); // Debug log
        e.dataTransfer.setData("application/x-card-id", cardId);
        e.target.classList.add("opacity-50");
      });

      card.addEventListener("dragend", e => {
        e.target.classList.remove("opacity-50");
      });
    });

    // Handle folder drop zones
    const folders = this.el.querySelectorAll('[data-folder-id]');
    folders.forEach(folder => {
      folder.addEventListener("dragover", e => {
        e.preventDefault();
        folder.classList.add("bg-indigo-50");
      });

      folder.addEventListener("dragleave", e => {
        e.preventDefault();
        folder.classList.remove("bg-indigo-50");
      });

      folder.addEventListener("drop", e => {
        e.preventDefault();
        const cardId = e.dataTransfer.getData("application/x-card-id");
        const folderId = folder.dataset.folderId;
        console.log('Drop - Card ID:', cardId, 'Folder ID:', folderId); // Debug log
        folder.classList.remove("bg-indigo-50");

        if (cardId && folderId) {
          this.pushEvent("assign_card", {
            card_id: cardId,
            folder_id: folderId
          });
        }
      });
    });
  }
};

export default DragAndDrop;
