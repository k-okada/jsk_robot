#if 0
#include <Adafruit_NeoPixel.h>

int Power = 11;
int PIN = 12;
#define NUMPIXELS 1

Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_RGB + NEO_KHZ800);
#endif

// On ESP32, ros.h need to be fixed see https://github.com/espressif/arduino-esp32/issues/4807
#include <ros.h>
#include <sensor_msgs/CompressedImage.h>

// https://arduino-esp8266.readthedocs.io/en/latest/filesystem.html
#include <LittleFS.h>

// https://github.com/Bodmer/TJpg_Decoder
#include <TJpg_Decoder.h>

// https://github.com/moononournation/Arduino_GFX/
#include <Arduino_GFX_Library.h>

/* Adafruit HUZZAH32 ESP32 Feather
https://www.instructables.com/ArduinoGFX/
DIN 23
CLK 18
CS   5
DC  27
RST 33
BL  22
 */

// https://github.com/moononournation/Arduino_GFX/wiki/Data-Bus-Class#spi
Arduino_DataBus *bus = new Arduino_ESP32SPI(27 /* DC */, 5 /* CS */, 18 /* SCK */, 23 /* MOSI */, GFX_NOT_DEFINED /* MISO */, VSPI /* spi_num */);

// https://github.com/moononournation/Arduino_GFX/wiki/Data-Bus-Class#spi
Arduino_GFX *gfx = new Arduino_GC9A01(bus, 33 /* RST */, 0 /* rotation */, true /* IPS */);

// more fonts at: https://github.com/moononournation/ArduinoFreeFontFile.git
#include "FreeSansBold10pt7b.h"

//
uint16_t hsi2rgb(int h, int i, float s);

//
#include <vector>
class BitmapImage
{
 public:
  BitmapImage() {
  }

  String filename;
  uint16_t width;
  uint16_t height;
  //uint16_t buffer[240*240];
  //uint16_t *buffer PROGMEM;
};

typedef std::vector<BitmapImage> ImageList;
ImageList images;

// https://answers.ros.org/question/208079/rosserial-arduino-custom-message-message-larger-than-buffer/
// <MAX_SUBSCRIBERS, MAX_PUBLISHERS, INPUT_SIZE, OUTPUT_SIZE>
//ros::NodeHandle_<ArduinoHardware, 10, 10, 32768, 32768> nh;  // 32768 = 128 * 256
ros::NodeHandle nh;

void imageCb(const sensor_msgs::CompressedImage& msg) {
  char log[255];
  sprintf(log, "cb %s %d", msg.format, msg.data_length);
  nh.loginfo(log);
  TJpgDec.drawFsJpg(0, 0, msg.format, LittleFS);
}

ros::Subscriber<sensor_msgs::CompressedImage> sub("image/compressed", &imageCb);

//
uint16_t* image_buf;
uint16_t image_width = 0;
bool output(int16_t x, int16_t y, uint16_t w, uint16_t h, uint16_t* bitmap)
{
#if 0
  //image_buf = new uint16_t[w*h];
  char txt[256];
  sprintf(txt, "%p : %d : %d %d %d %d", image_buf, image_width, x, y, w, h);
  gfx->println(txt);
  for(int i = 0; i < h; i++) {
    for(int j = 0; j < w; j++) {
      image_buf[(y+i)*image_width+(x+j)] = bitmap[i*w+j];
    }
  }
#endif
  gfx->draw16bitRGBBitmap(x, y, bitmap, w, h);

  // Return 1 to decode next block
  return 1;
}

void setup()
{
  // Initialize ROS
  nh.initNode();
  nh.subscribe(sub);
  nh.loginfo(".. initialized ROS");

  // Setup LED
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);
  nh.loginfo(".. initialized LED");

  // Setup GFX
  gfx->begin();
  gfx->fillScreen(BLACK);

#ifdef GFX_BL
  pinMode(GFX_BL, OUTPUT);
  digitalWrite(GFX_BL, HIGH);
