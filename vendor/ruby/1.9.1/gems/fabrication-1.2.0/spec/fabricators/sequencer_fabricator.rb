Fabricator(:sequencer) do
  simple_iterator { sequence }
  param_iterator  { sequence(:param_iterator, 9) }
  block_iterator  { sequence(:block_iterator) { |i| "block#{i}" } }
end

Fabricator("Sequencer::Namespaced") do
  iterator { sequence(:iterator) }
end
