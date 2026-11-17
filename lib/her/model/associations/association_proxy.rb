module Her
  module Model
    module Associations
      # Inherits from Ruby's ::BasicObject rather than ActiveSupport::ProxyObject
      # (deprecated in Rails 7.2, removed in 8.0) or ActiveSupport::BasicObject
      # (removed in Rails 4.1), so it behaves the same on every Rails version.
      class AssociationProxy < ::BasicObject
        # ActiveSupport::ProxyObject undefined these so they reach method_missing
        # and are forwarded to the fetched object.
        undef_method :==, :equal?

        # BasicObject has no #raise; keep the one ProxyObject provided.
        def raise(*args)
          ::Object.send(:raise, *args)
        end

        # @private
        def self.install_proxy_methods(target_name, *names)
          names.each do |name|
            module_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}(*args, &block)
                #{target_name}.send(#{name.inspect}, *args, &block)
              end
            RUBY
          end
        end

        install_proxy_methods :association,
                              :build, :create, :where, :find, :all, :assign_nested_attributes, :reload

        # @private
        def initialize(association)
          @_her_association = association
        end

        def association
          @_her_association
        end

        # @private
        def method_missing(name, *args, &block)
          if name == :object_id # avoid redefining object_id
            return association.fetch.object_id
          end

          # create a proxy to the fetched object's method
          AssociationProxy.install_proxy_methods 'association.fetch', name

          # resend message to fetched object
          __send__(name, *args, &block)
        end
      end
    end
  end
end
