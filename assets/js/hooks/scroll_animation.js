const ScrollAnimation = {
  mounted() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('animate-in');
          }
        });
      },
      {
        threshold: 0.1,
        rootMargin: '0px'
      }
    );

    this.el.querySelectorAll('[data-scroll-element]').forEach((element) => {
      this.observer.observe(element);
    });

    this.handleScroll = () => {
      const scrolled = window.scrollY;
      const section = this.el;
      const sectionTop = section.offsetTop;
      const sectionHeight = section.offsetHeight;
      const viewportHeight = window.innerHeight;

      if (scrolled >= sectionTop - viewportHeight && scrolled <= sectionTop + sectionHeight) {
        const progress = (scrolled - (sectionTop - viewportHeight)) / (sectionHeight + viewportHeight);

        this.el.querySelectorAll('[data-scroll-element]').forEach((element) => {
          const delay = element.classList.contains('delay-200') ? 0.2 :
                       element.classList.contains('delay-400') ? 0.4 : 0;

          const translateY = Math.max(0, 100 * (progress - delay));
          const opacity = Math.min(1, Math.max(0, (progress - delay) * 2));

          element.style.transform = `translateY(${translateY}px)`;
          element.style.opacity = opacity;
        });
      }
    };

    window.addEventListener('scroll', this.handleScroll, { passive: true });
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect();
    }
    window.removeEventListener('scroll', this.handleScroll);
  }
};

export default ScrollAnimation;
