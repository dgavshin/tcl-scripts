#!/usr/bin/tclsh

set data [expr 0x5FABFF01]

puts "Input: [format "0b%b" [expr $data]]"

set second_byte [expr ($data >> 8 * 1) & 0xff]
set inversed_seventh_bit [expr !(($data & 0xff) >> 7)]
set mirrored_17_20_bits [expr \
    (($data >> 17) & 1) << 3 | \
    (($data >> 18) & 1) << 2 | \
    (($data >> 19) & 1) << 1 | \
    ($data >> 20) & 1
]

puts "2nd byte: [format "0b%b" $second_byte]"
puts "Inversed 7th bit: [format "0b%b" $inversed_seventh_bit]"
puts "Mirrored 17-20 bits: [format "0b%b" $mirrored_17_20_bits]"
