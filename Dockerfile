FROM caddy:2.11.7 AS caddy

FROM runpod/comfyui:cuda12.8

COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy

COPY patch_start.py /opt/patch_start.py
COPY entrypoint.sh /opt/entrypoint.sh
COPY Caddyfile.template /opt/Caddyfile.template
COPY landing.html /opt/landing.html
COPY Qwen_2.1_Image_Edit_for_Dataset.json /opt/Qwen_2.1_Image_Edit_for_Dataset.json

RUN python /opt/patch_start.py /start.sh \
    && chmod +x /start.sh /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
