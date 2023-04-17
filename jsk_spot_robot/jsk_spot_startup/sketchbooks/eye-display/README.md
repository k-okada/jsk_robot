# eye_display

Install PlatformIO first.

Use https://www.switch-science.com/products/8098

## Build and burn

```bash
roscd jsk_spot_startup/sketchbooks/eye-display
pio run --target uploadfs --upload-port <port to display>
pio run --target upload --upload-port <port to display>
```
