# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'



target :'BarHop' do
  # Comment the next line if you're not using Swift and don't want to use dynamic 
  use_frameworks!
  pod 'AWSMobileClient', '~> 2.6.13'
  pod 'AWSUserPoolsSignIn', '~> 2.6.13'
  pod 'AWSAuthUI', '~> 2.6.13'
  pod 'AWSDynamoDB', '~> 2.6.13'
  
  # Braintree Pods
  pod 'Braintree'
  pod 'BraintreeDropIn'
  pod 'Braintree/Venmo'
  pod 'Braintree/DataCollector'

  # Pods for BarHop
  target 'BarHopTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'BarHopUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
