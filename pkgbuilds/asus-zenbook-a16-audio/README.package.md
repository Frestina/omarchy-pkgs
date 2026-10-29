# asus-zenbook-a16-audio

Speakers and microphones for the ASUS Zenbook A16 (UX3607OA, Snapdragon X2 Elite / Glymur).

Without it the `snd-x1e80100` card fails to probe:

```
qcom-apm gprsvc:service:2:1: tplg firmware loading qcom/glymur/GLYMUR-ASUS-Zenbook-A16-UX3607OA-tplg.bin failed -2
snd-x1e80100 sound: ASoC: failed to instantiate card -2
```

so there is no ALSA card and PipeWire only offers a dummy output.

The board's device tree has the same two audio links as Qualcomm's Glymur CRD: four WSA884x speakers (woofer and tweeter, left and right) on `WSA_CODEC_DMA_RX_0`, and two DMICs on `VA_CODEC_DMA_TX_0`. Those are exactly the backends the CRD topology defines, and the CRD UCM profile drives four WSA884x speakers. This package links the board names to the CRD files:

- `/usr/lib/firmware/qcom/glymur/GLYMUR-ASUS-Zenbook-A16-UX3607OA-tplg.bin` → `GLYMUR-CRD-tplg.bin` (linux-firmware-qcom)
- `/usr/share/alsa/ucm2/conf.d/glymur/ASUSTeKCOMPUTERINC.-ZenbookA16UX3607OA-1.0-UX3607OA.conf` → `Qualcomm/glymur/GLYMUR-CRD.conf` (alsa-ucm-conf)

The kernel requests the topology by the device tree's model, while UCM looks the profile up by the card's long name, which the kernel builds from DMI (`board_vendor-product_name-product_version-board_name`, stripped of spaces).

## Retirement

Drop it once linux-firmware ships a Zenbook A16 topology and alsa-ucm-conf a Zenbook A16 profile; the files would conflict.
