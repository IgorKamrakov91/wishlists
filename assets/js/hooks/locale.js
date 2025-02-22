const LocaleHook = {
  mounted() {
    const urlParams = new URLSearchParams(window.location.search);
    const urlLocale = urlParams.get('locale');
    const storedLocale = localStorage.getItem('locale');
    const browserLocale = navigator.language.split('-')[0];

    const supportedLocales = ['en', 'ru'];

    if (!urlLocale && !storedLocale) {
      const defaultLocale = supportedLocales.includes(browserLocale) ? browserLocale : 'en';
      this.pushEvent('switch_locale', { locale: defaultLocale });
    } else if (!urlLocale && storedLocale) {
      this.pushEvent('switch_locale', { locale: storedLocale });
    }

    this.handleEvent('store-locale', ({ locale }) => {
      localStorage.setItem('locale', locale);
    });
  }
};

export default LocaleHook;
