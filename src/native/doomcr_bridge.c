#include <stdint.h>
#include "doomgeneric.h"

typedef void (*doomcr_init_cb_t)(void);
typedef void (*doomcr_draw_cb_t)(uint32_t *screen);
typedef void (*doomcr_sleep_cb_t)(uint32_t ms);
typedef uint32_t (*doomcr_ticks_cb_t)(void);
typedef int (*doomcr_get_key_cb_t)(int *pressed, unsigned char *key);
typedef void (*doomcr_title_cb_t)(const unsigned char *title);

static doomcr_init_cb_t g_init_cb = 0;
static doomcr_draw_cb_t g_draw_cb = 0;
static doomcr_sleep_cb_t g_sleep_cb = 0;
static doomcr_ticks_cb_t g_ticks_cb = 0;
static doomcr_get_key_cb_t g_get_key_cb = 0;
static doomcr_title_cb_t g_title_cb = 0;

void doomcr_set_init_callback(doomcr_init_cb_t cb) { g_init_cb = cb; }
void doomcr_set_draw_callback(doomcr_draw_cb_t cb) { g_draw_cb = cb; }
void doomcr_set_sleep_callback(doomcr_sleep_cb_t cb) { g_sleep_cb = cb; }
void doomcr_set_ticks_callback(doomcr_ticks_cb_t cb) { g_ticks_cb = cb; }
void doomcr_set_get_key_callback(doomcr_get_key_cb_t cb) { g_get_key_cb = cb; }
void doomcr_set_title_callback(doomcr_title_cb_t cb) { g_title_cb = cb; }

uint32_t *doomcr_get_screenbuffer(void) { return (uint32_t *)DG_ScreenBuffer; }

void DG_Init() {
  if (g_init_cb) {
    g_init_cb();
  }
}

void DG_DrawFrame() {
  if (g_draw_cb) {
    g_draw_cb((uint32_t *)DG_ScreenBuffer);
  }
}

void DG_SleepMs(uint32_t ms) {
  if (g_sleep_cb) {
    g_sleep_cb(ms);
  }
}

uint32_t DG_GetTicksMs() {
  if (g_ticks_cb) {
    return g_ticks_cb();
  }
  return 0;
}

int DG_GetKey(int *pressed, unsigned char *key) {
  if (g_get_key_cb) {
    return g_get_key_cb(pressed, key);
  }
  return 0;
}

void DG_SetWindowTitle(const char *title) {
  if (g_title_cb) {
    g_title_cb((const unsigned char *)title);
  }
}
