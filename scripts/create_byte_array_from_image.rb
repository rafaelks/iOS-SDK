require 'stringio'

output_string = StringIO.new
output_string << "char image[] = { "

File.open(ARGV[0]) do |file|
  file.each_byte do |byte|
    hex = byte.to_s(16)
    output_string << "0x"
    output_string << "0" if hex.size == 1
    output_string << hex
    output_string << ", "
  end
end

output_string.seek(output_string.size - 2)
output_string << " };"
puts output_string.string
