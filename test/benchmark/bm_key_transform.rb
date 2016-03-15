require_relative './benchmarking_support'
require 'railtie/rails'
require 'active_model_serializers'
require 'active_model_serializers/key_transform'
require_relative './fixtures'

time = 10
disable_gc = true
ActiveModelSerializers.config.key_transform = :unaltered
comments = (0..50).map do |i|
  Comment.new(id: i, body: 'ZOMG A COMMENT')
end
author = Author.new(id: 42, name: 'Joao Moura.')
post = Post.new(id: 1337, title: 'New Post', blog: nil, body: 'Body', comments: comments, author: author)
serializer_instance = PostSerializer.new(post)
adapter = ActiveModelSerializers::Adapter::JsonApi.new(serializer)
serialization = adapter.as_json

Benchmark.ams('unaltered', time: time, disable_gc: disable_gc) do
  ActiveModelSerializers::KeyTransform.unaltered(serialization)
end

Benchmark.ams('dasherize', time: time, disable_gc: disable_gc) do
  ActiveModelSerializers::KeyTransform.dashed(serialization)
end

Benchmark.ams('camel', time: time, disable_gc: disable_gc) do
  ActiveModelSerializers::KeyTransform.camel(serialization)
end

Benchmark.ams('camel_lower', time: time, disable_gc: disable_gc) do
  ActiveModelSerializers::KeyTransform.camel_lower(serialization)
end
