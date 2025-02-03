const DragCard = {
  mounted() {
    this.el.addEventListener('dragstart', (e) => {
      console.log('Drag started with card ID:', this.el.dataset.cardId);
      // Add a custom property to track if we're dragging to delete
      this.el.dataset.draggingToDelete = 'false';

      e.dataTransfer.setData('application/json', JSON.stringify({
        cardId: this.el.dataset.cardId,
        type: 'card'
      }));
      e.dataTransfer.effectAllowed = 'move';
    });
  }
};

export default DragCard;
