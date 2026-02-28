require "termisu"
require "time"

record Doomcr::KeyEvent, pressed : Int32, key : UInt8

class Doomcr::Platform
  HALF_BLOCK        = '▀'
  KEY_RELEASE_DELAY = 75.milliseconds
  KEY_MAP           = {
    Termisu::Input::Key::Enter     => Doomcr::DoomKeys::KEY_ENTER,
    Termisu::Input::Key::Escape    => Doomcr::DoomKeys::KEY_ESCAPE,
    Termisu::Input::Key::Tab       => Doomcr::DoomKeys::KEY_TAB,
    Termisu::Input::Key::BackTab   => Doomcr::DoomKeys::KEY_TAB,
    Termisu::Input::Key::Backspace => Doomcr::DoomKeys::KEY_BACKSPACE,
    Termisu::Input::Key::Up        => Doomcr::DoomKeys::KEY_UPARROW,
    Termisu::Input::Key::Down      => Doomcr::DoomKeys::KEY_DOWNARROW,
    Termisu::Input::Key::Left      => Doomcr::DoomKeys::KEY_LEFTARROW,
    Termisu::Input::Key::Right     => Doomcr::DoomKeys::KEY_RIGHTARROW,
    Termisu::Input::Key::Home      => Doomcr::DoomKeys::KEY_HOME,
    Termisu::Input::Key::End       => Doomcr::DoomKeys::KEY_END,
    Termisu::Input::Key::PageUp    => Doomcr::DoomKeys::KEY_PGUP,
    Termisu::Input::Key::PageDown  => Doomcr::DoomKeys::KEY_PGDN,
    Termisu::Input::Key::Insert    => Doomcr::DoomKeys::KEY_INS,
    Termisu::Input::Key::Delete    => Doomcr::DoomKeys::KEY_DEL,
    Termisu::Input::Key::F1        => Doomcr::DoomKeys::KEY_F1,
    Termisu::Input::Key::F2        => Doomcr::DoomKeys::KEY_F2,
    Termisu::Input::Key::F3        => Doomcr::DoomKeys::KEY_F3,
    Termisu::Input::Key::F4        => Doomcr::DoomKeys::KEY_F4,
    Termisu::Input::Key::F5        => Doomcr::DoomKeys::KEY_F5,
    Termisu::Input::Key::F6        => Doomcr::DoomKeys::KEY_F6,
    Termisu::Input::Key::F7        => Doomcr::DoomKeys::KEY_F7,
    Termisu::Input::Key::F8        => Doomcr::DoomKeys::KEY_F8,
    Termisu::Input::Key::F9        => Doomcr::DoomKeys::KEY_F9,
    Termisu::Input::Key::F10       => Doomcr::DoomKeys::KEY_F10,
    Termisu::Input::Key::F11       => Doomcr::DoomKeys::KEY_F11,
    Termisu::Input::Key::F12       => Doomcr::DoomKeys::KEY_F12,
    Termisu::Input::Key::Space     => Doomcr::DoomKeys::KEY_FIRE,
  } of Termisu::Input::Key => UInt8

  getter? quit_requested = false
  getter termisu : Termisu

  @keys = Deque(KeyEvent).new
  @color_cache = Hash(UInt32, Termisu::Color).new
  @pending_releases = Hash(UInt8, Time::Instant).new

  def initialize
    @termisu = Termisu.new(sync_updates: false)
    @termisu.hide_cursor
    @termisu.clear
    @termisu.render
  end

  def close
    @termisu.close
  end

  def dg_init
    # Already initialized in constructor.
  end

  def dg_draw_frame(screen : Pointer(UInt32))
    pump_events
    render_frame(screen)
  end

  def dg_sleep_ms(ms : UInt32)
    sleep ms.milliseconds
  end

  def dg_get_key(pressed : Pointer(Int32), doom_key : Pointer(UInt8)) : Int32
    pump_events
    key = @keys.shift?
    return 0 unless key

    pressed.value = key.pressed
    doom_key.value = key.key
    1
  end

  def dg_set_window_title(title_ptr : Pointer(UInt8))
    return if title_ptr.null?

    # Keep behavior compatible with DoomGeneric without terminal title writes.
    _title = String.new(title_ptr)
  end

  private def pump_events
    flush_pending_releases

    while event = @termisu.try_poll_event
      case event
      when Termisu::Event::Key
        handle_key(event)
      when Termisu::Event::Resize
        @termisu.sync
      end
    end

    flush_pending_releases
  end

  private def handle_key(event : Termisu::Event::Key)
    if event.ctrl_c? || event.ctrl_q?
      @quit_requested = true
      return
    end

    if doom_key = map_key(event)
      queue_press(doom_key)
    end
  end

  private def map_key(event : Termisu::Event::Key) : UInt8?
    if mapped = KEY_MAP[event.key]?
      return mapped
    end

    if char = event.char
      return unless char.ascii?
      lower = char.downcase
      return Doomcr::DoomKeys::KEY_FIRE if lower == 'f'
      return Doomcr::DoomKeys::KEY_USE if lower == 'e'
      return lower.ord.to_u8
    end

    nil
  end

  private def queue_press(doom_key : UInt8)
    @keys << KeyEvent.new(1, doom_key)
    @pending_releases[doom_key] = Time.instant + KEY_RELEASE_DELAY
  end

  private def flush_pending_releases
    now = Time.instant
    expired = [] of UInt8

    @pending_releases.each do |key, deadline|
      next if now < deadline

      @keys << KeyEvent.new(0, key)
      expired << key
    end

    expired.each { |key| @pending_releases.delete(key) }
  end

  private def render_frame(screen : Pointer(UInt32))
    term_width, term_height = @termisu.size
    return if term_width <= 0 || term_height <= 0

    src_w = Doomcr::DOOMGENERIC_WIDTH
    src_h = Doomcr::DOOMGENERIC_HEIGHT

    x_scale = src_w.to_f / term_width
    y_scale = src_h.to_f / (term_height * 2)

    term_height.times do |y|
      src_top = (((y * 2) + 0.5) * y_scale).to_i.clamp(0, src_h - 1)
      src_bottom = (((y * 2) + 1.5) * y_scale).to_i.clamp(0, src_h - 1)

      term_width.times do |x|
        src_x = ((x + 0.5) * x_scale).to_i.clamp(0, src_w - 1)
        top = screen[(src_top * src_w) + src_x]
        bottom = screen[(src_bottom * src_w) + src_x]

        @termisu.set_cell(
          x,
          y,
          HALF_BLOCK,
          fg: color_for(top),
          bg: color_for(bottom),
        )
      end
    end

    @termisu.render
  end

  private def color_for(pixel : UInt32) : Termisu::Color
    rgb = pixel & 0x00ff_ffff_u32
    @color_cache[rgb] ||= begin
      r = ((rgb >> 16) & 0xff).to_i
      g = ((rgb >> 8) & 0xff).to_i
      b = (rgb & 0xff).to_i
      Termisu::Color.rgb(r, g, b)
    end
  end
end
