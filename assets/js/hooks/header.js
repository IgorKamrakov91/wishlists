const HideableHeader = {
  mounted() {
    const header = this.el;

    window.addEventListener('scroll', () => {
      if (window.pageYOffset > 0) {
        header.classList.add('translate-y-[-100%]');
      } else {
        header.classList.remove('translate-y-[-100%]');
      }
    }, { passive: true });
  }
}

export default HideableHeader;
