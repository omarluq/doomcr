require "time"

@[Link(ldflags: "#{__DIR__}/../../build/native/libdoomgeneric.a -lm")]
lib LibDoomGeneric
  fun doomgeneric_Create(argc : Int32, argv : Pointer(Pointer(UInt8))) : Nil
  fun doomgeneric_Tick : Nil
  fun doomcr_set_init_callback(cb : ->) : Nil
  fun doomcr_set_draw_callback(cb : Pointer(UInt32) ->) : Nil
  fun doomcr_set_sleep_callback(cb : UInt32 ->) : Nil
  fun doomcr_set_ticks_callback(cb : -> UInt32) : Nil
  fun doomcr_set_get_key_callback(cb : (Pointer(Int32), Pointer(UInt8) -> Int32)) : Nil
  fun doomcr_set_title_callback(cb : Pointer(UInt8) ->) : Nil
end

module Doomcr::Native
  @@platform : Doomcr::Platform? = nil
  @@start_time : Time::Instant = Time.instant
  @@callbacks_registered = false

  def self.prepare(platform : Doomcr::Platform)
    @@platform = platform
    reset_clock
    register_callbacks
  end

  def self.reset_clock
    @@start_time = Time.instant
  end

  def self.create(argc : Int32, argv : Pointer(Pointer(UInt8)))
    LibDoomGeneric.doomgeneric_Create(argc, argv)
  end

  def self.tick
    LibDoomGeneric.doomgeneric_Tick
  end

  def self.ticks_ms : UInt32
    elapsed_ms = (Time.instant - @@start_time).total_milliseconds
    return 0_u32 if elapsed_ms.negative?
    elapsed_ms.to_u32
  end

  def self.with_platform(&)
    platform = @@platform
    return unless platform
    yield platform
  end

  private def self.register_callbacks
    return if @@callbacks_registered

    LibDoomGeneric.doomcr_set_init_callback(->dg_init_callback)
    LibDoomGeneric.doomcr_set_draw_callback(->dg_draw_frame_callback(Pointer(UInt32)))
    LibDoomGeneric.doomcr_set_sleep_callback(->dg_sleep_ms_callback(UInt32))
    LibDoomGeneric.doomcr_set_ticks_callback(->dg_get_ticks_ms_callback)
    LibDoomGeneric.doomcr_set_get_key_callback(->dg_get_key_callback(Pointer(Int32), Pointer(UInt8)))
    LibDoomGeneric.doomcr_set_title_callback(->dg_set_window_title_callback(Pointer(UInt8)))

    @@callbacks_registered = true
  end

  private def self.dg_init_callback : Nil
    with_platform(&.dg_init)
  end

  private def self.dg_draw_frame_callback(screen : Pointer(UInt32)) : Nil
    with_platform(&.dg_draw_frame(screen))
  end

  private def self.dg_sleep_ms_callback(ms : UInt32) : Nil
    with_platform(&.dg_sleep_ms(ms))
  end

  private def self.dg_get_ticks_ms_callback : UInt32
    ticks_ms
  end

  private def self.dg_get_key_callback(pressed : Pointer(Int32), doom_key : Pointer(UInt8)) : Int32
    result = 0
    with_platform { |platform| result = platform.dg_get_key(pressed, doom_key) }
    result
  end

  private def self.dg_set_window_title_callback(title : Pointer(UInt8)) : Nil
    with_platform(&.dg_set_window_title(title))
  end
end
