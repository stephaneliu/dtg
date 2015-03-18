class Dtg

  DTG = {
     A: 1, B: 2, C: 3, D: 4, E: 5, F: 6, G: 7, H: 8, I: 9, J: NilDtg, K: 10, L: 11, M: 12,
     N: -1, O: -2, P: -3, Q: -4, R: -5, S: -6, T: -7, U: -8, V: -9, W: -10, X: -11, Y: -12,
  }
  @@DATE_FORMATS = { :W => {:format => '%d%H%M%Z %b %y', :offset => -10, :offset_name => 'HST'},
                   :Z => {:format => '%d%H%M%Z %b %y', :offset => 0, :offset_name => 'UTC'}
                 } # only formatting from whiskey or Zulu time right now (don't introduce dst into the mix)

  @@DTG_DISPLAY_FORMATS = { :zulu => "%d%H%MZ %b %y", :whiskey => "%d%H%MW %b %y", :pc2node => "%d %b" }

  def initialize(*dates_to_parse)
    @dates_to_parse = dates_to_parse
  end

  def self.DATE_FORMATS
    @@DATE_FORMATS
  end

  def self.DTG_DISPLAY_FORMATS
    @@DTG_DISPLAY_FORMATS
  end
  
  def self.display_time(time_at, opts={})
    return nil if time_at.blank?

    time = time_at
    format = opts[:format]

    if opts[:utc] == true # display in zulu
      format ||= @@DTG_DISPLAY_FORMATS[:zulu]
    else # display in whiskey
      time = time_at.try(:localtime)
      format ||= @@DTG_DISPLAY_FORMATS[:whiskey]
    end
    time = time.strftime(format).upcase if time

    time
  end

  # Format W or Z dtg as Time Object
  # dtg - Date and time in date time group format - 202000Z JAN 09 (Jan 20, 2009 8:00 p.m. UTC)
  # set_to_utc - Return Time in UTC timezone
  # TODO - Need to set localtime based on user setting so that other time zone designators can be applied
  def format_dtg_as_time(dtg, set_to_utc=true)
    raise ArgumentError, "Unable to parse #{dtg}" if dtg.nil? || dtg.class != String
    matches = dtg.upcase.match(/(\d{2})(\d{4})\s*(Z|W)\s*([A-Z]{3})\s*(\d{2,4})/)
    raise ArgumentError, "Unable to parse #{dtg}" if matches.nil?

    day = matches[1]
    time = matches[2]
    tz = matches[3].upcase == "Z" ? 'utc' : 'local'
    month = matches[4]
    year = matches[5].to_i
    year = year + (Time.now.year / 100 * 100) if year < 100

    #                  tz, year, month, day, hour,      min
    parsed = Time.send(tz, year, month, day, time[0,2], time[2,2])

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

  def self.round_to_minutes(datetime, format=DateTime)
    format.parse(datetime.utc.strftime("%Y-%m-%d %H:%M:00"))
  end
end
