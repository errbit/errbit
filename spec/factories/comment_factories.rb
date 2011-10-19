Factory.define :comment do |c|
  c.user       {|u| u.association :user}
  c.body       'Test comment'
  c.err        {|e| e.association :problem}
end

