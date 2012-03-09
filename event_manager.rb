require "csv"
require "sunlight"

class EventManager
  INVALID_ZIPCODE = "00000"
  Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

  def initialize(filename="event_attendees.csv")
    puts "EventManager Initialized."
    @file = CSV.open(filename, {:headers => true, :header_converters => :symbol})
  end

  def print_names
    @file.each do |line|
      puts "#{line[:first_name]} #{line[:last_name]}"
    end
  end

  def print_numbers
    @file.each do |line|
      puts clean_number(line[:homephone])
    end
  end

  def clean_number(number)
    number = number.gsub(/[^\d]/, '')
    if number.length == 10
      number
    elsif number.length == 11
      if number.start_with?("1")
        number = number[1..-1]
      else
        number = "0000000000"
      end
    else
      number = "0000000000"
    end
  end

  def print_zipcodes
    @file.each do |line|
      zipcode = clean_zipcode(line[:zipcode])
      puts zipcode
    end
  end

  def clean_zipcode(zipcode)
    zipcode = INVALID_ZIPCODE + zipcode.to_s
    zipcode[-5,5]
  end

  def output_data(filename = "event_attendees_clean.csv")
    output = CSV.open(filename, "w")
    puts @file.lineno
    @file.each do |line|
      puts @file.lineno
      if @file.lineno == 2
        output << line.headers
      end
      line[:homephone] = clean_number(line[:homephone])
      line[:zipcode] = clean_zipcode(line[:zipcode])
      output << line
    end
  end

  def rep_lookup
    20.times do
      line = @file.readline
      legislators = Sunlight::Legislator.all_in_zipcode(clean_zipcode(line[:zipcode]))
      
      names = legislators.collect do |leg|
        first_name = leg.firstname
        first_initial = first_name[0]
        last_name = leg.lastname
        party = leg.party
        title = leg.title
        "#{title} #{first_initial}. #{last_name} (#{party})"
      end

      puts "#{line[:last_name]}, #{line[:first_name]}, #{line[:zipcode]}, #{names.join(", ")}"
    end
  end

  def create_form_letters
    letter = File.open("form_letter.html", "r").read
    20.times do
      line = @file.readline

      custom_letter = letter.gsub("#first_name",line[:first_name])
      custom_letter = custom_letter.gsub("#last_name",line[:last_name])
      custom_letter = custom_letter.gsub("#street", line[:street])
      custom_letter = custom_letter.gsub("#city", line[:city])
      custom_letter = custom_letter.gsub("#state", line[:state])
      custom_letter = custom_letter.gsub("#zipcode", clean_zipcode(line[:zipcode]))

      filename = "output/thanks_#{line[:last_name]}_#{line[:first_name]}"
      output = File.new(filename, "w")
      output.write(custom_letter)
    end
  end

  def rank_times
    hours = Array.new(24){0}
    count = 0
    @file.each do |line|
      time = line[:regdate].split(" ")[1] #get time from registrant csv
      hour = time.split(":")[0] #get hour of time, which is separated by :
      hours[hour.to_i] = hours[hour.to_i] + 1
      count += 1
    end

    # SANITY CHECK: Make sure that there are 5175 attendees
    # puts count
    # sum = 0
    # hours.each do |val|
    #   sum += val
    #   puts "Total sum is: #{sum}"
    # end

    hours.each_with_index{|counter,hour| puts "#{hour}\t#{counter}"}
  end

  def day_stats
    days = Array.new(7){0}
    @file.each do |line|
      rawdate = line[:regdate].split(" ")[0]
      weekday = Date.strptime(rawdate, "%m/%d/%y").wday
      days[weekday] = days[weekday] + 1
    end

    days.each_with_index{|counter,day| puts "#{day}\t#{counter}"}
  end

  def state_stats
    state_data = {}
    @file.each do |line|
      state = line[:state]
      if state_data[state].nil?
        state_data[state] = 1
      else state_data[state] = state_data[state] + 1
      end
    end

    # state_data = state_data.sort_by{|state, counter| counter}

    # state_data.each do |state, counter|
    #   puts "#{state}: \t #{counter}"

    ranks = state_data.sort_by{|state, counter| counter}.collect{|state, counter| state}.reverse
    state_data = state_data.sort_by{|state, counter| state || ""}

    state_data.each do |state, counter|
      puts "#{state}:\t#{counter}\t(#{ranks.index(state) + 1})"
    end
  end

end

manager = EventManager.new("event_attendees.csv")
#manager.output_data("event_attendees_clean.csv")
manager.state_stats