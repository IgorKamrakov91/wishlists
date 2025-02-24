const ImageLoader = {
  mounted() {
    this.el.addEventListener('error', () => {
      this.el.src = '/images/gift.jpg';
    });
  }
};

export default ImageLoader;
