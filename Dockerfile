FROM caddy:2.11.7 AS caddy

FROM runpod/comfyui:cuda12.8

# ComfyUI v0.37.0 enthält die benötigten Qwen-Image-2.1-Nodes.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git rsync ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && git clone --branch v0.37.0 --depth 1 \
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
    && printf 'qwen-comfyui-v0.37.0\n' \
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
