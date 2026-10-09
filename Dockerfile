FROM caddy:2.11.7 AS caddy

FROM runpod/comfyui:cuda12.8

RUN apt-get update \
    && apt-get install -y --no-install-recommends git rsync ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && COMFYUI_VERSION="$(curl -fsSL https://api.github.com/repos/Comfy-Org/ComfyUI/releases/latest | python3.12 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')" \
    && echo "Baue ComfyUI-Version: ${COMFYUI_VERSION}" \
    && git clone --branch "${COMFYUI_VERSION}" --depth 1 \
       https://github.com/Comfy-Org/ComfyUI.git /tmp/comfyui-upstream \
    && rsync -a --delete \
       --exclude='/.runpod-bundle-version' \
       --exclude='/custom_nodes/' \
       --exclude='/models/' \
       --exclude='/input/' \
       --exclude='/output/' \
       --exclude='/user/' \
       --exclude='/extra_model_paths.yaml' \
       --exclude='/.venv*' \
       /tmp/comfyui-upstream/ /opt/comfyui-baked/ \
    && printf 'qwen-comfyui-%s\n' "${COMFYUI_VERSION}" \
       > /opt/comfyui-baked/.runpod-bundle-version \
    && rm -rf /tmp/comfyui-upstream

COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy

COPY patch_start.py /opt/patch_start.py
COPY entrypoint.sh /opt/entrypoint.sh
COPY Caddyfile.template /opt/Caddyfile.template
COPY landing.html /opt/landing.html
COPY Qwen_2.1_Image_Edit_for_Dataset.json /opt/Qwen_2.1_Image_Edit_for_Dataset.json

RUN python3.12 /opt/patch_start.py /start.sh \
    && chmod +x /start.sh /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
