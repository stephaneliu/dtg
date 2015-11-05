#
# ******** When working in lib folders remember that mongrel/web_brick and script/console  ********
# ******** must be restarted in order to see changes ********
#
#
class DateTimeFormatter
  @@ZULU_DTGZONE        = { letter: 'Z', offset: '+00:00' }
  @@DEFAULT_DTGZONE     = { letter: 'Z', offset: '+00:00' }
  @@DTG_DISPLAY_FORMATS = { :zulu => "%d%H%MZ %b %y", :whiskey => "%d%H%MW %b %y", :pc2node => "%d %b" }

  def initialize(*dates_to_parse)
    @dates_to_parse = dates_to_parse
  end

  def self.DTG_DISPLAY_FORMATS
    @@DTG_DISPLAY_FORMATS
  end
  
  def self.display_time(time_at, opts={})
    return if time_at.blank?
    return if time_at.year > 2037

    time   = time_at
    format = opts[:format]

    if format.blank?
      timezone = opts[:dtg_zone] || @@DEFAULT_DTGZONE[:letter]
      timezone = @@ZULU_DTGZONE[:letter] if opts[:utc] == true
      offset   = alpha_to_offset(timezone)

      if offset.nil?
        timezone = @@DEFAULT_DTGZONE[:letter]
        offset   = @@DEFAULT_DTGZONE[:offset]
      end

      format = "%d%H%M#{timezone} %b %y"

      time = time.clone.utc
      time = Time.new(time.year, time.month, time.day, time.hour, time.min, time.sec, offset)
      time += time.gmt_offset
    end

    time.strftime(format).upcase
  end

  # Format A-I,K-Z dtg as Time Object
  # dtg - Date and time in date time group format - 202000Z JAN 09 (Jan 20, 2009 8:00 p.m. UTC)
  # set_to_utc - Return Time in UTC timezone
  # TODO - Need to set localtime based on user setting so that other time zone designators can be applied
  def format_dtg_as_time(dtg, set_to_utc=true)
    return nil unless dtg

    raise ArgumentError, "Unable to parse #{dtg}" if dtg.class != String
    matches = dtg.upcase.match(/(\d{2})(\d{4})\s*([A-IK-Z])\s*(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s*(\d{2,4})/)
    raise ArgumentError, "Unable to parse #{dtg}" if matches.nil?

    day    = matches[1]
    time   = matches[2]
    offset = DateTimeFormatter.alpha_to_offset(matches[3])
    month  = matches[4]
    year   = matches[5].to_i
    year   = year + (Time.now.year / 100 * 100) if year < 100

    # year, month, day, hour, min, 0sec, tz
    parsed = Time.new(year, month, day, time[0,2], time[2,2], 0, offset)

    # Catch Feb 29 on years with no leap year - all other invalid dates will be handled correctly
    raise ArgumentError, "Unable to parse #{dtg}" if parsed.day != day.to_i

    parsed.utc if set_to_utc
    parsed
  end

  alias_method :validate_dtg_format, :format_dtg_as_time

  # parse a string that could be either dtg or date formatted
  def self.parse_unknown_format_to_time(str)
    return nil if str.nil?

    begin
      DateTimeFormatter.new.format_dtg_as_time(str, true)
    rescue
      DateTime.parse(str).utc
    end
  end

  def self.alpha_to_offset(alpha)
    alpha = alpha.to_s.downcase if alpha.present?

    case alpha
    when 'z' then '+00:00'
    when 'a' then '+01:00'
    when 'b' then '+02:00'
    when 'c' then '+03:00'
    when 'd' then '+04:00'
    when 'e' then '+05:00'
    when 'f' then '+06:00'
    when 'g' then '+07:00'
    when 'h' then '+08:00'
    when 'i' then '+09:00'
    when 'k' then '+10:00'
    when 'l' then '+11:00'
    when 'm' then '+12:00'
    when 'n' then '-01:00'
    when 'o' then '-02:00'
    when 'p' then '-03:00'
    when 'q' then '-04:00'
    when 'r' then '-05:00'
    when 's' then '-06:00'
    when 't' then '-07:00'
    when 'u' then '-08:00'
    when 'v' then '-09:00'
    when 'w' then '-10:00'
    when 'x' then '-11:00'
    when 'y' then '-12:00'
    else nil
    end
  end

  def self.round_to_minutes(datetime, format=DateTime)
    format.parse(datetime.utc.strftime("%Y-%m-%d %H:%M:00"))
  end
end
