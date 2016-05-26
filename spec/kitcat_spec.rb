require 'spec_helper'

describe KitCat do
  it 'behaves same as Kitcat' do
    expect(described_class).to eq(Kitcat)
    expect(described_class::Framework).to eq(Kitcat::Framework)
  end
end
