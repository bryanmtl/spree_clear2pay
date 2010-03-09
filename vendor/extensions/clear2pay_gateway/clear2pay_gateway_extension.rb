# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class Clear2payGatewayExtension < Spree::Extension
  version "1.0"
  description "Integration with Clear2Pay gateway. Added as a payment method"
  url "http://github.com/bryanmtl/clear2pay_gateway"

  def activate
    
    PaymentMethod::ClearPay.register    
        
    # inject paypal code into orders controller
    CheckoutsController.class_eval do
      include Spree::ClearPay
    end

    # probably not needed once the payments mech is generalised
    # Order.class_eval do
    #       has_many :clear_2_pay_payments
    #     end

    
    
    # make your helper avaliable in all views
    Spree::BaseController.class_eval do
        # helper YourHelper
        
    end
  end
end
