require_dependency 'application_helper'

module ApplicationHelper
  def calendar_for(field_id,showHours=nil)
    include_calendar_headers_tags
    javascript_tag("$(function() {" +
                      (showHours ? "datetimepickerOptions.timepicker=true; datetimepickerOptions.format='Y-m-d H:i';" : "datetimepickerOptions.timepicker=false;datetimepickerOptions.format='Y-m-d';") +
                      "datetimepickerCreate('##{field_id}');" +
                      "$('.custom_field_show_hours').click( function(){ " +
                        "if($('##{field_id}').val()=='') return;" +
                        "var asHours = $('##{field_id}').val().indexOf(':')!=-1;" +
                        "if($('#custom_field_show_hours_yes').prop('checked') && !asHours){ " +
                          "var dt = new Date();" +
                          "$('##{field_id}').val($('##{field_id}').val()+' '+(dt.getHours()<10?'0':'')+dt.getHours()+':00');" +
                        "}else if($('#custom_field_show_hours_no').prop('checked') && asHours) { " +
                          "$('##{field_id}').val($('##{field_id}').val().substr(0,10));" +
                        "} });" +
                  "});")
  end

  def include_calendar_headers_tags
    unless @calendar_headers_tags_included
      tags = javascript_include_tag('jquery.datetimepicker.js', plugin: 'redmine_datetime_custom_field') +
              stylesheet_link_tag('jquery.datetimepicker.css', plugin: 'redmine_datetime_custom_field')
      @calendar_headers_tags_included = true
      content_for :header_tags do
        start_of_week = Setting.start_of_week
        start_of_week = l(:general_first_day_of_week, :default => '1') if start_of_week.blank?
        # Redmine uses 1..7 (monday..sunday) in settings and locales
        # JQuery uses 0..6 (sunday..saturday), 7 needs to be changed to 0
        start_of_week = start_of_week.to_i % 7
        jquery_locale = l('jquery.locale', :default => current_language.to_s)
        tags << javascript_tag(
                "var datetimepickerOptions={format: 'Y-m-d', dayOfWeekStart: #{start_of_week}," +
                  "closeOnDateSelect:true," +
                  "lang:'#{jquery_locale}', id:'datetimepicker'," +
                  "onShow: function( currentDateTime ){" +
                    "if( $('#custom_field_show_hours_yes').length==0 ) return;" +
                    "this.setOptions( { format: ( $('#custom_field_show_hours_yes').prop('checked') ? 'Y-m-d H:i' : 'Y-m-d' )," +
                      "timepicker: $('#custom_field_show_hours_yes').prop('checked') } );" +
                "} };" +
                "function datetimepickerCreate(id){" +
                  "$(id).after( '<input alt=\"...\" class=\"ui-datepicker-trigger\" data-parent=\"'+id+'\" src=\"" + image_path('calendar.png') + "\" title=\"...\" type=\"image\"/>' );" +
                  "$('.ui-datepicker-trigger').click( function(){  $($(this).attr('data-parent')).trigger('focus'); return false; });" +
                  "$(id).datetimepicker(datetimepickerOptions);" +
                "}")
        tags
      end
    end
  end

  unless instance_methods.include?(:format_object_with_datetime_custom_field)
    def format_object_with_datetime_custom_field(object, html=true, &block)
      if (object.class.name=='CustomValue' || object.class.name== 'CustomFieldValue') && object.custom_field
        f = object.custom_field.format.formatted_custom_value(self, object, html)
        if f.nil? || f.is_a?(String)
          f
        else
          if f.class.name=='Time'
            format_time_without_zone(f)
          else
            format_object_without_datetime_custom_field(object, html, &block)
          end
        end
      else
        format_object_without_datetime_custom_field(object, html, &block)
      end
    end
    alias_method_chain :format_object, :datetime_custom_field
  end

  def format_time_without_zone(time, include_date = true)
    return nil unless time
    options = {}
    options[:format] = (Setting.time_format.blank? ? :time : Setting.time_format)
    options[:locale] = User.current.language unless User.current.language.blank?
    time = time.to_time if time.is_a?(String)
    # zone = User.current.time_zone
    # local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)
    (include_date ? "#{format_date(time)} " : "") + ::I18n.l(time, options)
  end

end
