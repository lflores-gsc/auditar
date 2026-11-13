# frozen_string_literal: true

# Compatibility patch for json >= 3.0.0 with Rails / ActiveSupport::JSON.decode,
# which passes an options Hash positionally as the second argument to JSON.parse.
module Json3PositionalOptsCompatibility
  def parse(source, opts = nil, **kwargs)
    merged = {}
    merged.merge!(opts.transform_keys(&:to_sym)) if opts.is_a?(Hash)
    merged.merge!(kwargs)
    merged.delete(:quirks_mode) if defined?(JSON::VERSION) && JSON::VERSION >= "3.0"
    super(source, **merged)
  end

  def unsafe_load(source, proc = nil, opts = nil, **kwargs)
    if proc.is_a?(Hash) && opts.nil?
      opts = proc
      proc = nil
    end
    merged = {}
    merged.merge!(opts.transform_keys(&:to_sym)) if opts.is_a?(Hash)
    merged.merge!(kwargs)
    merged.delete(:quirks_mode) if defined?(JSON::VERSION) && JSON::VERSION >= "3.0"
    super(source, proc, **merged)
  end
end

JSON.singleton_class.prepend(Json3PositionalOptsCompatibility)

