const DeleteBucket = {
  mounted() {
    this.bucket = this.el;
    this.overlay = this.el.querySelector('#delete-bucket-overlay');
    this.border = this.el.querySelector('#delete-bucket-border');

    // Show bucket when drag starts
    window.addEventListener('dragstart', () => {
      console.log('Showing delete bucket');
      this.bucket.style.transform = 'scale(1)';
    });

    // Hide bucket when drag ends
    window.addEventListener('dragend', () => {
      console.log('Hiding delete bucket');
      this.bucket.style.transform = 'scale(0)';
      this.overlay.style.opacity = '0';
      this.border.style.opacity = '0';
    });

    this.el.addEventListener('dragenter', (e) => {
      e.preventDefault();
      console.log('Drag entered delete bucket');
      this.overlay.style.opacity = '0.5';
      this.border.style.opacity = '1';

      // Find the dragged card and mark it as being dragged for deletion
      const draggedCard = document.querySelector('.dragging');
      if (draggedCard) {
        draggedCard.dataset.draggingToDelete = 'true';
      }
    });

    this.el.addEventListener('dragleave', (e) => {
      e.preventDefault();
      console.log('Drag left delete bucket');
      this.overlay.style.opacity = '0';
      this.border.style.opacity = '0';

      // Reset the deletion flag when leaving the delete bucket
      const draggedCard = document.querySelector('.dragging');
      if (draggedCard) {
        draggedCard.dataset.draggingToDelete = 'false';
      }
    });

    this.el.addEventListener('dragover', (e) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = 'move';
    });

    this.el.addEventListener('drop', (e) => {
      e.preventDefault();
      console.log('Drop event on delete bucket');

      try {
        const data = JSON.parse(e.dataTransfer.getData('application/json'));
        console.log('Dropped data:', data);

        if (data.type === 'card' && data.cardId) {
          console.log('Initiating card deletion:', data.cardId);
          this.pushEvent('delete_card', { id: data.cardId });
        }
      } catch (error) {
        console.error('Error processing drop:', error);
      }

      this.overlay.style.opacity = '0';
      this.border.style.opacity = '0';
      this.bucket.style.transform = 'scale(0)';
    });
  }
};

export default DeleteBucket;
