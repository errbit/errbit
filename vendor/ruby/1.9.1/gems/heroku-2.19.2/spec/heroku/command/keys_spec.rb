require "spec_helper"
require "heroku/command/keys"

module Heroku::Command
  describe Keys do
    before do
      @keys = prepare_command(Keys)
      @keys.heroku.stub!(:user).and_return('joe')
    end

    it "tries to find a key if no key filename is supplied" do
      Heroku::Auth.should_receive(:get_credentials)
      Heroku::Auth.should_receive(:associate_or_generate_ssh_key)
      @keys.add
    end

    it "adds a key from a specified keyfile path" do
      @keys.stub!(:args).and_return(['/my/key.pub'])
      @keys.should_not_receive(:find_key)
      File.should_receive(:read).with('/my/key.pub').and_return('ssh-rsa xyz')
      @keys.heroku.should_receive(:add_key).with('ssh-rsa xyz')
      @keys.add
    end

    it "list keys, trimming the hex code for better display" do
      @keys.heroku.should_receive(:keys).and_return(["ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAp9AJD5QABmOcrkHm6SINuQkDefaR0MUrfgZ1Pxir3a4fM1fwa00dsUwbUaRuR7FEFD8n1E9WwDf8SwQTHtyZsJg09G9myNqUzkYXCmydN7oGr5IdVhRyv5ixcdiE0hj7dRnOJg2poSQ3Qi+Ka8SVJzF7nIw1YhuicHPSbNIFKi5s0D5a+nZb/E6MNGvhxoFCQX2IcNxaJMqhzy1ESwlixz45aT72mXYq0LIxTTpoTqma1HuKdRY8HxoREiivjmMQulYP+CxXFcMyV9kxTKIUZ/FXqlC6G5vSm3J4YScSatPOj9ID5HowpdlIx8F6y4p1/28r2tTl4CY40FFyoke4MQ== pedro@heroku\n"])
      @keys.should_receive(:display).with('ssh-rsa AAAAB3NzaC...Fyoke4MQ== pedro@heroku')
      @keys.index
    end

    it "list keys showing the whole key hex with --long" do
      @keys.stub(:options).and_return(:long => true)
      @keys.heroku.should_receive(:keys).and_return(["ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAp9AJD5QABmOcrkHm6SINuQkDefaR0MUrfgZ1Pxir3a4fM1fwa00dsUwbUaRuR7FEFD8n1E9WwDf8SwQTHtyZsJg09G9myNqUzkYXCmydN7oGr5IdVhRyv5ixcdiE0hj7dRnOJg2poSQ3Qi+Ka8SVJzF7nIw1YhuicHPSbNIFKi5s0D5a+nZb/E6MNGvhxoFCQX2IcNxaJMqhzy1ESwlixz45aT72mXYq0LIxTTpoTqma1HuKdRY8HxoREiivjmMQulYP+CxXFcMyV9kxTKIUZ/FXqlC6G5vSm3J4YScSatPOj9ID5HowpdlIx8F6y4p1/28r2tTl4CY40FFyoke4MQ== pedro@heroku\n"])
      @keys.should_receive(:display).with("ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAp9AJD5QABmOcrkHm6SINuQkDefaR0MUrfgZ1Pxir3a4fM1fwa00dsUwbUaRuR7FEFD8n1E9WwDf8SwQTHtyZsJg09G9myNqUzkYXCmydN7oGr5IdVhRyv5ixcdiE0hj7dRnOJg2poSQ3Qi+Ka8SVJzF7nIw1YhuicHPSbNIFKi5s0D5a+nZb/E6MNGvhxoFCQX2IcNxaJMqhzy1ESwlixz45aT72mXYq0LIxTTpoTqma1HuKdRY8HxoREiivjmMQulYP+CxXFcMyV9kxTKIUZ/FXqlC6G5vSm3J4YScSatPOj9ID5HowpdlIx8F6y4p1/28r2tTl4CY40FFyoke4MQ== pedro@heroku")
      @keys.index
    end
  end
end
