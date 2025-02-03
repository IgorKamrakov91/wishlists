const SparkleEffect = {
  mounted() {
    this.el.addEventListener("click", () => {
      for (let i = 0; i < 30; i++) {
        createSparkle();
      }
    });

    function createSparkle() {
      const sparkle = document.createElement("div");
      sparkle.className = "sparkle";

      // Random position on the screen
      const startX = Math.random() * window.innerWidth;
      const startY = Math.random() * window.innerHeight;

      // Random size
      const size = Math.random() * 20 + 15; // Slightly bigger for better star visibility

      // Random color from a magical palette
      const colors = [
        'rgba(147, 51, 234, 0.8)', // Purple
        'rgba(79, 70, 229, 0.8)',  // Indigo
        'rgba(219, 39, 119, 0.8)', // Pink
        'rgba(236, 72, 153, 0.8)', // Rose
        'rgba(167, 139, 250, 0.8)', // Violet
      ];
      const color = colors[Math.floor(Math.random() * colors.length)];

      sparkle.style.cssText = `
        position: fixed;
        left: ${startX}px;
        top: ${startY}px;
        width: ${size}px;
        height: ${size}px;
        background-color: ${color};
        clip-path: polygon(50% 0%, 61% 35%, 98% 35%, 68% 57%, 79% 91%, 50% 70%, 21% 91%, 32% 57%, 2% 35%, 39% 35%, 50% 0%);
        filter: blur(0.5px);
        pointer-events: none;
        z-index: 9999;
        box-shadow: 0 0 ${size / 2}px ${color};
      `;

      document.body.appendChild(sparkle);

      // Animate the sparkle
      const angle = Math.random() * Math.PI * 2;
      const velocity = Math.random() * 200 + 100;
      const lifetime = Math.random() * 1500 + 800;

      let opacity = 1;
      let time = 0;

      function animate() {
        time += 16;
        opacity = 1 - (time / lifetime);

        sparkle.style.transform = `translate(
          ${Math.cos(angle) * velocity * (time / 1000)}px,
          ${Math.sin(angle) * velocity * (time / 1000)}px
        ) rotate(${time}deg)`; // Faster rotation for stars
        sparkle.style.opacity = opacity;

        if (opacity > 0) {
          requestAnimationFrame(animate);
        } else {
          sparkle.remove();
        }
      }

      requestAnimationFrame(animate);
    }
  }
}

export default SparkleEffect;
