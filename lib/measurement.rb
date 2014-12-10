require 'singleton'

class Measurement
  include Comparable

  attr_reader :amount, :unit

  def initialize(amount, unit)
    @amount = amount
    @unit = unit
  end

  def +(measurement)
    if @unit == measurement.unit
      result = Measurement.new(@amount + measurement.amount, @unit)
    else
      lhs = @unit.convert_amount_base_units(@amount)
      rhs = measurement.unit.convert_amount_base_units(measurement.amount)

      if lhs.unit == rhs.unit
        result = Measurement.new(lhs.amount + rhs.amount, lhs.unit)
      else
        fail("#{@unit.name} and #{measurement.unit.name} are not compatible")
      end
    end

    if result.amount == 0
      NullMeasurement.instance
    else
      result
    end
  end

  def -(measurement)
    if @unit == measurement.unit
      result = Measurement.new(@amount - measurement.amount, @unit)
    else
      lhs = @unit.convert_amount_base_units(@amount)
      rhs = measurement.unit.convert_amount_base_units(measurement.amount)

      if lhs.unit == rhs.unit
        result = Measurement.new(lhs.amount - rhs.amount, lhs.unit)
      else
        fail("#{@unit.name} and #{measurement.unit.name} are not compatible")
      end
    end


    if result.amount == 0
      NullMeasurement.instance
    else
      result
    end
  end

  def *(measurement)
    if @unit == measurement.unit || [@unit, measurement.unit].include?(NullUnit.instance)
      Measurement.new(@amount * measurement.amount, @unit * measurement.unit)
    else
      lhs = @unit.convert_amount_base_units(@amount)
      rhs = measurement.unit.convert_amount_base_units(measurement.amount)
      Measurement.new(lhs.amount * rhs.amount, lhs.unit * rhs.unit)
    end
  end

  def /(measurement)
    if @unit == measurement.unit || [@unit, measurement.unit].include?(NullUnit.instance)
      Measurement.new(@amount / measurement.amount, @unit / measurement.unit)
    else
      lhs = @unit.convert_amount_base_units(@amount)
      rhs = measurement.unit.convert_amount_base_units(measurement.amount)
      Measurement.new(lhs.amount / rhs.amount, lhs.unit / rhs.unit)
    end
  end

  def <=>(measurement)
    if @unit == measurement.unit
      lhs, rhs = self, measurement
    else
      lhs = @unit.convert_amount_base_units(@amount)
      rhs = measurement.unit.convert_amount_base_units(measurement.amount)

      if lhs.unit != rhs.unit
        fail("#{@unit.name} and #{measurement.unit.name} are not compatible")
      end
    end
    lhs.amount <=> rhs.amount
  end

  def to_s
    "#{@amount} #{@unit.name}"
  end
end

class NullMeasurement
  include Singleton

  def amount
    0
  end

  def unit
    NullUnit.instance
  end
end

class BaseUnit
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def base_unit
    self
  end

  def convert_amount_base_units(amount)
    Measurement.new(amount, self)
  end

  def *(unit)
    case unit
      when BaseUnit, ProportionalDerivedUnit
        MultipliedUnit.new([self, unit])
      when MultipliedUnit
        MultipliedUnit.new([self] + unit.factors)
      when DividedUnit
        DividedUnit.new(self * unit.numerator, unit.denominator)
      when NullUnit
        self
    end
  end

  def /(unit)
    case unit
      when BaseUnit, ProportionalDerivedUnit
        DividedUnit.new(self, unit)
      when DividedUnit
        DividedUnit.new(MultipliedUnit.new([self, unit.denominator]),
                        unit.numerator)
      when MultipliedUnit
        DividedUnit.new(self, unit)
      when NullUnit
        self
    end
  end
end

class ProportionalDerivedUnit < BaseUnit
  attr_reader :name, :factor, :base_unit

  def initialize(name, factor, base_unit)
    @name = name
    @factor = factor
    @base_unit = base_unit
  end

  def convert_amount_base_units(amount)
    Measurement.new(amount * @factor, @base_unit)
  end
end

class NullUnit
  include Singleton

  def name
    ''
  end

  def base_unit
    self
  end

  def convert_amount_base_units(amount)
    Measurement.new(amount, self)
  end

  def *(unit)
    unit
  end

  def /(unit)
    case unit
      when DividedUnit
        DividedUnit.new(unit.denominator, unit.numerator)
      when NullUnit
        self
      else
        DividedUnit.new(self, unit)
    end
  end
end

class DividedUnit
  attr_reader :numerator, :denominator

  def self.new(numerator, denominator)
    if numerator == denominator
      NullUnit.instance
    else
      super(numerator, denominator)
    end
  end

  def initialize(numerator, denominator)
    @numerator = numerator
    @denominator = denominator
  end

  def name
    if @denominator.is_a?(MultipliedUnit)
      "#{@numerator.name} / (#{@denominator.name})"
    else
      "#{@numerator.name} / #{@denominator.name}"
    end
  end

  def base_unit
    DividedUnit.new(@numerator.base_unit, @denominator.base_unit)
  end

  def convert_amount_base_units(amount)
    Measurement.new(
      @numerator.convert_amount_base_units(amount).amount /
        @denominator.convert_amount_base_units(1).amount,
      base_unit
    )
  end

  def *(unit)
    case unit
      when BaseUnit, ProportionalDerivedUnit
        DividedUnit.new(@numerator * unit, @denominator)
      when DividedUnit
        DividedUnit.new(@numerator * unit.numerator,
                        @denominator * unit.denominator)
      when MultipliedUnit
        DividedUnit.new(@numerator * unit, @denominator)
      when NullUnit
        self
    end
  end

  def /(unit)
    case unit
      when BaseUnit, ProportionalDerivedUnit
        DividedUnit.new(@numerator, @denominator * unit)
      when DividedUnit
        DividedUnit.new(@numerator * unit.denominator,
                        @denominator * unit.numerator)
      when MultipliedUnit
        DividedUnit.new(@numerator, @denominator * unit)
      when NullUnit
        self
    end
  end
end

class MultipliedUnit
  attr_reader :factors

  def initialize(factors)
    @factors = factors
  end

  def name
    @factors.map(&:name).join(' * ')
  end

  def base_unit
    MultipliedUnit.new(@factors.map(&:base_unit))
  end

  def convert_amount_base_units(amount)
    @factors.each do |factor|
      amount = factor.convert_amount_base_units(amount).amount
    end
    Measurement.new(amount, base_unit)
  end

  def *(unit)
    case unit
      when BaseUnit, ProportionalDerivedUnit
        MultipliedUnit.new(factors + [unit])
      when DividedUnit
        DividedUnit.new(self * unit.numerator, unit.denominator)
      when MultipliedUnit
        MultipliedUnit.new(factors + unit.factors)
      when NullUnit
        self
    end
  end

  def /(unit)
    case unit
      when BaseUnit, ProportionalDerivedUnit
        DividedUnit.new(self, unit)
      when DividedUnit
        DividedUnit.new(self * unit.denominator, unit.numerator)
      when MultipliedUnit
        DividedUnit.new(self, unit)
      when NullUnit
        self
    end
  end
end

class Numeric
  def amount
    self
  end

  def unit
    NullUnit.instance
  end
end