# coding: utf-8

require 'libis/tools/extend/http_fetch'

class GenericSearch
  #noinspection RubyResolve
  attr_accessor :host
  #noinspection RubyResolve
  attr_reader :term, :index, :base
  #noinspection RubyResolve
  attr_reader :num_records, :set_number
  #noinspection RubyResolve
  attr_reader :record_pointer, :session_id
  
  def query(term, index, base, options = {})
    raise RuntimeError, 'to be implemented'
  end
  
  def each
    raise RuntimeError, 'to be implemented'
  end

  def next_record
    raise RuntimeError, 'to be implemented'
  end

end