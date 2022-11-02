#!/usr/bin/tclsh

set parsers [dict create \
    {SD} {parse_SD} \
    {M} {parse_M}
]

# parse_packet_type --
#
# Parses the packet and retrieves it's type
# The format of the packet must be: #TP#DATA\r\n - where TP is the packet type
#
# Parameters:
#       packet -- raw packet
# Results:
#       Returns type of the specified packet, otherwise throws error
proc parse_packet_type {packet} {
    set type_pattern {^#([A-Z]+)#.+\r\n$}

    if {[regexp $type_pattern $packet all type] == 0} {
        error "Error: Packet does not match regex pattern, failed to get package type"
    }
    return $type
}

# parse_datetime --
# 
# Parses and validates input time/date string according to the specified format,
# then converts it to the new_format.
#
# Parameters:
#       datetime --     string that represents date, time or both
#       format --       clock-package-based datetime format
#       new_format --   new format of passed date/time string
# Results:
#       If valid, date/time string in new_format, otherwise empty string.
proc parse_datetime {value format new_format} {
    set parsed [clock scan $value -format $format]
    if {[string equal [clock format $parsed -format $format] $value] eq 1} {
        return [clock format $parsed -format $new_format]
    }
}

# parse_M --
#
# Parses M-type packets
#
# Parameters:
#       packet -- raw string of the M-type format
# Results:
#       Dict with keys: type, data
proc parse_M {packet} {
    # Packet example: #M#delivered
    set packet_pattern {^#M#(.+)$}

    if {[regexp $packet_pattern $packet all data] eq 0} {
        error "Error: M packet does not match regex pattern"
    }

    return [dict create \
        type "M" \
        data $data
    ]
}

# parse_SD --
#
# Parses SD-type packets
#
# Parameters:
#       packet -- raw string of the SD-type format
# Results:
#       Dict with keys: type, datetime (iso format), lat11, lat2, lon1, lon2
#       course, speed, height and stats
proc parse_SD {packet} {

    # Packet example: #SD#04012011;135515;5544.6025;N;03739.6834;E;35;215;110;7\r\n
    set packet_pattern {^#SD#([\d]{8});([\d]{6});([\d]{4}\.?[\d]{0,});([NS]);([\d]{5}\.?[\d]{0,});([EW]);([\d]+);([\d]+);([\d]+);([\d]+)\r\n$}

    if {[regexp $packet_pattern $packet all date time lat1 lat2 lon1 lon2 speed course height stats] eq 0} {
        error "Error: SD packet does not match regex pattern"
    }
    
    set parsed_date [parse_datetime $date {%d%m%Y} {%Y-%m-%d}]
    if {$parsed_date eq {}} {
            error "Error: invalid date format"
    }

    set parsed_time [parse_datetime $time {%H%M%S} {%H:%M:%S}]
    if {$parsed_time eq {}} {
        error "Error: invalid time format"
    }

    return [dict create \
        type "SD" \
        datetime "${parsed_date}T${parsed_time}" \
        lat1 [scan $lat1 {%f}] \
        lat2 $lat2 \
        lon1 [scan $lon1 {%f}] \
        lon2 $lon2 \
        speed $speed \
        course $course \
        height $height \
        stats $stats
    ]
}


# parse --
#
# Parses packets by parsers from 'parsers' global variable
#
# Parameters:
#       packet -- raw string of the certain format
# Results:
#       Dict with keys of specified packet type
proc parse {packet} {
    global parsers

    set packet_type [parse_packet_type $packet]

    if {[dict exists $parsers $packet_type] eq 0} {
        error "Package type '$packet_type' not supported"
    }

    set parser [dict get $parsers $packet_type]
    return [$parser $packet]
}


set i1 "#SD#04012011;225515;5544.6025;N;03739.221231232;E;35;215;110;7\r\n"
set i2 "#M#Hello qwdqpwkpdoqkwpdok qwpodk123 12\r\n"

set sd_data [parse $i1]
set m_data [parse $i2]

puts "SD PACKET\n--------"
foreach id [dict keys $sd_data] {
    puts "$id: [dict get $sd_data $id]"
}

puts "\nM PACKET\n--------"
foreach id [dict keys $m_data] {
    puts "$id: [dict get $m_data $id]"
}