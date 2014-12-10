require 'singleton'

class Measurement
end

class BaseUnit
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def base_unit
    self
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
end

class NullUnit
  include Singleton

  def name
    ''
  end

  def base_unit
    self
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