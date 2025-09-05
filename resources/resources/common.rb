# Cookbook:: cape
# Resource:: config

actions :add, :remove
default_action :add

attribute :s3_prefix, kind_of: String, default: 'rbdata'
attribute :s3_service, kind_of: String, default: 's3.service'
attribute :s3_port, kind_of: Integer, default: 9000
attribute :s3_secrets, kind_of: Hash, default: {}
