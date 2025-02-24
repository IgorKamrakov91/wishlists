const DragOrder = {
  mounted() {
    this.initDragAndDrop();
  },

  updated() {
    this.initDragAndDrop();
  },

  initDragAndDrop() {
    const container = this.el;

    if (this.sortable) {
      this.sortable.destroy();
    }

    this.sortable = new Sortable(container, {
      animation: 150,
      ghostClass: 'bg-indigo-100',
      onEnd: (evt) => {
        if (evt.oldIndex !== evt.newIndex) {
          const cardId = evt.item.dataset.cardId;
          const newPosition = evt.newIndex + 1;

          this.pushEvent("reorder_card", {
            card_id: cardId,
            position: newPosition
          });
        }
      }
    });
  },

  destroyed() {
    if (this.sortable) {
      this.sortable.destroy();
    }
  }
};

export default DragOrder;