#endif

  gfx->setFont(&FreeSansBold10pt7b);
  gfx->setTextColor(WHITE);
  gfx->setCursor(0,120+4);
  nh.loginfo(".. initialized GFX");

  // Setup LittleFS
  if (!LittleFS.begin()) {
    gfx->setTextColor(RED);
    gfx->setCursor(10,120-5);
    gfx->println("File System Mount Failed!");
    nh.logerror("File System Mount Failed!");
    return;
  }

  // list up images
  File root = LittleFS.open("/");
  File file = root.openNextFile();
  while ( file ) {
    if ( file.isDirectory() ) { continue; }
    BitmapImage image;
    image.filename = String(file.name());
    images.push_back(image);
    file = root.openNextFile();
  }
  root.close();
  nh.loginfo(".. initialized LittleFS");
  // get image size, store bitmap data
  nh.loginfo(".. loading...");
  TJpgDec.setJpgScale(1);
  TJpgDec.setCallback(output);
  gfx->setCursor(0,120);
  for (ImageList::iterator it = images.begin(); it != images.end(); it++ ) {
    char filename[256];
    sprintf(filename, "/%s", it->filename.c_str());
    gfx->println(filename);
    TJpgDec.getFsJpgSize(&it->width, &it->height, filename, LittleFS);
    //it->buffer = (uint16_t *)malloc(sizeof(uint16_t)*it->width*it->height);
    //it->buffer = buffer;
#if 0
    if ( it->buffer == nullptr) {
      gfx->setTextColor(RED);
      gfx->setCursor(10,120-5);
      gfx->println("malloc failed");
      nh.logerror("malloc failed");
      return;
    }
#endif
    //image_buf = it->buffer;
    //image_width = it->width;
    // use drawFsJpg to store bitmap buffer to images
    //TJpgDec.drawFsJpg(0, 0, filename, LittleFS);
  }
  // display
  for(int y = 240; y > (int)(images.size())*-20; y-=4) {
    gfx->fillScreen(BLACK);
    gfx->setCursor(0,y);
    for (ImageList::iterator it = images.begin(); it != images.end(); it++ ) {
      const char* message = String(it->filename + " " + String(it->width) + ", " + String(it->height)).c_str();
      gfx->println(message);
      nh.loginfo(message);
    }
  }

  // Show initial demonstration
  for(int r = 120; r >= 0; r-=1) {
    uint16_t rgb = hsi2rgb(240*pow(r/120.0, 2), 255, 1);
    gfx->drawCircle(120, 120, r, rgb);
  }
#if 0
  int rgb = 0x0000;
  char rgb_text[32];
  for(unsigned int r = 0; r < 256; r+=63) {
    for(unsigned int g = 0; g < 256; g+=63) {
      for(unsigned int b = 0; b < 256; b+=63) {
	rgb = ((r>>3) << 11) + ((g>>2) << 5) + (b>>3);
	gfx->fillScreen(rgb);
	gfx->setCursor(120-10*2,120-5);
	sprintf(rgb_text, "%04X", rgb);
	gfx->println(rgb_text);
	yield();
      }
    }
  }
#endif
  gfx->fillScreen(BLACK);

  // send dummy compressed image
  sensor_msgs::CompressedImage msg = sensor_msgs::CompressedImage();
  msg.format = "/ubuntu-logo-icon.jpg";
  imageCb((const sensor_msgs::CompressedImage &)msg);
}

static int loop_count = 0;
void loop()
{
  loop_count += 1;
  // Blink LED
  if (loop_count % 10000 == 0) {
    digitalWrite(13, HIGH-digitalRead(13));
    nh.loginfo("loop");
  }

#if 0
  pixels.clear();
  pixels.setPixelColor(0, pixels.Color(15, 15, 205));
  delay(400);
  pixels.show();

  pixels.clear();
  pixels.setPixelColor(0, pixels.Color(15, 205, 15));
  delay(400);
  pixels.show();

  pixels.clear();
  pixels.setPixelColor(0, pixels.Color(205, 15, 15));
  delay(400);
  pixels.show();
#endif

  // ROS Spinning...
  nh.spinOnce();
}

// hsi -> rgb
uint16_t hsi2rgb(int h, int i, float s) {
  // 0 <= h < 360, 0 <= i < 256, 0 <= s <= 1
  int r, g, b;
  float hh = h / 180.0 * M_PI;
  if ( h < 120) {
    r = i + i * s * cos(hh) / cos(M_PI/3 - hh);
    g = i + i * s * (1 - (cos(hh) / cos(M_PI/3 - hh)));
    b = i - i * s;
  } else if ( h < 240 ) {
    r = i - i * s;
    g = i + i * s * cos(hh-M_PI*2/3) / cos(M_PI - hh);
    b = i + i * s * (1 - (cos(hh-M_PI*2/3) / cos(M_PI - hh)));
  } else {
    r = i + i * s * (1 - (cos(hh-M_PI*4/3) / cos(M_PI*5/3 - hh)));
    g = i - i * s;
    b = i + i * s * cos(hh-M_PI*4/3) / cos(M_PI*5/3 - hh);
  }
  if ( r > 255 ) r = 255; if ( r < 0 ) r = 0;
  if ( g > 255 ) g = 255; if ( g < 0 ) g = 0;
  if ( b > 255 ) b = 255; if ( b < 0 ) b = 0;
  //
  return ((r>>3) << 11) + ((g>>2) << 5) + (b>>3);
}
