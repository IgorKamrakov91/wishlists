const CardConfettiEffect = {
  mounted() {
    this.handleEvent("trigger_card_confetti", () => {
      this.createConfettiBurst();
    });
  },

  createConfettiBurst() {
    // Создаем множество конфетти из центра экрана
    for (let i = 0; i < 50; i++) {
      this.createConfetti();
    }
  },

  createConfetti() {
    const confetti = document.createElement("div");
    confetti.className = "confetti";

    // Позиционируем конфетти в центре экрана
    const startX = window.innerWidth / 2;
    const startY = window.innerHeight / 2;

    // Random size
    const size = Math.random() * 10 + 5;

    // Random colors - используем цвета в стиле приложения
    const colors = [
      '#818cf8', // индиго
      '#8b5cf6', // фиолетовый
      '#d946ef', // розовый
      '#6366f1', // индиго-600
      '#a855f7', // фиолетовый-500
      '#ec4899', // розовый-500
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
    const velocity = Math.random() * 300 + 100; // Увеличенная скорость
    const rotationSpeed = Math.random() * 720; // Увеличенная скорость вращения
    const lifetime = Math.random() * 2000 + 1000;

    let opacity = 1;
    let time = 0;

    const animate = () => {
      time += 16;
      opacity = 1 - (time / lifetime);

      confetti.style.transform = `translate(
        ${Math.cos(angle) * velocity * (time / 1000)}px,
        ${(Math.sin(angle) * velocity * (time / 1000)) + (0.5 * 9.81 * Math.pow(time / 1000, 2))}px
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

export default CardConfettiEffect;
