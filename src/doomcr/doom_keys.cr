module Doomcr::DoomKeys
  KEY_RIGHTARROW = 0xae_u8
  KEY_LEFTARROW  = 0xac_u8
  KEY_UPARROW    = 0xad_u8
  KEY_DOWNARROW  = 0xaf_u8
  KEY_STRAFE_L   = 0xa0_u8
  KEY_STRAFE_R   = 0xa1_u8
  KEY_USE        = 0xa2_u8
  KEY_FIRE       = 0xa3_u8

  KEY_ESCAPE    =   27_u8
  KEY_ENTER     =   13_u8
  KEY_TAB       =    9_u8
  KEY_BACKSPACE = 0x7f_u8

  KEY_EQUALS = 0x3d_u8
  KEY_MINUS  = 0x2d_u8

  KEY_F1  = (0x80 + 0x3b).to_u8
  KEY_F2  = (0x80 + 0x3c).to_u8
  KEY_F3  = (0x80 + 0x3d).to_u8
  KEY_F4  = (0x80 + 0x3e).to_u8
  KEY_F5  = (0x80 + 0x3f).to_u8
  KEY_F6  = (0x80 + 0x40).to_u8
  KEY_F7  = (0x80 + 0x41).to_u8
  KEY_F8  = (0x80 + 0x42).to_u8
  KEY_F9  = (0x80 + 0x43).to_u8
  KEY_F10 = (0x80 + 0x44).to_u8
  KEY_F11 = (0x80 + 0x57).to_u8
  KEY_F12 = (0x80 + 0x58).to_u8

  KEY_RSHIFT = (0x80 + 0x36).to_u8
  KEY_RCTRL  = (0x80 + 0x1d).to_u8
  KEY_RALT   = (0x80 + 0x38).to_u8
  KEY_LALT   = KEY_RALT

  KEY_HOME = (0x80 + 0x47).to_u8
  KEY_END  = (0x80 + 0x4f).to_u8
  KEY_PGUP = (0x80 + 0x49).to_u8
  KEY_PGDN = (0x80 + 0x51).to_u8
  KEY_INS  = (0x80 + 0x52).to_u8
  KEY_DEL  = (0x80 + 0x53).to_u8
end
