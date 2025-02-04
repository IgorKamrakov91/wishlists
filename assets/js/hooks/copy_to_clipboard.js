const CopyToClipboard = {
  mounted() {
    window.copyToClipboard = async (text) => {
      try {
        await navigator.clipboard.writeText(text);
        this.pushEvent("copied_to_clipboard", {});
      } catch (err) {
        console.error('Failed to copy text:', err);
      }
    };
  }
};

export default CopyToClipboard;
