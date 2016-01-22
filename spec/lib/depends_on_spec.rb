require 'spec_helper'
require 'depends_on'

describe DependsOn do

  before do
    class ExampleClassDependency; end
    module ExampleModuleDependency; end
    class ExampleDependentClass < ExampleClassDependency; end
    ExampleDependentClass.include(ExampleModuleDependency)
    ExampleDependentClass.include(DependsOn)
  end

  after do
    [:ExampleClassDependency, :ExampleModuleDependency, :ExampleDependentClass].each do |class_name|
      Object.send(:remove_const, class_name)
    end    
  end

  describe '.depends_on' do
    it 'raises an exception if the class does not inherit from any one of the specified dependencies' do
      expect{ ExampleDependentClass.depends_on("ExampleClassDependency", "ExampleModuleDependency", "foo") }.to raise_error DependsOn::MissingDependencies
    end

    it 'does not raise an exception if the class inherits from all of the specified dependencies' do
      expect{ ExampleDependentClass.depends_on("ExampleClassDependency", "ExampleModuleDependency") }.to_not raise_error DependsOn::MissingDependencies
    end
  end

end