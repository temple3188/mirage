class Hash
  alias_method :backup, :[]

  def [] desired_key
    result = backup(desired_key)
    return result if result
    key, value = find{|key, value| key.is_a?(Regexp) && desired_key.is_a?(String) && key.match(desired_key) }
    value
  end
end
hash = {/hello/ => 'hello', :foo => 'bar'}

#def hash.[] desired_key
#  key, value = find{|key, value| key.match(desired_key)}
#  value
#end


puts hash['hello']
puts hash[:foo]

Marshal.dump(hash)