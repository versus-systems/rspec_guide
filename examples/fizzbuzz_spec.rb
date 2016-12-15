def fizzbuzz n
  result = ''
  result += 'Fizz' if (n % 3).zero?
  result += 'Buzz' if (n % 5).zero?
  result.empty? ? n : result
end

describe '#fizzbuzz' do
  it 'returns 1 given 1' do
    expect(fizzbuzz 1).to eq 1
  end

  it 'returns 2 given 2' do
    expect(fizzbuzz 2).to eq 2
  end

  it 'returns "Fizz" given 3' do
    expect(fizzbuzz 3).to eq 'Fizz'
  end

  it 'returns "Buzz" given 5' do
    expect(fizzbuzz 5).to eq 'Buzz'
  end

  it 'returns "Fizz" given 6' do
    expect(fizzbuzz 6).to eq 'Fizz'
  end

  it 'returns 8 given 8' do
    expect(fizzbuzz 8).to eq 8
  end

  it 'returns "Buzz" given 10' do
    expect(fizzbuzz 10).to eq 'Buzz'
  end

  it 'returns "FizzBuzz" given 15' do
    expect(fizzbuzz 15).to eq 'FizzBuzz'
  end
end
