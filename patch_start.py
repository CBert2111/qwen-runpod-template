from pathlib import Path
import sys

start_file = Path(sys.argv[1])
text = start_file.read_text()

marker = 'echo "Starting ComfyUI with args: $FIXED_ARGS"'

if marker not in text:
    raise SystemExit(
        "FEHLER: Der erwartete Startpunkt wurde in /start.sh nicht gefunden. "
        "Das Image wird nicht gebaut."
    )

block = r'''
BUNDLE_VERSION="$(cat /opt/comfyui-baked/.runpod-bundle-version)"
REQ_MARKER="/workspace/runpod-slim/.${BUNDLE_VERSION}-requirements-installed"

if [ ! -f "$REQ_MARKER" ]; then
    echo "=== COMFYUI REQUIREMENTS START: $BUNDLE_VERSION ==="

    python -m pip install -r "$COMFYUI_DIR/requirements.txt"

    mkdir -p "$(dirname "$REQ_MARKER")"
    touch "$REQ_MARKER"

    echo "=== COMFYUI REQUIREMENTS COMPLETE: $BUNDLE_VERSION ==="
fi
echo "=== QWEN MODEL PROVISIONING START ==="

BASE="https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main"

download_model() {
    url="$1"
    destination="$2"
    mkdir -p "$(dirname "$destination")"

    if [ -s "$destination" ]; then
        echo "Bereits vorhanden: $destination"
        return 0
    fi

    echo "DOWNLOAD START: $destination"
    tmp="${destination}.part"
    rm -f "$tmp"

    if ! curl -fL --retry 3 --progress-bar "$url" -o "$tmp"; then
        rm -f "$tmp"
        echo "FEHLER: Download fehlgeschlagen: $url"
        exit 1
    fi

    mv "$tmp" "$destination"
    echo "DOWNLOAD FERTIG: $destination"
}

download_model \
  "$BASE/diffusion_models/qwen_image_2.1_int8_convrot.safetensors" \
  "$COMFYUI_DIR/models/diffusion_models/qwen_image_2.1_int8_convrot.safetensors"

download_model \
  "$BASE/text_encoders/qwen3vl_8b_int8_convrot.safetensors" \
  "$COMFYUI_DIR/models/text_encoders/qwen3vl_8b_int8_convrot.safetensors"

download_model \
  "$BASE/text_encoders/qwen3.5_9b_qwen_image_2.1_pe_i2i.int8_convrot.safetensors" \
  "$COMFYUI_DIR/models/text_encoders/qwen3.5_9b_qwen_image_2.1_pe_i2i.int8_convrot.safetensors"

download_model \
  "$BASE/vae/qwen_image_2.1_vae_bf16.safetensors" \
  "$COMFYUI_DIR/models/vae/qwen_image_2.1_vae_bf16.safetensors"

WORKFLOW_DIR="$COMFYUI_DIR/user/default/workflows"
mkdir -p "$WORKFLOW_DIR"
cp /opt/Qwen_2.1_Image_Edit_for_Dataset.json \
   "$WORKFLOW_DIR/Qwen_2.1_Image_Edit_for_Dataset.json"

echo "WORKFLOW BEREIT: $WORKFLOW_DIR/Qwen_2.1_Image_Edit_for_Dataset.json"
echo "=== QWEN MODEL PROVISIONING COMPLETE ==="
'''

text = text.replace(marker, block + "\n" + marker, 1)
start_file.write_text(text)
print("Offizielles Startskript erfolgreich erweitert.")
