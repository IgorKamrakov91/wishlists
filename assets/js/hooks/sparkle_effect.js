const ConfettiEffect = {
  mounted() {
    this.el.addEventListener("click", () => {
      for (let i = 0; i < 30; i++) {
        createConfetti();
      }
    });

    function createConfetti() {
      const confetti = document.createElement("div");
      confetti.className = "confetti";

      // Random position near the click area
      const startX = Math.random() * window.innerWidth;
      const startY = Math.random() * window.innerHeight;

      // Random size
      const size = Math.random() * 10 + 5;

      // Random colors
      const colors = [
        '#ff0a54', '#ff477e', '#ff7096', '#ff85a1', '#ff99ac',
        '#ffba08', '#f48c06', '#e85d04', '#dc2f02', '#d00000'
      ];
      const color = colors[Math.floor(Math.random() * colors.length)];

      // Random shape
      const shapes = ['circle', 'square', 'rectangle'];
      const shape = shapes[Math.floor(Math.random() * shapes.length)];

      confetti.style.cssText = `
        position: fixed;
        left: ${startX}px;
        top: ${startY}px;
        width: ${size}px;
        height: ${shape === 'rectangle' ? size * 2 : size}px;
        background-color: ${color};
        opacity: 1;
        transform-origin: center;
        pointer-events: none;
        z-index: 9999;
        border-radius: ${shape === 'circle' ? '50%' : '0'};
      `;

      document.body.appendChild(confetti);

      // Animation properties
      const angle = Math.random() * Math.PI * 2;
      const velocity = Math.random() * 150 + 50;
      const rotationSpeed = Math.random() * 360;
      const lifetime = Math.random() * 2000 + 1000;

      let opacity = 1;
      let time = 0;

      function animate() {
        time += 16;
        opacity = 1 - (time / lifetime);

        confetti.style.transform = `translate(
          ${Math.cos(angle) * velocity * (time / 1000)}px,
          ${Math.sin(angle) * velocity * (time / 1000)}px
        ) rotate(${time / 10 * rotationSpeed}deg)`;
        confetti.style.opacity = opacity;

        if (opacity > 0) {
          requestAnimationFrame(animate);
        } else {
          confetti.remove();
        }
      }

      requestAnimationFrame(animate);
    }
  }
}

export default ConfettiEffect;
