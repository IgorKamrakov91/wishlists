const LocaleHook = {
  mounted() {
    const urlParams = new URLSearchParams(window.location.search);
    const urlLocale = urlParams.get('locale');
    const storedLocale = localStorage.getItem('locale');

    if (!urlLocale && storedLocale) {
      this.pushEvent('switch_locale', { locale: storedLocale });
    }

    this.handleEvent('store-locale', ({ locale }) => {
      localStorage.setItem('locale', locale);
    });
  }
};

export default LocaleHook;
