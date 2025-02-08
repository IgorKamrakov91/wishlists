const CountdownTimer = {
  mounted() {
    this.updateCountdown();
    this.timer = setInterval(() => this.updateCountdown(), 1000);
  },

  destroyed() {
    if (this.timer) {
      clearInterval(this.timer);
    }
  },

  isSameDay(date1, date2) {
    return date1.getFullYear() === date2.getFullYear() &&
      date1.getMonth() === date2.getMonth() &&
      date1.getDate() === date2.getDate();
  },

  isTomorrow(date) {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    return this.isSameDay(date, tomorrow);
  },

  updateCountdown() {
    const targetDateStr = this.el.dataset.targetDate;
    const targetDate = new Date(targetDateStr + 'T23:59:59');
    const now = new Date();
    const difference = targetDate - now;

    if (difference <= 0) {
      this.el.innerHTML = "<span class='text-purple-600'>Event has passed 🗓️</span>";
      clearInterval(this.timer);
      return;
    }

    // Check if event is today
    if (this.isSameDay(targetDate, now)) {
      this.el.innerHTML = "<span class='text-emerald-600 font-medium'>Event is today! ✨</span>";
      return;
    }

    // Check if event is tomorrow
    if (this.isTomorrow(targetDate)) {
      this.el.innerHTML = "<span class='text-indigo-600 font-medium'>Event is tomorrow! 🎉</span>";
      return;
    }

    // Regular countdown for other dates
    const days = Math.ceil(difference / (1000 * 60 * 60 * 24));
    this.el.innerHTML = `<span class="text-indigo-700">${days} days remaining</span>`;
  }
};

export default CountdownTimer;
