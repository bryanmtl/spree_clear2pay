# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class Clear2payGatewayExtension < Spree::Extension
  version "1.0"
  description "Integration with Clear2Pay gateway. Intercepts standard checkout step."
  url "http://github.com/bryanmtl/clear2pay_gateway"

  # Please use clear2pay_gateway/config/routes.rb instead for extension routes.

  # def self.require_gems(config)
  #   config.gem "gemname-goes-here", :version => '1.2.3'
  # end
  
  def activate
    
    [
			Gateway::Clear2pay
    ].each{|gw|
      begin
        gw.register  
      rescue Exception => e
        $stderr.puts "Error registering gateway #{c_model}"
      end
    }
    
    
    AppConfiguration.class_eval do
      preference :enable_clear2pay, :boolean, :default => true
      preference :address_requires_state, :boolean, :default => true
    end
    
  
    # customize the checkout state machine
    # Checkout.state_machines[:state] = StateMachine::Machine.new(Checkout, :initial => 'address') do
    #       after_transition :to => 'complete', :do => :complete_order
    #       before_transition :to => 'complete', :do => :process_payment
    #       event :next do
    #         transition :to => 'delivery', :from  => 'address'
    #         transition :to => 'clearpay', :from => 'delivery'
    #         transition :to => 'complete', :from => 'clearpay'
    #       end
    #     end
    
    
    CheckoutsController.class_eval do
      # include this to enable Clear2pay checkout functions
      before_filter :set_clear2pay_gateway
      
      def set_clear2pay_gateway
        @clear2pay_gateway ||= Gateway.current
      end
      
    end

    # # bypass creation of address objects in the checkouts controller (prevent validation errors)
    #     CheckoutsController.class_eval do
    #       def object
    #         return @object if @object
    #         @object = parent_object.checkout
    #         unless params[:checkout] and params[:checkout][:coupon_code]
    #           @object.creditcard ||= Creditcard.new(:month => Date.today.month, :year => Date.today.year)
    #         end
    #         @object
    #       end
    #     end  
    #   end
    
    # make your helper avaliable in all views
    Spree::BaseController.class_eval do
        # helper YourHelper
        
    end
  end
end
