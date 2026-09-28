extends Node

## Web-only helper that opens the browser's normal photo/file picker.
signal file_ready(bytes: PackedByteArray, filename: String)
signal cancelled

var _js_callback: JavaScriptObject
var _picker: JavaScriptObject


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	_js_callback = JavaScriptBridge.create_callback(_on_js_picked)
	JavaScriptBridge.eval("""
(() => {
  if (window.CyberTimeFiles) return;
  window.CyberTimeFiles = {
    callback: null,
    pickImage: function () {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = 'image/png,image/jpeg,image/jpg,image/webp,image/*';
      input.style.display = 'none';
      document.body.appendChild(input);
      input.addEventListener('change', async () => {
        const file = input.files && input.files[0];
        input.remove();
        if (!file || !window.CyberTimeFiles.callback) {
          if (window.CyberTimeFiles.callback) {
            window.CyberTimeFiles.callback('', '');
          }
          return;
        }
        const buf = new Uint8Array(await file.arrayBuffer());
        let binary = '';
        const chunk = 0x8000;
        for (let i = 0; i < buf.length; i += chunk) {
          binary += String.fromCharCode.apply(null, buf.subarray(i, i + chunk));
        }
        window.CyberTimeFiles.callback(file.name || 'upload.png', btoa(binary));
      }, { once: true });
      input.addEventListener('cancel', () => {
        input.remove();
        if (window.CyberTimeFiles.callback) {
          window.CyberTimeFiles.callback('', '');
        }
      }, { once: true });
      input.click();
    }
  };
})();
""", true)
	_picker = JavaScriptBridge.get_interface("CyberTimeFiles")
	if _picker != null:
		_picker.callback = _js_callback


func is_available() -> bool:
	return OS.has_feature("web") and _picker != null


func pick_image() -> void:
	if not is_available():
		cancelled.emit()
		return
	_picker.pickImage()


func _on_js_picked(args: Array) -> void:
	if args.is_empty():
		cancelled.emit()
		return
	var filename := str(args[0])
	var b64 := str(args[1]) if args.size() > 1 else ""
	if filename == "" or b64 == "":
		cancelled.emit()
		return
	var bytes := Marshalls.base64_to_raw(b64)
	if bytes.is_empty():
		cancelled.emit()
		return
	file_ready.emit(bytes, filename)
