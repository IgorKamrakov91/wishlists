const DragOrder = {
  mounted() {
    this.initDragAndDrop();
  },

  updated() {
    this.initDragAndDrop();
  },

  initDragAndDrop() {
    const container = this.el;

    const config = {
      animation: 150,
      ghostClass: 'bg-indigo-100',
      onStart: (evt) => {
        const item = evt.item;
        // Сохраняем текущие стили
        item.dataset.originalColumn = item.style.gridColumn;
        item.dataset.originalRow = item.style.gridRow;
      },
      onEnd: (evt) => {
        const item = evt.item;
        // Восстанавливаем размеры на основе сохраненного соотношения сторон
        const ratio = parseFloat(item.dataset.aspectRatio);
        if (ratio) {
          if (ratio > 1.5) {
            item.style.gridColumn = 'span 2';
            item.style.gridRow = 'span 1';
          } else if (ratio < 0.7) {
            item.style.gridColumn = 'span 1';
            item.style.gridRow = 'span 2';
          } else {
            item.style.gridColumn = 'span 1';
            item.style.gridRow = 'span 1';
          }
        }

        if (evt.oldIndex !== evt.newIndex) {
          const cardId = item.dataset.cardId;
          const newPosition = evt.newIndex + 1;

          this.pushEvent("reorder_card", {
            card_id: cardId,
            position: newPosition
          });
        }
      }
    };

    if (this.sortable) {
      this.sortable.destroy();
    }

    this.sortable = new Sortable(container, config);
  },

  destroyed() {
    if (this.sortable) {
      this.sortable.destroy();
    }
  }
};

export default DragOrder;
