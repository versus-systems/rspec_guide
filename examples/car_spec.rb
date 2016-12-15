class FuelTank
  def fuel
  end

  def burn gallons
  end
end

class Car
  attr_reader :color, :fuel_tank, :odometer

  def initialize color, fuel_tank=FuelTank.new
    @color = color
    @fuel_tank = fuel_tank
    @odometer = 0
  end

  def popular?
    color == :red
  end

  def range
    fuel_tank.fuel * 20
  end

  def drive miles
    fuel_tank.burn(miles / 20)
    @odometer += miles
  end
end

describe Car do
  subject(:car) { Car.new color, fuel_tank }
  let(:fuel_tank) { instance_double 'FuelTank', fuel: fuel, burn: nil }
  let(:color) { :white }
  let(:fuel) { 0 }

  describe '#popular?' do
    context 'when the car is red' do
      let(:color) { :red }

      it { is_expected.to be_popular }
    end

    context 'when the car is blue' do
      let(:color) { :blue }

      it { is_expected.to_not be_popular }
    end
  end

  describe '#range' do
    context 'with a tank with 3 gallons of fuel' do
      let(:fuel) { 3 }

      specify { expect(car.range).to eq 60 }
    end

    context 'with a tank with 5 gallons of fuel' do
      let(:fuel) { 5 }

      specify { expect(car.range).to eq 100 }
    end
  end

  describe '#drive' do
    context 'when driving 20 miles' do
      let(:fuel) { 1 }

      specify { expect { car.drive 20 }.to change(car, :odometer).by 20 }

      it 'burns 1 gallon of fuel' do
        expect(fuel_tank).to receive(:burn).with 1
        car.drive 20
      end
    end

    context 'when driving 40 miles' do
      let(:fuel) { 2 }

      specify { expect { car.drive 40 }.to change(car, :odometer).by 40 }

      it 'burns 2 gallons of fuel' do
        expect(fuel_tank).to receive(:burn).with 2
        car.drive 40
      end
    end
  end
end
