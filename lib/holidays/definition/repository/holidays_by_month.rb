module Holidays
  module Definition
    module Repository
      class HolidaysByMonth
        def initialize
          @holidays_by_month = {}
        end

        def all
          @holidays_by_month
        end

        def find_by_month(year, month)
          raise ArgumentError unless month >= 0 && month <= 12

          holidays = @holidays_by_month[month] || []
          holidays.concat(find_lunar_holidays_by_month(year, month))
        end

        def add(new_holidays)
          new_holidays.each do |month, holiday_defs|
            @holidays_by_month[month] = [] unless @holidays_by_month[month]

            holiday_defs.each do |holiday_def|
              exists = false
              @holidays_by_month[month].each do |existing_def|
                if definition_exists?(existing_def, holiday_def)
                  # append regions
                  existing_def[:regions] << holiday_def[:regions]

                  # Should do this once we're done
                  existing_def[:regions].flatten!
                  existing_def[:regions].uniq!
                  exists = true
                end
              end

              @holidays_by_month[month] << holiday_def unless exists
            end
          end
        end

        private

        def find_lunar_holidays_by_month(year, solar_month)
          lunar_holidays = []
          @holidays_by_month.each_pair{|month, holidays|
            lunar_holidays << holidays.filter{ |h|
              is_lunar_holiday?(h) &&
              get_solar_month(year, month, h[:mday], h[:regions].first) == solar_month
            }
          }
          lunar_holidays.flatten!
        end

        def is_lunar_holiday?(holiday)
          holiday[:function] == "lunar_to_solar(year, month, day, region)"
        end

        def get_solar_month(year, month, day, region)
          Holidays::DateCalculator::LunarDate.new.to_solar(
            year, month, day, region
          ).month
        end

        def definition_exists?(existing_def, target_def)
          existing_def[:name] == target_def[:name] &&
          existing_def[:wday] == target_def[:wday] &&
          existing_def[:mday] == target_def[:mday] &&
          existing_def[:week] == target_def[:week] &&
          existing_def[:function] == target_def[:function] &&
          existing_def[:function_modifier] == target_def[:function_modifier] &&
          existing_def[:type] == target_def[:type] &&
          existing_def[:observed] == target_def[:observed] &&
          existing_def[:year_ranges] == target_def[:year_ranges]
        end
      end
    end
  end
end
