# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class ClearParkExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/clear_park"

  # Please use clear_park/config/routes.rb instead for extension routes.

  # def self.require_gems(config)
  #   config.gem "gemname-goes-here", :version => '1.2.3'
  # end
  
  def activate


     AppConfiguration.class_eval do
       preference :address_requires_state, :boolean, :default => false
     end


  end
end
